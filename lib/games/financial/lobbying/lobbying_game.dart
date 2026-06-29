import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// LobbyingGame — "Lobbying"  (BioScale.financial)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Light potato-politics SATIRE about public choice. You run a spud-lobby PAC: a
// BILL comes up for a vote, a panel of OFFICIALS each have a leaning (a starting
// yes-chance) and a PRICE, and you spend a LOBBYING BUDGET on the right officials
// to swing enough of them YES before the vote timer runs out. Pass the bill → it
// pays out (concentrated benefit to you, diffuse cost to everyone). Fail → your
// spend is gone.
//
// The teaching is in the visible cost→probability curve:
//   • Influence on an official has DIMINISHING RETURNS — a saturating swing, so
//     the marginal "+Δ%" each card shows shrinks as you pour money in.
//   • A live PROJECTED pass-% (poisson-binomial over the panel) lets you watch
//     where a dollar actually moves the outcome — cheap swing votes near 50%
//     move it most; padding a sure thing or a lost cause is waste.
//   • A rival lobby pushes back over time (opposition creeps your gains down).
//   • OVERREACH heats an official up; max heat = SCANDAL (lose budget, bill dies).
//
// Score = total payouts BANKED in 60s, reported via session.addScore on each
// passed bill. The host (MiniGameHost) owns the clock / countdown / results; this
// widget only runs the sim while session.isRunning.

// --- Economy / tuning -------------------------------------------------------
const double _kStartBudget = 250.0; // opening PAC war chest
const double _kTrickle = 4.5; // passive small-donor income, $/sec
const double _kUnitCost = 18.0; // $ per "influence unit" at price 1.0
const double _kMaxSwing = 0.60; // ceiling a fully-funded official can be swung
const double _kSwingScale = 1.5; // units → swing curve constant (saturation)
const double _kSaturationUnits = 3.0; // past this, marginal gain is tiny → heat
const double _kHeatGain = 0.32; // heat added per over-saturated unit invested
const double _kHeatCool = 0.06; // heat bled off per second
const double _kScandalPenalty = 120.0; // budget lost when an official scandals

// --- Bill / panel escalation (lerped by elapsed fraction) -------------------
const double _kPayoutMin = 160.0;
const double _kPayoutMax = 440.0;
const double _kVoteTimeMax = 11.0; // seconds for an early, leisurely bill
const double _kVoteTimeMin = 6.0; // seconds for a late, frantic bill
const double _kOppRateMin = 0.014; // rival lobby pushback, per sec (early)
const double _kOppRateMax = 0.052; // (late)
const double _kOppCap = 0.40; // most the rival lobby can drag an official down

const List<int> _kDonations = [10, 25, 50, 100];

const Color _kGreen = Color(0xFF66BB6A);
const Color _kRed = Color(0xFFEF5350);

// Satirical potato bills: [title, "who wins · who pays"].
const List<List<String>> _kBills = [
  ['Fryer Subsidy Act', 'Tax credit for Big Fry · paid by every grocery shopper'],
  ['National Tot Reserve', 'Strategic tater-tot stockpile · funded from general budget'],
  ['Couch Potato Protection Act', 'Snack rights for loungers · cost spread to all'],
  ['Gravy Infrastructure Bill', 'Gravy pipelines to stadiums · everyone chips in'],
  ['Peeler Deregulation', 'Looser peeler safety rules · risk borne by consumers'],
  ['Mash Neutrality Act', 'Equal lumps for all mash · admin cost socialized'],
  ['Spud Tax Loophole', 'Carve-out for offshore potatoes · revenue lost to all'],
  ['Right to Bear Spuds', 'Constitutional potato carry · enforced on the public dime'],
  ['Sweet Potato Reclassification', '"Not a real potato" decree · litigation funded publicly'],
  ['Butter Ration Mandate', 'Guaranteed butter quotas · subsidized by the treasury'],
  ['Hash Brown Bailout', 'Rescue for failing hash chains · billed to taxpayers'],
];

const List<String> _kTitles = [
  'Senator', 'Rep.', 'Gov.', 'Mayor', 'Chair', 'Whip', 'Delegate', 'Sec.',
];
const List<String> _kSurnames = [
  'Russet', 'Yukon', 'Maris', 'Desiree', 'Kennebec', 'Fingerling',
  'Idaho', 'Spud', 'Bintje', 'Rooster', 'Charlotte', 'Vivaldi',
];

