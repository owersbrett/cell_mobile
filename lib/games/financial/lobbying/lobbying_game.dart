import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
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
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to lobby itself. Registered always
    // (harmless in normal play — the host only calls it in hands-free mode).
    // See [_autoStep]. This is an action game, so it acts every host tick.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ─── ATTRACT autopilot ──────────────────────────────────────────────────────
  /// One hands-free lobbying move per host tick (~250ms). Deterministic, no
  /// synthetic taps: it reads the live panel and spends ONE donation on the
  /// official whose nudge most raises the bill's projected pass-% — i.e. a cheap
  /// swing vote near the flip point, not a sure thing (wasted, diminishing
  /// returns) or a lost cause. It skips overreach (scandal risk) and stops once
  /// the bill is comfortably passing, so the timer banks the payout cleanly.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    // Already winning → don't overspend; let the vote timer resolve it.
    if (_passProbability() >= 0.85) return;
    // Can't afford the current donation → nothing to do.
    if (_budget < _donation - 1e-6) return;

    final baseline = _passProbability();
    _Official? best;
    double bestGain = 0.0;
    for (final o in _bill.panel) {
      // Diminishing returns / scandal guards: skip officials already safely YES,
      // those a donation would push past saturation, and any running hot.
      if (o.heat > 0.6) continue;
      if (_yesProb(o) >= 0.9) continue;
      final unitsAfter = (o.invested + _donation) / (o.price * _kUnitCost);
      if (unitsAfter > _kSaturationUnits) continue;
      // Marginal improvement to the bill's pass probability from one donation.
      // Evaluate without side effects by briefly toggling invested.
      final saved = o.invested;
      o.invested += _donation;
      final gain = _passProbability() - baseline;
      o.invested = saved;
      if (gain > bestGain) {
        bestGain = gain;
        best = o;
      }
    }
    // Nothing meaningfully movable (every swing is padding or waste) → hold.
    if (best == null || bestGain < 1e-4) return;
    _invest(best);
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
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the sim must
    // advance by wall-clock time regardless of the render rate.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
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

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the REAL in-game
// components (the official card, its yes-% bar, the projected-% banner, the
// scandal heat bar) in the game's own style. Static + cheap: rendered once on
// the intro screen, never per frame. Palette reuses the game's own constants
// (_kGreen / _kRed / the accent green) + lib/theme/potatuhs.dart — no new hex.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kLegendAccent = _LobbyingGameState._accent; // 0xFF9CCC65 (reused)

// A rounded surface panel, matching the game's Potatuhs.surface cards.
void _legendPanel(Canvas c, Rect r, Color fill, Color border,
    {double radius = 12, double stroke = 1.5}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  c.drawRRect(rr, Paint()..color = fill);
  c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = border);
}

// A small rounded chip with centred label — the leaning / payout chips.
void _legendChip(Canvas c, Offset center, String label, double fontSize,
    Color tint) {
  final w = fontSize * (label.length * 0.62) + 14;
  final h = fontSize + 8;
  final r = Rect.fromCenter(center: center, width: w, height: h);
  _legendPanel(c, r, tint.withValues(alpha: 0.18),
      tint.withValues(alpha: 0.55),
      radius: h / 2, stroke: 1);
  GameFx.text(c, label, center, fontSize, tint, weight: FontWeight.w800);
}

// The official's yes-% bar (red→green fill), exactly like the card's bar.
void _legendProbBar(Canvas c, Rect r, double p, {bool showLabel = true}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
  c.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.08));
  final fillW = (r.width * p.clamp(0.0, 1.0));
  if (fillW > 0.5) {
    final col = Color.lerp(_kRed, _kGreen, p.clamp(0.0, 1.0))!;
    c.save();
    c.clipRRect(rr);
    c.drawRect(
      Rect.fromLTWH(r.left, r.top, fillW, r.height),
      Paint()
        ..shader = LinearGradient(colors: [
          col.withValues(alpha: 0.5),
          col,
        ]).createShader(Rect.fromLTWH(r.left, r.top, fillW, r.height)),
    );
    c.restore();
  }
  if (showLabel) {
    GameFx.text(c, '${(p * 100).round()}% YES', r.center,
        (r.height * 0.55).clamp(7.0, 12.0), Potatuhs.textPrimary,
        weight: FontWeight.w800);
  }
}

