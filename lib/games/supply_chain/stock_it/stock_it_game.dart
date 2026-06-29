import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// StockItGame — "Stock It Right"  (BioScale.supplyChain)
// ═══════════════════════════════════════════════════════════════════════════════
//
// The "Beer Game", lite. You run ONE potato warehouse that ships spuds to
// stores. Time advances in DAYS. Each day customer DEMAND eats potatoes off
// your shelf (sales = revenue). You place ORDERS to restock — but an order
// arrives only after a LEAD TIME (it lands in your incoming pipeline and shows
// up N days later). So you must order for the FUTURE, not for today.
//
// Two ways to bleed points:
//   • STOCKOUT  — demand you can't fill is lost sales + a penalty.
//   • OVERSTOCK — every potato held above a free buffer costs a daily HOLDING
//     fee. Hoarding rots your profit.
//
// The lesson lives in the chart: because orders are delayed, panic-ordering
// after a demand spike makes your stock OSCILLATE (over, then under, then over)
// — the BULLWHIP EFFECT. A small wobble in demand amplifies into a big wobble in
// your orders. A live BULLWHIP meter shows the player their own amplification.
//
// Score = running PROFIT (revenue − holding − stockout penalty), pushed to the
// host via session.addScore (the session clamps at 0). noteStreak tracks a
// "smooth supply" run of days with neither a stockout nor heavy overstock.
//
// Performance: continuous motion is ONE CustomPainter repainted off a single
// Ticker (the day-progress sweep + chart). Discrete state (stats, controls)
// rebuilds only on day boundaries and button taps — never per frame.

// --- Sim tuning -------------------------------------------------------------
const double _kDayLenStart = 1.8; // seconds per day at the start
const double _kDayLenEnd = 1.15; // seconds per day late (it speeds up)
const int _kStartStock = 30; // opening shelf stock
const double _kPrice = 12.0; // revenue per potato SOLD
const double _kHoldingCost = 0.6; // cost per potato held above the free buffer
const int _kHoldFree = 10; // potatoes you may hold free (no holding fee)
const double _kStockoutPenalty = 16.0; // penalty per unit of unmet demand
const double _kBaseDemand = 9.0; // opening demand level (potatoes/day)
const int _kPipelineSlots = 7; // pipeline depth (must exceed max lead time)
const int _kHistMax = 44; // chart history length (≈ one game of days)
const int _kWobbleWin = 10; // window for the bullwhip amplification meter
const int _kMaxOrder = 99;

class StockItGame extends StatefulWidget {
  final MiniGameSession session;
  const StockItGame({super.key, required this.session});

  @override
  State<StockItGame> createState() => _StockItGameState();
}

/// One recorded day for the stock-history chart.
class _DayPoint {
  final double stock; // shelf stock at end of day
  final double demand; // demand that day
  _DayPoint(this.stock, this.demand);
}

