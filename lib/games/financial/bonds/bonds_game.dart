import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BondsGame — "Bonds"  (BioScale.financial)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Teaches the one non-obvious truth of fixed income: when interest RATES rise,
// the price of an EXISTING bond FALLS — and the longer the maturity, the harder
// it falls (duration / interest-rate risk).
//
// A central RATE ticker drifts up and down. Each tradeable bond's price is the
// present value of its fixed coupons + face, discounted at the live rate, so the
// price moves INVERSELY to the rate in real time. Longer bonds swing more for the
// same rate move. The player buys bonds when rates are high (prices cheap) and
// sells after rates fall (prices rise) — or dumps before rates climb. Score =
// cumulative REALIZED profit, pushed to the host session on every sell. The host
// owns the clock / countdown / results; this widget only runs while
// session.isRunning.

// --- Wallet / sim tuning ----------------------------------------------------
const double _kFace        = 100.0;   // par value of every bond ($100 convention)
const double _kStartCash   = 2000.0;  // opening capital
const double _kGameSeconds = 60.0;    // mirrors host clock
const double _kRateStart   = 5.0;     // opening market yield (%)
const double _kRateMin     = 1.5;     // rate floor (%)
const double _kRateMax     = 12.0;    // rate ceiling (%)
const int    _kChartMax    = 110;     // rate-history samples kept for the chart

// Lot presets (in bonds) offered as one-tap sizing.
const List<int> _kLotPresets = [1, 5];

// Game accent (a cool "treasury blue", distinct from Market Trader's airForce).
const Color _kAccent = Color(0xFF7C9CB5);
const Color _kUp     = Color(0xFF66BB6A);
const Color _kDown   = Color(0xFFEF5350);

/// A tradeable bond: fixed coupon + maturity, set at issue and never changing.
/// Its market PRICE is derived live from the moving rate, so it is not stored.
class _BondDef {
  final String label;     // "10Y"
  final int    maturity;  // years to maturity
  final double couponRate;// annual coupon as a fraction of face (0.04 = 4%)
  final Color  color;
  final double unlockAt;  // elapsed seconds before this maturity becomes tradeable
  const _BondDef(
      this.label, this.maturity, this.couponRate, this.color, this.unlockAt);
}

const List<_BondDef> _kBonds = [
  _BondDef('2Y',  2,  0.045, Color(0xFF8FD3B6), 0),    // short: barely moves
  _BondDef('5Y',  5,  0.045, Color(0xFF6FB6D6), 0),    // medium
  _BondDef('10Y', 10, 0.040, Color(0xFFE1C916), 18),   // long: unlocks mid-game
  _BondDef('30Y', 30, 0.040, Color(0xFFE16416), 38),   // longest: most sensitive
];

/// Mutable per-bond position (held quantity + weighted average cost).
class _Holding {
  double qty = 0;
  double avgCost = 0;
}

class BondsGame extends StatefulWidget {
  final MiniGameSession session;
  const BondsGame({super.key, required this.session});
  @override
  State<BondsGame> createState() => _BondsGameState();
}

