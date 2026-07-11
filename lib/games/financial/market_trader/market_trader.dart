import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
// Every event is a PURCHASE: this flat price is deducted from AVAILABLE cash
// and booked as a realized expense against P&L (exactly like the cancel fee).
const double _kMtEventCost      = 60.0;

// --- Hustle (comeback) tuning -------------------------------------------------
// Each pound of the HUSTLE button earns this much FREE CASH. Labor income: it
// builds a stake but NEVER touches realized P&L — only trading moves the score.
// No cooldown, no throttle: every tap pays. The floor, not a strategy.
const double _kMtHustlePerTap = 1.0;
// Cap on simultaneous floating "+$1" pops so tap-spam can't flood the FX
// canvas. The VISUALS are capped; the earnings never are.
const int _kMtMaxHustlePops = 12;

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
  const FinancialTradingGame({super.key, required this.session});
  @override
  State<FinancialTradingGame> createState() => _FinancialTradingGameState();
}

class _FinancialTradingGameState extends State<FinancialTradingGame>
    with TickerProviderStateMixin {
  // Repaint driver for the smooth painters (background atmosphere + FX) — NOT
  // the sim clock. The painters listen to it and read its lastElapsedDuration.
  late AnimationController _ctrl;
  // Press-squash feedback for the HUSTLE button. Its own tiny controller so a
  // tap-spam animates the button WITHOUT forcing full-tree rebuilds — the
  // AnimatedBuilder wraps only the button, with the static subtree hoisted.
  late AnimationController _hustlePress;
  // The sim clock: a Ticker delivering real wall-clock elapsed time.
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
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
  // Effectively locked out of the market: free cash can't afford even the
  // CHEAPEST possible action (1 share resting at the deepest limit discount),
  // nothing held, nothing resting. Open orders block bust — reserved cash is
  // still working capital (it will fill into shares or is cancellable), so this
  // can't false-positive while an order is on the book.
  bool   get _isBusted =>
      !_inPosition &&
      _orders.isEmpty &&
      _available < _price * (1.0 - _kMtLimitOffsetMax);

  @override
  void initState() {
    super.initState();
    _eventCooldowns = List.filled(_kMtEvents.length, 0.0);
    _chart.add(_MtPriceSample(_price));
    // _ctrl only repaints the painters; the sim advances on _ticker below.
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(hours: 1))
      ..forward();
    _hustlePress = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this desk knows how to trade itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _hustlePress.dispose();
    _ctrl.dispose();
    _chartRev.dispose();
    super.dispose();
  }

  // ─── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One competent, deterministic move per host tick (~250ms). Plays the desk
  /// the way it's meant to be played — buy low, sell high — off the game's OWN
  /// fields (price, position, cash, chart), never randomness or synthetic taps:
  ///   • Holding at a worthwhile profit over the average cost → MARKET SELL all,
  ///     realizing the gain into the score.
  ///   • Otherwise, when the live price sits at/below the short recent average
  ///     (a relatively "low" entry) and there's free cash → MARKET BUY a lot
  ///     sized to a slice of that cash.
  ///   • Nothing attractive → hold.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // Busted — no cash for even the cheapest entry, nothing held, nothing
    // resting. Do what a player would: pound HUSTLE a few times to rebuild a
    // stake, then get back to trading. (Rare in practice — the bot only ever
    // deploys a slice of its cash — but the comeback must work hands-free too.)
    if (_isBusted) {
      for (int i = 0; i < 4; i++) {
        _hustle();
      }
      return;
    }

    // Sell the held position once it clears the average cost by a small margin.
    if (_inPosition) {
      const profitMargin = 0.006; // ~0.6% over basis is worth banking
      if (_price > _avgCost * (1 + profitMargin)) {
        _sellAll();
        return;
      }
    }

    // Otherwise accumulate when price is low relative to the recent average.
    final recentAvg = _recentAvgPrice();
    if (_price <= recentAvg && _available > _price) {
      // Deploy roughly a third of free cash per entry, at least one share.
      final lot = max(1, (_available / max(_price, 0.01) / 3).floor());
      if (_lotSize != lot) _setLot(lot);
      if (_canMarketBuy) _marketBuy();
      return;
    }
    // else hold — no worthwhile move this tick.
  }

  /// Short recent average price from the chart history — the autopilot's "low"
  /// reference for deciding whether the current price is a good entry.
  double _recentAvgPrice() {
    if (_chart.isEmpty) return _price;
    final n = min(_chart.length, 20);
    double sum = 0;
    for (int i = _chart.length - n; i < _chart.length; i++) {
      sum += _chart[i].price;
    }
    return sum / n;
  }

  // ─── Main loop (host owns the clock) ──────────────────────────────────────
  // The sim advances every frame; painters animate off Listenables. We only
  // rebuild the widget tree at _kMtRenderHz, or immediately when a discrete
  // event (order fill, news, cooldown ready) changes what the controls show.
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the sim must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) return;
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

  // ─── HUSTLE (the comeback) ────────────────────────────────────────────────
  /// One pound of the HUSTLE button: +$1 of FREE CASH. Labor income — it flows
  /// into [_available] (spendable on market buys AND order reserves) and NEVER
  /// into [_realized], so tapping alone can never move the session score. No
  /// cooldown, no throttle: each tap pays, that IS the hustle.
  ///
  /// Deliberately no setState here: the AVAILABLE readout refreshes on the
  /// 20 Hz render tick, the "+$1" pop lives on the FX canvas, and the press
  /// squash runs on [_hustlePress] — so tap-spam can't force full-tree
  /// rebuilds past the throttle.
  void _hustle() {
    if (!widget.session.isRunning) return;
    _available += _kMtHustlePerTap;
    _hustlePress.forward(from: 0);
    // Visual pop, capped — earnings are never capped.
    if (_pops.length < _kMtMaxHustlePops) {
      final x = 44.0 + (_rng.nextDouble() * 28 - 14);
      final y = _screen == Size.zero ? 400.0 : _screen.height - 104.0;
      _pops.add(_MtPop(Offset(x, y), '+\$1', Potatuhs.gold));
    }
  }

  // ─── Player market events ─────────────────────────────────────────────────
  void _triggerEvent(int idx) {
    if (!widget.session.isRunning) return;
    if (_eventCooldowns[idx] > 0) return;
    if (_available < _kMtEventCost - 1e-6) return; // events are a PURCHASE
    setState(() {
      final ev = _kMtEvents[idx];
      final impulse = ev.sign * _kMtEventImpulse;
      // Pay for the event: cash out of AVAILABLE, and the cost is a realized
      // expense against P&L — same accounting as the cancel fee.
      _available -= _kMtEventCost;
      _realized  -= _kMtEventCost;
      _syncScore();
      _news       = _MtNews(ev.label.toUpperCase(), impulse, _kMtEventDuration);
      _newsTimer  = _kMtEventDuration;
      _trend      = ev.sign * 0.95;
      _trendTimer = _kMtEventDuration;
      _eventCooldowns[idx] = _kMtEventCooldown;
      _popLabel('-\$${_kMtEventCost.toStringAsFixed(0)}',
          const Color(0xFFEF5350), yFrac: 0.40);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            style: Potatuhs.label(size: 10, color: Potatuhs.textFaint),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: Potatuhs.body(
                  size: 19, weight: FontWeight.w800, color: color),
              maxLines: 1),
        ),
      ]),
    );
  }

  Widget _walletDivider() => Container(
        width: 1,
        height: 34,
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: (up
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF7F0000))
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${up ? "▲" : "▼"} ${delta.abs().toStringAsFixed(2)}',
              style: Potatuhs.label(
                  size: 13,
                  color: up
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350)),
            ),
          ),
          const Spacer(),
          if (_inPosition)
            Text(
              'avg \$${_avgCost.toStringAsFixed(2)}',
              style: Potatuhs.label(size: 12, color: Potatuhs.textSecondary),
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
        const Text('\u{1F4F0}', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(news.headline,
              style: Potatuhs.body(
                  size: 13, weight: FontWeight.w700, color: Potatuhs.gold)),
        ),
        Text(
          news.impulse > 0 ? '▲ SPIKE' : '▼ CRASH',
          style: Potatuhs.label(
              size: 12,
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
      // Busted (can't afford the cheapest action, nothing resting): swap the
      // idle hint for the comeback line. One line, no modal, no interruption.
      final busted = _isBusted;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        child: Text(
          busted
              ? 'Hustle back in — \$1 a tap'
              : 'No shares held — set a size, then BUY or place a LIMIT order',
          style: Potatuhs.label(
              size: 12,
              color: busted ? Potatuhs.gold : Potatuhs.textFaint),
          textAlign: TextAlign.center,
        ),
      );
    }
    final upnl = _unrealizedPnl;
    final col  = upnl >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: Potatuhs.surface(
        fill: col.withValues(alpha: 0.18),
        borderColor: col.withValues(alpha: 0.5),
        radius: 10,
      ),
      child: Row(children: [
        Text('${_heldShares.toStringAsFixed(0)} sh @ \$${_avgCost.toStringAsFixed(2)}',
            style: Potatuhs.label(size: 13, color: Potatuhs.textSecondary)),
        const Spacer(),
        Text('val \$${_positionValue.toStringAsFixed(0)}',
            style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
        const SizedBox(width: 12),
        Text(
          'unreal ${upnl >= 0 ? "+" : "-"}\$${upnl.abs().toStringAsFixed(0)}',
          style: Potatuhs.body(size: 15, weight: FontWeight.w700, color: col),
        ),
      ]),
    );
  }

  // ─── SIZE control (the batch knob) ────────────────────────────────────────
  Widget _buildSizeControl() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.7),
        borderColor: Potatuhs.gold.withValues(alpha: 0.3),
        radius: 12,
      ),
      child: Column(children: [
        Row(children: [
          Text('SIZE',
              style: Potatuhs.label(size: 12, color: Potatuhs.gold)),
          const SizedBox(width: 8),
          _stepperBtn('−', () => _bumpLot(-1)),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$_lotSize sh',
                    style: Potatuhs.body(
                        size: 24,
                        weight: FontWeight.w800,
                        color: Potatuhs.textPrimary)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _stepperBtn('+', () => _bumpLot(1)),
        ]),
        const SizedBox(height: 8),
        // Lot presets on their own row so each stays a comfortable touch target.
        Row(children: [
          ..._kMtLotPresets.map((p) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _presetBtn('$p', () => _setLot(p), _lotSize == p),
                ),
              )),
          Expanded(child: _presetBtn('MAX', _maxLot, false, wide: true)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('LIMIT', style: Potatuhs.label(size: 11, color: Potatuhs.airForce)),
          const SizedBox(width: 6),
          Text(
            _limitOffset <= 0.001
                ? 'at market \$${_price.toStringAsFixed(2)}'
                : '\$${_limitPrice.toStringAsFixed(2)}  (${(_limitOffset * _kMtLimitOffsetMax * 100).toStringAsFixed(0)}% below)',
            style: Potatuhs.label(size: 11, color: Potatuhs.textSecondary),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 20),
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
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(label,
            style: Potatuhs.body(
                size: 24,
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
        constraints: BoxConstraints(minWidth: wide ? 48 : 40),
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        child: Text(label,
            style: Potatuhs.label(
                size: 13,
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
              height: 54,
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
                          size: 13,
                          color: placeReady
                              ? Potatuhs.airForce
                              : Potatuhs.textFaint)),
                  const SizedBox(height: 2),
                  Text(
                    'reserve \$${_orderCost.toStringAsFixed(0)}  ·  $_lotSize @ \$${_limitPrice.toStringAsFixed(2)}',
                    style: Potatuhs.label(size: 10, color: Potatuhs.textFaint),
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
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        size: 12,
                        color: _orders.isNotEmpty
                            ? const Color(0xFFEF5350)
                            : Potatuhs.textFaint)),
                const SizedBox(height: 2),
                Text('${(_kMtCancelFeeRate * 100).toStringAsFixed(0)}% fee',
                    style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
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
        spacing: 7,
        runSpacing: 6,
        children: List.generate(_orders.length, (i) {
          final o = _orders[i];
          return GestureDetector(
            onTap: () => _cancelOrder(i),
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Potatuhs.sienna.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
                border:
                    Border.all(color: Potatuhs.sienna.withValues(alpha: 0.55)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${o.shares} @ \$${o.limit.toStringAsFixed(2)}',
                    style: Potatuhs.label(size: 12, color: Potatuhs.sienna)),
                const SizedBox(width: 7),
                Icon(Icons.close,
                    size: 15, color: const Color(0xFFEF5350).withValues(alpha: 0.9)),
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
          final onCd     = cd > 0;
          final progress = onCd ? 1.0 - (cd / _kMtEventCooldown) : 1.0;
          // Events are a purchase: unaffordable renders exactly like
          // cooldown-disabled and taps do nothing.
          final ready    = !onCd && _available >= _kMtEventCost - 1e-6;
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
                    height: 52,
                    decoration: BoxDecoration(
                      color: ready
                          ? accentCol.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(11),
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
                              fontSize: 17,
                              color: ready
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            )),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              '${ev.label} · \$${_kMtEventCost.toStringAsFixed(0)}',
                              style: Potatuhs.label(
                                size: 9,
                                color: ready
                                    ? accentCol
                                    : Potatuhs.textFaint.withValues(alpha: 0.4),
                              )),
                        ),
                      ],
                    ),
                  ),
                  if (onCd)
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CustomPaint(
                        painter: _MtCooldownRingPainter(progress, accentCol),
                      ),
                    ),
                  if (onCd)
                    Positioned(
                      bottom: 3,
                      right: 4,
                      child: Text('${cd.ceil()}',
                          style: Potatuhs.label(
                              size: 9,
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

  // ─── HUSTLE / BUY (market) / SELL row ─────────────────────────────────────
  Widget _buildTradeButtons() {
    final buyReady  = _canMarketBuy && widget.session.isRunning;
    final sellReady = _inPosition && widget.session.isRunning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        _buildHustleButton(),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: sellReady ? _sellAll : null,
          child: Container(
            height: 64,
            width: 62,
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
                    size: 13,
                    color: sellReady
                        ? const Color(0xFFEF5350)
                        : Potatuhs.textFaint)),
          ),
        ),
      ]),
    );
  }

  // ─── HUSTLE button (the comeback) ─────────────────────────────────────────
  // Rapid-fire friendly: a Listener firing on pointer-DOWN, so every pound of
  // the thumb (any finger, any cadence) pays $1 — no tap-up gesture arena, no
  // cooldown. When the player is busted (see [_isBusted]) the button gets a
  // gentle attention pulse; the glow alpha is computed from the sim clock and
  // picked up by the 20 Hz refresh — plenty smooth for a slow pulse, and no
  // extra per-frame widget animation.
  Widget _buildHustleButton() {
    final busted = _isBusted;
    final t = _lastElapsed.inMicroseconds / 1e6;
    final pulse = busted ? 0.5 + 0.5 * sin(t * 2 * pi / 1.4) : 0.0;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _hustle(),
      child: AnimatedBuilder(
        animation: _hustlePress,
        builder: (context, child) {
          final squash = 1.0 - 0.10 * sin(_hustlePress.value * pi);
          return Transform.scale(scale: squash, child: child);
        },
        child: Container(
          height: 64,
          width: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Potatuhs.sienna.withValues(alpha: 0.55),
                Potatuhs.gold.withValues(alpha: 0.30 + 0.15 * pulse),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Potatuhs.gold.withValues(alpha: 0.65 + 0.35 * pulse),
              width: 1.5,
            ),
            boxShadow: busted
                ? [
                    BoxShadow(
                      color: Potatuhs.gold.withValues(alpha: 0.2 + 0.3 * pulse),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('HUSTLE',
                  style: Potatuhs.label(size: 11, color: Potatuhs.gold)),
              Text('+\$1',
                  style: Potatuhs.display(size: 17, color: Potatuhs.gold)),
            ],
          ),
        ),
      ),
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
        height: 64,
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
            // Scale-down (never ellipsize) so the lot count always reads even
            // on narrow screens now that HUSTLE shares the row.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(top,
                    style: Potatuhs.display(
                        size: 21,
                        color: enabled ? accent : Potatuhs.textFaint)),
              ),
            ),
            const SizedBox(height: 2),
            Text(sub,
                style: Potatuhs.label(
                    size: 10,
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
    for (final p in pops) {
      p.paint(canvas);
    }
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

// ═══════════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame draws the LITERAL desk
// components (the chart, the BUY/SELL buttons, the SIZE control, the limit line,
// the order chips) in the exact styles the live game uses.
// ═══════════════════════════════════════════════════════════════════════════════

// The desk's trading palette (same values used throughout the live UI above).
const Color _kMtUp       = Color(0xFF66BB6A);
const Color _kMtUpDeep   = Color(0xFF1B5E20);
const Color _kMtUpMid    = Color(0xFF388E3C);
const Color _kMtDown     = Color(0xFFEF5350);
const Color _kMtDownDeep = Color(0xFF7F0000);
const Color _kMtDownMid  = Color(0xFFC62828);

/// Width-constrained centered text for the legend cards. The shared
/// [GameFx.text] lays out at natural width with no cap, so packed desk lingo
/// ("RESERVED \$460", "market \$520", the order chip) could crowd on the narrow
/// embeds the cell runs in. This shrinks the font toward [minSize] until the
/// line fits [maxWidth]. Local by design — the shared kit stays unconstrained.
void _mtFit(Canvas canvas, String s, Offset center, double size, Color color,
    double maxWidth,
    {bool display = false,
    FontWeight weight = FontWeight.w800,
    double glow = 0,
    double minSize = 5}) {
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

bool _mtLegendBad(Size size) =>
    size.width <= 0 ||
    size.height <= 0 ||
    !size.width.isFinite ||
    !size.height.isFinite;

// Price tapes (fractional x/y inside the chart rect; y 0 = top = high price).
const List<Offset> _kMtTapeUp = [
  Offset(0.00, 0.60), Offset(0.08, 0.50), Offset(0.16, 0.64),
  Offset(0.24, 0.44), Offset(0.34, 0.54), Offset(0.44, 0.36),
  Offset(0.52, 0.48), Offset(0.62, 0.30), Offset(0.72, 0.44),
  Offset(0.82, 0.26), Offset(0.92, 0.36), Offset(1.00, 0.22),
];
const List<Offset> _kMtTapeValleyPeak = [
  Offset(0.00, 0.42), Offset(0.10, 0.52), Offset(0.20, 0.62),
  Offset(0.28, 0.70), Offset(0.34, 0.76), Offset(0.42, 0.66),
  Offset(0.50, 0.52), Offset(0.58, 0.40), Offset(0.66, 0.28),
  Offset(0.74, 0.20), Offset(0.82, 0.28), Offset(0.92, 0.24),
  Offset(1.00, 0.32),
];
const List<Offset> _kMtTapeDip = [
  Offset(0.00, 0.30), Offset(0.10, 0.38), Offset(0.20, 0.32),
  Offset(0.30, 0.44), Offset(0.40, 0.38), Offset(0.50, 0.52),
  Offset(0.60, 0.46), Offset(0.70, 0.58), Offset(0.80, 0.66),
  Offset(0.90, 0.60), Offset(1.00, 0.70),
];

/// Draws one chart card exactly the way [_MtChartPainter] renders the live
/// chart: ink gradient panel, grid, dashed baseline, sienna dashed limit line,
/// gradient fill under the price line, glow stroke + core stroke, glowing tip.
void _mtLegendChart(Canvas canvas, Rect r, List<Offset> pts, Color lineColor,
    {double? baselineFrac, double? limitFrac}) {
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Potatuhs.inkPanel.withValues(alpha: 0.95),
          Potatuhs.inkDeep.withValues(alpha: 0.98),
        ],
      ).createShader(r),
  );
  canvas.save();
  canvas.clipRRect(rrect);

  final gridPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.06)
    ..strokeWidth = 0.5;
  for (int i = 1; i <= 4; i++) {
    final y = r.top + r.height * i / 5;
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), gridPaint);
  }

  if (baselineFrac != null) {
    final y = r.top + r.height * baselineFrac;
    final dash = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (double x = r.left; x < r.right; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
    }
  }

  if (limitFrac != null) {
    final y = r.top + r.height * limitFrac;
    final lim = Paint()
      ..color = Potatuhs.sienna.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    for (double x = r.left; x < r.right; x += 12) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), lim);
    }
  }

  Offset pt(Offset f) =>
      Offset(r.left + f.dx * r.width, r.top + f.dy * r.height);

  final linePath = Path();
  for (int i = 0; i < pts.length; i++) {
    final p = pt(pts[i]);
    i == 0 ? linePath.moveTo(p.dx, p.dy) : linePath.lineTo(p.dx, p.dy);
  }

  final fillPath = Path.from(linePath)
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.left, r.bottom)
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
      ).createShader(r),
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

  final tip = pt(pts.last);
  canvas.drawCircle(
    tip, 7,
    Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawCircle(tip, 3.5, Paint()..color = lineColor);
  canvas.restore();
}

