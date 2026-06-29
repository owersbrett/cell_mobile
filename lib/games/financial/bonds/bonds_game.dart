import 'dart:math';

import 'package:flutter/material.dart';

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
  late final AnimationController _ctrl;
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Main loop (host owns the clock) ───────────────────────────────────────
  void _tick() {
    if (!widget.session.isRunning) return;
    const dt = 1 / 60.0;
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
      ]);
    });
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
            sub: _canSell ? 'realize gains' : 'no bonds',
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
    GameFx.text(canvas, 'RATE', Offset(28, 12), 9, Potatuhs.gold,
        weight: FontWeight.w800);
    GameFx.text(canvas, 'PRICE', Offset(size.width - 28, 12), 9, priceColor,
        weight: FontWeight.w800);
  }

  @override
  bool shouldRepaint(covariant _BdChartPainter old) => true;
}

// ─── FX overlay painter ────────────────────────────────────────────────────────
class _BdFxPainter extends CustomPainter {
  final List<FxParticle> particles;
  final List<FxPop> pops;
  _BdFxPainter(this.particles, this.pops);

  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, particles);
    for (final p in pops) p.paint(canvas);
  }

  @override
  bool shouldRepaint(covariant _BdFxPainter old) => true;
}