class _BondsGameState extends State<BondsGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _rng = Random();

  // --- Wallet / score ---
  double _cash     = _kStartCash;
  double _realized = 0.0; // cumulative realized P&L — this IS the score
  int    _streak   = 0;   // consecutive profitable sells (reported to session)

  // --- Rate engine ---
  double _rate       = _kRateStart;
  double _rateTarget = _kRateStart;
  double _rateTimer  = 0.0;

  // --- Time / escalation ---
  double _elapsed     = 0.0;
  double _sampleClock = 0.0;

  // --- Positions ---
  final List<_Holding> _hold =
      List.generate(_kBonds.length, (_) => _Holding());
  final List<bool> _unlocked =
      List.generate(_kBonds.length, (i) => _kBonds[i].unlockAt <= 0);
  int _sel = 1; // selected bond (default 5Y)

  // --- Sizing ---
  int _lot = 5;

  // --- How-to coach: an unmissable in-context teach that fades after the
  //     player's FIRST buy (bond finance is unfamiliar to most). While it's up
  //     it explains the ONE core action; after a buy it's dismissed for good. ---
  bool   _didBuy      = false;
  double _coachAlpha  = 1.0; // 1 = fully shown; fades to 0 after first buy
  double _coachPulse  = 0.0; // gentle breathing so it reads as "alive", not a modal

  // --- Chart: only the rate history is stored; bond prices are recomputed from
  //     it in the painter so every line is always consistent + truly inverse. ---
  final List<double> _rateHist = [_kRateStart];

  // --- FX ---
  final List<FxParticle> _fx   = [];
  final List<FxPop>      _pops = [];
  Color  _flashColor = Colors.transparent;
  double _flashAlpha = 0.0;

  Size _screen = Size.zero;

  // ─── Derived ───────────────────────────────────────────────────────────────
  _BondDef get _selDef => _kBonds[_sel];
  _Holding get _selHold => _hold[_sel];

  /// Bond price = PV of fixed coupons + face, discounted at the live yield.
  /// Rate ↑ ⇒ every discount factor shrinks ⇒ price ↓ (the inverse relation).
  double _price(_BondDef b, double ratePct) {
    final y = ratePct / 100.0;
    final c = b.couponRate * _kFace;
    double pv = 0;
    double df = 1.0; // (1+y)^-t accumulated iteratively (no pow import needed)
    for (int t = 1; t <= b.maturity; t++) {
      df /= (1 + y);
      pv += c * df;
    }
    pv += _kFace * df; // face returned at maturity
    return pv;
  }

  /// % the price FALLS if rates rise 1% — a live, readable duration / rate-risk
  /// gauge. Longer maturities show a bigger number.
  double _sensitivity(_BondDef b) {
    final p0 = _price(b, _rate);
    final p1 = _price(b, (_rate + 1).clamp(_kRateMin, _kRateMax));
    if (p0 <= 0) return 0;
    return (p0 - p1) / p0 * 100.0;
  }

  double _holdingsValue() {
    double v = 0;
    for (int i = 0; i < _kBonds.length; i++) {
      v += _hold[i].qty * _price(_kBonds[i], _rate);
    }
    return v;
  }

  bool get _canBuy =>
      widget.session.isRunning &&
      _lot > 0 &&
      _cash >= _price(_selDef, _rate) * _lot - 1e-6;
  bool get _canSell => widget.session.isRunning && _selHold.qty > 1e-6;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this desk knows the fixed-income playbook. Registered
    // always (harmless in normal play — the host only calls it in autoplay).
    // See [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ─── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One competent, deterministic move per host tick (~250ms), played off the
  /// game's OWN fields (rate, rate history, holdings, cash) and its OWN handlers
  /// — never randomness or synthetic taps. Trades the one lesson of the game:
  /// bond prices move INVERSE to rates.
  ///   • Holding a bond now worth more than its cost basis (i.e. rates fell
  ///     since we bought) by a worthwhile margin → SELL ALL of it, realizing
  ///     the gain into the score (only SOLD bonds count).
  ///   • Otherwise, when the live rate sits in the UPPER part of its recent
  ///     range (rates HIGH ⇒ prices CHEAP) and cash allows → BUY the longest
  ///     unlocked maturity (biggest duration swing), sized to a slice of cash.
  ///   • Nothing attractive → hold.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // 1) Realize gains. Bonds move slowly, so ~0.5% over basis is worth banking.
    for (int i = 0; i < _kBonds.length; i++) {
      final h = _hold[i];
      if (h.qty <= 1e-6) continue;
      final price = _price(_kBonds[i], _rate);
      if (price > h.avgCost * 1.005) {
        _sel = i; // act on this bond via the game's own select + sell handlers
        _sellAll();
        return;
      }
    }

    // 2) Accumulate when rates are relatively HIGH (prices cheap). "High" is
    //    derived from the rate's own recent range, not a magic threshold.
    if (_rateHist.length >= 4) {
      final lo = _rateHist.reduce(min);
      final hi = _rateHist.reduce(max);
      if (hi - lo > 0.3) {
        final pos = (_rate - lo) / (hi - lo); // 0 = cheapest rate, 1 = highest
        if (pos >= 0.6) {
          // Prefer the longest UNLOCKED maturity — it swings hardest as rates
          // fall, so the eventual sell realizes more.
          int target = -1;
          for (int i = _kBonds.length - 1; i >= 0; i--) {
            if (_unlocked[i]) {
              target = i;
              break;
            }
          }
          if (target >= 0) {
            _sel = target;
            // Deploy about half of free cash per entry (≥1 bond) so there's dry
            // powder left for a cheaper rung later.
            final price = _price(_kBonds[target], _rate);
            final affordable = (_cash / max(price, 0.01)).floor();
            final lot = max(1, (affordable / 2).floor());
            if (_lot != lot) _setLot(lot);
            if (_canBuy) _buy();
          }
        }
      }
    }
    // else hold — no worthwhile move this tick.
  }

  // ─── Main loop (host owns the clock) ───────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow motion — the sim must advance by
    // wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) return;
    setState(() {
      _elapsed += dt;
      final t = (_elapsed / _kGameSeconds).clamp(0.0, 1.0);

      // Escalation: bigger, faster, sharper rate swings as the round wears on.
      final interval = 4.5 - 2.5 * t;   // 4.5s → 2.0s between new targets
      final swing    = 1.0 + 2.6 * t;   // ±1.0% → ±3.6% target jumps
      final approach = 0.5 + 0.8 * t;   // how fast rate chases its target

      _rateTimer -= dt;
      if (_rateTimer <= 0) {
        _rateTarget =
            (_rate + (_rng.nextDouble() * 2 - 1) * swing)
                .clamp(_kRateMin, _kRateMax);
        _rateTimer = interval * (0.7 + _rng.nextDouble() * 0.6);
      }
      _rate += (_rateTarget - _rate) * approach * dt;
      _rate = _rate.clamp(_kRateMin, _kRateMax);

      _sampleClock += dt;
      if (_sampleClock >= 0.1) {
        _sampleClock = 0;
        _rateHist.add(_rate);
        if (_rateHist.length > _kChartMax) _rateHist.removeAt(0);
      }

      for (int i = 0; i < _kBonds.length; i++) {
        if (!_unlocked[i] && _elapsed >= _kBonds[i].unlockAt) {
          _unlocked[i] = true;
          _pop('${_kBonds[i].label} UNLOCKED', _kBonds[i].color, yFrac: 0.30);
          _flash(_kBonds[i].color, 0.16);
        }
      }

      if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 2.5).clamp(0, 1);

      // Coach: breathe until the first buy, then fade out over ~0.6s.
      _coachPulse += dt;
      if (_didBuy && _coachAlpha > 0) {
        _coachAlpha = (_coachAlpha - dt * 1.6).clamp(0.0, 1.0);
      }

      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ─── Trading ───────────────────────────────────────────────────────────────
  void _setLot(int v) => setState(() => _lot = v.clamp(1, 9999));
  void _bumpLot(int by) => setState(() => _lot = (_lot + by).clamp(1, 9999));
  void _maxLot() {
    final p = _price(_selDef, _rate);
    setState(() => _lot = max(1, (_cash / max(p, 0.01)).floor()));
  }

  void _buy() {
    if (!_canBuy) return;
    final b = _selDef;
    final h = _selHold;
    final price = _price(b, _rate);
    final qty = _lot.toDouble();
    final cost = price * qty;
    if (cost > _cash + 1e-6) return;
    setState(() {
      _didBuy = true; // first buy dismisses the how-to coach
      _cash -= cost;
      final nt = h.qty + qty;
      h.avgCost = (h.avgCost * h.qty + price * qty) / nt;
      h.qty = nt;
      _flash(_kAccent, 0.16);
      _spawnFx(_kAccent, count: 8, speed: 70);
      _pop('BUY ${qty.toStringAsFixed(0)} @ \$${price.toStringAsFixed(2)}',
          _kAccent, yFrac: 0.46);
    });
  }

  void _sell(double wanted) {
    final h = _selHold;
    if (h.qty <= 1e-6) return;
    final b = _selDef;
    final price = _price(b, _rate);
    final qty = min(wanted, h.qty);
    if (qty <= 1e-6) return;
    final pnl = (price - h.avgCost) * qty;
    setState(() {
      _cash += price * qty;
      h.qty -= qty;
      if (h.qty <= 1e-6) {
        h.qty = 0;
        h.avgCost = 0;
      }
      _realized += pnl;
      _syncScore();
      final profit = pnl > 0;
      if (profit) {
        _streak += 1;
        widget.session.noteStreak(_streak);
      } else {
        _streak = 0;
      }
      final col = profit ? _kUp : _kDown;
      _flash(col, 0.28);
      _pop('${profit ? "+" : "-"}\$${pnl.abs().toStringAsFixed(0)}', col,
          yFrac: 0.42);
      if (profit && pnl > 4) {
        _spawnFx(Potatuhs.gold,
            count: pnl > 30 ? 20 : 12, speed: pnl > 30 ? 150 : 100,
            yFrac: 0.44);
      }
    });
  }

  void _sellLot() => _sell(_lot.toDouble());
  void _sellAll() => _sell(_selHold.qty);

  /// Push the running realized P&L to the host scoreboard. The session clamps at
  /// 0 and is monotonic, so it tracks the high-water positive realized total.
  void _syncScore() {
    final target = _realized.round();
    widget.session.addScore(target - widget.session.score);
  }

  // ─── FX helpers ─────────────────────────────────────────────────────────────
  void _flash(Color c, double a) {
    _flashColor = c;
    _flashAlpha = a;
  }

  void _spawnFx(Color color,
      {int count = 10, double speed = 90, double yFrac = 0.5}) {
    if (_screen == Size.zero) return;
    final center = Offset(_screen.width / 2, _screen.height * yFrac);
    _fx.addAll(FxBurst.spawn(center, color, count: count, speed: speed));
  }

  void _pop(String label, Color color, {double yFrac = 0.42}) {
    final pos = _screen == Size.zero
        ? const Offset(160, 240)
        : Offset(_screen.width * 0.5, _screen.height * yFrac);
    _pops.add(FxPop(pos, label, color));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _screen = Size(w, h);
      final chartH = (h * 0.22).clamp(96.0, 168.0);

      return Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BdBackgroundPainter(_elapsed, _kAccent),
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
            _buildWalletBar(),
            _buildObjectiveStrip(),
            _buildRatePanel(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: SizedBox(
                height: chartH,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _BdChartPainter(
                      List<double>.from(_rateHist),
                      _selDef.couponRate,
                      _selDef.maturity,
                      _selDef.color,
                    ),
                  ),
                ),
              ),
            ),
            _buildSizeControl(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(children: [
                  for (int i = 0; i < _kBonds.length; i++) _buildBondRow(i),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
            _buildTradeButtons(),
            const SizedBox(height: 8),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _BdFxPainter(_fx, _pops)),
          ),
        ),
        if (_coachAlpha > 0.01) _buildCoach(chartH),
      ]);
    });
  }

  // ─── How-to coach ───────────────────────────────────────────────────────────
  /// Unmissable, in-context teach of the ONE core action. Sits over the chart
  /// (where the eye already is), breathes gently, and fades for good on the
  /// first buy. Pointer-transparent so it never traps a tap.
  Widget _buildCoach(double chartH) {
    // Position it just below the wallet/objective/rate stack, over the chart.
    final pulse = 0.5 + 0.5 * sin(_coachPulse * 2.2);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: _coachAlpha.clamp(0.0, 1.0),
          child: Align(
            alignment: const Alignment(0, -0.14),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Potatuhs.inkPanel.withValues(alpha: 0.96),
                    Potatuhs.inkDeep.withValues(alpha: 0.98),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Potatuhs.gold.withValues(alpha: 0.4 + 0.35 * pulse),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Potatuhs.gold
                        .withValues(alpha: 0.14 + 0.14 * pulse),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('HOW TO PLAY',
                      style: Potatuhs.label(size: 9, color: Potatuhs.gold)),
                  const SizedBox(height: 6),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Potatuhs.body(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Potatuhs.textPrimary),
                      children: const [
                        TextSpan(text: 'Rates '),
                        TextSpan(
                            text: 'HIGH', style: TextStyle(color: _kDown)),
                        TextSpan(text: ' ⇒ bonds '),
                        TextSpan(
                            text: 'CHEAP', style: TextStyle(color: _kUp)),
                        TextSpan(text: '.\nTap a bond, '),
                        TextSpan(
                            text: 'BUY', style: TextStyle(color: _kAccent)),
                        TextSpan(text: ' — then when rates '),
                        TextSpan(
                            text: 'FALL', style: TextStyle(color: _kUp)),
                        TextSpan(text: ', '),
                        TextSpan(
                            text: 'SELL', style: TextStyle(color: _kUp)),
                        TextSpan(text: ' for profit.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('tap BUY to begin',
                      style: Potatuhs.label(
                          size: 9,
                          color: Potatuhs.gold
                              .withValues(alpha: 0.5 + 0.5 * pulse))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Always-visible objective strip ─────────────────────────────────────────
  /// The one-line "what am I doing" that never leaves the screen — buy low vs
  /// the rate, sell after it falls. Live: it names the CURRENT best move so the
  /// finance abstraction always maps to a concrete action.
  Widget _buildObjectiveStrip() {
    // Is any held bond above its cost basis (a profit ready to bank)?
    double bankable = 0;
    for (int i = 0; i < _kBonds.length; i++) {
      final h = _hold[i];
      if (h.qty <= 1e-6) continue;
      bankable += (_price(_kBonds[i], _rate) - h.avgCost) * h.qty;
    }
    final holding = _holdingsValue() > 0.5;

    String msg;
    Color col;
    IconData icon;
    if (bankable > 1) {
      // Sitting on a gain — the actionable prompt: bank it.
      msg = 'PROFIT READY — SELL to bank +\$${bankable.toStringAsFixed(0)}';
      col = _kUp;
      icon = Icons.savings_outlined;
    } else if (holding) {
      // Holding but underwater — wait for rates to fall.
      msg = 'HOLDING — wait for rates to FALL, then SELL';
      col = Potatuhs.gold;
      icon = Icons.hourglass_bottom;
    } else {
      // Flat — the core buy instruction.
      msg = 'BUY a bond cheap, SELL after rates fall';
      col = _kAccent;
      icon = Icons.flag_outlined;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Potatuhs.surface(
        fill: col.withValues(alpha: 0.12),
        borderColor: col.withValues(alpha: 0.4),
        radius: 10,
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: col),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: Potatuhs.label(size: 10, color: col),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  // ─── Wallet bar ─────────────────────────────────────────────────────────────
  Widget _buildWalletBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.9),
        borderColor: _kAccent.withValues(alpha: 0.35),
        radius: 14,
      ),
      child: Row(children: [
        _stat('CASH', '\$${_cash.toStringAsFixed(0)}', Potatuhs.textPrimary),
        _divider(),
        _stat('BONDS', '\$${_holdingsValue().toStringAsFixed(0)}',
            _holdingsValue() > 0.5 ? _kAccent : Potatuhs.textFaint),
        _divider(),
        _stat(
          'PROFIT',
          '${_realized >= 0 ? "+" : "-"}\$${_realized.abs().toStringAsFixed(0)}',
          _realized >= 0 ? _kUp : _kDown,
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: Potatuhs.label(size: 8, color: Potatuhs.textFaint),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value,
            style:
                Potatuhs.body(size: 15, weight: FontWeight.w800, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.08),
      );

  // ─── Rate panel (the central object) ────────────────────────────────────────
  Widget _buildRatePanel() {
    // Rate trend vs a few samples back.
    final prev = _rateHist.length >= 8
        ? _rateHist[_rateHist.length - 8]
        : _rateHist.first;
    final delta = _rate - prev;
    final ratesUp = delta >= 0;
    // Prices move the OPPOSITE way — that's the whole lesson.
    final pricesUp = !ratesUp;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.7),
        borderColor: Potatuhs.gold.withValues(alpha: 0.30),
        radius: 12,
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('INTEREST RATE',
              style: Potatuhs.label(size: 8, color: Potatuhs.gold)),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic, children: [
            Text('${_rate.toStringAsFixed(2)}%',
                style: Potatuhs.display(size: 26, color: Potatuhs.gold)
                    .copyWith(shadows: [
                  Shadow(
                      color: Potatuhs.gold.withValues(alpha: 0.5),
                      blurRadius: 12),
                ])),
            const SizedBox(width: 6),
            Text('${ratesUp ? "▲" : "▼"}${delta.abs().toStringAsFixed(2)}',
                style: Potatuhs.label(
                    size: 11, color: ratesUp ? _kDown : _kUp)),
          ]),
        ]),
        const Spacer(),
        // The live cause→effect arrow that names the inverse rule.
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('RATES ${ratesUp ? "▲" : "▼"}',
              style: Potatuhs.label(
                  size: 10, color: ratesUp ? _kDown : _kUp)),
          const SizedBox(height: 2),
          Text('⇒ PRICES ${pricesUp ? "▲" : "▼"}',
              style: Potatuhs.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: pricesUp ? _kUp : _kDown)),
        ]),
      ]),
    );
  }

  // ─── Size control ───────────────────────────────────────────────────────────
  Widget _buildSizeControl() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.7),
        borderColor: _kAccent.withValues(alpha: 0.3),
        radius: 12,
      ),
      child: Row(children: [
        Text('SIZE', style: Potatuhs.label(size: 10, color: _kAccent)),
        const SizedBox(width: 8),
        _stepperBtn('−', () => _bumpLot(-1)),
        const SizedBox(width: 6),
        Expanded(
          child: Center(
            child: Text('$_lot',
                style: Potatuhs.body(
                    size: 20,
                    weight: FontWeight.w800,
                    color: Potatuhs.textPrimary)),
          ),
        ),
        _stepperBtn('+', () => _bumpLot(1)),
        const SizedBox(width: 8),
        ..._kLotPresets.map((p) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _presetBtn('$p', () => _setLot(p), _lot == p),
            )),
        const SizedBox(width: 4),
        _presetBtn('MAX', _maxLot, false, wide: true),
      ]),
    );
  }

  Widget _stepperBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(label,
            style: Potatuhs.body(
                size: 19,
                weight: FontWeight.w800,
                color: Potatuhs.textPrimary)),
      ),
    );
  }

  Widget _presetBtn(String label, VoidCallback onTap, bool active,
      {bool wide = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: wide ? 40 : 28),
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? _kAccent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? _kAccent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(label,
            style: Potatuhs.label(
                size: 10, color: active ? _kAccent : Potatuhs.textSecondary)),
      ),
    );
  }

  // ─── A bond row (tap to select; shows live price + your position) ───────────
  Widget _buildBondRow(int i) {
    final b = _kBonds[i];
    final h = _hold[i];
    final unlocked = _unlocked[i];
    final selected = i == _sel;

    if (!unlocked) {
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: Potatuhs.surface(
          fill: Colors.white.withValues(alpha: 0.03),
          borderColor: Colors.white.withValues(alpha: 0.08),
          radius: 12,
        ),
        child: Row(children: [
          Icon(Icons.lock_outline,
              size: 16, color: Potatuhs.textFaint.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Text('${b.label} bond',
              style: Potatuhs.body(size: 13, color: Potatuhs.textFaint)),
          const Spacer(),
          Text('unlocks at ${b.unlockAt.toStringAsFixed(0)}s',
              style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
        ]),
      );
    }

    final price = _price(b, _rate);
    final prevRate = _rateHist.length >= 8
        ? _rateHist[_rateHist.length - 8]
        : _rateHist.first;
    final priceDelta = price - _price(b, prevRate);
    final up = priceDelta >= 0;
    final sens = _sensitivity(b);
    final hasPos = h.qty > 1e-6;
    final upnl = hasPos ? (price - h.avgCost) * h.qty : 0.0;

    return GestureDetector(
      onTap: () => setState(() => _sel = i),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 3, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: Potatuhs.surface(
          fill: selected
              ? b.color.withValues(alpha: 0.16)
              : Potatuhs.inkPanel.withValues(alpha: 0.6),
          borderColor: selected
              ? b.color.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.10),
          radius: 12,
          borderWidth: selected ? 1.8 : 1.2,
        ),
        child: Row(children: [
          // Maturity badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: b.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: b.color.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Text(b.label,
                  style: Potatuhs.body(
                      size: 14, weight: FontWeight.w800, color: b.color)),
              Text('${(b.couponRate * 100).toStringAsFixed(1)}%',
                  style: Potatuhs.label(size: 7, color: Potatuhs.textSecondary)),
            ]),
          ),
          const SizedBox(width: 10),
          // Price + sensitivity + position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('\$${price.toStringAsFixed(2)}',
                      style: Potatuhs.body(
                          size: 16,
                          weight: FontWeight.w800,
                          color: Potatuhs.textPrimary)),
                  const SizedBox(width: 6),
                  Text('${up ? "▲" : "▼"}${priceDelta.abs().toStringAsFixed(2)}',
                      style: Potatuhs.label(
                          size: 10, color: up ? _kUp : _kDown)),
                ]),
                const SizedBox(height: 1),
                Text('rate +1% ⇒ −${sens.toStringAsFixed(1)}%',
                    style: Potatuhs.label(
                        size: 8,
                        color: Potatuhs.textFaint),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Holdings
          if (hasPos)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('×${h.qty.toStringAsFixed(0)}',
                  style: Potatuhs.body(
                      size: 13, weight: FontWeight.w700, color: b.color)),
              Text(
                '${upnl >= 0 ? "+" : "-"}\$${upnl.abs().toStringAsFixed(0)}',
                style: Potatuhs.label(
                    size: 9, color: upnl >= 0 ? _kUp : _kDown),
              ),
            ])
          else
            Text('—', style: Potatuhs.label(size: 11, color: Potatuhs.textFaint)),
        ]),
      ),
    );
  }

  // ─── BUY / SELL row (acts on the selected bond) ─────────────────────────────
  Widget _buildTradeButtons() {
    final b = _selDef;
    final price = _price(b, _rate);
    // Live P&L on the selected position — surfaced on the SELL button so the
    // score-driver ("selling banks THIS much") is legible at the moment of action.
    final selHold = _selHold;
    final hasSelPos = selHold.qty > 1e-6;
    final selUpnl =
        hasSelPos ? (price - selHold.avgCost) * selHold.qty : 0.0;
    final String sellSub;
    if (!hasSelPos) {
      sellSub = 'no bonds';
    } else if (selUpnl >= 0) {
      sellSub = 'bank +\$${selUpnl.toStringAsFixed(0)}';
    } else {
      sellSub = 'loss -\$${selUpnl.abs().toStringAsFixed(0)}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: _bigBtn(
            top: 'BUY $_lot',
            sub: '${b.label} · \$${(price * _lot).toStringAsFixed(0)}',
            enabled: _canBuy,
            colorA: const Color(0xFF1B4D5E),
            colorB: const Color(0xFF2E7D99),
            accent: _kAccent,
            onTap: _buy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _bigBtn(
            top: 'SELL $_lot',
            sub: sellSub,
            enabled: _canSell,
            colorA: const Color(0xFF7F0000),
            colorB: const Color(0xFFC62828),
            accent: _kDown,
            onTap: _sellLot,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _canSell ? _sellAll : null,
          child: Container(
            height: 58,
            width: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _canSell
                  ? const Color(0xFFC62828).withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _canSell
                    ? _kDown.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Text('SELL\nALL',
                textAlign: TextAlign.center,
                style: Potatuhs.label(
                    size: 11,
                    color: _canSell ? _kDown : Potatuhs.textFaint)),
          ),
        ),
      ]),
    );
  }

  Widget _bigBtn({
    required String top,
    required String sub,
    required bool enabled,
    required Color colorA,
    required Color colorB,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorA, colorB],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 16)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(top,
                style: Potatuhs.display(
                    size: 18, color: enabled ? accent : Potatuhs.textFaint)),
            Text(sub,
                style: Potatuhs.label(
                    size: 8,
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.85)
                        : Potatuhs.textFaint)),
          ],
        ),
      ),
    );
  }
}