/// One big trade button, drawn like [_bigBtn]: diagonal gradient, accent border
/// + soft glow, display-face top label and a small sub-label.
void _mtLegendBtn(Canvas canvas, Rect r, String top, String sub, Color colorA,
    Color colorB, Color accent) {
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
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
  _mtFit(canvas, top, Offset(r.center.dx, r.center.dy - r.height * 0.14),
      r.height * 0.30, accent, r.width - 12,
      display: true);
  _mtFit(canvas, sub, Offset(r.center.dx, r.center.dy + r.height * 0.26),
      r.height * 0.15, Colors.white.withValues(alpha: 0.8), r.width - 12);
}

/// A small pill button in the SIZE-control style ([_presetBtn] / [_stepperBtn]).
void _mtLegendPill(Canvas canvas, Rect r, String label, bool active,
    {double fontSize = 10}) {
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = active
          ? Potatuhs.gold.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.06),
  );
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = active
          ? Potatuhs.gold.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.14),
  );
  _mtFit(canvas, label, r.center, fontSize,
      active ? Potatuhs.gold : Potatuhs.textSecondary, r.width - 4);
}

/// One open-order chip, drawn like [_buildOpenOrders]: sienna pill + cancel ✕.
void _mtLegendOrderChip(Canvas canvas, Rect r, String label) {
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
  canvas.drawRRect(
      rrect, Paint()..color = Potatuhs.sienna.withValues(alpha: 0.18));
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Potatuhs.sienna.withValues(alpha: 0.55),
  );
  // Label fills the pill left of the cancel ✕; fit it so a long "5 @ \$92.00"
  // never runs under the ✕ mark.
  final xZone = r.height * 0.9; // space the ✕ reserves on the right
  _mtFit(canvas, label, Offset(r.left + (r.width - xZone) / 2, r.center.dy),
      r.height * 0.38, Potatuhs.sienna, r.width - xZone - 6);
  final xc = Offset(r.right - r.height * 0.42, r.center.dy);
  final xr = r.height * 0.14;
  final xPaint = Paint()
    ..color = _kMtDown.withValues(alpha: 0.9)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(xc.translate(-xr, -xr), xc.translate(xr, xr), xPaint);
  canvas.drawLine(xc.translate(xr, -xr), xc.translate(-xr, xr), xPaint);
}