class _StockItGameState extends State<StockItGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // --- Warehouse ---
  double _stock = _kStartStock.toDouble();
  // Pipeline: index i = potatoes ARRIVING in i day-advances. Placing an order
  // adds to slot [_leadTime]; each day shifts everything one slot toward 0.
  final List<double> _pipeline = List<double>.filled(_kPipelineSlots, 0);

  // --- Time ---
  int _day = 1;
  double _dayClock = 0; // 0..dayLen, seconds into the current day
  double _lastT = 0;

  // --- Demand model ---
  // The underlying demand LEVEL drifts in slow regime-shifts; the daily demand
  // is the level plus small noise. The whole bullwhip lesson is: read the LEVEL
  // and order to it — don't chase the daily noise.
  double _demandLevel = _kBaseDemand;
  int _demandToday = _kBaseDemand.round();
  int _regimeTimer = 6;

  // --- Economy ---
  double _profit = 0;

  // --- Difficulty (escalates) ---
  int _leadTime = 3;

  // --- Order control ---
  int _orderSize = 9;
  int _orderThisDay = 0; // orders placed during the current day (for bullwhip)

  // --- Streak ("smooth supply" days) ---
  int _streak = 0;

  // --- History / chart ---
  final List<_DayPoint> _history = [];
  final List<double> _demandWindow = []; // recent demand-per-day
  final List<double> _orderWindow = []; // recent order-per-day

  // --- Feedback ---
  final List<FxPop> _pops = [];
  String _flashText = '';
  Color _flashColor = Potatuhs.airForce;
  double _flash = 0;
  double _stockoutFlash = 0;

  Size _screen = Size.zero;

  // ─── Derived targets (drive the chart band + colour) ──────────────────────
  /// The stock you'd want on hand to cover demand across the whole lead time
  /// plus a day of safety — the "order up to" target the band centres on.
  double get _target => _demandLevel * (_leadTime + 1);
  double get _bandLow => _target * 0.6;
  double get _bandHigh => _target * 1.4;
  double get _heavyOver => _target * 1.9;
  double get _incoming => _pipeline.fold(0.0, (s, v) => s + v);
  double get _dayLen {
    final f = (_day / 34.0).clamp(0.0, 1.0);
    return _kDayLenStart + (_kDayLenEnd - _kDayLenStart) * f;
  }

  /// std(orders) / std(demand) over the recent window — the bullwhip
  /// amplification. >1 means your ordering wobbles more than demand does.
  double get _bullwhip {
    if (_demandWindow.length < 4 || _orderWindow.length < 4) return 0;
    final ds = _std(_demandWindow);
    final os = _std(_orderWindow);
    if (ds < 0.5) return os < 0.5 ? 1.0 : 3.0;
    return os / ds;
  }

  static double _std(List<double> xs) {
    if (xs.length < 2) return 0;
    final m = xs.reduce((a, b) => a + b) / xs.length;
    var v = 0.0;
    for (final x in xs) {
      v += (x - m) * (x - m);
    }
    return math.sqrt(v / xs.length);
  }

  @override
  void initState() {
    super.initState();
    // Seed a short flat history so the chart reads as a line from the first frame.
    for (var i = 0; i < 4; i++) {
      _history.add(_DayPoint(_kStartStock.toDouble(), _kBaseDemand));
      _demandWindow.add(_kBaseDemand);
      _orderWindow.add(_kBaseDemand);
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Main loop (host owns the wall clock; we own the day clock) ────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX decay runs even between plays so feedback fades cleanly.
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_flash > 0) _flash = (_flash - dt * 1.2).clamp(0.0, 1.0);
    if (_stockoutFlash > 0) {
      _stockoutFlash = (_stockoutFlash - dt * 2.2).clamp(0.0, 1.0);
    }

    if (!widget.session.isRunning) return;

    _dayClock += dt;
    if (_dayClock >= _dayLen) {
      _dayClock -= _dayLen;
      _advanceDay();
    }
  }

  // ─── A day passes: arrivals → demand/sales → costs → record ───────────────
  void _advanceDay() {
    // 1. Pipeline arrivals land on the shelf, then the pipeline shifts forward.
    final arrived = _pipeline[0];
    for (var i = 0; i < _pipeline.length - 1; i++) {
      _pipeline[i] = _pipeline[i + 1];
    }
    _pipeline[_pipeline.length - 1] = 0;
    _stock += arrived;

    // 2. Demand: occasional regime-shift in the level, then today's noisy draw.
    _regimeTimer--;
    if (_regimeTimer <= 0) {
      _regimeTimer = 5 + _rng.nextInt(5);
      // Swings grow as the game escalates — bigger surprises later.
      final swing = 2.0 + 4.0 * (_day / 34.0).clamp(0.0, 1.0);
      _demandLevel =
          (_demandLevel + (_rng.nextDouble() * 2 - 1) * swing).clamp(4.0, 22.0);
    }
    final noise = (_rng.nextDouble() * 2 - 1) * 2.0;
    final demand = math.max(0, (_demandLevel + noise).round());
    _demandToday = demand;

    // 3. Sales = min(stock, demand). Unmet demand is a stockout.
    final sales = math.min(_stock, demand.toDouble());
    final missed = demand - sales;
    _stock -= sales;

    // 4. Costs. Holding is charged on stock above the free buffer.
    final revenue = sales * _kPrice;
    final overFree = math.max(0.0, _stock - _kHoldFree);
    final holding = overFree * _kHoldingCost;
    final penalty = missed * _kStockoutPenalty;
    _profit += revenue - holding - penalty;
    _syncScore();

    // 5. Streak: a "smooth supply" day filled all demand with no heavy overstock.
    final heavyOver = _stock > _heavyOver;
    final smooth = missed <= 0.001 && !heavyOver;
    if (smooth) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    // 6. Feedback.
    if (missed > 0.5) {
      _stockoutFlash = 1.0;
      _flashText = 'STOCKOUT! −${missed.round()} sold out';
      _flashColor = const Color(0xFFEF5350);
      _flash = 1.0;
      _pops.add(FxPop(_center(0.42), '−\$${penalty.round()}',
          const Color(0xFFEF5350)));
    } else if (heavyOver) {
      _flashText = 'OVERSTOCK — holding \$${holding.round()}/day';
      _flashColor = Potatuhs.sienna;
      _flash = 0.9;
    } else if (smooth && _streak >= 3 && _streak % 2 == 1) {
      _flashText = '×$_streak SMOOTH SUPPLY';
      _flashColor = const Color(0xFF66BB6A);
      _flash = 0.9;
    }

    // 7. Record history + the per-day demand/order series for the bullwhip meter.
    _history.add(_DayPoint(_stock, demand.toDouble()));
    if (_history.length > _kHistMax) _history.removeAt(0);
    _demandWindow.add(demand.toDouble());
    if (_demandWindow.length > _kWobbleWin) _demandWindow.removeAt(0);
    _orderWindow.add(_orderThisDay.toDouble());
    if (_orderWindow.length > _kWobbleWin) _orderWindow.removeAt(0);
    _orderThisDay = 0;

    // 8. Escalate: lead time stretches as the game goes on (orders take longer).
    _day++;
    _leadTime = _day < 14
        ? 3
        : _day < 26
            ? 4
            : 5;

    setState(() {});
  }

  /// Push running profit to the host scoreboard (session clamps at 0).
  void _syncScore() {
    final target = _profit.round();
    widget.session.addScore(target - widget.session.score);
  }

  Offset _center(double yFrac) => _screen == Size.zero
      ? const Offset(160, 240)
      : Offset(_screen.width * 0.5, _screen.height * yFrac);

  // ─── Order controls ───────────────────────────────────────────────────────
  void _placeOrder() {
    if (!widget.session.isRunning) return;
    setState(() {
      _pipeline[_leadTime] += _orderSize.toDouble();
      _orderThisDay += _orderSize;
      _pops.add(FxPop(_center(0.62), '+$_orderSize ordered', Potatuhs.airForce));
    });
  }

  void _bumpOrder(int by) =>
      setState(() => _orderSize = (_orderSize + by).clamp(0, _kMaxOrder));
  void _setOrder(int v) => setState(() => _orderSize = v.clamp(0, _kMaxOrder));

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      _screen = Size(c.maxWidth, c.maxHeight);
      final chartH = (c.maxHeight * 0.30).clamp(120.0, 200.0);
      final running = widget.session.isRunning;
      return Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _StockChartPainter(this, _ctrl),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            _goalLine(),
            _statBar(),
            const SizedBox(height: 4),
            // Chart sits in the painted area; this just reserves its height.
            SizedBox(height: chartH),
            const Spacer(),
            _pipelineRow(),
            const SizedBox(height: 6),
            _orderControl(running),
            const SizedBox(height: 8),
          ]),
        ),
        if (!running)
          Positioned.fill(
            child: IgnorePointer(child: Center(child: _readyHint())),
          ),
      ]);
    });
  }

  Widget _goalLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        'KEEP STOCK IN THE BAND — ORDER AHEAD OF THE LEAD TIME',
        textAlign: TextAlign.center,
        style: Potatuhs.label(size: 9.5, color: Potatuhs.textFaint),
      ),
    );
  }

  // STOCK / DEMAND / INCOMING / PROFIT.
  Widget _statBar() {
    final stockCol = _stock <= 0
        ? const Color(0xFFEF5350)
        : _stock < _bandLow
            ? Potatuhs.orange
            : _stock > _heavyOver
                ? const Color(0xFFEF5350)
                : _stock > _bandHigh
                    ? Potatuhs.gold
                    : const Color(0xFF66BB6A);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.9),
        borderColor: Potatuhs.airForce.withValues(alpha: 0.32),
        radius: 14,
      ),
      child: Row(children: [
        _stat('STOCK', _stock.round().toString(), stockCol),
        _div(),
        _stat('DEMAND', '$_demandToday/day', Potatuhs.textPrimary),
        _div(),
        _stat('INCOMING', _incoming.round().toString(),
            _incoming > 0 ? Potatuhs.airForce : Potatuhs.textFaint),
        _div(),
        _stat(
          'PROFIT',
          '${_profit >= 0 ? "+" : "−"}\$${_profit.abs().round()}',
          _profit >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
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
            style: Potatuhs.body(size: 15, weight: FontWeight.w800, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _div() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.08),
      );

  // Incoming pipeline: boxes arriving in N days. The heart of "lead time".
  Widget _pipelineRow() {
    final chips = <Widget>[];
    for (var i = 0; i < _pipeline.length; i++) {
      if (_pipeline[i] <= 0) continue;
      final arriving = i == 0 ? 'next day' : 'in ${i}d';
      chips.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Potatuhs.airForce.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Potatuhs.airForce.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_shipping_outlined,
              size: 12, color: Potatuhs.airForce),
          const SizedBox(width: 4),
          Text('${_pipeline[i].round()} · $arriving',
              style: Potatuhs.label(size: 9, color: Potatuhs.airForce)),
        ]),
      ));
    }
    return SizedBox(
      height: 28,
      child: chips.isEmpty
          ? Center(
              child: Text(
                'NOTHING INCOMING — orders take $_leadTime days to arrive',
                style: Potatuhs.label(size: 9, color: Potatuhs.textFaint),
              ),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: chips,
            ),
    );
  }

  // Order size stepper + presets + the big ORDER button.
  Widget _orderControl(bool running) {
    final lvl = _demandLevel.round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.7),
        borderColor: Potatuhs.gold.withValues(alpha: 0.3),
        radius: 14,
      ),
      child: Column(children: [
        Row(children: [
          Text('ORDER', style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
          const SizedBox(width: 8),
          _step('−', () => _bumpOrder(-1)),
          const SizedBox(width: 6),
          Expanded(
            child: Center(
              child: Text('$_orderSize',
                  style: Potatuhs.body(
                      size: 22,
                      weight: FontWeight.w800,
                      color: Potatuhs.textPrimary)),
            ),
          ),
          _step('+', () => _bumpOrder(1)),
          const SizedBox(width: 8),
          _preset('=$lvl', () => _setOrder(lvl), _orderSize == lvl),
          _preset('+5', () => _setOrder(_orderSize + 5), false),
          _preset('0', () => _setOrder(0), _orderSize == 0),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: running ? _placeOrder : null,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: running
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF35586B), Color(0xFF6690A3)],
                    )
                  : null,
              color: running ? null : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: running
                    ? Potatuhs.airForce.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: running
                  ? [
                      BoxShadow(
                          color: Potatuhs.airForce.withValues(alpha: 0.3),
                          blurRadius: 14)
                    ]
                  : null,
            ),
            child: Text(
              _orderSize <= 0
                  ? 'ORDER NOTHING'
                  : 'ORDER $_orderSize  ·  arrives in $_leadTime days',
              style: Potatuhs.body(
                  size: 14,
                  weight: FontWeight.w800,
                  color: running ? Potatuhs.textPrimary : Potatuhs.textFaint),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _step(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(label,
            style: Potatuhs.body(
                size: 20, weight: FontWeight.w800, color: Potatuhs.textPrimary)),
      ),
    );
  }

  Widget _preset(String label, VoidCallback onTap, bool active) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 30),
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active
                ? Potatuhs.gold.withValues(alpha: 0.26)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? Potatuhs.gold.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Text(label,
              style: Potatuhs.label(
                  size: 10,
                  color: active ? Potatuhs.gold : Potatuhs.textSecondary)),
        ),
      ),
    );
  }

  Widget _readyHint() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.92),
        borderColor: Potatuhs.airForce.withValues(alpha: 0.4),
        radius: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.warehouse_outlined,
            size: 30, color: Potatuhs.airForce),
        const SizedBox(height: 8),
        Text('STOCK IT RIGHT',
            style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
        const SizedBox(height: 6),
        Text(
          'Orders arrive AFTER a lead time — order for the future.\n'
          'Hold a safety buffer. Don\'t chase spikes: overreacting is\n'
          'exactly what makes the bullwhip whip.',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 11.5, color: Potatuhs.textSecondary),
        ),
      ]),
    );
  }
}