// ─── Background painter ────────────────────────────────────────────────────────
class _BdBackgroundPainter extends CustomPainter {
  final double t;
  final Color accent;
  _BdBackgroundPainter(this.t, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accent, t, motes: 24);
  }

  @override
  bool shouldRepaint(covariant _BdBackgroundPainter old) => true;
}

// ─── Chart painter: RATE line + the selected bond's PRICE line, moving inverse ──
class _BdChartPainter extends CustomPainter {
  final List<double> rateHist;
  final double couponRate;
  final int maturity;
  final Color priceColor;
  _BdChartPainter(
      this.rateHist, this.couponRate, this.maturity, this.priceColor);

  double _price(double ratePct) {
    final y = ratePct / 100.0;
    final c = couponRate * _kFace;
    double pv = 0;
    double df = 1.0;
    for (int t = 1; t <= maturity; t++) {
      df /= (1 + y);
      pv += c * df;
    }
    pv += _kFace * df;
    return pv;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(12)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkPanel.withValues(alpha: 0.95),
            Potatuhs.inkDeep.withValues(alpha: 0.98),
          ],
        ).createShader(bgRect),
    );

    final n = rateHist.length;
    if (n < 2) return;

    // Build the price series from the rate series — guarantees the two lines are
    // exactly inverse (price is a strictly-decreasing function of rate).
    final prices = [for (final r in rateHist) _price(r)];

    double rMin = rateHist.reduce(min), rMax = rateHist.reduce(max);
    double pMin = prices.reduce(min), pMax = prices.reduce(max);
    if (rMax - rMin < 0.4) {
      final m = (rMin + rMax) / 2;
      rMin = m - 0.2;
      rMax = m + 0.2;
    }
    if (pMax - pMin < 0.4) {
      final m = (pMin + pMax) / 2;
      pMin = m - 0.2;
      pMax = m + 0.2;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double px(int i) => (i / (n - 1)) * size.width;

    Path pathFor(List<double> data, double lo, double hi) {
      final p = Path();
      for (int i = 0; i < n; i++) {
        final norm = (data[i] - lo) / (hi - lo);
        final y = size.height - norm * (size.height * 0.82) - size.height * 0.09;
        i == 0 ? p.moveTo(px(i), y) : p.lineTo(px(i), y);
      }
      return p;
    }

    final ratePath = pathFor(rateHist, rMin, rMax);
    final pricePath = pathFor(prices, pMin, pMax);

    void stroke(Path path, Color color, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..strokeWidth = width + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // PRICE line drawn first (bolder — it's what you trade), RATE on top.
    stroke(pricePath, priceColor, 2.4);
    stroke(ratePath, Potatuhs.gold, 2.0);

    // Legend.
    GameFx.text(canvas, 'RATE', const Offset(28, 12), 9, Potatuhs.gold,
        weight: FontWeight.w800);
    GameFx.text(canvas, 'PRICE', Offset(size.width - 28, 12), 9, priceColor,
        weight: FontWeight.w800);
  }

  @override
  bool shouldRepaint(covariant _BdChartPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME components the
// live game uses (the gold rate gauge, the maturity-badge bond card, the
// BUY/SELL pills, the inverse RATES⇒PRICES arrow). Static + cheap: rendered
// once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// Width-constrained centered text for the legend cards. [GameFx.text] lays out
/// at the string's natural width and can spill past its box on the narrow embeds
/// the cell runs in (iframe on hotpotatogames.com), which is how the rate-gauge
/// finance lingo ("5.00%" ↔ "⇒ PRICES ▼") collided. This shrinks the font toward
/// [minSize] until the line fits [maxWidth], so a label never overruns its slot.
/// Mirrors the shared-kit fix pattern in `tissue/skin_layers`, but local (the
/// shared `GameFx.text` intentionally has no max-width and must not change).
void _bdFit(Canvas canvas, String s, Offset center, double size, Color color,
    double maxWidth,
    {bool display = false,
    FontWeight weight = FontWeight.w800,
    double glow = 0,
    double minSize = 6}) {
  if (maxWidth <= 0 || s.isEmpty) return;
  var fontSize = size;
  TextPainter tp() => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: display ? Potatuhs.displayFont : Potatuhs.bodyFont,
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
            shadows: glow > 0
                ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 12)]
                : null,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
  var painter = tp()..layout();
  while (painter.width > maxWidth && fontSize > minSize) {
    fontSize = (fontSize - 0.5).clamp(minSize, size);
    painter = tp()..layout();
  }
  painter = tp()..layout(maxWidth: maxWidth);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Bond price = PV of fixed coupons + face, discounted at [ratePct] — the same
/// formula the game trades on. Top-level copy so the legend needs no state.
double _bdLegendPrice(_BondDef b, double ratePct) {
  final y = ratePct / 100.0;
  final c = b.couponRate * _kFace;
  double pv = 0;
  double df = 1.0;
  for (int t = 1; t <= b.maturity; t++) {
    df /= (1 + y);
    pv += c * df;
  }
  pv += _kFace * df;
  return pv;
}

/// The gold interest-rate gauge + the inverse cause→effect arrow, mirroring
/// `_buildRatePanel`. [ratesUp] flips both the rate colour and the (opposite)
/// price colour so one helper draws both the winning and the losing case.
void _bdRateGauge(Canvas canvas, Rect r, {required bool ratesUp}) {
  if (r.width < 8 || r.height < 8) return;
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(
      rrect, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.7));
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Potatuhs.gold.withValues(alpha: 0.30),
  );

  final rateCol = ratesUp ? _kDown : _kUp; // rising rates read as bad (red)
  final priceCol = ratesUp ? _kDown : _kUp; // prices move the OTHER way

  // Split the strip into two non-overlapping columns with a gutter between, so
  // the readout ("INTEREST RATE / 5.00%") can never collide with the lesson
  // ("RATES ▲ ⇒ PRICES ▼") on a narrow embed. Each label is width-fit to its
  // own column, so both stay legible instead of spilling across the divide.
  const pad = 10.0;
  const gutter = 12.0;
  final colW = (r.width - pad * 2 - gutter) / 2;
  final leftCx = r.left + pad + colW / 2;
  final rightCx = r.right - pad - colW / 2;

  // Left column: the live rate readout.
  _bdFit(canvas, 'INTEREST RATE', Offset(leftCx, r.top + 15), 9, Potatuhs.gold,
      colW);
  _bdFit(canvas, '5.00%', Offset(leftCx, r.center.dy + 10), 24, Potatuhs.gold,
      colW,
      display: true, glow: 0.5);

  // Right column: RATES ▲/▼  ⇒  PRICES ▼/▲ — the whole lesson, colour-coded.
  _bdFit(canvas, 'RATES ${ratesUp ? "▲" : "▼"}',
      Offset(rightCx, r.center.dy - 12), 11, rateCol, colW);
  _bdFit(canvas, '⇒ PRICES ${ratesUp ? "▼" : "▲"}',
      Offset(rightCx, r.center.dy + 10), 13, priceCol, colW);
}

