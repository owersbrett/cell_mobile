import 'dart:math';

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FinancialTradingGame — "Market Trader"  (BioScale.financial)
// ═══════════════════════════════════════════════════════════════════════════════
//
// A coherent trading desk. The player has DIRECT control over:
//   • SIZE — how many shares each action moves (stepper + lot presets + MAX).
//   • ORDERS — place LIMIT BUY orders that RESERVE cash until they fill against
//     the moving market, or CANCEL them (small fee) to free that cash back up.
//   • MARKET buys/sells — instant fills at the live price.
//
// Cash is split into AVAILABLE (free to deploy) and RESERVED (tied up in open
// buy orders). Score = cumulative REALIZED P&L, reported to the host session on
// every sell via session.addScore. The host owns the clock / countdown /
// results; this widget only runs the sim while session.isRunning.

// --- Wallet / market tuning -------------------------------------------------
const double _kMtStartingCash   = 1000.0; // opening capital
const double _kMtGameDuration   = 60.0;   // seconds (mirrors host clock)
const double _kMtBaseTickHz     = 12.0;
const double _kMtMaxTickHz      = 30.0;
const double _kMtBaseVolatility = 1.8;
const double _kMtMaxVolatility  = 9.0;
const double _kMtTrendDuration  = 4.0;
const double _kMtNewsDuration   = 1.5;
const double _kMtNewsChance     = 0.08;
const double _kMtNewsAmplitude  = 14.0;
const double _kMtStartingPrice  = 100.0;

// --- Order / sizing tuning --------------------------------------------------
// A limit buy can be placed up to this fraction below the live price.
const double _kMtLimitOffsetMax = 0.18;
// Cancelling an open order costs this fraction of the order's reserved value.
const double _kMtCancelFeeRate  = 0.01;
// Lot presets (in shares) offered as one-tap sizing buttons.
const List<int> _kMtLotPresets  = [1, 5, 25];

// --- Player market-event tuning ---
const double _kMtEventImpulse   = 22.0;
const double _kMtEventDuration  = 2.5;
const double _kMtEventCooldown  = 14.0;

// --- Render cadence ---------------------------------------------------------
// The simulation steps every animation frame (~60 Hz), but the WIDGET TREE only
// rebuilds at this rate. The smooth visuals (chart, particles, atmosphere) are
// drawn by Listenable-driven CustomPainters, so we never rebuild the big control
// tree 60×/sec — the app's known render-overload / black-screen bug class.
const double _kMtRenderHz       = 20.0;
// How often (seconds) a price sample is appended to the chart history.
const double _kMtChartSampleSec = 0.25;

class _MtPriceSample {
  final double price;
  _MtPriceSample(this.price);
}

class _MtPop {
  Offset pos;
  final String label;
  final Color color;
  double life = 1.1;
  _MtPop(this.pos, this.label, this.color);
  bool step(double dt) {
    pos = pos.translate(0, -48 * dt);
    life -= dt / 1.1;
    return life > 0;
  }
  void paint(Canvas canvas) {
    final a = life.clamp(0.0, 1.0);
    GameFx.text(canvas, label, pos, 22, color.withValues(alpha: a),
        weight: FontWeight.w800, glow: 0.8 * a);
  }
}

class _MtNews {
  final String headline;
  final double impulse;
  double ttl;
  _MtNews(this.headline, this.impulse, this.ttl);
}

class _MtEventDef {
  final String label;
  final String emoji;
  final double sign;
  const _MtEventDef(this.label, this.emoji, this.sign);
}

const List<_MtEventDef> _kMtEvents = [
  _MtEventDef('Drought',   '☀️',  1.0),
  _MtEventDef('Flooding',  '🌊',  1.0),
  _MtEventDef('Tornado',   '🌪️',  1.0),
  _MtEventDef('Quake',     '⚡',  1.0),
  _MtEventDef('Recession', '📉', -1.0),
  _MtEventDef('Abundance', '🌾', -1.0),
];

/// One open LIMIT BUY order. Reserves [reserved] cash (= shares × limit) until
/// the market trades at/under [limit] and the order fills.
class _MtOrder {
  final int    shares;
  final double limit;
  double get reserved => shares * limit;
  _MtOrder(this.shares, this.limit);
}

class FinancialTradingGame extends StatefulWidget {
  final MiniGameSession session;
  const FinancialTradingGame({Key? key, required this.session})
      : super(key: key);
  @override
  State<FinancialTradingGame> createState() => _FinancialTradingGameState();
}