/// A trade marker on the tape: glowing dot + BUY/SELL tag, like the fill pops.
void _mtLegendMarker(Canvas canvas, Offset p, String label, Color color,
    {required bool labelBelow}) {
  canvas.drawCircle(
    p, 9,
    Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawCircle(p, 4, Paint()..color = color);
  GameFx.text(canvas, label, p.translate(0, labelBelow ? 15 : -15), 11, color,
      weight: FontWeight.w800, glow: 0.6);
}

// ── Frame 1: the desk — the live price tape and the market BUY/SELL verbs ────
void _legendDesk(Canvas canvas, Size size) {
  if (_mtLegendBad(size)) return;
  final w = size.width, h = size.height;
  _mtLegendChart(
    canvas,
    Rect.fromLTWH(w * 0.07, h * 0.06, w * 0.86, h * 0.46),
    _kMtTapeUp,
    _kMtUp,
    baselineFrac: 0.58,
  );
  _mtFit(canvas, '\$104.20 ▲', Offset(w * 0.5, h * 0.60), h * 0.055, _kMtUp,
      w * 0.6,
      glow: 0.5);
  final btnW = w * 0.38, btnH = h * 0.20, by = h * 0.70;
  _mtLegendBtn(canvas, Rect.fromLTWH(w * 0.09, by, btnW, btnH), 'BUY 5',
      'market', _kMtUpDeep, _kMtUpMid, _kMtUp);
  _mtLegendBtn(canvas, Rect.fromLTWH(w * 0.53, by, btnW, btnH), 'SELL 5',
      'realize', _kMtDownDeep, _kMtDownMid, _kMtDown);
}

// ── Frame 2: the SIZE control — the batch knob every action obeys ────────────
void _legendSize(Canvas canvas, Size size) {
  if (_mtLegendBad(size)) return;
  final w = size.width, h = size.height;

  // The gold SIZE panel, drawn like _buildSizeControl.
  final panel = Rect.fromLTWH(w * 0.07, h * 0.10, w * 0.86, h * 0.42);
  final prr = RRect.fromRectAndRadius(panel, const Radius.circular(12));
  canvas.drawRRect(
      prr, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.7));
  canvas.drawRRect(
    prr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Potatuhs.gold.withValues(alpha: 0.4),
  );
  GameFx.text(canvas, 'SIZE', Offset(panel.left + w * 0.09, panel.top + h * 0.07),
      h * 0.038, Potatuhs.gold,
      weight: FontWeight.w800);

  // Stepper − / count / + row.
  final rowY = panel.top + panel.height * 0.36;
  final btn = h * 0.115;
  _mtLegendPill(
      canvas,
      Rect.fromCenter(
          center: Offset(w * 0.28, rowY), width: btn, height: btn),
      '−',
      false,
      fontSize: btn * 0.55);
  GameFx.text(canvas, '5 sh', Offset(w * 0.5, rowY), h * 0.075,
      Potatuhs.textPrimary,
      weight: FontWeight.w800);
  _mtLegendPill(
      canvas,
      Rect.fromCenter(
          center: Offset(w * 0.72, rowY), width: btn, height: btn),
      '+',
      false,
      fontSize: btn * 0.55);

  // Lot presets 1 / 5 / 25 / MAX (5 active).
  const labels = ['1', '5', '25', 'MAX'];
  final chipY = panel.bottom - panel.height * 0.24;
  final chipW = panel.width * 0.19;
  for (int i = 0; i < 4; i++) {
    final cx = panel.left + panel.width * (0.14 + i * 0.24);
    _mtLegendPill(
        canvas,
        Rect.fromCenter(
            center: Offset(cx, chipY), width: chipW, height: h * 0.09),
        labels[i],
        i == 1,
        fontSize: h * 0.038);
  }

  // The lot flows into the trade button label.
  final arrow = Paint()
    ..color = Potatuhs.gold
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final ax = w * 0.5, ay = h * 0.60;
  canvas.drawLine(Offset(ax, h * 0.555), Offset(ax, ay), arrow);
  canvas.drawLine(Offset(ax - 7, ay - 6), Offset(ax, ay + 2), arrow);
  canvas.drawLine(Offset(ax + 7, ay - 6), Offset(ax, ay + 2), arrow);
  _mtLegendBtn(
      canvas,
      Rect.fromLTWH(w * 0.28, h * 0.68, w * 0.44, h * 0.20),
      'BUY 5',
      'market \$520',
      _kMtUpDeep,
      _kMtUpMid,
      _kMtUp);
}