/// One tradeable bond card — the maturity badge + coupon + live price + an
/// optional coloured delta, mirroring `_buildBondRow`.
void _bdBondCard(Canvas canvas, Rect r, _BondDef b, double price,
    {bool selected = true, String? delta, Color? deltaColor}) {
  if (r.width < 8 || r.height < 8) return;
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = selected
          ? b.color.withValues(alpha: 0.16)
          : Potatuhs.inkPanel.withValues(alpha: 0.6),
  );
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.8 : 1.2
      ..color = selected
          ? b.color.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.10),
  );

  // Maturity badge (label + coupon).
  final badge = Rect.fromLTWH(r.left + 10, r.center.dy - 18, 42, 36);
  final brr = RRect.fromRectAndRadius(badge, const Radius.circular(8));
  canvas.drawRRect(brr, Paint()..color = b.color.withValues(alpha: 0.22));
  canvas.drawRRect(
    brr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = b.color.withValues(alpha: 0.5),
  );
  _bdFit(canvas, b.label, badge.center.translate(0, -6), 13, b.color,
      badge.width - 6);
  _bdFit(canvas, '${(b.couponRate * 100).toStringAsFixed(1)}%',
      badge.center.translate(0, 9), 7, Potatuhs.textSecondary, badge.width - 6,
      weight: FontWeight.w700);

  // Live price (+ optional delta beneath). Centre it in the space RIGHT of the
  // maturity badge and fit to that width so "$1,234.56 / +$xx" never runs off
  // the card or back over the badge on a narrow embed.
  final priceLeft = badge.right + 10;
  final priceW = (r.right - 10) - priceLeft;
  final px = priceLeft + priceW / 2;
  _bdFit(canvas, '\$${price.toStringAsFixed(2)}',
      Offset(px, r.center.dy + (delta != null ? -7 : 0)), 16,
      Potatuhs.textPrimary, priceW);
  if (delta != null) {
    _bdFit(canvas, delta, Offset(px, r.center.dy + 11), 11,
        deltaColor ?? _kUp, priceW,
        weight: FontWeight.w700);
  }
}

