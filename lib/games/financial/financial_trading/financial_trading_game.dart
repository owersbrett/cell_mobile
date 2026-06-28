import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Helper: shared particle class for visual juice
// ---------------------------------------------------------------------------
class _JuiceParticle {
  double x, y, vx, vy, life, maxLife, radius;
  Color color;
  _JuiceParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.radius = 3,
  }) : maxLife = life;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. FinancialTradingGame — "Market Trader"  (BioScale.financial)
// ═══════════════════════════════════════════════════════════════════════════════
//
// CORE LOOP: a live price moves rapidly every frame driven by shifting market
// conditions (trend + volatility + random news spikes).  Player watches the
// chart, taps BUY to enter a position at the current price, then taps SELL to
// realise the gain/loss.  Buy low, sell high.  ~60s escalating to frantic.
//
// Tuning constants — edit here to adjust feel without touching logic.
// -------------------------------------------------------------------------
const double _kMtStartingCash   = 200.0;  // opening wallet
const double _kMtGameDuration   = 60.0;   // seconds
const double _kMtBaseTickHz     = 12.0;   // price-update steps per second at start
const double _kMtMaxTickHz      = 30.0;   // price-update rate at t=60 (frantic)
const double _kMtBaseVolatility = 1.8;    // price step std-dev at t=0 (dollars)
const double _kMtMaxVolatility  = 9.0;    // price step std-dev at t=60
const double _kMtTrendDuration  = 4.0;    // seconds per market-trend segment
const double _kMtNewsDuration   = 1.5;    // how long a news spike lasts
const double _kMtNewsChance     = 0.08;   // probability per trend-flip of news event
const double _kMtNewsAmplitude  = 14.0;   // extra price impulse from news
const double _kMtStartingPrice  = 100.0;  // initial asset price

// --- Player market-event tuning ---
const double _kMtEventImpulse   = 22.0;   // impulse amplitude per tick while event active
const double _kMtEventDuration  = 2.5;    // seconds the price impulse is sustained
const double _kMtEventCooldown  = 14.0;   // per-button cooldown (must exceed duration)

// --- Debt / credit tuning ---
const double _kMtLoanSize       = 120.0;  // cash added per "Take Credit" tap
const double _kMtInterestRate   = 0.04;   // fraction of outstanding debt lost per second
const double _kMtMinPayment     = 30.0;   // "Minimum Payment" chunk size

// --- Market price sample (chart) ---
class _MtPriceSample {
  final double price;
  _MtPriceSample(this.price);
}

// --- Floating P&L pop ---
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

// --- News event ---
class _MtNews {
  final String headline;
  final double impulse; // signed price impulse per tick while active
  double ttl;           // seconds remaining
  _MtNews(this.headline, this.impulse, this.ttl);
}

// --- Player market-event button descriptor ---
class _MtEventDef {
  final String label;
  final String emoji;
  final double sign;    // +1 = price up, -1 = price down
  const _MtEventDef(this.label, this.emoji, this.sign);
}