// ── Frame 3: scoring — buy the valley, sell the peak, bank realized P&L ──────
void _legendPnl(Canvas canvas, Size size) {
  if (_mtLegendBad(size)) return;
  final w = size.width, h = size.height;
  final chart = Rect.fromLTWH(w * 0.07, h * 0.14, w * 0.86, h * 0.56);
  _mtLegendChart(canvas, chart, _kMtTapeValleyPeak, _kMtUp,
      baselineFrac: 0.42);
  Offset pt(double fx, double fy) =>
      Offset(chart.left + fx * chart.width, chart.top + fy * chart.height);
  _mtLegendMarker(canvas, pt(0.34, 0.76), 'BUY', _kMtUp, labelBelow: true);
  _mtLegendMarker(canvas, pt(0.74, 0.20), 'SELL', _kMtDown, labelBelow: false);
  // The realized-gain pop, exactly like a sell's _MtPop.
  GameFx.text(canvas, '+\$120', Offset(w * 0.5, h * 0.85), h * 0.09,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.8);
}

// ── Frame 4: limit orders + the risk of holding at the buzzer ────────────────
void _legendLimit(Canvas canvas, Size size) {
  if (_mtLegendBad(size)) return;
  final w = size.width, h = size.height;
  final chart = Rect.fromLTWH(w * 0.07, h * 0.06, w * 0.86, h * 0.46);
  _mtLegendChart(canvas, chart, _kMtTapeDip, _kMtDown, limitFrac: 0.78);
  _mtFit(
      canvas,
      'LIMIT \$92',
      Offset(chart.left + chart.width * 0.16,
          chart.top + chart.height * 0.78 - 10),
      h * 0.036,
      Potatuhs.sienna,
      chart.width * 0.32);

  // The resting order chip + the cash it reserves.
  final chipRect = Rect.fromLTWH(w * 0.09, h * 0.58, w * 0.44, h * 0.105);
  _mtLegendOrderChip(canvas, chipRect, '5 @ \$92.00');
  // "RESERVED $460" fills the column right of the chip, fit so it can't back
  // over the chip on a narrow card.
  final resLeft = chipRect.right + 8;
  final resW = (w - 8) - resLeft;
  _mtFit(canvas, 'RESERVED \$460', Offset(resLeft + resW / 2, h * 0.633),
      h * 0.038, Potatuhs.sienna, resW);

  // The buzzer risk: unsold shares bank nothing — SELL ALL before 0:00. Fit the
  // clock into the column left of the button so the two never touch.
  _mtFit(canvas, '0:07', Offset(w * 0.20, h * 0.815), h * 0.075, _kMtDown,
      w * 0.34,
      glow: 0.6);
  _mtLegendBtn(
      canvas,
      Rect.fromLTWH(w * 0.42, h * 0.735, w * 0.44, h * 0.17),
      'SELL ALL',
      'bank it in time',
      _kMtDownDeep,
      _kMtDownMid,
      _kMtDown);
}