/// A gradient trade pill, mirroring `_buildTradeButtons`' BUY/SELL buttons.
void _bdTradePill(Canvas canvas, Rect r, String label, Color colorA,
    Color colorB, Color accent) {
  if (r.width < 8 || r.height < 8) return;
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(16));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colorA, colorB],
      ).createShader(r),
  );
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.8),
  );
  _bdFit(canvas, label, r.center, 18, accent, r.width - 12, display: true);
}

// ── Frame 1: the core object + verb — a bond, and BUY / SELL. ────────────────
void _legendTrade(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final b = _kBonds[1]; // 5Y — tradeable from the opening bell
  final card = Rect.fromLTWH(
      size.width * 0.12, size.height * 0.20, size.width * 0.76, 56);
  _bdBondCard(canvas, card, b, _bdLegendPrice(b, _kRateStart));

  final pillW = size.width * 0.36;
  final pillY = size.height * 0.58;
  _bdTradePill(canvas, Rect.fromLTWH(size.width * 0.12, pillY, pillW, 56),
      'BUY', const Color(0xFF1B4D5E), const Color(0xFF2E7D99), _kAccent);
  _bdTradePill(
      canvas,
      Rect.fromLTWH(size.width * 0.52, pillY, pillW, 56),
      'SELL',
      const Color(0xFF7F0000),
      const Color(0xFFC62828),
      _kDown);
}