// One official card: potato portrait, name, leaning chip, yes-% bar. [heat]
// tints the border red and (when > 0) draws a scandal-risk bar under it.
void _legendOfficialCard(Canvas c, Rect r,
    {required String name,
    required double yes,
    required String lean,
    required Color leanCol,
    String? marginal,
    Color? marginalCol,
    double heat = 0}) {
  _legendPanel(
    c,
    r,
    Potatuhs.inkPanel.withValues(alpha: 0.85),
    heat > 0.5
        ? _kRed.withValues(alpha: 0.5 + 0.4 * heat)
        : _kLegendAccent.withValues(alpha: 0.3),
    radius: 12,
  );
  final pad = r.height * 0.14;
  // Potato portrait — the literal '🥔' the game draws on each card.
  final potY = r.top + pad + r.height * 0.14;
  GameFx.text(c, '\u{1F954}', Offset(r.left + pad + r.height * 0.16, potY),
      r.height * 0.28, Potatuhs.textPrimary);
  GameFx.text(
      c,
      name,
      Offset(r.left + pad + r.height * 0.16 + r.width * 0.22, potY),
      (r.height * 0.16).clamp(9.0, 14.0),
      Potatuhs.textPrimary,
      weight: FontWeight.w700);
  // Leaning chip, top-right.
  _legendChip(c, Offset(r.right - pad - r.width * 0.13, potY), lean,
      (r.height * 0.11).clamp(6.0, 9.0), leanCol);
  // Yes-% bar across the middle.
  final barRect = Rect.fromLTWH(
      r.left + pad, r.center.dy - r.height * 0.02, r.width - pad * 2,
      r.height * 0.20);
  _legendProbBar(c, barRect, yes);
  // Marginal readout (the "where a dollar moves the needle" line).
  if (marginal != null) {
    GameFx.text(
        c,
        marginal,
        Offset(r.center.dx, r.bottom - pad - r.height * 0.06),
        (r.height * 0.12).clamp(7.0, 10.0),
        marginalCol ?? _kLegendAccent,
        weight: FontWeight.w700);
  }
  // Scandal-risk heat bar along the bottom.
  if (heat > 0.02) {
    final hr = Rect.fromLTWH(r.left + pad, r.bottom - pad - r.height * 0.04,
        (r.width - pad * 2), r.height * 0.05);
    final hrr = RRect.fromRectAndRadius(hr, const Radius.circular(3));
    c.drawRRect(hrr, Paint()..color = Colors.white.withValues(alpha: 0.06));
    c.save();
    c.clipRRect(hrr);
    c.drawRect(
        Rect.fromLTWH(hr.left, hr.top, hr.width * heat.clamp(0.0, 1.0),
            hr.height),
        Paint()..color = _kRed);
    c.restore();
  }
}

// Frame 1 — the core object + verb: an official card you tap to fund.
void _legendCore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.16,
      size.width * 0.84, size.height * 0.5);
  _legendOfficialCard(canvas, r,
      name: 'Sen. Russet',
      yes: 0.52,
      lean: 'SWING VOTE',
      leanCol: Potatuhs.sienna,
      marginal: 'next \$25: +8%');
  // A DONATE chip below, the spend you tap with.
  _legendChip(canvas, Offset(size.width * 0.5, size.height * 0.82), '\$25',
      (size.height * 0.05).clamp(11.0, 16.0), Potatuhs.gold);
}

// Frame 2 — how to score: push PROJECTED % over NEED, bank the payout.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.12,
      size.width * 0.84, size.height * 0.62);
  _legendPanel(canvas, r, Potatuhs.inkPanel.withValues(alpha: 0.92),
      _kLegendAccent.withValues(alpha: 0.4), radius: 14);
  final pad = r.width * 0.06;
  // Bill title + payout chip.
  GameFx.text(canvas, 'Fryer Subsidy Act',
      Offset(r.left + pad + r.width * 0.24, r.top + r.height * 0.16),
      (r.height * 0.11).clamp(11.0, 16.0), Potatuhs.gold,
      weight: FontWeight.w800);
  _legendChip(canvas, Offset(r.right - pad - r.width * 0.15,
      r.top + r.height * 0.16), 'PAYS \$320',
      (r.height * 0.09).clamp(8.0, 11.0), Potatuhs.gold);
  // The big PROJECTED % readout (green = passing).
  GameFx.text(canvas, 'PROJECTED',
      Offset(r.center.dx, r.top + r.height * 0.40),
      (r.height * 0.08).clamp(7.0, 10.0), Potatuhs.textFaint,
      weight: FontWeight.w700);
  GameFx.text(canvas, '78%', Offset(r.center.dx, r.top + r.height * 0.58),
      (r.height * 0.24).clamp(20.0, 40.0), _kGreen,
      weight: FontWeight.w800, glow: 0.5);
  // Vote-timer bar near the bottom.
  final tr = Rect.fromLTWH(r.left + pad, r.bottom - r.height * 0.14,
      r.width - pad * 2, r.height * 0.06);
  final trr = RRect.fromRectAndRadius(tr, const Radius.circular(3));
  canvas.drawRRect(trr, Paint()..color = Colors.white.withValues(alpha: 0.08));
  canvas.save();
  canvas.clipRRect(trr);
  canvas.drawRect(
      Rect.fromLTWH(tr.left, tr.top, tr.width * 0.6, tr.height),
      Paint()..color = _kLegendAccent);
  canvas.restore();
}