class _FinancialTradingGameState extends State<FinancialTradingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // --- Wallet ---
  // Free cash you can spend right now.
  double _available = _kMtStartingCash;
  // Cash locked behind open buy orders (sum of every _MtOrder.reserved).
  double _reserved  = 0.0;
  // Cumulative realized P&L — this IS the score reported to the session.
  double _realized  = 0.0;

  double _timeLeft = _kMtGameDuration;

  // Widget-tree refresh throttle + chart-sampling clocks (seconds).
  double _renderAccum = 0.0;
  double _chartTimer  = 0.0;

  // --- Position (held shares, average cost basis) ---
  double _heldShares  = 0.0;
  double _avgCost      = 0.0; // weighted avg entry price of held shares

  // --- Sizing ---
  int _lotSize = 5;          // shares per action (the player's batch knob)
  // Limit offset 0..1 → 0 = at market, 1 = max below market. Drives limit price.
  double _limitOffset = 0.0;

  // --- Open buy orders ---
  final List<_MtOrder> _orders = [];

  // --- Price / market ---
  double _price       = _kMtStartingPrice;
  double _trend       = 0.0;
  double _trendTimer  = 0.0;
  double _priceClock  = 0.0;
  _MtNews? _news;
  double _newsTimer   = 0.0;

  // --- Chart ---
  final List<_MtPriceSample> _chart = [];
  static const int _kChartMax = 200;
  // Repaint signal for the chart painter — bumped when a sample is appended or
  // the open-order set changes, so the chart repaints on real change only, not
  // 60×/sec.
  final ValueNotifier<int> _chartRev = ValueNotifier<int>(0);
  void _bumpChart() => _chartRev.value++;

  // --- FX ---
  final List<FxParticle> _fxParticles = [];
  final List<_MtPop>     _pops        = [];

  late final List<double> _eventCooldowns;

  Color  _flashColor = Colors.transparent;
  double _flashAlpha = 0.0;

  Size _screen = Size.zero;

  // --- Derived ---
  double get _volatility {
    final t = 1.0 - (_timeLeft / _kMtGameDuration);
    return _kMtBaseVolatility + (_kMtMaxVolatility - _kMtBaseVolatility) * t;
  }
  double get _tickHz {
    final t = 1.0 - (_timeLeft / _kMtGameDuration);
    return _kMtBaseTickHz + (_kMtMaxTickHz - _kMtBaseTickHz) * t;
  }
  bool   get _inPosition  => _heldShares > 1e-6;
  double get _positionValue => _heldShares * _price;
  double get _unrealizedPnl =>
      _inPosition ? (_price - _avgCost) * _heldShares : 0.0;
  // The selected limit price for a new buy order (offset below market).
  double get _limitPrice =>
      _price * (1.0 - _limitOffset * _kMtLimitOffsetMax);
  // Cash cost to reserve a buy of the current lot at the current limit.
  double get _orderCost => _lotSize * _limitPrice;
  bool   get _canPlaceOrder =>
      _lotSize > 0 && _available >= _orderCost - 1e-6;
  bool   get _canMarketBuy =>
      _lotSize > 0 && _available >= _lotSize * _price - 1e-6;

  @override
  void initState() {
    super.initState();
    _eventCooldowns = List.filled(_kMtEvents.length, 0.0);
    _chart.add(_MtPriceSample(_price));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _chartRev.dispose();
    super.dispose();
  }

  // ─── Main loop (host owns the clock) ──────────────────────────────────────
  // The sim advances every frame; painters animate off Listenables. We only
  // rebuild the widget tree at _kMtRenderHz, or immediately when a discrete
  // event (order fill, news, cooldown ready) changes what the controls show.
  void _tick() {
    if (!widget.session.isRunning) return;
    const dt = 1 / 60.0;
    _timeLeft = widget.session.remaining.inMilliseconds / 1000.0;
    bool dirty = false; // a discrete change that needs an immediate rebuild

    _trendTimer -= dt;
    if (_trendTimer <= 0) {
      _trend      = (_rng.nextDouble() * 2 - 1);
      _trendTimer = _kMtTrendDuration * (0.6 + _rng.nextDouble() * 0.8);
      if (_news == null && _rng.nextDouble() < _kMtNewsChance) {
        _spawnNews();
        dirty = true;
      }
    }

    if (_news != null) {
      _newsTimer -= dt;
      if (_newsTimer <= 0) {
        _news = null;
        dirty = true;
      }
    }

    _priceClock += dt * _tickHz;
    final steps = _priceClock.floor();
    _priceClock -= steps;
    for (int s = 0; s < steps; s++) {
      _stepPrice();
      if (_fillOrders()) dirty = true; // limit fills are discrete events
    }

    _chartTimer += dt;
    if (_chart.length < 2 || _chartTimer >= _kMtChartSampleSec) {
      _chartTimer = 0;
      _chart.add(_MtPriceSample(_price));
      if (_chart.length > _kChartMax) _chart.removeAt(0);
      _bumpChart();
    }

    for (int i = 0; i < _eventCooldowns.length; i++) {
      if (_eventCooldowns[i] > 0) {
        _eventCooldowns[i] =
            (_eventCooldowns[i] - dt).clamp(0.0, _kMtEventCooldown);
        if (_eventCooldowns[i] == 0) dirty = true; // button just re-enabled
      }
    }

    if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 3).clamp(0, 1);

    _fxParticles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    _renderAccum += dt;
    if (dirty || _renderAccum >= 1.0 / _kMtRenderHz) {
      _renderAccum = 0;
      setState(() {}); // fields already mutated above
    }
  }

  void _stepPrice() {
    final vol   = _volatility;
    final drift = _trend * vol * 0.35;
    final noise = (_rng.nextDouble() * 2 - 1) * vol;
    double impulse = 0;
    if (_news != null) impulse = _news!.impulse * 0.5;
    _price = (_price + drift + noise + impulse).clamp(10.0, 9999.0);
  }

  void _spawnNews() {
    final positive = _rng.nextBool();
    final headlines = positive
        ? ['STRONG EARNINGS', 'UPGRADE: BUY', 'SHORT SQUEEZE!', 'BULLISH DATA']
        : ['EARNINGS MISS', 'FED HIKE FEAR', 'SELL-OFF WAVE', 'MARGIN CALLS'];
    final impulse = (positive ? 1 : -1) *
        (_kMtNewsAmplitude * (0.7 + _rng.nextDouble() * 0.6));
    _news      = _MtNews(
      headlines[_rng.nextInt(headlines.length)],
      impulse,
      _kMtNewsDuration,
    );
    _newsTimer  = _kMtNewsDuration;
    _trend      = positive ? 0.9 : -0.9;
    _trendTimer = _kMtNewsDuration;
  }

  // ─── Sizing controls ──────────────────────────────────────────────────────
  void _setLot(int v) => setState(() => _lotSize = v.clamp(1, 9999));
  void _bumpLot(int by) => setState(() => _lotSize = (_lotSize + by).clamp(1, 9999));
  void _maxLot() {
    // Largest lot the available cash can buy at the live MARKET price. Sizing to
    // market (not the lower limit price) guarantees BOTH a market BUY and a
    // resting LIMIT order stay affordable — so MAX never leaves a button greyed.
    final maxByCash = (_available / max(_price, 0.01)).floor();
    setState(() => _lotSize = max(1, maxByCash));
  }

  // ─── Orders ───────────────────────────────────────────────────────────────
  /// Place a LIMIT BUY: reserves cash now, fills when price ≤ limit.
  void _placeOrder() {
    if (!widget.session.isRunning) return;
    final cost = _orderCost;
    if (_lotSize <= 0 || _available < cost - 1e-6) return;
    setState(() {
      _available -= cost;
      _reserved  += cost;
      _orders.add(_MtOrder(_lotSize, _limitPrice));
      _spawnFx(Potatuhs.airForce, count: 8, speed: 70);
      _bumpChart();
    });
  }

  /// Instant MARKET BUY of the current lot at the live price.
  void _marketBuy() {
    if (!widget.session.isRunning) return;
    final cost = _lotSize * _price;
    if (_lotSize <= 0 || _available < cost - 1e-6) return;
    setState(() {
      _available -= cost;
      _addShares(_lotSize.toDouble(), _price);
      _flashColor = Potatuhs.airForce;
      _flashAlpha = 0.18;
      _spawnFx(Potatuhs.airForce, count: 10, speed: 90);
    });
  }

  /// Cancel an open order: refund reserved cash MINUS a small fee.
  void _cancelOrder(int index) {
    if (!widget.session.isRunning) return;
    if (index < 0 || index >= _orders.length) return;
    setState(() {
      final o   = _orders.removeAt(index);
      final fee = o.reserved * _kMtCancelFeeRate;
      _reserved  = max(0.0, _reserved - o.reserved);
      _available += o.reserved - fee;
      _realized  -= fee; // the cancel fee is a realized cost against your P&L
      _syncScore();
      _bumpChart();
      _popLabel('-\$${fee.toStringAsFixed(1)} fee', const Color(0xFFEF5350),
          yFrac: 0.40);
    });
  }

  void _cancelAllOrders() {
    if (!widget.session.isRunning) return;
    if (_orders.isEmpty) return;
    setState(() {
      double feeTotal = 0;
      for (final o in _orders) {
        final fee = o.reserved * _kMtCancelFeeRate;
        feeTotal   += fee;
        _available += o.reserved - fee;
      }
      _orders.clear();
      _reserved  = 0.0; // every reserve was just released
      _realized -= feeTotal;
      _syncScore();
      _bumpChart();
      if (feeTotal > 0) {
        _popLabel('-\$${feeTotal.toStringAsFixed(1)} fees',
            const Color(0xFFEF5350), yFrac: 0.40);
      }
    });
  }

  /// Fill any open buy order whose limit is at/above the current price.
  /// Cash was already reserved at placement; here it converts to shares.
  /// Returns true if at least one order filled.
  bool _fillOrders() {
    if (_orders.isEmpty) return false;
    bool filled = false;
    for (int i = _orders.length - 1; i >= 0; i--) {
      final o = _orders[i];
      if (_price <= o.limit + 1e-9) {
        // Fill at the limit (cash reserved at the limit, so basis = limit).
        _reserved = max(0.0, _reserved - o.reserved);
        _addShares(o.shares.toDouble(), o.limit);
        _orders.removeAt(i);
        filled = true;
        _flashColor = const Color(0xFF66BB6A);
        _flashAlpha = 0.20;
        _spawnFx(const Color(0xFF66BB6A), count: 8, speed: 80);
        _popLabel('FILLED ${o.shares}@\$${o.limit.toStringAsFixed(2)}',
            const Color(0xFF66BB6A), yFrac: 0.46);
      }
    }
    if (filled) _bumpChart(); // open-order set (limit line) changed
    return filled;
  }

  void _addShares(double shares, double price) {
    final newTotal = _heldShares + shares;
    if (newTotal <= 1e-9) return;
    _avgCost   = (_avgCost * _heldShares + price * shares) / newTotal;
    _heldShares = newTotal;
  }

  // ─── Selling (realizes P&L → score) ───────────────────────────────────────
  void _sell(int shares, {bool silent = false}) {
    if (!widget.session.isRunning) return;
    if (_heldShares <= 1e-6) return;
    final qty = min(shares.toDouble(), _heldShares);
    if (qty <= 1e-6) return;
    final proceeds = qty * _price;
    final pnl      = (_price - _avgCost) * qty;
    setState(() {
      _available  += proceeds;
      _heldShares -= qty;
      if (_heldShares <= 1e-6) {
        _heldShares = 0;
        _avgCost    = 0;
      }
      _realized += pnl;
      _syncScore();
      if (silent) return;
      final profit = pnl >= 0;
      final col    = profit ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
      _flashColor  = col;
      _flashAlpha  = 0.28;
      _popLabel('${profit ? "+" : "-"}\$${pnl.abs().toStringAsFixed(0)}', col,
          yFrac: 0.42);
      if (profit && pnl > 5) {
        _spawnFx(Potatuhs.gold,
            count: pnl > 40 ? 22 : 14, speed: pnl > 40 ? 160 : 110, yFrac: 0.44);
      }
    });
  }

  void _sellLot()  => _sell(_lotSize);
  void _sellAll()  => _sell(_heldShares.ceil());

  /// Report the running realized P&L to the host scoreboard. The session
  /// clamps at 0, so it tracks the high-water positive total of realized gains.
  void _syncScore() {
    // session.score is monotonic via addScore; push the delta to reach _realized.
    final target  = _realized.round();
    final current = widget.session.score;
    widget.session.addScore(target - current);
  }

  // ─── Player market events ─────────────────────────────────────────────────
  void _triggerEvent(int idx) {
    if (!widget.session.isRunning) return;
    if (_eventCooldowns[idx] > 0) return;
    setState(() {
      final ev = _kMtEvents[idx];
      final impulse = ev.sign * _kMtEventImpulse;
      _news       = _MtNews(ev.label.toUpperCase(), impulse, _kMtEventDuration);
      _newsTimer  = _kMtEventDuration;
      _trend      = ev.sign * 0.95;
      _trendTimer = _kMtEventDuration;
      _eventCooldowns[idx] = _kMtEventCooldown;
    });
  }

  // ─── FX helpers ───────────────────────────────────────────────────────────
  void _spawnFx(Color color,
      {int count = 10, double speed = 90, double yFrac = 0.5}) {
    if (_screen == Size.zero) return;
    final center = Offset(_screen.width / 2, _screen.height * yFrac);
    _fxParticles.addAll(FxBurst.spawn(center, color, count: count, speed: speed));
  }

  void _popLabel(String label, Color color, {double yFrac = 0.42}) {
    final pos = _screen == Size.zero
        ? const Offset(160, 260)
        : Offset(_screen.width * 0.5, _screen.height * yFrac);
    _pops.add(_MtPop(pos, label, color));
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
      final chartH = (h * 0.26).clamp(110.0, 190.0);

      return Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MtBackgroundPainter(_ctrl, Potatuhs.airForce),
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
            _buildPriceTicker(),
            if (_news != null) _buildNewsBanner(_news!),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: SizedBox(
                height: chartH,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _MtChartPainter(_chart, _kMtStartingPrice,
                          _limitPriceLine(), _chartRev),
                    ),
                  ),
                ),
              ),
            ),

            _buildPositionRow(),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(children: [
                  _buildSizeControl(),
                  _buildOrderControls(),
                  if (_orders.isNotEmpty) _buildOpenOrders(),
                  _buildEventButtons(),
                  const SizedBox(height: 6),
                ]),
              ),
            ),

            _buildTradeButtons(),
            const SizedBox(height: 8),
          ]),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _MtFxPainter(_fxParticles, _pops, _ctrl),
            ),
          ),
        ),
      ]);
    });
  }

  // The open-order limit line drawn on the chart (null = none / at market).
  double? _limitPriceLine() {
    if (_orders.isEmpty) return null;
    // Highest pending limit — the next one likely to fill.
    return _orders.map((o) => o.limit).reduce(max);
  }

  // ─── Wallet bar: AVAILABLE / RESERVED / POSITION / REALIZED ───────────────
  Widget _buildWalletBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.9),
        borderColor: Potatuhs.airForce.withValues(alpha: 0.35),
        radius: 14,
      ),
      child: Row(children: [
        _walletStat('AVAILABLE', '\$${_available.toStringAsFixed(0)}',
            Potatuhs.textPrimary),
        _walletDivider(),
        _walletStat('RESERVED', '\$${_reserved.toStringAsFixed(0)}',
            _reserved > 0.5 ? Potatuhs.sienna : Potatuhs.textFaint),
        _walletDivider(),
        _walletStat(
          'POSITION',
          _inPosition
              ? '${_heldShares.toStringAsFixed(0)} sh'
              : '—',
          _inPosition ? Potatuhs.airForce : Potatuhs.textFaint,
        ),
        _walletDivider(),
        _walletStat(
          'P&L',
          '${_realized >= 0 ? "+" : "-"}\$${_realized.abs().toStringAsFixed(0)}',
          _realized >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        ),
      ]),
    );
  }

  Widget _walletStat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: Potatuhs.label(size: 8, color: Potatuhs.textFaint),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value,
            style: Potatuhs.body(
                size: 15, weight: FontWeight.w800, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _walletDivider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.08),
      );

  // ─── Live price ───────────────────────────────────────────────────────────
  Widget _buildPriceTicker() {
    final delta = _chart.length >= 6
        ? _price - _chart[max(0, _chart.length - 6)].price
        : 0.0;
    final up = delta >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '\$${_price.toStringAsFixed(2)}',
            style: Potatuhs.display(
              size: 30,
              color: up ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            ).copyWith(shadows: [
              Shadow(
                color: (up
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFEF5350))
                    .withValues(alpha: 0.55),
                blurRadius: 14,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (up
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF7F0000))
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${up ? "▲" : "▼"} ${delta.abs().toStringAsFixed(2)}',
              style: Potatuhs.label(
                  size: 11,
                  color: up
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350)),
            ),
          ),
          const Spacer(),
          if (_inPosition)
            Text(
              'avg \$${_avgCost.toStringAsFixed(2)}',
              style: Potatuhs.label(size: 10, color: Potatuhs.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsBanner(_MtNews news) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Potatuhs.orange.withValues(alpha: 0.3),
          Potatuhs.sienna.withValues(alpha: 0.15),
        ]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Potatuhs.orange.withValues(alpha: 0.6)),
      ),
      child: Row(children: [
        const Text('\u{1F4F0}', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(news.headline,
              style: Potatuhs.body(
                  size: 12, weight: FontWeight.w700, color: Potatuhs.gold)),
        ),
        Text(
          news.impulse > 0 ? '▲ SPIKE' : '▼ CRASH',
          style: Potatuhs.label(
              size: 10,
              color: news.impulse > 0
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350)),
        ),
      ]),
    );
  }

  // ─── Position summary ─────────────────────────────────────────────────────
  Widget _buildPositionRow() {
    if (!_inPosition) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        child: Text(
          'No shares held — set a size, then BUY or place a LIMIT order',
          style: Potatuhs.label(size: 10, color: Potatuhs.textFaint),
          textAlign: TextAlign.center,
        ),
      );
    }
    final upnl = _unrealizedPnl;
    final col  = upnl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: Potatuhs.surface(
        fill: col.withValues(alpha: 0.18),
        borderColor: col.withValues(alpha: 0.5),
        radius: 10,
      ),
      child: Row(children: [
        Text('${_heldShares.toStringAsFixed(0)} sh @ \$${_avgCost.toStringAsFixed(2)}',
            style: Potatuhs.label(size: 11, color: Potatuhs.textSecondary)),
        const Spacer(),
        Text('val \$${_positionValue.toStringAsFixed(0)}',
            style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)),
        const SizedBox(width: 10),
        Text(
          'unreal ${upnl >= 0 ? "+" : "-"}\$${upnl.abs().toStringAsFixed(0)}',
          style: Potatuhs.body(size: 13, weight: FontWeight.w700, color: col),
        ),
      ]),
    );
  }

  // ─── SIZE control (the batch knob) ────────────────────────────────────────
  Widget _buildSizeControl() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.7),
        borderColor: Potatuhs.gold.withValues(alpha: 0.3),
        radius: 12,
      ),
      child: Column(children: [
        Row(children: [
          Text('SIZE',
              style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
          const SizedBox(width: 10),
          _stepperBtn('−', () => _bumpLot(-1)),
          const SizedBox(width: 6),
          Expanded(
            child: Center(
              child: Text('$_lotSize sh',
                  style: Potatuhs.body(
                      size: 20,
                      weight: FontWeight.w800,
                      color: Potatuhs.textPrimary)),
            ),
          ),
          _stepperBtn('+', () => _bumpLot(1)),
          const SizedBox(width: 8),
          ..._kMtLotPresets.map((p) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _presetBtn('$p', () => _setLot(p), _lotSize == p),
              )),
          const SizedBox(width: 4),
          _presetBtn('MAX', _maxLot, false, wide: true),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('LIMIT', style: Potatuhs.label(size: 9, color: Potatuhs.airForce)),
          const SizedBox(width: 6),
          Text(
            _limitOffset <= 0.001
                ? 'at market \$${_price.toStringAsFixed(2)}'
                : '\$${_limitPrice.toStringAsFixed(2)}  (${(_limitOffset * _kMtLimitOffsetMax * 100).toStringAsFixed(0)}% below)',
            style: Potatuhs.label(size: 9, color: Potatuhs.textSecondary),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Potatuhs.airForce,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Potatuhs.airForce,
              ),
              child: Slider(
                value: _limitOffset,
                onChanged: (v) => setState(() => _limitOffset = v),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _stepperBtn(String label, VoidCallback onTap) {
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
                size: 20,
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
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? Potatuhs.gold.withValues(alpha: 0.28)
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
    );
  }

  // ─── Order controls: PLACE LIMIT / CANCEL ALL ─────────────────────────────
  Widget _buildOrderControls() {
    final placeReady = _canPlaceOrder && widget.session.isRunning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: placeReady ? _placeOrder : null,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: placeReady
                    ? Potatuhs.airForce.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: placeReady
                      ? Potatuhs.airForce.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PLACE LIMIT BUY',
                      style: Potatuhs.label(
                          size: 11,
                          color: placeReady
                              ? Potatuhs.airForce
                              : Potatuhs.textFaint)),
                  Text(
                    'reserve \$${_orderCost.toStringAsFixed(0)}  ·  $_lotSize @ \$${_limitPrice.toStringAsFixed(2)}',
                    style: Potatuhs.label(size: 8, color: Potatuhs.textFaint),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _orders.isNotEmpty ? _cancelAllOrders : null,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _orders.isNotEmpty
                  ? const Color(0xFF7F0000).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _orders.isNotEmpty
                    ? const Color(0xFFEF5350).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CANCEL ALL',
                    style: Potatuhs.label(
                        size: 10,
                        color: _orders.isNotEmpty
                            ? const Color(0xFFEF5350)
                            : Potatuhs.textFaint)),
                Text('${(_kMtCancelFeeRate * 100).toStringAsFixed(0)}% fee',
                    style: Potatuhs.label(size: 7, color: Potatuhs.textFaint)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Open-order chips (tap to cancel one) ─────────────────────────────────
  Widget _buildOpenOrders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: List.generate(_orders.length, (i) {
          final o = _orders[i];
          return GestureDetector(
            onTap: () => _cancelOrder(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Potatuhs.sienna.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Potatuhs.sienna.withValues(alpha: 0.55)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${o.shares} @ \$${o.limit.toStringAsFixed(2)}',
                    style: Potatuhs.label(size: 9, color: Potatuhs.sienna)),
                const SizedBox(width: 6),
                Icon(Icons.close,
                    size: 12, color: const Color(0xFFEF5350).withValues(alpha: 0.9)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ─── Player market events ─────────────────────────────────────────────────
  Widget _buildEventButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: Row(
        children: List.generate(_kMtEvents.length, (i) {
          final ev       = _kMtEvents[i];
          final cd       = _eventCooldowns[i];
          final ready    = cd <= 0;
          final progress = ready ? 1.0 : 1.0 - (cd / _kMtEventCooldown);
          final isUp     = ev.sign > 0;
          final accentCol =
              isUp ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
          return Expanded(
            child: GestureDetector(
              onTap: ready ? () => _triggerEvent(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: ready
                          ? accentCol.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ready
                            ? accentCol.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ev.emoji,
                            style: TextStyle(
                              fontSize: 13,
                              color: ready
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            )),
                        Text(ev.label,
                            style: Potatuhs.label(
                              size: 7,
                              color: ready
                                  ? accentCol
                                  : Potatuhs.textFaint.withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!ready)
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CustomPaint(
                        painter: _MtCooldownRingPainter(progress, accentCol),
                      ),
                    ),
                  if (!ready)
                    Positioned(
                      bottom: 2,
                      right: 3,
                      child: Text('${cd.ceil()}',
                          style: Potatuhs.label(
                              size: 7,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── BUY (market) / SELL row ──────────────────────────────────────────────
  Widget _buildTradeButtons() {
    final buyReady  = _canMarketBuy && widget.session.isRunning;
    final sellReady = _inPosition && widget.session.isRunning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(
          child: _bigBtn(
            top: 'BUY $_lotSize',
            sub: 'market \$${(_lotSize * _price).toStringAsFixed(0)}',
            enabled: buyReady,
            colorA: const Color(0xFF1B5E20),
            colorB: const Color(0xFF388E3C),
            accent: const Color(0xFF66BB6A),
            onTap: _marketBuy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _bigBtn(
            top: 'SELL $_lotSize',
            sub: sellReady ? 'realize gains' : 'no shares',
            enabled: sellReady,
            colorA: const Color(0xFF7F0000),
            colorB: const Color(0xFFC62828),
            accent: const Color(0xFFEF5350),
            onTap: _sellLot,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: sellReady ? _sellAll : null,
          child: Container(
            height: 58,
            width: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sellReady
                  ? const Color(0xFFC62828).withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sellReady
                    ? const Color(0xFFEF5350).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Text('SELL\nALL',
                textAlign: TextAlign.center,
                style: Potatuhs.label(
                    size: 11,
                    color: sellReady
                        ? const Color(0xFFEF5350)
                        : Potatuhs.textFaint)),
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
                    size: 18,
                    color: enabled ? accent : Potatuhs.textFaint)),
            Text(sub,
                style: Potatuhs.label(
                    size: 8,
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.8)
                        : Potatuhs.textFaint)),
          ],
        ),
      ),
    );
  }
}

// ─── Background painter ───────────────────────────────────────────────────────
// Repaints off the AnimationController (60 fps) without rebuilding any widgets,
// deriving its own seconds-clock so the atmosphere drift stays smooth even while
// the control tree refreshes at the lower _kMtRenderHz.
class _MtBackgroundPainter extends CustomPainter {
  final AnimationController controller;
  final Color accent;
  _MtBackgroundPainter(this.controller, this.accent)
      : super(repaint: controller);
  @override
  void paint(Canvas canvas, Size size) {
    final t = (controller.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
    GameFx.atmosphere(canvas, size, accent, t, motes: 28);
  }
  @override
  bool shouldRepaint(covariant _MtBackgroundPainter old) => false;
}

// ─── Chart painter ────────────────────────────────────────────────────────────
class _MtChartPainter extends CustomPainter {
  final List<_MtPriceSample> chart;
  final double baseline;
  final double? limitLine;
  _MtChartPainter(this.chart, this.baseline, this.limitLine, Listenable repaint)
      : super(repaint: repaint);

  // Reused TextPainters for the axis/limit labels — avoids rebuilding a
  // TextPainter for every label on every repaint. Keyed by text+style; the cap
  // keeps it from growing as price labels churn.
  static final Map<String, TextPainter> _tpCache = {};
  void _label(Canvas canvas, String s, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w400}) {
    final key = '$s|$color|$size|${weight.value}';
    final tp = _tpCache.putIfAbsent(key, () {
      if (_tpCache.length > 96) _tpCache.clear();
      return TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
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

    if (chart.length < 2) return;

    double minP = chart.map((s) => s.price).reduce(min);
    double maxP = chart.map((s) => s.price).reduce(max);
    if (baseline < minP) minP = baseline;
    if (baseline > maxP) maxP = baseline;
    if (limitLine != null) {
      if (limitLine! < minP) minP = limitLine!;
      if (limitLine! > maxP) maxP = limitLine!;
    }
    final pad = (maxP - minP) * 0.12 + 4;
    minP -= pad;
    maxP += pad;
    final range = maxP - minP;
    if (range <= 0) return;

    double px(int i) => (i / (chart.length - 1)) * size.width;
    double py(double price) =>
        size.height - ((price - minP) / range) * size.height;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final baseY = py(baseline);
    final dashPaint = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, baseY), Offset(x + 5, baseY), dashPaint);
    }

    // Open-order limit line (sienna dashes + label).
    if (limitLine != null) {
      final ly = py(limitLine!);
      final limPaint = Paint()
        ..color = Potatuhs.sienna.withValues(alpha: 0.8)
        ..strokeWidth = 1.2;
      for (double x = 0; x < size.width; x += 12) {
        canvas.drawLine(Offset(x, ly), Offset(x + 6, ly), limPaint);
      }
      _label(
        canvas,
        'LIMIT \$${limitLine!.toStringAsFixed(0)}',
        Offset(40, ly - 12),
        9,
        Potatuhs.sienna,
        weight: FontWeight.w700,
      );
    }

    final linePath = Path();
    for (int i = 0; i < chart.length; i++) {
      final x = px(i);
      final y = py(chart[i].price);
      i == 0 ? linePath.moveTo(x, y) : linePath.lineTo(x, y);
    }

    final lastPrice = chart.last.price;
    final profiting = lastPrice >= baseline;
    final lineColor =
        profiting ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.04),
          ],
        ).createShader(bgRect),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final tipX = px(chart.length - 1);
    final tipY = py(lastPrice);
    canvas.drawCircle(
      Offset(tipX, tipY), 7,
      Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(Offset(tipX, tipY), 3.5, Paint()..color = lineColor);

    final axisColor = Potatuhs.textFaint.withValues(alpha: 0.7);
    _label(canvas, '\$${maxP.toStringAsFixed(0)}',
        Offset(size.width - 22, 9), 9, axisColor, weight: FontWeight.w700);
    _label(canvas, '\$${minP.toStringAsFixed(0)}',
        Offset(size.width - 22, size.height - 9), 9, axisColor,
        weight: FontWeight.w700);
  }

  @override
  bool shouldRepaint(covariant _MtChartPainter old) =>
      old.limitLine != limitLine || old.chart.length != chart.length;
}

// ─── FX overlay painter ───────────────────────────────────────────────────────
// Reads the live particle/pop lists and repaints off the controller (60 fps),
// so bursts stay smooth without forcing widget rebuilds.
class _MtFxPainter extends CustomPainter {
  final List<FxParticle> particles;
  final List<_MtPop>     pops;
  _MtFxPainter(this.particles, this.pops, Listenable repaint)
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, particles);
    for (final p in pops) p.paint(canvas);
  }

  @override
  bool shouldRepaint(covariant _MtFxPainter old) => false;
}

// ─── Cooldown ring painter ────────────────────────────────────────────────────
class _MtCooldownRingPainter extends CustomPainter {
  final double progress;
  final Color  color;
  _MtCooldownRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progress * 2 * pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MtCooldownRingPainter old) =>
      old.progress != progress;
}