// ── Frame 2: how to score — rates fall ⇒ prices rise, buy low & sell high. ───
void _legendProfit(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final gauge = Rect.fromLTWH(
      size.width * 0.08, size.height * 0.16, size.width * 0.84, 66);
  _bdRateGauge(canvas, gauge, ratesUp: false);

  final b = _kBonds[1];
  final buyP = _bdLegendPrice(b, _kRateStart + 2); // bought when rates high
  final sellP = _bdLegendPrice(b, _kRateStart - 1); // sold after rates fell
  final card = Rect.fromLTWH(
      size.width * 0.12, size.height * 0.60, size.width * 0.76, 56);
  _bdBondCard(canvas, card, b, sellP,
      delta: '+\$${(sellP - buyP).toStringAsFixed(2)}', deltaColor: _kUp);
}

// ── Frame 3: the danger — rates climb ⇒ prices fall, sell before the drop. ───
void _legendDanger(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final gauge = Rect.fromLTWH(
      size.width * 0.08, size.height * 0.16, size.width * 0.84, 66);
  _bdRateGauge(canvas, gauge, ratesUp: true);

  final b = _kBonds[3]; // 30Y — the hardest hit when rates rise
  final highP = _bdLegendPrice(b, _kRateStart);
  final lowP = _bdLegendPrice(b, _kRateStart + 2); // rates rose ⇒ price sank
  final card = Rect.fromLTWH(
      size.width * 0.12, size.height * 0.60, size.width * 0.76, 56);
  _bdBondCard(canvas, card, b, lowP,
      delta: '-\$${(highP - lowP).toStringAsFixed(2)}', deltaColor: _kDown);
}