const List<_MtEventDef> _kMtEvents = [
  // Price-UP (scarcity / supply shock)
  _MtEventDef('Drought',   '☀️',  1.0),
  _MtEventDef('Flooding',  '🌊',  1.0),
  _MtEventDef('Tornado',   '🌪️',  1.0),
  _MtEventDef('Quake',     '⚡',  1.0),
  // Price-DOWN (crash / glut)
  _MtEventDef('Recession', '📉', -1.0),
  _MtEventDef('Abundance', '🌾', -1.0),
];

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
  double _cash     = _kMtStartingCash;
  double _timeLeft = _kMtGameDuration;
  bool   _gameOver = false;
  double _elapsed  = 0.0;

  // --- Price / market ---
  double _price       = _kMtStartingPrice;
  double _trend       = 0.0;   // persistent drift direction (-1..+1)
  double _trendTimer  = 0.0;
  double _priceClock  = 0.0;   // accumulator for sub-frame price steps
  _MtNews? _news;
  double _newsTimer   = 0.0;

  // --- Player position ---
  bool   _inPosition   = false;
  double _entryPrice   = 0.0;
  double _shares       = 0.0;   // how many units bought (cash / entryPrice)

  // --- Chart history ---
  final List<_MtPriceSample> _chart = [];
  static const int _kChartMax = 200;

  // --- FX ---
  final List<FxParticle> _fxParticles = [];
  final List<_MtPop>     _pops        = [];
  final List<_JuiceParticle> _juiceParticles = [];

  // --- High scores ---
  List<Map<String, dynamic>> _highScores = [];
  double _bestScore    = 0.0;
  bool   _newHighScore = false;
  double _newHsTimer   = 0.0;

  // --- Player market events ---
  // Parallel array indexed by _kMtEvents position; 0 = ready, >0 = cooldown remaining
  late final List<double> _eventCooldowns;

  // --- Debt / credit ---
  double _debt = 0.0;  // total outstanding loan balance

  // --- Flash tint (green/red on trade close) ---
  Color  _flashColor = Colors.transparent;
  double _flashAlpha = 0.0;

  // --- Derived ---
  double get _volatility {
    final t = 1.0 - (_timeLeft / _kMtGameDuration);
    return _kMtBaseVolatility + (_kMtMaxVolatility - _kMtBaseVolatility) * t;
  }
  double get _tickHz {
    final t = 1.0 - (_timeLeft / _kMtGameDuration);
    return _kMtBaseTickHz + (_kMtMaxTickHz - _kMtBaseTickHz) * t;
  }
  double get _unrealizedPnl =>
      _inPosition ? (_price - _entryPrice) * _shares : 0.0;
  // Gross portfolio value (cash + open position) — used for display
  double get _totalNetWorth =>
      _cash + (_inPosition ? _price * _shares : 0.0);
  // Score = net worth minus any outstanding debt
  double get _finalScore => _totalNetWorth - _debt;

  @override
  void initState() {
    super.initState();
    _eventCooldowns = List.filled(_kMtEvents.length, 0.0);
    _chart.add(_MtPriceSample(_price));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _loadHighScores();
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('market_trader_hs_v2');
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      if (mounted) {
        setState(() {
          _highScores =
              decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (_highScores.isNotEmpty) {
            _bestScore = (_highScores.first['score'] as num).toDouble();
          }
        });
      }
    }
  }

  Future<void> _saveHighScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    _highScores.add({
      'score': score,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
    _highScores.sort(
        (a, b) => (b['score'] as num).compareTo(a['score'] as num));
    if (_highScores.length > 5) _highScores = _highScores.sublist(0, 5);
    await prefs.setString('market_trader_hs_v2', jsonEncode(_highScores));
    if (_highScores.isNotEmpty) {
      _bestScore = (_highScores.first['score'] as num).toDouble();
    }
  }

  void _checkAndSaveHighScore() {
    final score = _finalScore;
    final qualifies = _highScores.length < 5 ||
        score > (_highScores.last['score'] as num).toDouble();
    if (qualifies) {
      _newHighScore = true;
      _newHsTimer   = 3.0;
      _saveHighScore(score);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // --- Main game loop ---
  void _tick() {
    // The host owns the clock + countdown; only advance the simulation
    // while the session is in its playing phase.
    if (!widget.session.isRunning) return;
    const dt = 1 / 60.0;
    // Mirror the host clock so the volatility / tick-rate ramp (keyed off
    // _timeLeft) still tightens as the round runs down.
    _timeLeft = widget.session.remaining.inMilliseconds / 1000.0;
    setState(() {
      _elapsed  += dt;

      // Trend engine
      _trendTimer -= dt;
      if (_trendTimer <= 0) {
        _trend      = (_rng.nextDouble() * 2 - 1);
        _trendTimer = _kMtTrendDuration * (0.6 + _rng.nextDouble() * 0.8);
        if (_news == null && _rng.nextDouble() < _kMtNewsChance) {
          _spawnNews();
        }
      }

      // News countdown
      if (_news != null) {
        _newsTimer -= dt;
        if (_newsTimer <= 0) _news = null;
      }

      // Price steps (sub-frame accurate)
      _priceClock += dt * _tickHz;
      final steps = _priceClock.floor();
      _priceClock -= steps;
      for (int s = 0; s < steps; s++) {
        _stepPrice();
      }

      // Chart sample
      if (_chart.isEmpty ||
          _chart.length < (_elapsed * _kMtBaseTickHz / 3).round() + 1) {
        _chart.add(_MtPriceSample(_price));
        if (_chart.length > _kChartMax) _chart.removeAt(0);
      }

      // Debt interest accrual (bleeds cash each tick)
      if (_debt > 0) {
        final interest = _debt * _kMtInterestRate * dt;
        _debt += interest;
        _cash  = (_cash - interest).clamp(0.0, double.infinity);
      }

      // Event cooldown countdown
      for (int i = 0; i < _eventCooldowns.length; i++) {
        if (_eventCooldowns[i] > 0) {
          _eventCooldowns[i] = (_eventCooldowns[i] - dt).clamp(0.0, _kMtEventCooldown);
        }
      }

      // Flash decay
      if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 3).clamp(0, 1);

      // FX particles
      _fxParticles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
      for (final p in _juiceParticles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _juiceParticles.removeWhere((p) => p.life <= 0);

      if (_newHsTimer > 0) _newHsTimer -= dt;
    });
  }

  // --- Step the price by one tick ---
  void _stepPrice() {
    final vol   = _volatility;
    final drift = _trend * vol * 0.35;
    final noise = (_rng.nextDouble() * 2 - 1) * vol;
    double impulse = 0;
    if (_news != null) impulse = _news!.impulse * 0.5;
    _price = (_price + drift + noise + impulse).clamp(10.0, 9999.0);
  }

  // --- Spawn a news event ---
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

  // --- Trade actions ---
  void _buy(Size screenSize) {
    if (_gameOver || _inPosition) return;
    final investAmount = _cash * 0.8;
    if (investAmount < 1) return;
    setState(() {
      _entryPrice = _price;
      _shares     = investAmount / _price;
      _cash      -= investAmount;
      _inPosition = true;
      final center = Offset(screenSize.width / 2, screenSize.height * 0.55);
      _fxParticles.addAll(
          FxBurst.spawn(center, Potatuhs.airForce, count: 10, speed: 90));
    });
  }

  void _sell({bool silent = false, Size screenSize = Size.zero}) {
    if (!_inPosition) return;
    final proceeds  = _price * _shares;
    final pnl       = proceeds - _entryPrice * _shares;
    final pnlInt    = pnl.round();
    _cash          += proceeds;
    _inPosition     = false;
    _shares         = 0;
    _entryPrice     = 0;
    // Report realized P&L on this close to the host scoreboard. Session score
    // is the authoritative measure; clamps at 0 on net losses.
    widget.session.addScore(pnlInt);
    if (silent) return;
    final profit = pnl >= 0;
    final col    = profit ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    _flashColor  = col;
    _flashAlpha  = 0.28;
    // P&L pop: centre of screen, just above mid-height so it floats upward
    final popPos = screenSize == Size.zero
        ? const Offset(160, 260)
        : Offset(screenSize.width * 0.5, screenSize.height * 0.42);
    _pops.add(_MtPop(popPos, '${profit ? "+" : ""}\$${pnlInt.abs()}', col));
    if (profit && pnl > 5) {
      final burstOrigin = screenSize == Size.zero
          ? const Offset(180, 270)
          : Offset(screenSize.width * 0.5, screenSize.height * 0.44);
      _fxParticles.addAll(FxBurst.spawn(
        burstOrigin, Potatuhs.gold,
        count: pnl > 20 ? 22 : 14, speed: pnl > 20 ? 160 : 110,
      ));
    }
  }

  void _restart() {
    setState(() {
      _cash        = _kMtStartingCash;
      _timeLeft    = _kMtGameDuration;
      _gameOver    = false;
      _elapsed     = 0.0;
      _price       = _kMtStartingPrice;
      _trend       = 0.0;
      _trendTimer  = 0.0;
      _priceClock  = 0.0;
      _news        = null;
      _newsTimer   = 0.0;
      _inPosition  = false;
      _entryPrice  = 0.0;
      _shares      = 0.0;
      _debt        = 0.0;
      for (int i = 0; i < _eventCooldowns.length; i++) {
        _eventCooldowns[i] = 0.0;
      }
      _chart.clear();
      _chart.add(_MtPriceSample(_price));
      _fxParticles.clear();
      _pops.clear();
      _juiceParticles.clear();
      _flashAlpha  = 0.0;
      _newHighScore = false;
      _newHsTimer  = 0.0;
    });
  }

  // --- Player market event trigger ---
  void _triggerEvent(int idx) {
    if (_gameOver) return;
    if (_eventCooldowns[idx] > 0) return;
    setState(() {
      final ev = _kMtEvents[idx];
      final impulse = ev.sign * _kMtEventImpulse;
      _news      = _MtNews(ev.label.toUpperCase(), impulse, _kMtEventDuration);
      _newsTimer  = _kMtEventDuration;
      _trend      = ev.sign * 0.95;
      _trendTimer = _kMtEventDuration;
      _eventCooldowns[idx] = _kMtEventCooldown;
    });
  }

  // --- Debt / credit actions ---
  void _takeCredit() {
    if (_gameOver) return;
    setState(() {
      _cash += _kMtLoanSize;
      _debt += _kMtLoanSize;
    });
  }

  void _payDebt() {
    if (_gameOver || _debt <= 0) return;
    setState(() {
      final payment = min(_cash, _debt);
      _cash -= payment;
      _debt -= payment;
      if (_debt < 0.01) _debt = 0.0;
    });
  }

  void _minPayment() {
    if (_gameOver || _debt <= 0) return;
    setState(() {
      final payment = min(_cash, min(_kMtMinPayment, _debt));
      _cash -= payment;
      _debt -= payment;
      if (_debt < 0.01) _debt = 0.0;
    });
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final chartH = (h * 0.34).clamp(120.0, 220.0);
      final screenSize = Size(w, h);

      return Stack(children: [
        // Background
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MtBackgroundPainter(_elapsed, Potatuhs.airForce),
            ),
          ),
        ),

        // Flash tint on trade close
        if (_flashAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: _flashColor.withValues(alpha: _flashAlpha),
              ),
            ),
          ),

        // Main layout
        SafeArea(
          child: Column(children: [
            // Live price + trend chip
            _buildPriceTicker(),

            // News banner (when active)
            if (_news != null)
              _buildNewsBanner(_news!),

            // Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: SizedBox(
                height: chartH,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _MtChartPainter(
                        _chart, _kMtStartingPrice, _elapsed),
                  ),
                ),
              ),
            ),

            // Position status row
            _buildPositionRow(),

            const Spacer(),

            // Market events + debt controls (between BUY/SELL and position row)
            _buildEventButtons(),
            _buildDebtControls(),

            // BUY / SELL controls
            _buildTradeButtons(screenSize),

            const SizedBox(height: 10),
          ]),
        ),

        // FX overlays
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _MtFxPainter(_fxParticles, _pops, _juiceParticles),
            ),
          ),
        ),

      ]);
    });
  }

  // --- Widget helpers ---

  Widget _buildHud(double w, double pnl, bool timerRed) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.88),
        borderColor: Potatuhs.airForce.withValues(alpha: 0.35),
        radius: 14,
      ),
      child: Row(children: [
        Text(
          '${_timeLeft.ceil()}s',
          style: Potatuhs.body(
            size: 18,
            weight: FontWeight.w800,
            color: timerRed ? const Color(0xFFEF5350) : Potatuhs.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        if (_bestScore > 0)
          Text(
            'BEST \$${_bestScore.toStringAsFixed(0)}',
            style: Potatuhs.label(size: 9, color: Potatuhs.textFaint),
          ),
        const Spacer(),
        Text(
          '\$${_totalNetWorth.toStringAsFixed(0)}',
          style: Potatuhs.body(
              size: 20, weight: FontWeight.w800, color: Potatuhs.sienna),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (pnl >= 0
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFF7F0000))
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: pnl >= 0
                  ? const Color(0xFF66BB6A).withValues(alpha: 0.6)
                  : const Color(0xFFEF5350).withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            '${pnl >= 0 ? "+" : ""}\$${pnl.toStringAsFixed(0)}',
            style: Potatuhs.label(
              size: 11,
              color: pnl >= 0
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350),
            ),
          ),
        ),
      ]),
    );
  }

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
              size: 36,
              color: up ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            ).copyWith(
              shadows: [
                Shadow(
                  color: (up
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFEF5350))
                      .withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: (up
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF7F0000)).withValues(alpha: 0.7),
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
          if (_news != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Potatuhs.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Potatuhs.orange.withValues(alpha: 0.7)),
              ),
              child: Text('NEWS',
                  style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
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
          child: Text(
            news.headline,
            style: Potatuhs.body(
                size: 12,
                weight: FontWeight.w700,
                color: Potatuhs.gold),
          ),
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

  Widget _buildPositionRow() {
    if (!_inPosition) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Text(
          'No open position  —  tap BUY to enter',
          style: Potatuhs.label(size: 11, color: Potatuhs.textFaint),
          textAlign: TextAlign.center,
        ),
      );
    }
    final upnl = _unrealizedPnl;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: Potatuhs.surface(
        fill: (upnl >= 0
            ? const Color(0xFF1B5E20)
            : const Color(0xFF7F0000)).withValues(alpha: 0.35),
        borderColor: (upnl >= 0
            ? const Color(0xFF66BB6A)
            : const Color(0xFFEF5350)).withValues(alpha: 0.5),
        radius: 10,
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('OPEN  @  \$${_entryPrice.toStringAsFixed(2)}',
              style: Potatuhs.label(size: 10, color: Potatuhs.textSecondary)),
          const SizedBox(height: 2),
          Text(
            'Unrealized  ${upnl >= 0 ? "+" : ""}\$${upnl.toStringAsFixed(2)}',
            style: Potatuhs.body(
              size: 14,
              weight: FontWeight.w700,
              color: upnl >= 0
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350),
            ),
          ),
        ]),
        const Spacer(),
        Text(
          '\$${(_price * _shares).toStringAsFixed(0)} value',
          style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
        ),
      ]),
    );
  }

  Widget _buildTradeButtons(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(children: [
        // BUY
        Expanded(
          child: GestureDetector(
            onTap: _inPosition ? null : () => _buy(screenSize),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 62,
              decoration: BoxDecoration(
                gradient: _inPosition
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      ),
                color: _inPosition
                    ? Colors.white.withValues(alpha: 0.06)
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _inPosition
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF66BB6A).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: _inPosition
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  'BUY',
                  style: Potatuhs.display(
                    size: 22,
                    color: _inPosition
                        ? Potatuhs.textFaint
                        : const Color(0xFF66BB6A),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // SELL
        Expanded(
          child: GestureDetector(
            onTap: _inPosition
                ? () => setState(() => _sell(screenSize: screenSize))
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 62,
              decoration: BoxDecoration(
                gradient: _inPosition
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7F0000), Color(0xFFC62828)],
                      )
                    : null,
                color: _inPosition
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _inPosition
                      ? const Color(0xFFEF5350).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: _inPosition
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFEF5350).withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'SELL',
                  style: Potatuhs.display(
                    size: 22,
                    color: _inPosition
                        ? const Color(0xFFEF5350)
                        : Potatuhs.textFaint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // --- Market-event buttons (6 buttons with cooldown ring) ---
  Widget _buildEventButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Row(
        children: List.generate(_kMtEvents.length, (i) {
          final ev       = _kMtEvents[i];
          final cd       = _eventCooldowns[i];
          final ready    = cd <= 0;
          final progress = ready ? 1.0 : 1.0 - (cd / _kMtEventCooldown);
          final isUp     = ev.sign > 0;
          final accentCol = isUp
              ? const Color(0xFF66BB6A)
              : const Color(0xFFEF5350);
          return Expanded(
            child: GestureDetector(
              onTap: ready ? () => _triggerEvent(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Stack(alignment: Alignment.center, children: [
                  // Background chip
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 44,
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
                        Text(
                          ev.emoji,
                          style: TextStyle(
                            fontSize: 14,
                            color: ready
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        Text(
                          ev.label,
                          style: Potatuhs.label(
                            size: 7,
                            color: ready
                                ? accentCol
                                : Potatuhs.textFaint.withValues(alpha: 0.4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Cooldown arc overlay
                  if (!ready)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomPaint(
                        painter: _MtCooldownRingPainter(
                            progress, accentCol),
                      ),
                    ),
                  // Cooldown timer text
                  if (!ready)
                    Positioned(
                      bottom: 2,
                      right: 3,
                      child: Text(
                        '${cd.ceil()}',
                        style: Potatuhs.label(
                            size: 7,
                            color:
                                Colors.white.withValues(alpha: 0.55)),
                      ),
                    ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Debt / credit controls + readout ---
  Widget _buildDebtControls() {
    final hasDebt = _debt > 0.01;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasDebt
              ? const Color(0xFF7F0000).withValues(alpha: 0.22)
              : Potatuhs.inkPanel.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDebt
                ? const Color(0xFFEF5350).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Row(children: [
          // Debt readout
          if (hasDebt) ...[
            const Text('💳', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'DEBT  \$${_debt.toStringAsFixed(0)}',
                style: Potatuhs.label(
                    size: 9,
                    color: const Color(0xFFEF5350)),
              ),
              Text(
                '${(_kMtInterestRate * 100).toStringAsFixed(0)}%/s bleeding',
                style: Potatuhs.label(
                    size: 7,
                    color: Potatuhs.textFaint),
              ),
            ]),
            const SizedBox(width: 6),
          ] else ...[
            Text(
              'Credit available',
              style: Potatuhs.label(size: 9, color: Potatuhs.textFaint),
            ),
          ],
          const Spacer(),
          // Take Credit button
          _debtBtn(
            label: '+\$${_kMtLoanSize.toInt()} Credit',
            color: Potatuhs.airForce,
            onTap: _takeCredit,
          ),
          if (hasDebt) ...[
            const SizedBox(width: 6),
            _debtBtn(
              label: 'Min \$${_kMtMinPayment.toInt()}',
              color: const Color(0xFFEF9A00),
              onTap: _minPayment,
            ),
            const SizedBox(width: 6),
            _debtBtn(
              label: 'Pay All',
              color: const Color(0xFF66BB6A),
              onTap: _payDebt,
            ),
          ],
        ]),
      ),
    );
  }

  Widget _debtBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
        ),
        child: Text(label,
            style: Potatuhs.label(size: 9, color: color)),
      ),
    );
  }

  Widget _buildGameOver() {
    final score  = _finalScore;
    final won    = score >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: Potatuhs.surface(
          fill: Potatuhs.inkPanel.withValues(alpha: 0.95),
          borderColor: won
              ? const Color(0xFF66BB6A).withValues(alpha: 0.5)
              : const Color(0xFFEF5350).withValues(alpha: 0.5),
          radius: 18,
          glowColor: won ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
          glowStrength: 0.25,
        ),
        child: Column(children: [
          Text(
            won ? 'PROFITABLE CLOSE' : 'CLOSED IN THE RED',
            style: Potatuhs.display(
              size: 20,
              color: won ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: \$${score.toStringAsFixed(0)}  (${won ? "+" : ""}\$${(score - _kMtStartingCash).toStringAsFixed(0)})',
            style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
          ),
          if (_debt > 0.01)
            Text(
              'Debt penalty: −\$${_debt.toStringAsFixed(0)}',
              style: Potatuhs.label(
                  size: 11,
                  color: const Color(0xFFEF5350)),
            ),
          if (_highScores.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('TOP SCORES',
                style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
            const SizedBox(height: 4),
            ..._highScores.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Text(
                '${i + 1}.  \$${(s['score'] as num).toStringAsFixed(0)}  ${s['date']}',
                style: Potatuhs.body(size: 11, color: Potatuhs.textFaint),
              );
            }),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _restart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                gradient: Potatuhs.ctaGradient,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Potatuhs.ink, width: 2),
                boxShadow:
                    Potatuhs.glow(Potatuhs.orange, strength: 0.4, blur: 16),
              ),
              child: Text('PLAY AGAIN',
                  style: Potatuhs.display(size: 16, color: Potatuhs.ink)),
            ),
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

// --- Background painter ---
class _MtBackgroundPainter extends CustomPainter {
  final double t;
  final Color accent;
  _MtBackgroundPainter(this.t, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accent, t, motes: 28);
  }
  @override
  bool shouldRepaint(covariant _MtBackgroundPainter old) => true;
}

// --- Premium glowing line-area chart ---
class _MtChartPainter extends CustomPainter {
  final List<_MtPriceSample> chart;
  final double baseline;
  final double elapsed;
  _MtChartPainter(this.chart, this.baseline, this.elapsed);

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
    final pad = (maxP - minP) * 0.12 + 4;
    minP -= pad;
    maxP += pad;
    final range = maxP - minP;
    if (range <= 0) return;

    double px(int i) => (i / (chart.length - 1)) * size.width;
    double py(double price) =>
        size.height - ((price - minP) / range) * size.height;

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Baseline dashes
    final baseY = py(baseline);
    final dashPaint = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, baseY), Offset(x + 5, baseY), dashPaint);
    }

    // Build line path
    final linePath = Path();
    for (int i = 0; i < chart.length; i++) {
      final x = px(i);
      final y = py(chart[i].price);
      i == 0 ? linePath.moveTo(x, y) : linePath.lineTo(x, y);
    }

    final lastPrice = chart.last.price;
    final profiting  = lastPrice >= baseline;
    final lineColor  = profiting
        ? const Color(0xFF66BB6A)
        : const Color(0xFFEF5350);
    final glowColor  = lineColor;

    // Gradient fill (shaded area under chart)
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

    // Outer glow pass
    canvas.drawPath(
      linePath,
      Paint()
        ..color = glowColor.withValues(alpha: 0.3)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Bright core line
    canvas.drawPath(
      linePath,
      Paint()
        ..color      = lineColor
        ..strokeWidth = 2.2
        ..style      = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Glowing tip dot
    final tipX = px(chart.length - 1);
    final tipY = py(lastPrice);
    canvas.drawCircle(
      Offset(tipX, tipY), 7,
      Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(tipX, tipY), 3.5,
      Paint()..color = lineColor,
    );

    // Price labels on Y axis
    GameFx.text(
      canvas,
      '\$${maxP.toStringAsFixed(0)}',
      Offset(size.width - 22, 8),
      9,
      Potatuhs.textFaint.withValues(alpha: 0.7),
    );
    GameFx.text(
      canvas,
      '\$${minP.toStringAsFixed(0)}',
      Offset(size.width - 22, size.height - 8),
      9,
      Potatuhs.textFaint.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _MtChartPainter old) => true;
}

// --- FX overlay painter ---
class _MtFxPainter extends CustomPainter {
  final List<FxParticle>     particles;
  final List<_MtPop>         pops;
  final List<_JuiceParticle> juice;
  _MtFxPainter(this.particles, this.pops, this.juice);

  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, particles);
    for (final p in pops)  p.paint(canvas);
    for (final j in juice) {
      final a = (j.life / j.maxLife).clamp(0.0, 1.0) * 0.85;
      canvas.drawCircle(
        Offset(j.x, j.y), j.radius * (0.4 + 0.6 * (j.life / j.maxLife)),
        Paint()..color = j.color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MtFxPainter old) => true;
}


// --- Cooldown ring painter for market-event buttons ---
class _MtCooldownRingPainter extends CustomPainter {
  final double progress; // 0.0 = just triggered, 1.0 = ready
  final Color  color;
  _MtCooldownRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;
    // Dark overlay to dim the button
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    // Arc filling in as cooldown expires
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,            // start at top
      progress * 2 * pi,  // sweeps clockwise
      false,
      Paint()
        ..color       = color.withValues(alpha: 0.65)
        ..strokeWidth = 2.5
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MtCooldownRingPainter old) =>
      old.progress != progress;
}