// ── Frame 5: the comeback — HUSTLE taps rebuild a stake; trades make score ───
void _legendHustle(Canvas canvas, Size size) {
  if (_mtLegendBad(size)) return;
  final w = size.width, h = size.height;
  // The bust state: an empty wallet.
  _mtFit(canvas, 'AVAILABLE \$0', Offset(w * 0.5, h * 0.10), h * 0.055, _kMtDown,
      w * 0.7,
      glow: 0.5);
  // The gold HUSTLE button, drawn like the live one.
  _mtLegendBtn(
      canvas,
      Rect.fromLTWH(w * 0.30, h * 0.34, w * 0.40, h * 0.22),
      'HUSTLE',
      '+\$1 a tap',
      Potatuhs.sienna,
      Potatuhs.copper,
      Potatuhs.gold);
  // The "+$1" pops streaming up under rapid taps.
  GameFx.text(canvas, '+\$1', Offset(w * 0.24, h * 0.30), h * 0.05,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.7);
  GameFx.text(canvas, '+\$1', Offset(w * 0.76, h * 0.24), h * 0.05,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.7);
  GameFx.text(canvas, '+\$1', Offset(w * 0.62, h * 0.16), h * 0.05,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.7);
  // Labor buys the stake; the market is where it compounds.
  _mtFit(canvas, 'taps buy a stake', Offset(w * 0.5, h * 0.68), h * 0.045,
      Potatuhs.textSecondary, w * 0.86,
      weight: FontWeight.w700);
  _mtFit(canvas, 'only TRADES score', Offset(w * 0.5, h * 0.80), h * 0.055,
      _kMtUp, w * 0.86,
      glow: 0.5);
}

/// The visual manual for Market Trader — wired into the registry spec.
final List<LegendFrame> marketTraderLegendFrames = [
  const LegendFrame(
      caption: 'Watch the live price — BUY dips, SELL spikes',
      paint: _legendDesk),
  const LegendFrame(
      caption: 'Set SIZE — how many shares each tap trades',
      paint: _legendSize),
  const LegendFrame(
      caption: 'Buy low, sell high — banked P&L is your score',
      paint: _legendPnl),
  const LegendFrame(
      caption: 'Rest LIMIT BUYs below market — cash is reserved',
      paint: _legendLimit),
  const LegendFrame(
      caption: 'Busted? HUSTLE — \$1 a tap buys back in',
      paint: _legendHustle),
];