// Frame 3 — the danger: overspend one official → SCANDAL, lose the chest.
void _legendScandal(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.14,
      size.width * 0.84, size.height * 0.48);
  _legendOfficialCard(canvas, r,
      name: 'Gov. Yukon',
      yes: 0.86,
      lean: 'OVERREACH',
      leanCol: _kRed,
      heat: 1.0);
  // A SCANDAL pop, like the one the game throws on max heat.
  GameFx.text(canvas, 'SCANDAL!  -\$120',
      Offset(size.width * 0.5, size.height * 0.80),
      (size.height * 0.06).clamp(14.0, 24.0), _kRed,
      weight: FontWeight.w800, glow: 0.7);
}

// Frame 4 — the escalation: faster timers, bigger payouts, panels grow to 7.
void _legendEscalation(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  // A tall, dense 7-official panel (late-game) with a short, urgent timer bar.
  final top = size.height * 0.1;
  const rows = 7;
  final gap = size.height * 0.012;
  final rowH = (size.height * 0.66 - gap * (rows - 1)) / rows;
  for (int i = 0; i < rows; i++) {
    final ry = top + i * (rowH + gap);
    final rr = Rect.fromLTWH(size.width * 0.08, ry, size.width * 0.6, rowH);
    _legendPanel(canvas, rr, Potatuhs.inkPanel.withValues(alpha: 0.8),
        _kLegendAccent.withValues(alpha: 0.25),
        radius: 6, stroke: 1);
    // A thin yes-% bar in each row, various fills.
    final bar = Rect.fromLTWH(rr.left + rr.width * 0.06,
        rr.center.dy - rowH * 0.16, rr.width * 0.88, rowH * 0.32);
    _legendProbBar(canvas, bar, 0.28 + 0.62 * ((i * 0.19) % 1.0),
        showLabel: false);
  }
  // Big payout chip + a short red (urgent) vote timer on the right.
  _legendChip(canvas, Offset(size.width * 0.83, size.height * 0.22),
      'PAYS \$440', (size.height * 0.045).clamp(9.0, 13.0), Potatuhs.gold);
  final tr = Rect.fromLTWH(size.width * 0.72, size.height * 0.34,
      size.width * 0.22, size.height * 0.03);
  final trr = RRect.fromRectAndRadius(tr, const Radius.circular(3));
  canvas.drawRRect(trr, Paint()..color = Colors.white.withValues(alpha: 0.08));
  canvas.save();
  canvas.clipRRect(trr);
  canvas.drawRect(
      Rect.fromLTWH(tr.left, tr.top, tr.width * 0.25, tr.height),
      Paint()..color = _kRed);
  canvas.restore();
  GameFx.text(canvas, '6.0s', Offset(size.width * 0.83, size.height * 0.42),
      (size.height * 0.05).clamp(11.0, 16.0), _kRed,
      weight: FontWeight.w800);
}

/// The visual manual for Lobbying — wired into the registry spec.
final List<LegendFrame> lobbyingLegendFrames = [
  const LegendFrame(
      caption: 'Tap an official to fund their YES vote',
      paint: _legendCore),
  const LegendFrame(
      caption: 'Push PROJECTED % over NEED before the vote to bank cash',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Overspend one official — they overheat into SCANDAL',
      paint: _legendScandal),
  const LegendFrame(
      caption: 'Bills speed up, pay more, and grow to 7 officials',
      paint: _legendEscalation),
];