// ─── Chart painter: the whole continuous-motion surface (one Ticker) ──────────
class _StockChartPainter extends CustomPainter {
  final _StockItGameState s;
  _StockChartPainter(this.s, Listenable repaint) : super(repaint: repaint);

  // Chart geometry must match the SizedBox reserved in build(): it starts under
  // the goal line + stat bar and is `chartH` tall.
  @override
  void paint(Canvas canvas, Size size) {
    // Atmosphere fills the whole play area behind everything.
    GameFx.atmosphere(canvas, size, Potatuhs.airForce, s._dayClock + s._day * 1.0,
        motes: 20);

    final chartH = (size.height * 0.30).clamp(120.0, 200.0);
    // Approximate top offset: SafeArea top + goal line (~24) + stat bar (~48) + gaps.
    const top = 84.0;
    final rect = Rect.fromLTWH(10, top, size.width - 20, chartH);
    _paintChart(canvas, rect);

    // FX overlay (pops + center flash) over the chart region.
    for (final p in s._pops) {
      p.paint(canvas);
    }
    if (s._flash > 0) {
      GameFx.text(
        canvas,
        s._flashText,
        Offset(size.width / 2, rect.center.dy),
        17,
        s._flashColor.withValues(alpha: s._flash.clamp(0.0, 1.0)),
        weight: FontWeight.w800,
        glow: 0.7 * s._flash,
      );
    }
  }