/// One official on the current bill's panel. [baseLean] is their starting
/// yes-chance; [invested] is what you've spent on them; [opposition] is the
/// rival lobby's accumulated pushback; [heat] is scandal risk from overreach.
class _Official {
  final String name;
  final double baseLean;
  final double price;
  double invested = 0.0;
  double opposition = 0.0;
  double heat = 0.0;
  _Official(this.name, this.baseLean, this.price);
}

/// One bill up for a vote.
class _Bill {
  final String title;
  final String subtitle;
  final int payout;
  final int need; // yes votes required to pass
  final List<_Official> panel;
  _Bill(this.title, this.subtitle, this.payout, this.need, this.panel);
}

/// A floating callout (pass/fail/scandal/marginal pops).
class _Pop {
  Offset pos;
  final String label;
  final Color color;
  final double size;
  double life = 1.1;
  _Pop(this.pos, this.label, this.color, {this.size = 20});
  bool step(double dt) {
    pos = pos.translate(0, -46 * dt);
    life -= dt / 1.1;
    return life > 0;
  }

  void paint(Canvas canvas) {
    final a = life.clamp(0.0, 1.0);
    GameFx.text(canvas, label, pos, size, color.withValues(alpha: a),
        weight: FontWeight.w800, glow: 0.8 * a);
  }
}

class LobbyingGame extends StatefulWidget {
  final MiniGameSession session;
  const LobbyingGame({super.key, required this.session});
  @override
  State<LobbyingGame> createState() => _LobbyingGameState();
}