// ── Frame 4: escalation — longer maturities swing hardest; late unlocks. ─────
void _legendDuration(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final n = _kBonds.length;
  final slot = size.width / n;
  // Sensitivity = % the price falls if rates rise 1% (the in-game duration tell).
  double sens(_BondDef b) {
    final p0 = _bdLegendPrice(b, _kRateStart);
    final p1 = _bdLegendPrice(b, _kRateStart + 1);
    return p0 <= 0 ? 0 : (p0 - p1) / p0 * 100.0;
  }

  final maxSens = _kBonds.map(sens).reduce(max);
  final baseY = size.height * 0.82;
  final barMaxH = size.height * 0.52;
  for (int i = 0; i < n; i++) {
    final b = _kBonds[i];
    final cx = slot * (i + 0.5);
    final s = sens(b);
    final h = maxSens <= 0 ? 4.0 : (s / maxSens) * barMaxH + 6;
    // Bar — taller = more interest-rate risk.
    final bar =
        Rect.fromLTWH(cx - slot * 0.22, baseY - h, slot * 0.44, h);
    final brr = RRect.fromRectAndRadius(bar, const Radius.circular(6));
    canvas.drawRRect(brr, Paint()..color = b.color.withValues(alpha: 0.30));
    canvas.drawRRect(
      brr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = b.color.withValues(alpha: 0.8),
    );
    _bdFit(canvas, b.label, Offset(cx, baseY - h - 12), 12, b.color, slot - 4);
    _bdFit(canvas, '−${s.toStringAsFixed(1)}%', Offset(cx, baseY + 14), 9,
        Potatuhs.textFaint, slot - 4,
        weight: FontWeight.w700);
  }
}

/// The visual manual for Bonds — wired into the registry spec.
final List<LegendFrame> bondsLegendFrames = [
  const LegendFrame(
      caption: 'Buy a bond, then sell it for more than you paid',
      paint: _legendTrade),
  const LegendFrame(
      caption: 'Rates fall ⇒ prices rise: buy cheap, sell dear',
      paint: _legendProfit),
  const LegendFrame(
      caption: 'Rates climb ⇒ prices fall: sell before the drop',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Longer bonds swing hardest; 10Y & 30Y unlock late',
      paint: _legendDuration),
];

// ─── FX overlay painter ────────────────────────────────────────────────────────
class _BdFxPainter extends CustomPainter {
  final List<FxParticle> particles;
  final List<FxPop> pops;
  _BdFxPainter(this.particles, this.pops);

  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _BdFxPainter old) => true;
}