  void _paintChart(Canvas canvas, Rect r) {
    // Panel.
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkPanel.withValues(alpha: 0.92),
            Potatuhs.inkDeep.withValues(alpha: 0.96),
          ],
        ).createShader(r),
    );
    canvas.save();
    canvas.clipRRect(rr);

    final hist = s._history;
    // Y range: 0 up to a headroom above the heavy-overstock line / peak stock.
    double maxStock = s._heavyOver * 1.15;
    for (final p in hist) {
      if (p.stock > maxStock) maxStock = p.stock * 1.08;
    }
    if (maxStock < 20) maxStock = 20;

    double yOf(double stock) =>
        r.bottom - (stock / maxStock).clamp(0.0, 1.0) * r.height;
    double xOf(int i) =>
        r.left + (hist.length <= 1 ? 0 : i / (hist.length - 1)) * r.width;

    // Healthy band (shaded) — where stock SHOULD live.
    final bandTop = yOf(s._bandHigh);
    final bandBot = yOf(s._bandLow);
    canvas.drawRect(
      Rect.fromLTRB(r.left, bandTop, r.right, bandBot),
      Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.10),
    );
    _dashed(canvas, Offset(r.left, bandTop), Offset(r.right, bandTop),
        const Color(0xFF66BB6A).withValues(alpha: 0.5));
    _dashed(canvas, Offset(r.left, bandBot), Offset(r.right, bandBot),
        const Color(0xFF66BB6A).withValues(alpha: 0.5));

    // Stockout line (zero) — the red floor.
    final zeroY = yOf(0);
    _dashed(canvas, Offset(r.left, zeroY), Offset(r.right, zeroY),
        const Color(0xFFEF5350).withValues(alpha: 0.6));

    // Faint demand line (the SMALL wobble) for contrast against your stock swing.
    if (hist.length >= 2) {
      final dPath = Path();
      for (var i = 0; i < hist.length; i++) {
        final x = xOf(i);
        final y = yOf(hist[i].demand);
        i == 0 ? dPath.moveTo(x, y) : dPath.lineTo(x, y);
      }
      canvas.drawPath(
        dPath,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.45)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Stock line — the main event. Colour by where the last point sits.
    if (hist.length >= 2) {
      final path = Path();
      for (var i = 0; i < hist.length; i++) {
        final x = xOf(i);
        final y = yOf(hist[i].stock);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final last = hist.last.stock;
      final lineCol = last <= 0
          ? const Color(0xFFEF5350)
          : last < s._bandLow
              ? Potatuhs.orange
              : last > s._heavyOver
                  ? const Color(0xFFEF5350)
                  : last > s._bandHigh
                      ? Potatuhs.gold
                      : const Color(0xFF66BB6A);
      // Glow pass + core.
      canvas.drawPath(
        path,
        Paint()
          ..color = lineCol.withValues(alpha: 0.30)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = lineCol
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      // Tip dot.
      final tip = Offset(xOf(hist.length - 1), yOf(last));
      canvas.drawCircle(tip, 3.5, Paint()..color = lineCol);
    }

    canvas.restore();

    // Labels: band + the bullwhip amplification meter.
    GameFx.text(canvas, 'HEALTHY', Offset(r.left + 30, bandTop + 8), 8,
        const Color(0xFF66BB6A).withValues(alpha: 0.8));
    GameFx.text(canvas, 'STOCKOUT', Offset(r.left + 32, zeroY - 8), 8,
        const Color(0xFFEF5350).withValues(alpha: 0.85));
    GameFx.text(canvas, 'demand', Offset(r.right - 24, r.top + 10), 8,
        Potatuhs.gold.withValues(alpha: 0.75));

    _paintBullwhip(canvas, r);
  }

  // The teaching readout: how much your ORDERS wobble vs how much DEMAND wobbles.
  void _paintBullwhip(Canvas canvas, Rect r) {
    final amp = s._bullwhip;
    if (amp <= 0) return;
    final label = amp < 1.3
        ? 'SMOOTH ×${amp.toStringAsFixed(1)}'
        : amp < 2.1
            ? 'RIPPLING ×${amp.toStringAsFixed(1)}'
            : 'BULLWHIP! ×${amp.toStringAsFixed(1)}';
    final col = amp < 1.3
        ? const Color(0xFF66BB6A)
        : amp < 2.1
            ? Potatuhs.gold
            : const Color(0xFFEF5350);
    final boxW = 118.0;
    final box = Rect.fromLTWH(r.right - boxW - 6, r.top + 6, boxW, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = col.withValues(alpha: 0.6),
    );
    GameFx.text(canvas, 'BULLWHIP', Offset(box.center.dx, box.top + 9), 7,
        Potatuhs.textFaint);
    GameFx.text(canvas, label, Offset(box.center.dx, box.top + 21), 10.5, col,
        weight: FontWeight.w800);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    final total = (b - a).distance;
    final dir = total == 0 ? Offset.zero : (b - a) / total;
    for (double d = 0; d < total; d += 10) {
      final p1 = a + dir * d;
      final p2 = a + dir * math.min(d + 5, total);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StockChartPainter old) => true;
}