class _LobbyingGameState extends State<LobbyingGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  double _budget = _kStartBudget;
  int _banked = 0; // total payouts won → mirrors session.score
  int _streak = 0;
  int _donation = 25;

  late _Bill _bill;
  double _voteTimer = 0;
  double _voteMax = 1;

  double _elapsed = 0.0; // visual clock for the background drift

  final List<FxParticle> _fx = [];
  final List<_Pop> _pops = [];
  Color _flashColor = Colors.transparent;
  double _flashAlpha = 0.0;

  Size _screen = Size.zero;

  static const Color _accent = Color(0xFF9CCC65);

  // ─── Escalation ───────────────────────────────────────────────────────────
  double get _progress {
    final remaining =
        widget.session.remaining.inMilliseconds / 1000.0;
    final t = 1.0 - (remaining / widget.session.spec.durationSeconds);
    return t.clamp(0.0, 1.0);
  }

  double get _oppRate =>
      _kOppRateMin + (_kOppRateMax - _kOppRateMin) * _progress;

  @override
  void initState() {
    super.initState();
    _bill = _makeBill();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Influence model ────────────────────────────────────────────────────────
  double _swingFor(double invested, double price) =>
      _kMaxSwing *
      (1 - math.exp(-(invested / (price * _kUnitCost)) / _kSwingScale));

  double _yesProb(_Official o) =>
      (o.baseLean + _swingFor(o.invested, o.price) - o.opposition)
          .clamp(0.02, 0.98);

  double _yesProbWith(_Official o, double extra) =>
      (o.baseLean + _swingFor(o.invested + extra, o.price) - o.opposition)
          .clamp(0.02, 0.98);

  /// P(at least [bill.need] of the panel vote YES) — exact poisson-binomial DP.
  double _passProbability() {
    final n = _bill.panel.length;
    final dp = List<double>.filled(n + 1, 0.0);
    dp[0] = 1.0;
    int filled = 0;
    for (final o in _bill.panel) {
      final p = _yesProb(o);
      for (int j = filled + 1; j >= 1; j--) {
        dp[j] = dp[j] * (1 - p) + dp[j - 1] * p;
      }
      dp[0] = dp[0] * (1 - p);
      filled++;
    }
    double sum = 0;
    for (int j = _bill.need; j <= n; j++) {
      sum += dp[j];
    }
    return sum;
  }

  // ─── Bill generation ────────────────────────────────────────────────────────
  _Bill _makeBill() {
    final t = _progress;
    final n = t < 0.38 ? 5 : (t < 0.72 ? 6 : 7);
    final need = (n ~/ 2) + 1;
    final payout = (_kPayoutMin + (_kPayoutMax - _kPayoutMin) * t).round();
    final priceScale = 1.0 + 0.45 * t;

    final bill = _kBills[_rng.nextInt(_kBills.length)];
    final used = <String>{};
    final panel = <_Official>[];
    for (int i = 0; i < n; i++) {
      String name;
      do {
        name = '${_kTitles[_rng.nextInt(_kTitles.length)]} '
            '${_kSurnames[_rng.nextInt(_kSurnames.length)]}';
      } while (!used.add(name));
      final baseLean = 0.18 + _rng.nextDouble() * 0.5; // 0.18 .. 0.68
      final price = (0.8 + _rng.nextDouble() * 1.9) * priceScale;
      panel.add(_Official(name, baseLean, price));
    }

    _voteMax = _kVoteTimeMax + (_kVoteTimeMin - _kVoteTimeMax) * t;
    _voteTimer = _voteMax;
    return _Bill(bill[0], bill[1], payout, need, panel);
  }

  void _nextBill() {
    _bill = _makeBill();
  }

  // ─── Main loop (host owns the wall clock) ───────────────────────────────────
  void _tick() {
    const dt = 1 / 60.0;
    setState(() {
      _elapsed += dt;
      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
      if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 2.4).clamp(0.0, 1.0);

      if (!widget.session.isRunning) return;

      // Passive small-donor income.
      _budget += dt * _kTrickle;

      // Rival lobby pushback + heat cooldown.
      final rate = _oppRate;
      for (final o in _bill.panel) {
        // The rival concentrates on officials currently leaning your way.
        final lean = _yesProb(o);
        o.opposition =
            (o.opposition + dt * rate * (0.35 + math.max(0.0, lean - 0.4)))
                .clamp(0.0, _kOppCap);
        if (o.heat > 0) {
          o.heat = (o.heat - dt * _kHeatCool).clamp(0.0, 1.0);
        }
      }

      // Vote timer.
      _voteTimer -= dt;
      if (_voteTimer <= 0) {
        _resolve(calledEarly: false);
      }
    });
  }

  // ─── Spending influence ─────────────────────────────────────────────────────
  void _invest(_Official o) {
    if (!widget.session.isRunning) return;
    if (_budget < _donation - 1e-6) {
      _flashColor = _kRed;
      _flashAlpha = 0.14;
      return;
    }
    final pBefore = _yesProb(o);
    final unitsBefore = o.invested / (o.price * _kUnitCost);
    o.invested += _donation;
    _budget -= _donation;
    final unitsAfter = o.invested / (o.price * _kUnitCost);

    // Overreach past the saturation point heats the official up.
    if (unitsAfter > _kSaturationUnits) {
      final over = unitsAfter - math.max(unitsBefore, _kSaturationUnits);
      o.heat = (o.heat + over * _kHeatGain).clamp(0.0, 1.0);
    }

    if (o.heat >= 1.0) {
      _triggerScandal(o);
      return;
    }

    final pAfter = _yesProb(o);
    final delta = (pAfter - pBefore) * 100;
    _popAt(0.5, 0.18,
        '+${delta.toStringAsFixed(delta >= 1 ? 0 : 1)}%', _accent,
        size: 16);
    _spawnFx(_accent, count: 6, speed: 60, yFrac: 0.2);
  }

  void _triggerScandal(_Official o) {
    final penalty = math.min(_budget, _kScandalPenalty);
    _budget -= penalty;
    _streak = 0;
    _flashColor = _kRed;
    _flashAlpha = 0.34;
    _popAt(0.5, 0.34, 'SCANDAL!  -\$${penalty.toStringAsFixed(0)}', _kRed,
        size: 22);
    _spawnFx(_kRed, count: 18, speed: 140, yFrac: 0.34);
    _nextBill();
  }

  // ─── Resolving a vote ───────────────────────────────────────────────────────
  void _callVote() {
    if (!widget.session.isRunning) return;
    setState(() => _resolve(calledEarly: true));
  }

  void _resolve({required bool calledEarly}) {
    int yes = 0;
    for (final o in _bill.panel) {
      if (_rng.nextDouble() < _yesProb(o)) yes++;
    }
    final passed = yes >= _bill.need;
    if (passed) {
      final payout = _bill.payout;
      _budget += payout;
      _banked += payout;
      _streak++;
      widget.session.addScore(payout);
      widget.session.noteStreak(_streak);
      _flashColor = _kGreen;
      _flashAlpha = 0.30;
      _popAt(0.5, 0.30,
          'PASSED  +\$$payout  ($yes/${_bill.panel.length})', _kGreen,
          size: 22);
      _spawnFx(Potatuhs.gold, count: 22, speed: 160, yFrac: 0.30);
    } else {
      _streak = 0;
      _flashColor = _kRed;
      _flashAlpha = 0.24;
      _popAt(0.5, 0.30, 'FAILED  ($yes/${_bill.panel.length} yes)', _kRed,
          size: 20);
      _spawnFx(_kRed, count: 12, speed: 110, yFrac: 0.30);
    }
    _nextBill();
  }

  // ─── FX helpers ─────────────────────────────────────────────────────────────
  void _spawnFx(Color color,
      {int count = 10, double speed = 90, double yFrac = 0.3}) {
    if (_screen == Size.zero) return;
    final center = Offset(_screen.width / 2, _screen.height * yFrac);
    _fx.addAll(FxBurst.spawn(center, color, count: count, speed: speed));
  }

  void _popAt(double xFrac, double yFrac, String label, Color color,
      {double size = 20}) {
    final pos = _screen == Size.zero
        ? const Offset(160, 200)
        : Offset(_screen.width * xFrac, _screen.height * yFrac);
    _pops.add(_Pop(pos, label, color, size: size));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      _screen = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BgPainter(_elapsed, _accent),
            ),
          ),
        ),
        if (_flashAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: _flashColor.withValues(alpha: _flashAlpha),
              ),
            ),
          ),
        SafeArea(
          child: Column(children: [
            _buildBillBanner(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                physics: const ClampingScrollPhysics(),
                itemCount: _bill.panel.length,
                itemBuilder: (c, i) => _buildOfficialCard(_bill.panel[i]),
              ),
            ),
            _buildControlBar(),
            const SizedBox(height: 6),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FxPainter(_fx, _pops)),
          ),
        ),
      ]);
    });
  }

  // ─── Bill banner: title, who-pays, payout, NEED, projected %, vote timer ───
  Widget _buildBillBanner() {
    final pass = _passProbability();
    final passPct = (pass * 100).round();
    final passCol = Color.lerp(_kRed, _kGreen, pass)!;
    final timeFrac = (_voteTimer / _voteMax).clamp(0.0, 1.0);
    final urgent = _voteTimer <= 3.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.92),
        borderColor: _accent.withValues(alpha: 0.4),
        radius: 14,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_bill.title,
                      style: Potatuhs.display(size: 17, color: Potatuhs.gold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(_bill.subtitle,
                      style: Potatuhs.label(
                          size: 8, color: Potatuhs.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Potatuhs.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Potatuhs.gold.withValues(alpha: 0.6)),
              ),
              child: Text('PAYS \$${_bill.payout}',
                  style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
            ),
            const SizedBox(height: 3),
            Text('NEED ${_bill.need}/${_bill.panel.length} YES',
                style:
                    Potatuhs.label(size: 8, color: Potatuhs.textSecondary)),
          ]),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('PROJECTED',
              style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
          const SizedBox(width: 8),
          Text('$passPct%',
              style: Potatuhs.display(size: 22, color: passCol).copyWith(
                  shadows: [
                    Shadow(
                        color: passCol.withValues(alpha: 0.5), blurRadius: 12)
                  ])),
          const SizedBox(width: 6),
          Text('to pass',
              style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
          const Spacer(),
          Icon(Icons.timer,
              size: 13,
              color: urgent ? _kRed : Potatuhs.textSecondary),
          const SizedBox(width: 4),
          Text('${_voteTimer.clamp(0, 99).toStringAsFixed(1)}s',
              style: Potatuhs.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: urgent ? _kRed : Potatuhs.textPrimary)),
        ]),
        const SizedBox(height: 6),
        // Vote timer bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(children: [
            Container(height: 5, color: Colors.white.withValues(alpha: 0.08)),
            FractionallySizedBox(
              widthFactor: timeFrac,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: urgent ? _kRed : _accent,
                  boxShadow: [
                    BoxShadow(
                        color: (urgent ? _kRed : _accent)
                            .withValues(alpha: 0.6),
                        blurRadius: 6)
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── One official card (tap to invest the selected donation) ───────────────
  Widget _buildOfficialCard(_Official o) {
    final p = _yesProb(o);
    final pPct = (p * 100).round();
    final barCol = Color.lerp(_kRed, _kGreen, p)!;
    final marginal = (_yesProbWith(o, _donation.toDouble()) - p) * 100;
    final affordable = _budget >= _donation - 1e-6;
    final leanLabel = o.baseLean >= 0.55
        ? 'SPUD-FRIENDLY'
        : (o.baseLean >= 0.42 ? 'SWING VOTE' : 'BIG-MASH ALLY');
    final leanCol = o.baseLean >= 0.55
        ? _kGreen
        : (o.baseLean >= 0.42 ? Potatuhs.sienna : Potatuhs.airForce);

    return GestureDetector(
      onTap: () => setState(() => _invest(o)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
        decoration: Potatuhs.surface(
          fill: Potatuhs.inkPanel.withValues(alpha: affordable ? 0.8 : 0.5),
          borderColor: o.heat > 0.55
              ? _kRed.withValues(alpha: 0.5 + 0.4 * o.heat)
              : _accent.withValues(alpha: 0.25),
          radius: 12,
        ),
        child: Column(children: [
          Row(children: [
            const Text('\u{1F954}', style: TextStyle(fontSize: 16)), // potato
            const SizedBox(width: 7),
            Expanded(
              child: Text(o.name,
                  style: Potatuhs.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Potatuhs.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: leanCol.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(leanLabel,
                  style: Potatuhs.label(size: 7, color: leanCol)),
            ),
          ]),
          const SizedBox(height: 6),
          // Yes-probability bar.
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 14,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FractionallySizedBox(
                widthFactor: p,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      barCol.withValues(alpha: 0.5),
                      barCol,
                    ]),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text('$pPct% YES',
                    style: Potatuhs.label(
                        size: 8, color: Potatuhs.textPrimary)),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('\$${o.invested.toStringAsFixed(0)} in',
                style: Potatuhs.label(
                    size: 9,
                    color: o.invested > 0
                        ? Potatuhs.gold
                        : Potatuhs.textFaint)),
            const SizedBox(width: 8),
            Text('price ${o.price.toStringAsFixed(1)}×',
                style: Potatuhs.label(size: 8, color: Potatuhs.textFaint)),
            const Spacer(),
            // Marginal preview — the "where a dollar moves the needle" readout.
            Text(
              marginal < 0.15
                  ? 'next \$$_donation: ~0% (saturated)'
                  : 'next \$$_donation: +${marginal.toStringAsFixed(marginal >= 1 ? 0 : 1)}%',
              style: Potatuhs.label(
                  size: 9,
                  color: marginal < 0.15
                      ? _kRed.withValues(alpha: 0.8)
                      : _accent),
            ),
          ]),
          if (o.heat > 0.02) ...[
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.local_fire_department,
                  size: 11, color: _kRed.withValues(alpha: 0.5 + 0.5 * o.heat)),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(children: [
                    Container(
                        height: 4, color: Colors.white.withValues(alpha: 0.06)),
                    FractionallySizedBox(
                      widthFactor: o.heat,
                      child: Container(height: 4, color: _kRed),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              Text('SCANDAL RISK',
                  style: Potatuhs.label(
                      size: 7,
                      color: _kRed.withValues(alpha: 0.4 + 0.5 * o.heat))),
            ]),
          ],
        ]),
      ),
    );
  }

  // ─── Bottom control bar: budget, donation size, CALL VOTE ──────────────────
  Widget _buildControlBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.92),
        borderColor: _accent.withValues(alpha: 0.35),
        radius: 14,
      ),
      child: Column(children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('WAR CHEST',
                style: Potatuhs.label(size: 8, color: Potatuhs.textFaint)),
            Text('\$${_budget.toStringAsFixed(0)}',
                style: Potatuhs.body(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Potatuhs.textPrimary)),
          ]),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BANKED',
                style: Potatuhs.label(size: 8, color: Potatuhs.textFaint)),
            Text('\$$_banked',
                style: Potatuhs.body(
                    size: 18, weight: FontWeight.w800, color: _kGreen)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: _callVote,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF558B2F), Color(0xFF8BC34A)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.85)),
                boxShadow: [
                  BoxShadow(
                      color: _accent.withValues(alpha: 0.3), blurRadius: 12)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('CALL VOTE',
                      style: Potatuhs.display(
                          size: 14, color: Potatuhs.inkDeep)),
                  Text('resolve now',
                      style: Potatuhs.label(
                          size: 7,
                          color: Potatuhs.inkDeep.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('DONATE',
              style: Potatuhs.label(size: 9, color: Potatuhs.gold)),
          const SizedBox(width: 8),
          ..._kDonations.map((d) {
            final active = _donation == d;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _donation = d),
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? Potatuhs.gold.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active
                            ? Potatuhs.gold.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text('\$$d',
                        style: Potatuhs.body(
                            size: 14,
                            weight: FontWeight.w800,
                            color: active
                                ? Potatuhs.gold
                                : Potatuhs.textSecondary)),
                  ),
                ),
              ),
            );
          }),
        ]),
        const SizedBox(height: 4),
        Text('Tap an official to spend · diminishing returns · overreach = scandal',
            style: Potatuhs.label(size: 7, color: Potatuhs.textFaint),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Background painter ─────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  final Color accent;
  _BgPainter(this.t, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accent, t, motes: 22);
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => true;
}

// ─── FX overlay painter ─────────────────────────────────────────────────────
class _FxPainter extends CustomPainter {
  final List<FxParticle> particles;
  final List<_Pop> pops;
  _FxPainter(this.particles, this.pops);
  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) => true;
}
