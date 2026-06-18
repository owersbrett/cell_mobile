import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../games/fx.dart';
import '../../../theme/potatuhs.dart';

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
  const FinancialTradingGame({Key? key}) : super(key: key);
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
    if (_gameOver) return;
    const dt = 1 / 60.0;
    setState(() {
      _elapsed  += dt;
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        if (_inPosition) _sell(silent: true);
        _timeLeft = 0;
        _gameOver = true;
        _checkAndSaveHighScore();
        return;
      }

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
    final pnl      = _totalNetWorth - _kMtStartingCash;
    final timerRed = _timeLeft < 10 && !_gameOver;

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
            // HUD top bar
            _buildHud(w, pnl, timerRed),

            // Instruction banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Text(
                'Buy low, sell high — beat the market',
                textAlign: TextAlign.center,
                style: Potatuhs.label(
                    size: 11, color: Potatuhs.textSecondary),
              ),
            ),

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
            if (!_gameOver) ...[
              _buildEventButtons(),
              _buildDebtControls(),
            ],

            // BUY / SELL controls
            if (!_gameOver)
              _buildTradeButtons(screenSize),

            const SizedBox(height: 10),

            // Game-over panel
            if (_gameOver)
              _buildGameOver(),
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

        // NEW HIGH SCORE overlay
        if (_newHighScore && _newHsTimer > 0)
          Positioned(
            top: h * 0.22,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'NEW HIGH SCORE!',
                  style: Potatuhs.display(size: 26, color: Potatuhs.gold)
                      .copyWith(
                    shadows: [
                      Shadow(
                          color: Potatuhs.orange.withValues(alpha: 0.9),
                          blurRadius: 24),
                    ],
                  ),
                ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// 2. GlobalFeedGame — "Feed the World"
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductType {
  final String name;
  final IconData icon;
  final Color color;
  final double valueMultiplier;
  final int unlockCost; // 0 = always available
  final String label;
  const _ProductType(this.name, this.icon, this.color, this.valueMultiplier, this.unlockCost, this.label);
}

const List<_ProductType> _allProducts = [
  _ProductType('potatoes', Icons.grass, Color(0xFFE19816), 1.0, 0, 'Potatoes'),
  _ProductType('fries', Icons.local_dining, Color(0xFFFFB74D), 2.0, 200, 'French Fries'),
  _ProductType('chips', Icons.breakfast_dining, Color(0xFFFF8A65), 2.5, 400, 'Potato Chips'),
  _ProductType('starch', Icons.science, Color(0xFF90CAF9), 1.8, 300, 'Potato Starch'),
  _ProductType('textiles', Icons.checkroom, Color(0xFFCE93D8), 3.0, 600, 'Potato Merch'),
  _ProductType('vodka', Icons.local_bar, Color(0xFF80CBC4), 4.0, 800, 'Potato Vodka'),
  _ProductType('futures', Icons.trending_up, Color(0xFFFFD54F), 5.0, 1200, 'Futures Contract'),
];

class _Company {
  final String name;
  double x, y;
  final String demandType; // matches _ProductType.name
  final int demandAmount; // population equivalent
  bool supplied = false;
  bool expired = false;
  double timer; // seconds until lost
  final Color color;
  _Company(this.name, this.x, this.y, this.demandType, this.demandAmount, this.timer, this.color);
}

class _RegionData {
  final String name;
  final double centerX, centerY;
  final List<_Company> Function(Random rng) generateCompanies;
  const _RegionData(this.name, this.centerX, this.centerY, this.generateCompanies);
}

List<_Company> _northAmericaCompanies(Random rng) => [
  _Company('BurgerKing HQ', 0.25, 0.35, 'fries', 500000, 25, const Color(0xFFFF6F00)),
  _Company('Costco Bulk', 0.15, 0.25, 'potatoes', 800000, 30, const Color(0xFFE53935)),
  _Company('Frito-Lay Plant', 0.35, 0.30, 'chips', 600000, 22, const Color(0xFFFF8F00)),
  _Company('Starch Industries', 0.45, 0.40, 'starch', 400000, 28, const Color(0xFF1E88E5)),
  _Company('Idaho Grocer', 0.20, 0.45, 'potatoes', 200000, 20, const Color(0xFF43A047)),
  _Company('Vodka Distillery', 0.55, 0.25, 'vodka', 300000, 35, const Color(0xFF00897B)),
  _Company("Wendy's Supply", 0.40, 0.55, 'fries', 450000, 24, const Color(0xFFD81B60)),
  _Company('Potato Merch Co', 0.60, 0.45, 'textiles', 150000, 40, const Color(0xFF8E24AA)),
  _Company('AgriTrade Futures', 0.50, 0.60, 'futures', 700000, 45, const Color(0xFFFDD835)),
  _Company('McDonalds Depot', 0.30, 0.50, 'fries', 900000, 20, const Color(0xFFFFC107)),
];

List<_Company> _europeCompanies(Random rng) => [
  _Company('Tayto Factory', 0.35, 0.30, 'chips', 400000, 24, const Color(0xFFFF6F00)),
  _Company('Tesco Distribution', 0.30, 0.25, 'potatoes', 600000, 28, const Color(0xFF1565C0)),
  _Company('Belgian Frite Stand', 0.40, 0.35, 'fries', 200000, 20, const Color(0xFFFFB300)),
  _Company('Polish Vodka House', 0.55, 0.30, 'vodka', 350000, 32, const Color(0xFF00695C)),
  _Company('German Starch Co', 0.48, 0.28, 'starch', 500000, 26, const Color(0xFF42A5F5)),
  _Company('London Market', 0.32, 0.22, 'potatoes', 700000, 22, const Color(0xFF66BB6A)),
  _Company('Parisian Bistro Chain', 0.38, 0.38, 'fries', 300000, 25, const Color(0xFFEF5350)),
  _Company('Spud Wear EU', 0.45, 0.45, 'textiles', 180000, 38, const Color(0xFFAB47BC)),
  _Company('EuroAgri Exchange', 0.52, 0.40, 'futures', 600000, 42, const Color(0xFFFFF176)),
];

List<_Company> _asiaCompanies(Random rng) => [
  _Company('Tokyo Calbee Plant', 0.75, 0.30, 'chips', 550000, 22, const Color(0xFFFF7043)),
  _Company('Shanghai Market', 0.60, 0.35, 'potatoes', 900000, 26, const Color(0xFF66BB6A)),
  _Company('Mumbai FoodCo', 0.45, 0.50, 'fries', 700000, 24, const Color(0xFFFFCA28)),
  _Company('Korean Soju Maker', 0.70, 0.28, 'vodka', 400000, 30, const Color(0xFF26A69A)),
  _Company('Starch Asia Ltd', 0.55, 0.45, 'starch', 350000, 28, const Color(0xFF42A5F5)),
  _Company('Delhi Grocer Net', 0.42, 0.45, 'potatoes', 500000, 25, const Color(0xFF43A047)),
  _Company('Potato Fashion Tokyo', 0.78, 0.35, 'textiles', 200000, 36, const Color(0xFFCE93D8)),
  _Company('Beijing Commodity Ex', 0.58, 0.30, 'futures', 800000, 40, const Color(0xFFFFD54F)),
  _Company('Thai Fry Chain', 0.55, 0.55, 'fries', 300000, 22, const Color(0xFFFF8A65)),
];

final List<_RegionData> _regions = [
  _RegionData('North America', 0.3, 0.4, _northAmericaCompanies),
  _RegionData('Europe', 0.45, 0.3, _europeCompanies),
  _RegionData('Asia', 0.6, 0.4, _asiaCompanies),
];

class GlobalFeedGame extends StatefulWidget {
  const GlobalFeedGame({Key? key}) : super(key: key);
  @override
  State<GlobalFeedGame> createState() => _GlobalFeedGameState();
}

class _GlobalFeedGameState extends State<GlobalFeedGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  double _timeLeft = 60;
  int _transportPoints = 100;
  bool _gameOver = false;
  int _citiesFed = 0;
  int _round = 1;
  int _totalPeopleFed = 0;
  int _citiesLost = 0;
  static const int _maxCitiesLost = 3;
  bool _showingCelebration = false;
  double _celebrationTimer = 0;
  bool _isNewHighScore = false;

  // Phase system: 1=global overview, 2=zoomed regional
  int _phase = 1;
  int _money = 0;
  int _selectedProductIdx = 0;
  final Set<int> _unlockedProducts = {0}; // index 0 (potatoes) always unlocked
  List<_Company> _companies = [];
  String _regionName = '';
  // Warehouse position in regional view
  double _warehouseX = 0.10;
  double _warehouseY = 0.75;

  // High scores
  List<Map<String, dynamic>> _highScores = [];

  // Producers: name, x%, y%
  final List<_MapNode> _producers = [
    _MapNode('Idaho Falls', 0.15, 0.30, Colors.amber),
    _MapNode('Lima', 0.22, 0.65, Colors.amber),
    _MapNode('China', 0.72, 0.35, Colors.amber),
    _MapNode('India', 0.65, 0.45, Colors.amber),
    _MapNode('Dublin', 0.47, 0.25, Colors.amber),
  ];

  // Base city list for round 1
  static List<_CityNode> _baseCities() => [
    _CityNode('Minsk', 0.52, 0.22, 120000, false, false),
    _CityNode('Lagos', 0.44, 0.55, 450000, false, false),
    _CityNode('Tokyo', 0.82, 0.33, 900000, false, false),
    _CityNode('Delhi', 0.67, 0.40, 750000, false, false),
    _CityNode('SP', 0.28, 0.68, 600000, false, false),
  ];

  // Extra city names pool (potato-themed where possible)
  static const List<String> _extraCityNames = [
    'London', 'Cairo', 'Seoul', 'Sydney', 'Berlin', 'Rio', 'Moscow',
    'Boise', 'Cusco', 'Cork', 'Vitebsk', 'Quito', 'Nairobi',
    'Manila', 'Jakarta', 'Dhaka', 'Bogota',
  ];
  static const List<int> _extraCityPops = [
    500000, 320000, 600000, 280000, 400000, 550000, 700000,
    120000, 90000, 80000, 110000, 200000, 350000,
    650000, 500000, 800000, 420000,
  ];

  late List<_CityNode> _cities;

  // Routes drawn
  final List<_SupplyRoute> _routes = [];

  // Drag state
  int? _dragSourceIdx;
  Offset? _dragCurrent;

  // Route info overlay
  String? _routeInfoText;
  double _routeInfoTimer = 0;

  // City starvation timers (seconds until city starves)
  final Map<int, double> _starvationTimers = {};
  static const double _baseStarvationTime = 20.0;

  // Particles
  final List<_JuiceParticle> _particles = [];

  // Layout dimensions cached
  double _lastW = 0;
  double _lastH = 0;

  double get _starvationTimeForRound {
    final t = _baseStarvationTime - (_round - 1) * 2.0;
    return t < 8.0 ? 8.0 : t;
  }

  @override
  void initState() {
    super.initState();
    _cities = _baseCities();
    _initStarvationTimers();
    _loadHighScores();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  void _initStarvationTimers() {
    _starvationTimers.clear();
    for (int i = 0; i < _cities.length; i++) {
      if (!_cities[i].fed && !_cities[i].starved) {
        _starvationTimers[i] = _starvationTimeForRound;
      }
    }
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('feed_the_world_high_scores');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _highScores = decoded
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      } catch (_) {
        _highScores = [];
      }
    }
  }

  Future<void> _saveHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'feed_the_world_high_scores',
      jsonEncode(_highScores),
    );
  }

  void _checkAndSaveHighScore(int score) {
    final entry = {
      'score': score,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    };
    _highScores.add(entry);
    _highScores.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );
    if (_highScores.length > 5) {
      _highScores = _highScores.sublist(0, 5);
    }
    // Check if our score made it into the top 5
    _isNewHighScore = _highScores.any(
      (e) => e['score'] == score && e['date'] == entry['date'],
    );
    _saveHighScores();
  }

  int get _currentBestScore {
    if (_highScores.isEmpty) return 0;
    return _highScores.first['score'] as int;
  }

  int get _currentScore => _totalPeopleFed;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      // Celebration pause between rounds
      if (_showingCelebration) {
        _celebrationTimer -= dt;
        if (_rng.nextDouble() < 0.3) {
          _spawnP(
            _lastW * (0.2 + _rng.nextDouble() * 0.6),
            _lastH * (0.2 + _rng.nextDouble() * 0.4),
            [
              Colors.greenAccent,
              Colors.amberAccent,
              Colors.cyanAccent,
              Colors.pinkAccent,
            ][_rng.nextInt(4)],
            3,
          );
        }
        if (_celebrationTimer <= 0) {
          _showingCelebration = false;
          _startNextRound();
        }
        _updateParticles(dt);
        return;
      }

      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _endGame();
        return;
      }

      // Route info fade
      if (_routeInfoTimer > 0) {
        _routeInfoTimer -= dt;
        if (_routeInfoTimer <= 0) _routeInfoText = null;
      }

      // Phase 2: company timers and supply logic
      if (_phase == 2) {
        for (final c in _companies) {
          if (!c.supplied && !c.expired) {
            c.timer -= dt;
            if (c.timer <= 0) {
              c.expired = true;
              _citiesLost++;
              _spawnP(c.x * _lastW, c.y * _lastH, Colors.grey, 15);
              if (_citiesLost >= _maxCitiesLost) {
                _endGame();
                return;
              }
            }
          }
        }

        // Animate route deliveries for phase 2
        for (final r in _routes) {
          r.progress += dt * 0.5;
          if (r.progress >= 1.0 && !r.delivered) {
            r.delivered = true;
            if (r.cityIdx < _companies.length &&
                !_companies[r.cityIdx].supplied &&
                !_companies[r.cityIdx].expired) {
              final company = _companies[r.cityIdx];
              company.supplied = true;
              _citiesFed++;
              // Check product match for bonus
              final product = _allProducts[r.producerIdx]; // reusing producerIdx as product index
              final matchBonus = product.name == company.demandType ? 2.0 : 0.5;
              final earned = (company.demandAmount * product.valueMultiplier * matchBonus).toInt();
              _totalPeopleFed += earned;
              _money += (earned / 10000).round();
              _spawnP(company.x * _lastW, company.y * _lastH,
                  matchBonus > 1 ? Colors.greenAccent : Colors.orangeAccent, 12);
            }
          }
        }

        // Check if all companies supplied -> round complete
        final active = _companies.where((c) => !c.expired).toList();
        if (active.isNotEmpty && active.every((c) => c.supplied)) {
          _showingCelebration = true;
          _celebrationTimer = 2.5;
          _money += 50 * _round; // round bonus
          for (int i = 0; i < 30; i++) {
            _spawnP(
              _lastW * (0.2 + _rng.nextDouble() * 0.6),
              _lastH * (0.2 + _rng.nextDouble() * 0.6),
              [Colors.greenAccent, Colors.amberAccent, Colors.cyanAccent][_rng.nextInt(3)],
              2,
            );
          }
        }

        // Route info fade
        if (_routeInfoTimer > 0) {
          _routeInfoTimer -= dt;
          if (_routeInfoTimer <= 0) _routeInfoText = null;
        }

        _updateParticles(dt);
        return;
      }

      // Phase 1: starvation timers for unfed cities
      final keysToRemove = <int>[];
      for (final key in _starvationTimers.keys.toList()) {
        if (key < _cities.length &&
            !_cities[key].fed &&
            !_cities[key].starved) {
          _starvationTimers[key] = _starvationTimers[key]! - dt;
          if (_starvationTimers[key]! <= 0) {
            _cities[key].starved = true;
            _citiesLost++;
            _spawnP(
              _cities[key].x * _lastW,
              _cities[key].y * _lastH,
              Colors.grey,
              15,
            );
            keysToRemove.add(key);
            if (_citiesLost >= _maxCitiesLost) {
              _endGame();
              return;
            }
          }
        }
      }
      for (final k in keysToRemove) {
        _starvationTimers.remove(k);
      }

      // Spawn new hungry cities periodically
      final spawnRate = 0.003 + (_round - 1) * 0.001;
      final maxCities = 5 + _round * 2;
      if (_rng.nextDouble() < spawnRate && _cities.length < maxCities) {
        final nameIdx = _rng.nextInt(_extraCityNames.length);
        final newIdx = _cities.length;
        _cities.add(_CityNode(
          _extraCityNames[nameIdx],
          0.1 + _rng.nextDouble() * 0.8,
          0.15 + _rng.nextDouble() * 0.65,
          _extraCityPops[nameIdx],
          false,
          false,
        ));
        _starvationTimers[newIdx] = _starvationTimeForRound;
      }

      // Animate route deliveries
      for (final r in _routes) {
        r.progress += dt * 0.5;
        if (r.progress >= 1.0 && !r.delivered) {
          r.delivered = true;
          if (r.cityIdx < _cities.length &&
              !_cities[r.cityIdx].fed &&
              !_cities[r.cityIdx].starved) {
            _cities[r.cityIdx].fed = true;
            _citiesFed++;
            _totalPeopleFed += _cities[r.cityIdx].population;
            _starvationTimers.remove(r.cityIdx);
            _spawnP(
              _cities[r.cityIdx].x * _lastW,
              _cities[r.cityIdx].y * _lastH,
              Colors.greenAccent,
              10,
            );
          }
        }
      }

      // Check if all feedable cities are fed -> round complete
      final feedable = _cities.where((c) => !c.starved).toList();
      if (feedable.isNotEmpty && feedable.every((c) => c.fed)) {
        _showingCelebration = true;
        _celebrationTimer = 2.0;
        for (int i = 0; i < 30; i++) {
          _spawnP(
            _lastW * (0.2 + _rng.nextDouble() * 0.6),
            _lastH * (0.2 + _rng.nextDouble() * 0.6),
            [
              Colors.greenAccent,
              Colors.amberAccent,
              Colors.cyanAccent,
            ][_rng.nextInt(3)],
            2,
          );
        }
      }

      _updateParticles(dt);
    });
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void _endGame() {
    _gameOver = true;
    _checkAndSaveHighScore(_currentScore);
  }

  void _startNextRound() {
    _round++;
    _transportPoints += 60 + _round * 10;
    _routes.clear();

    // After round 1, transition to phase 2 (regional zoom)
    if (_round == 2 && _phase == 1) {
      _phase = 2;
      final region = _regions[_rng.nextInt(_regions.length)];
      _regionName = region.name;
      _companies = region.generateCompanies(_rng);
      _money += 100; // starting money for phase 2
      _citiesFed = 0;
      _starvationTimers.clear();
      _cities.clear();
      return;
    }

    if (_phase == 2) {
      // Generate new companies for next regional round
      final region = _regions.firstWhere((r) => r.name == _regionName,
          orElse: () => _regions[_rng.nextInt(_regions.length)]);
      _companies = region.generateCompanies(_rng);
      // Add difficulty: shorter timers, more companies
      for (final c in _companies) {
        c.timer = (c.timer - (_round - 2) * 2).clamp(10.0, 50.0);
      }
      _citiesFed = 0;
      _starvationTimers.clear();
      return;
    }

    final numCities = 5 + _round;
    _cities = [];
    final allNames = [
      'Minsk', 'Lagos', 'Tokyo', 'Delhi', 'SP',
      ..._extraCityNames,
    ];
    final allPops = [
      120000, 450000, 900000, 750000, 600000,
      ..._extraCityPops,
    ];
    final usedIdxs = <int>{};
    for (int i = 0; i < numCities && i < allNames.length; i++) {
      int idx;
      do {
        idx = _rng.nextInt(allNames.length);
      } while (usedIdxs.contains(idx));
      usedIdxs.add(idx);
      _cities.add(_CityNode(
        allNames[idx],
        0.1 + _rng.nextDouble() * 0.8,
        0.15 + _rng.nextDouble() * 0.65,
        allPops[idx],
        false,
        false,
      ));
    }
    _citiesFed = 0;
    _initStarvationTimers();
  }

  void _spawnP(double x, double y, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: x,
        y: y,
        vx: (_rng.nextDouble() - 0.5) * 80,
        vy: (_rng.nextDouble() - 0.5) * 80,
        life: 0.6,
        color: c,
      ));
    }
  }

  void _unlockProduct(int idx) {
    if (idx >= _allProducts.length) return;
    final cost = _allProducts[idx].unlockCost;
    if (_money >= cost && !_unlockedProducts.contains(idx)) {
      setState(() {
        _money -= cost;
        _unlockedProducts.add(idx);
        _selectedProductIdx = idx;
      });
    }
  }

  void _restart() {
    setState(() {
      _timeLeft = 60;
      _transportPoints = 100;
      _gameOver = false;
      _citiesFed = 0;
      _round = 1;
      _totalPeopleFed = 0;
      _citiesLost = 0;
      _showingCelebration = false;
      _isNewHighScore = false;
      _routeInfoText = null;
      _routeInfoTimer = 0;
      _routes.clear();
      _particles.clear();
      _cities = _baseCities();
      _initStarvationTimers();
      _phase = 1;
      _money = 0;
      _selectedProductIdx = 0;
      _unlockedProducts.clear();
      _unlockedProducts.add(0);
      _companies.clear();
      _regionName = '';
    });
  }

  String _formatPopulation(int pop) {
    if (pop >= 1000000) return '${(pop / 1000000).toStringAsFixed(1)}M';
    if (pop >= 1000) return '${(pop / 1000).toStringAsFixed(0)}K';
    return pop.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _lastW = w;
      _lastH = h;

      if (_phase == 2 && !_gameOver) {
        return _buildPhase2(w, h);
      }

      return GestureDetector(
        onPanStart: (details) {
          if (_gameOver || _showingCelebration) return;
          for (int i = 0; i < _producers.length; i++) {
            final px = _producers[i].x * w;
            final py = _producers[i].y * h;
            if ((details.localPosition - Offset(px, py)).distance < 30) {
              _dragSourceIdx = i;
              _dragCurrent = details.localPosition;
              break;
            }
          }
        },
        onPanUpdate: (details) {
          if (_dragSourceIdx != null) {
            setState(() => _dragCurrent = details.localPosition);
          }
        },
        onPanEnd: (details) {
          if (_dragSourceIdx != null && _dragCurrent != null) {
            for (int i = 0; i < _cities.length; i++) {
              if (_cities[i].fed || _cities[i].starved) continue;
              final cx = _cities[i].x * w;
              final cy = _cities[i].y * h;
              if ((_dragCurrent! - Offset(cx, cy)).distance < 30) {
                final prod = _producers[_dragSourceIdx!];
                final dx = prod.x - _cities[i].x;
                final dy = prod.y - _cities[i].y;
                final dist = sqrt(dx * dx + dy * dy);
                final cost = (dist * 50).round();
                final distKm = (dist * 20000).round();
                if (_transportPoints >= cost) {
                  setState(() {
                    _transportPoints -= cost;
                    _routes.add(
                      _SupplyRoute(_dragSourceIdx!, i, 0, false),
                    );
                    _routeInfoText = '${distKm}km  Cost: $cost';
                    _routeInfoTimer = 2.0;
                  });
                }
                break;
              }
            }
          }
          _dragSourceIdx = null;
          _dragCurrent = null;
        },
        child: Container(
          color: const Color(0xFF0A1628),
          child: CustomPaint(
            painter: _WorldMapPainter(
              _producers,
              _cities,
              _routes,
              _dragSourceIdx,
              _dragCurrent,
              _particles,
              _starvationTimers,
              _starvationTimeForRound,
            ),
            child: Stack(
              children: [
                // HUD top row
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_timeLeft.toInt()}s',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 16,
                          color: _timeLeft < 10
                              ? Colors.redAccent
                              : Colors.white70,
                        ),
                      ),
                      Text(
                        'R$_round',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      Text(
                        'Transport: $_transportPoints',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                // HUD second row
                Positioned(
                  top: 28,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fed: $_citiesFed/'
                        '${_cities.where((c) => !c.starved).length}',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                      ),
                      Text(
                        'People: ${_formatPopulation(_totalPeopleFed)}',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 12,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < _maxCitiesLost; i++)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                i < _citiesLost
                                    ? Icons.close
                                    : Icons.location_city,
                                size: 12,
                                color: i < _citiesLost
                                    ? Colors.redAccent
                                    : Colors.white30,
                              ),
                            ),
                        ],
                      ),
                      if (_currentBestScore > 0)
                        Text(
                          'Best: ${_formatPopulation(_currentBestScore)}',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
                // Route info overlay
                if (_routeInfoText != null && _routeInfoTimer > 0)
                  Positioned(
                    top: h * 0.45,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _routeInfoText!,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 13,
                            color: Colors.amberAccent.withValues(
                              alpha: (_routeInfoTimer / 2.0).clamp(0.0, 1.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Celebration overlay
                if (_showingCelebration)
                  Positioned(
                    top: h * 0.35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Round $_round Complete!',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatPopulation(_totalPeopleFed)} people fed',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 14,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                          if (_round == 1)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Zooming into region...',
                                style: TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Next round in '
                              '${_celebrationTimer.toInt() + 1}...',
                              style: const TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // Game over overlay
                if (_gameOver)
                  _buildGameOverOverlay(),
                if (!_gameOver && !_showingCelebration)
                  const Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Drag from producers to hungry cities',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPhase2(double w, double h) {
    final selectedProduct = _allProducts[_selectedProductIdx];
    return GestureDetector(
      onPanStart: (details) {
        if (_showingCelebration) return;
        // Drag from warehouse
        final wx = _warehouseX * w;
        final wy = _warehouseY * h;
        if ((details.localPosition - Offset(wx, wy)).distance < 40) {
          _dragSourceIdx = _selectedProductIdx;
          _dragCurrent = details.localPosition;
        }
      },
      onPanUpdate: (details) {
        if (_dragSourceIdx != null) {
          setState(() => _dragCurrent = details.localPosition);
        }
      },
      onPanEnd: (details) {
        if (_dragSourceIdx != null && _dragCurrent != null) {
          for (int i = 0; i < _companies.length; i++) {
            if (_companies[i].supplied || _companies[i].expired) continue;
            final cx = _companies[i].x * w;
            final cy = _companies[i].y * h;
            if ((_dragCurrent! - Offset(cx, cy)).distance < 35) {
              final dx = _warehouseX - _companies[i].x;
              final dy = _warehouseY - _companies[i].y;
              final dist = sqrt(dx * dx + dy * dy);
              final cost = (dist * 40).round() + 5;
              if (_transportPoints >= cost) {
                setState(() {
                  _transportPoints -= cost;
                  _routes.add(_SupplyRoute(_selectedProductIdx, i, 0, false));
                  final product = _allProducts[_selectedProductIdx];
                  final match = product.name == _companies[i].demandType;
                  _routeInfoText = '${product.label} -> ${_companies[i].name}${match ? " (MATCH!)" : ""}  Cost: $cost';
                  _routeInfoTimer = 2.5;
                });
              }
              break;
            }
          }
        }
        _dragSourceIdx = null;
        _dragCurrent = null;
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2A3A)],
          ),
        ),
        child: Stack(
          children: [
            // Regional map with companies
            CustomPaint(
              size: Size(w, h),
              painter: _RegionalMapPainter(
                companies: _companies,
                routes: _routes,
                particles: _particles,
                warehouseX: _warehouseX,
                warehouseY: _warehouseY,
                dragSource: _dragSourceIdx,
                dragCurrent: _dragCurrent,
                selectedProduct: selectedProduct,
              ),
            ),

            // HUD
            Positioned(
              top: 8, left: 12, right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_timeLeft.toInt()}s',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 16,
                      color: _timeLeft < 10 ? Colors.redAccent : Colors.white70)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$_regionName  R$_round',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.cyanAccent)),
                  ),
                  Text('TP: $_transportPoints',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.amberAccent)),
                ],
              ),
            ),

            // Second HUD row: money, fed count, lives
            Positioned(
              top: 30, left: 12, right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$$_money',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE19816))),
                  Text('Supplied: $_citiesFed/${_companies.where((c) => !c.expired).length}',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.greenAccent)),
                  Text('Score: ${_formatPopulation(_totalPeopleFed)}',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.lightBlueAccent)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _maxCitiesLost; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            i < _citiesLost ? Icons.close : Icons.storefront,
                            size: 12,
                            color: i < _citiesLost ? Colors.redAccent : Colors.white30,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Product selector bar at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xDD0A1628),
                  border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('PRODUCT LINE', style: TextStyle(fontFamily: 'Avenir', fontSize: 8, color: Colors.white30, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 46,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allProducts.length,
                        itemBuilder: (context, idx) {
                          final p = _allProducts[idx];
                          final unlocked = _unlockedProducts.contains(idx);
                          final selected = idx == _selectedProductIdx;
                          final canAfford = _money >= p.unlockCost;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () {
                                if (unlocked) {
                                  setState(() => _selectedProductIdx = idx);
                                } else if (canAfford) {
                                  _unlockProduct(idx);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? p.color.withValues(alpha: 0.3)
                                      : unlocked
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? p.color
                                        : unlocked
                                            ? p.color.withValues(alpha: 0.3)
                                            : Colors.white12,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(p.icon, size: 12,
                                          color: unlocked ? p.color : Colors.grey),
                                        const SizedBox(width: 3),
                                        Text(p.label,
                                          style: TextStyle(fontFamily: 'Avenir', fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: unlocked ? p.color : Colors.grey)),
                                      ],
                                    ),
                                    if (!unlocked)
                                      Text('\$${p.unlockCost}',
                                        style: TextStyle(fontFamily: 'Avenir', fontSize: 8,
                                          color: canAfford ? Colors.amberAccent : Colors.white24)),
                                    if (unlocked)
                                      Text('${p.valueMultiplier}x',
                                        style: TextStyle(fontFamily: 'Avenir', fontSize: 8,
                                          color: p.color.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Route info
            if (_routeInfoText != null && _routeInfoTimer > 0)
              Positioned(
                top: h * 0.45, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xDD000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(_routeInfoText!,
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 13,
                        color: Colors.amberAccent.withValues(alpha: (_routeInfoTimer / 2.5).clamp(0.0, 1.0)))),
                  ),
                ),
              ),

            // Celebration
            if (_showingCelebration)
              Positioned(
                top: h * 0.3, left: 0, right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Round $_round Complete!',
                        style: const TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                      const SizedBox(height: 6),
                      Text('+\$${50 * _round} bonus',
                        style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Color(0xFFE19816))),
                      const SizedBox(height: 4),
                      Text('${_formatPopulation(_totalPeopleFed)} total score',
                        style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.lightBlueAccent)),
                    ],
                  ),
                ),
              ),

            // Game over
            if (_gameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isNewHighScore) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const Text('NEW HIGH SCORE!',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 24,
                        fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _citiesLost >= _maxCitiesLost
                      ? 'Too Many Lost!'
                      : 'Time Up!',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 20,
                    fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 12),
                _statRow('Rounds completed', '$_round'),
                _statRow('Total score', _formatPopulation(_totalPeopleFed)),
                if (_phase == 2) _statRow('Money earned', '\$$_money'),
                if (_phase == 2) _statRow('Products unlocked', '${_unlockedProducts.length}/${_allProducts.length}'),
                _statRow('Lost', '$_citiesLost'),
                const SizedBox(height: 16),
                if (_highScores.isNotEmpty) ...[
                  const Text('LEADERBOARD',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                      fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 6),
                  for (int i = 0; i < _highScores.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 20, child: Text('${i + 1}.',
                            style: TextStyle(fontFamily: 'Avenir', fontSize: 12,
                              color: i == 0 ? Colors.amberAccent : Colors.white54))),
                          SizedBox(width: 80, child: Text(_formatPopulation(_highScores[i]['score'] as int),
                            style: TextStyle(fontFamily: 'Avenir', fontSize: 12, fontWeight: FontWeight.bold,
                              color: _highScores[i]['score'] == _currentScore ? Colors.greenAccent : Colors.white70))),
                          Text(_highScores[i]['date'] as String,
                            style: const TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Colors.white38)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                GestureDetector(
                  onTap: _restart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text('Play Again',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Avenir',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode {
  final String name;
  final double x, y;
  final Color color;
  _MapNode(this.name, this.x, this.y, this.color);
}

class _CityNode {
  final String name;
  final double x, y;
  final int population;
  bool fed;
  bool starved;
  _CityNode(
    this.name, this.x, this.y, this.population, this.fed, this.starved,
  );
}

class _SupplyRoute {
  final int producerIdx, cityIdx;
  double progress;
  bool delivered;
  _SupplyRoute(this.producerIdx, this.cityIdx, this.progress, this.delivered);
}

class _WorldMapPainter extends CustomPainter {
  final List<_MapNode> producers;
  final List<_CityNode> cities;
  final List<_SupplyRoute> routes;
  final int? dragSource;
  final Offset? dragCurrent;
  final List<_JuiceParticle> particles;
  final Map<int, double> starvationTimers;
  final double maxStarvationTime;

  _WorldMapPainter(
    this.producers,
    this.cities,
    this.routes,
    this.dragSource,
    this.dragCurrent,
    this.particles,
    this.starvationTimers,
    this.maxStarvationTime,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Continent outlines (simplified)
    final continentPaint = Paint()
      ..color = const Color(0xFF1A3050)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF2A5080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    _drawEllipse(
      canvas, size, 0.17, 0.28, 0.12, 0.14, continentPaint, outlinePaint,
    );
    _drawEllipse(
      canvas, size, 0.24, 0.62, 0.07, 0.16, continentPaint, outlinePaint,
    );
    _drawEllipse(
      canvas, size, 0.48, 0.25, 0.08, 0.08, continentPaint, outlinePaint,
    );
    _drawEllipse(
      canvas, size, 0.48, 0.52, 0.08, 0.15, continentPaint, outlinePaint,
    );
    _drawEllipse(
      canvas, size, 0.70, 0.30, 0.16, 0.14, continentPaint, outlinePaint,
    );
    _drawEllipse(
      canvas, size, 0.82, 0.65, 0.06, 0.06, continentPaint, outlinePaint,
    );

    // Routes
    for (final r in routes) {
      if (r.producerIdx >= producers.length ||
          r.cityIdx >= cities.length) {
        continue;
      }
      final p = producers[r.producerIdx];
      final c = cities[r.cityIdx];
      final from = Offset(p.x * size.width, p.y * size.height);
      final to = Offset(c.x * size.width, c.y * size.height);
      final routePaint = Paint()
        ..color = (r.delivered ? Colors.greenAccent : Colors.amberAccent)
            .withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, routePaint);

      if (!r.delivered) {
        final dotPos =
            Offset.lerp(from, to, r.progress.clamp(0.0, 1.0))!;
        canvas.drawCircle(dotPos, 4, Paint()..color = Colors.amberAccent);
      }
    }

    // Drag line
    if (dragSource != null && dragCurrent != null) {
      final p = producers[dragSource!];
      final dragPaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(p.x * size.width, p.y * size.height),
        dragCurrent!,
        dragPaint,
      );
    }

    // Producers (glow)
    for (final p in producers) {
      final pos = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(
        pos, 18, Paint()..color = Colors.amber.withValues(alpha: 0.15),
      );
      canvas.drawCircle(
        pos, 10, Paint()..color = Colors.amber.withValues(alpha: 0.4),
      );
      canvas.drawCircle(pos, 5, Paint()..color = Colors.amber);
      _drawLabel(canvas, p.name, pos.dx, pos.dy - 16, Colors.amberAccent, 10);
    }

    // Cities
    for (int i = 0; i < cities.length; i++) {
      final c = cities[i];
      final pos = Offset(c.x * size.width, c.y * size.height);
      if (c.starved) {
        canvas.drawCircle(
          pos, 10, Paint()..color = Colors.grey.withValues(alpha: 0.3),
        );
        canvas.drawCircle(
          pos, 5, Paint()..color = Colors.grey.withValues(alpha: 0.6),
        );
        _drawLabel(canvas, '\u2620', pos.dx, pos.dy - 2, Colors.grey, 14);
        _drawLabel(canvas, c.name, pos.dx, pos.dy + 14, Colors.grey, 9);
      } else if (c.fed) {
        canvas.drawCircle(
          pos, 8,
          Paint()..color = Colors.greenAccent.withValues(alpha: 0.4),
        );
        canvas.drawCircle(pos, 4, Paint()..color = Colors.greenAccent);
        _drawLabel(
          canvas, c.name, pos.dx, pos.dy + 12, Colors.greenAccent, 10,
        );
      } else {
        final alpha = 0.3 +
            0.7 *
                ((DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
        canvas.drawCircle(
          pos, 12,
          Paint()..color = Colors.redAccent.withValues(alpha: alpha * 0.2),
        );
        canvas.drawCircle(
          pos, 6,
          Paint()..color = Colors.redAccent.withValues(alpha: alpha),
        );
        _drawLabel(
          canvas, c.name, pos.dx, pos.dy + 12, Colors.redAccent, 10,
        );

        // Starvation timer bar
        final timeLeft = starvationTimers[i];
        if (timeLeft != null && maxStarvationTime > 0) {
          final frac = (timeLeft / maxStarvationTime).clamp(0.0, 1.0);
          const barW = 20.0;
          const barH = 3.0;
          final barX = pos.dx - barW / 2;
          final barY = pos.dy + 20;
          canvas.drawRect(
            Rect.fromLTWH(barX, barY, barW, barH),
            Paint()..color = Colors.white12,
          );
          canvas.drawRect(
            Rect.fromLTWH(barX, barY, barW * frac, barH),
            Paint()
              ..color = frac < 0.3 ? Colors.redAccent : Colors.orangeAccent,
          );
        }
      }
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x, p.y),
          3,
          Paint()
            ..color = p.color.withValues(
              alpha: (p.life / p.maxLife).clamp(0.0, 1.0),
            ),
        );
      }
    }
  }

  void _drawEllipse(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double rx,
    double ry,
    Paint fill,
    Paint outline,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(cx * size.width, cy * size.height),
      width: rx * 2 * size.width,
      height: ry * 2 * size.height,
    );
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, outline);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir', fontSize: fontSize, color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter old) => true;
}


// RegionalMapPainter — zoomed-in view for phase 2
class _RegionalMapPainter extends CustomPainter {
  final List<_Company> companies;
  final List<_SupplyRoute> routes;
  final List<_JuiceParticle> particles;
  final double warehouseX, warehouseY;
  final int? dragSource;
  final Offset? dragCurrent;
  final _ProductType selectedProduct;

  _RegionalMapPainter({
    required this.companies,
    required this.routes,
    required this.particles,
    required this.warehouseX,
    required this.warehouseY,
    required this.dragSource,
    required this.dragCurrent,
    required this.selectedProduct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()..color = const Color(0x0AFFFFFF)..strokeWidth = 0.5;
    for (int i = 1; i < 8; i++) {
      canvas.drawLine(Offset(0, h * i / 8), Offset(w, h * i / 8), gridPaint);
      canvas.drawLine(Offset(w * i / 8, 0), Offset(w * i / 8, h), gridPaint);
    }

    final roadPaint = Paint()..color = const Color(0x15FFFFFF)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final whPos = Offset(warehouseX * w, warehouseY * h);
    for (final c in companies) {
      if (!c.supplied && !c.expired) {
        canvas.drawLine(whPos, Offset(c.x * w, c.y * h), roadPaint);
      }
    }

    for (final r in routes) {
      if (r.cityIdx >= companies.length) continue;
      final c = companies[r.cityIdx];
      final from = whPos;
      final to = Offset(c.x * w, c.y * h);
      canvas.drawLine(from, to, Paint()..color = (r.delivered ? Colors.greenAccent : Colors.amberAccent).withValues(alpha: 0.5)..strokeWidth = 2.5..style = PaintingStyle.stroke);
      if (!r.delivered) {
        final dotPos = Offset.lerp(from, to, r.progress.clamp(0.0, 1.0))!;
        final product = _allProducts[r.producerIdx.clamp(0, _allProducts.length - 1)];
        canvas.drawCircle(dotPos, 6, Paint()..color = product.color);
        canvas.drawCircle(dotPos, 6, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }

    if (dragSource != null && dragCurrent != null) {
      canvas.drawLine(whPos, dragCurrent!, Paint()..color = selectedProduct.color.withValues(alpha: 0.6)..strokeWidth = 2..style = PaintingStyle.stroke);
    }

    canvas.drawCircle(whPos, 22, Paint()..color = const Color(0xFF1A3A50));
    canvas.drawCircle(whPos, 22, Paint()..color = Colors.amberAccent.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(whPos, 14, Paint()..color = const Color(0xFFE19816));
    _drawLabel(canvas, 'WAREHOUSE', whPos.dx, whPos.dy - 30, Colors.amberAccent, 10);
    _drawLabel(canvas, selectedProduct.label, whPos.dx, whPos.dy + 30, selectedProduct.color, 9);

    for (int i = 0; i < companies.length; i++) {
      final c = companies[i];
      final pos = Offset(c.x * w, c.y * h);
      if (c.expired) {
        canvas.drawCircle(pos, 10, Paint()..color = Colors.grey.withValues(alpha: 0.2));
        _drawLabel(canvas, c.name, pos.dx, pos.dy + 14, Colors.grey, 8);
      } else if (c.supplied) {
        canvas.drawCircle(pos, 12, Paint()..color = Colors.greenAccent.withValues(alpha: 0.2));
        canvas.drawCircle(pos, 7, Paint()..color = Colors.greenAccent.withValues(alpha: 0.7));
        _drawLabel(canvas, c.name, pos.dx, pos.dy + 14, Colors.greenAccent, 9);
      } else {
        final pulse = 0.5 + 0.5 * sin(DateTime.now().millisecondsSinceEpoch / 300.0 + i);
        canvas.drawCircle(pos, 16, Paint()..color = c.color.withValues(alpha: pulse * 0.15));
        canvas.drawCircle(pos, 10, Paint()..color = c.color.withValues(alpha: 0.6));
        canvas.drawCircle(pos, 10, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
        _drawLabel(canvas, c.name, pos.dx, pos.dy + 16, c.color, 9);
        final demandProduct = _allProducts.firstWhere((p) => p.name == c.demandType, orElse: () => _allProducts[0]);
        _drawLabel(canvas, 'Wants: ${demandProduct.label}', pos.dx, pos.dy + 26, demandProduct.color.withValues(alpha: 0.7), 7);
        final frac = (c.timer / 30.0).clamp(0.0, 1.0);
        const barW = 24.0;
        const barH = 3.0;
        final barX = pos.dx - barW / 2;
        final barY = pos.dy + 33;
        canvas.drawRect(Rect.fromLTWH(barX, barY, barW, barH), Paint()..color = Colors.white12);
        canvas.drawRect(Rect.fromLTWH(barX, barY, barW * frac, barH), Paint()..color = frac < 0.3 ? Colors.redAccent : Colors.orangeAccent);
      }
    }

    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(Offset(p.x, p.y), 3, Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)));
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'Avenir', fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RegionalMapPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. PlanetCatchGame — "Gravity Well"
// Slingshot a missile through curved gravity fields — each round is a puzzle.
// Three bodies of DIFFERENT SIZES anchor each level; bigger = stronger pull.
// A straight shot always misses; you must exploit the curves to reach the target.
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak these without touching game logic
// ─────────────────────────────────────────────────────────────────────────────

// Cannon
const double _kMaxLaunchSpeed = 820.0; // px/s — maximum projectile speed
const double _kMinLaunchSpeed = 180.0; // px/s — minimum launch speed
const double _kDragToSpeedScale = 2.0; // drag px → speed multiplier
const double _kProjectileRadius = 6.0; // visual + hit radius of missile

// Gravity — made STRONG so trajectories bend dramatically
// G * mass / r^2 is the acceleration. With G=120000 and mass=3.5 at r=200px:
//   a = 120000*3.5/40000 ≈ 10.5 px/s² per substep — very curvy.
const double _kGravityConstant = 120000.0; // G — strong curvy pull

// Per-body mass categories (used in _buildLevels):
//   Large  body: mass 3.0–4.0, radius 38–50 px  → dominant slingshot anchor
//   Medium body: mass 1.2–1.8, radius 22–30 px  → secondary curve deflector
//   Small  body: mass 0.5–0.8, radius 12–16 px  → fine-tuning body

// Trajectory preview — more steps so curvy paths show clearly
const int _kPreviewSteps = 120; // steps for the dotted preview arc
const double _kPreviewDt = 0.022; // seconds per step (~2.6 s of flight shown)

// Target
const double _kTargetBaseRadius = 24.0; // hit zone radius on level 1
const double _kTargetRadiusShrinkPerLevel = 1.5; // shrinks each level

// Scoring
const int _kPointsPerHit = 100; // base score per hit
const int _kBonusPerExtraShot = 25; // bonus per spare shot on level clear
const int _kShotsPerLevel = 4; // shots per puzzle
const double _kTotalGameSeconds = 60.0;

// Moving target (later levels)
const double _kTargetMoveSpeed = 55.0; // px/s lateral oscillation
// ─────────────────────────────────────────────────────────────────────────────

/// One gravity body in a puzzle layout.
class _GravBody {
  final Offset pos; // fraction of canvas [0..1]
  final double mass; // multiplied by _kGravityConstant — larger = stronger
  final Color color; // brand-palette color
  final double radius; // visual radius in px — must correlate with mass
  /// Label shown near body so player reads its size/gravity role
  final String label; // e.g. 'GIANT', 'MID', 'SMALL'
  _GravBody({
    required this.pos,
    required this.mass,
    required this.color,
    required this.radius,
    this.label = '',
  });
}

/// Static description of a single puzzle level.
class _CannonLevel {
  final List<_GravBody> bodies; // always ~3, different sizes
  final Offset targetPos; // fraction of canvas
  final bool targetMoves;
  final String hint; // WarioWare-style instruction
  _CannonLevel({
    required this.bodies,
    required this.targetPos,
    this.targetMoves = false,
    this.hint = '',
  });
}

/// Live missile in flight.
class _Projectile {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  final List<Offset> trail;
  _Projectile({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true,
        trail = [];
}

class PlanetCatchGame extends StatefulWidget {
  const PlanetCatchGame({Key? key}) : super(key: key);
  @override
  State<PlanetCatchGame> createState() => _PlanetCatchGameState();
}

class _PlanetCatchGameState extends State<PlanetCatchGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // ── state ──────────────────────────────────────────────────────────────────
  bool _waitingToStart = true;
  bool _gameOver = false;
  int _score = 0;
  int _level = 0;
  int _shotsLeft = _kShotsPerLevel;
  double _timeLeft = _kTotalGameSeconds;
  int _highScore = 0;
  bool _newBest = false;

  // ── score pops ─────────────────────────────────────────────────────────────
  final List<FxPop> _pops = [];

  // ── aiming ─────────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  Size _canvasSize = Size.zero;

  // ── live sim ───────────────────────────────────────────────────────────────
  _Projectile? _projectile;
  final List<FxParticle> _fxParticles = [];

  // moving-target drift
  double _targetDrift = 0.0;
  double _targetDriftDir = 1.0;

  // animate clock for atmosphere
  double _t = 0.0;

  // ── level table ────────────────────────────────────────────────────────────
  late List<_CannonLevel> _levels;

  // cannon origin (bottom-left area, fraction)
  static const Offset _cannonFrac = Offset(0.12, 0.82);

  @override
  void initState() {
    super.initState();
    _buildLevels();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
    _loadHighScore();
  }

  // ── puzzle layouts ─────────────────────────────────────────────────────────
  // Every level has 3 bodies of clearly different sizes.
  // The target is placed so only a curved path reaches it —
  // a direct shot from the cannon corner hits a body or flies past.
  void _buildLevels() {
    _levels = [
      // ── Level 1 — INTRO: arc around the giant ─────────────────────────────
      // Giant in center blocks straight shot; swing right of it to reach top-right target.
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.50, 0.48), mass: 3.2, radius: 46,
              color: Potatuhs.airForce, label: 'GIANT'),
          _GravBody(pos: const Offset(0.72, 0.65), mass: 1.4, radius: 24,
              color: Potatuhs.glaucous, label: 'MID'),
          _GravBody(pos: const Offset(0.32, 0.32), mass: 0.6, radius: 13,
              color: Potatuhs.copper, label: 'SMALL'),
        ],
        targetPos: const Offset(0.84, 0.22),
        hint: 'SWING AROUND THE GIANT',
      ),

      // ── Level 2 — SLINGSHOT: use giant as catapult ────────────────────────
      // Target is behind and to the left of the giant; fly past, let it bend you back.
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.55, 0.42), mass: 3.6, radius: 50,
              color: Potatuhs.sienna, label: 'GIANT'),
          _GravBody(pos: const Offset(0.28, 0.60), mass: 1.5, radius: 26,
              color: Potatuhs.glaucous, label: 'MID'),
          _GravBody(pos: const Offset(0.75, 0.72), mass: 0.7, radius: 14,
              color: Potatuhs.copper, label: 'SMALL'),
        ],
        targetPos: const Offset(0.15, 0.22),
        hint: 'SLINGSHOT — FLY PAST THE GIANT',
      ),

      // ── Level 3 — DOUBLE CURVE: mid deflects into small nudge ─────────────
      // Aim slightly high-right; mid curves down; small redirects into target.
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.40, 0.35), mass: 1.6, radius: 28,
              color: Potatuhs.glaucous, label: 'MID'),
          _GravBody(pos: const Offset(0.68, 0.30), mass: 0.6, radius: 13,
              color: Potatuhs.copper, label: 'SMALL'),
          _GravBody(pos: const Offset(0.30, 0.65), mass: 3.8, radius: 52,
              color: Potatuhs.orange, label: 'GIANT'),
        ],
        targetPos: const Offset(0.85, 0.55),
        hint: 'USE MID THEN SMALL TO DEFLECT',
      ),

      // ── Level 4 — ORBIT ASSIST + moving target ────────────────────────────
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.52, 0.40), mass: 3.4, radius: 48,
              color: Potatuhs.gold, label: 'GIANT'),
          _GravBody(pos: const Offset(0.78, 0.55), mass: 1.3, radius: 23,
              color: Potatuhs.glaucous, label: 'MID'),
          _GravBody(pos: const Offset(0.28, 0.28), mass: 0.7, radius: 14,
              color: Potatuhs.copper, label: 'SMALL'),
        ],
        targetPos: const Offset(0.82, 0.20),
        targetMoves: true,
        hint: 'LEAD THE MOVING TARGET',
      ),

      // ── Level 5 — S-CURVE: chain three bodies in sequence ─────────────────
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.35, 0.42), mass: 3.5, radius: 49,
              color: Potatuhs.orange, label: 'GIANT'),
          _GravBody(pos: const Offset(0.60, 0.28), mass: 1.5, radius: 26,
              color: Potatuhs.airForce, label: 'MID'),
          _GravBody(pos: const Offset(0.75, 0.60), mass: 0.7, radius: 14,
              color: Potatuhs.copper, label: 'SMALL'),
        ],
        targetPos: const Offset(0.88, 0.78),
        hint: 'CHAIN THE S-CURVE',
      ),

      // ── Level 6 — PINBALL: tight corridor, moving target ──────────────────
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.45, 0.50), mass: 4.0, radius: 54,
              color: Potatuhs.sienna, label: 'GIANT'),
          _GravBody(pos: const Offset(0.72, 0.38), mass: 1.6, radius: 27,
              color: Potatuhs.glaucous, label: 'MID'),
          _GravBody(pos: const Offset(0.25, 0.30), mass: 0.8, radius: 15,
              color: Potatuhs.gold, label: 'SMALL'),
        ],
        targetPos: const Offset(0.88, 0.50),
        targetMoves: true,
        hint: 'PINBALL THROUGH THE GAP',
      ),

      // ── Level 7 — EXPERT: all pull strong, tiny target, moves fast ─────────
      _CannonLevel(
        bodies: [
          _GravBody(pos: const Offset(0.48, 0.44), mass: 4.0, radius: 54,
              color: Potatuhs.gold, label: 'GIANT'),
          _GravBody(pos: const Offset(0.70, 0.65), mass: 1.8, radius: 30,
              color: Potatuhs.airForce, label: 'MID'),
          _GravBody(pos: const Offset(0.30, 0.25), mass: 0.8, radius: 16,
              color: Potatuhs.copper, label: 'SMALL'),
        ],
        targetPos: const Offset(0.82, 0.18),
        targetMoves: true,
        hint: 'EXPERT — FEEL THE CURVES',
      ),
    ];
  }

  _CannonLevel get _currentLevel =>
      _levels[_level.clamp(0, _levels.length - 1)];
  double get _targetRadius =>
      (_kTargetBaseRadius - _level * _kTargetRadiusShrinkPerLevel)
          .clamp(10.0, _kTargetBaseRadius);

  Offset _targetPx(Size size) {
    final base = _currentLevel.targetPos;
    if (_currentLevel.targetMoves) {
      return Offset(base.dx * size.width + _targetDrift, base.dy * size.height);
    }
    return Offset(base.dx * size.width, base.dy * size.height);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('orbit_catch_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('orbit_catch_high_score', s);
  }

  void _startGame() {
    setState(() {
      _waitingToStart = false;
      _newBest = false;
      _score = 0;
      _level = 0;
      _shotsLeft = _kShotsPerLevel;
      _timeLeft = _kTotalGameSeconds;
      _targetDrift = 0.0;
      _targetDriftDir = 1.0;
      _projectile = null;
      _fxParticles.clear();
      _pops.clear();
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── main tick ──────────────────────────────────────────────────────────────
  void _tick() {
    if (_gameOver || _waitingToStart) return;
    const dt = 1 / 60.0;
    setState(() {
      _t += dt;
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _endGame();
        return;
      }

      // Moving target drift
      if (_currentLevel.targetMoves && _canvasSize != Size.zero) {
        _targetDrift += _targetDriftDir * _kTargetMoveSpeed * dt;
        final maxDrift = _canvasSize.width * 0.10;
        if (_targetDrift.abs() > maxDrift) {
          _targetDriftDir = -_targetDriftDir;
          _targetDrift = _targetDrift.sign * maxDrift;
        }
      }

      // Advance missile physics
      if (_projectile != null && _projectile!.alive) {
        _advanceProjectile(_projectile!, dt);
      }

      // Step FxParticles
      _fxParticles.removeWhere((p) => !p.step(dt));

      // Step score pops
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── physics — high G, 8 sub-steps for accuracy ────────────────────────────
  void _advanceProjectile(_Projectile proj, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    const subSteps = 8; // more sub-steps = more accurate curves
    final subDt = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      for (final body in _currentLevel.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final dx = bx - proj.x;
        final dy = by - proj.y;
        // Clamp minimum distance to avoid singularity (but keep it low enough
        // that gravity feels strong very close to body surface).
        final distSq = (dx * dx + dy * dy).clamp(400.0, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        proj.vx += (dx / dist) * force * subDt;
        proj.vy += (dy / dist) * force * subDt;

        // Collision with body surface
        if (dist < body.radius + _kProjectileRadius) {
          proj.alive = false;
          _spawnBurst(Offset(proj.x, proj.y), Potatuhs.orange, 16);
          return;
        }
      }

      proj.x += proj.vx * subDt;
      proj.y += proj.vy * subDt;

      // Record trail (every sub-step)
      proj.trail.add(Offset(proj.x, proj.y));
      if (proj.trail.length > 55) proj.trail.removeAt(0);

      // Hit target?
      final tpx = _targetPx(size);
      final tdx = proj.x - tpx.dx;
      final tdy = proj.y - tpx.dy;
      if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
        proj.alive = false;
        _onHit(tpx);
        return;
      }

      // Out of bounds
      if (proj.x < -100 || proj.x > size.width + 100 ||
          proj.y < -100 || proj.y > size.height + 100) {
        proj.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _onHit(Offset tpx) {
    final timeBonus = (_timeLeft / _kTotalGameSeconds * 60).round();
    final shotBonus = _shotsLeft * _kBonusPerExtraShot;
    final pts = _kPointsPerHit + timeBonus + shotBonus;
    _score += pts;

    // Big particle burst at target
    _spawnBurst(tpx, Potatuhs.gold, 24);
    _spawnBurst(tpx, Potatuhs.airForce, 14);

    // Floating score pop
    _pops.add(FxPop(tpx, '+$pts', Potatuhs.gold));

    _level++;
    _shotsLeft = _kShotsPerLevel;
    _targetDrift = 0.0;
    _targetDriftDir = 1.0;
    _projectile = null;
  }

  void _onMiss() {
    _shotsLeft--;
    if (_shotsLeft <= 0) {
      if (_level > 0) _level--;
      _shotsLeft = _kShotsPerLevel;
    }
    _projectile = null;
  }

  void _endGame() {
    _gameOver = true;
    if (_score > _highScore) {
      _highScore = _score;
      _newBest = true;
      _saveHighScore(_score);
    }
    _ctrl.stop();
  }

  // ── aiming input ───────────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails d) {
    if (_gameOver || _waitingToStart) return;
    if (_projectile != null && _projectile!.alive) return;
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() {
      _dragCurrent = d.localPosition;
    });
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragStart == null || _dragCurrent == null) return;
    if (_canvasSize == Size.zero) return;
    final cannonPx = Offset(
        _cannonFrac.dx * _canvasSize.width, _cannonFrac.dy * _canvasSize.height);
    final dx = _dragStart!.dx - _dragCurrent!.dx;
    final dy = _dragStart!.dy - _dragCurrent!.dy;
    final dragLen = sqrt(dx * dx + dy * dy).clamp(1.0, 200.0);
    final rawSpeed =
        (dragLen * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    final nx = dx / dragLen;
    final ny = dy / dragLen;
    setState(() {
      _projectile = _Projectile(
          x: cannonPx.dx, y: cannonPx.dy, vx: nx * rawSpeed, vy: ny * rawSpeed);
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  // ── trajectory preview — uses same gravity sim ─────────────────────────────
  List<Offset> _buildPreview(Size size) {
    if (!_isDragging) return [];
    final cannonPx = Offset(
        _cannonFrac.dx * size.width, _cannonFrac.dy * size.height);
    final dx = _dragStart!.dx - _dragCurrent!.dx;
    final dy = _dragStart!.dy - _dragCurrent!.dy;
    final dragLen = sqrt(dx * dx + dy * dy).clamp(1.0, 200.0);
    final rawSpeed =
        (dragLen * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    final nx = dx / dragLen;
    final ny = dy / dragLen;

    double px = cannonPx.dx, py = cannonPx.dy;
    double vx = nx * rawSpeed, vy = ny * rawSpeed;
    final pts = <Offset>[];

    for (int i = 0; i < _kPreviewSteps; i++) {
      for (final body in _currentLevel.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final ddx = bx - px;
        final ddy = by - py;
        final distSq = (ddx * ddx + ddy * ddy).clamp(400.0, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        vx += (ddx / dist) * force * _kPreviewDt;
        vy += (ddy / dist) * force * _kPreviewDt;
      }
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      if (px < -100 || px > size.width + 100 ||
          py < -100 || py > size.height + 100) break;
    }
    return pts;
  }

  // ── FX helpers ─────────────────────────────────────────────────────────────
  void _spawnBurst(Offset at, Color color, int count) {
    _fxParticles.addAll(
        FxBurst.spawn(at, color, count: count, speed: 160, size: 4));
  }

  void _restart() {
    _ctrl.reset();
    setState(() {
      _waitingToStart = true;
      _gameOver = false;
      _score = 0;
      _level = 0;
      _shotsLeft = _kShotsPerLevel;
      _timeLeft = _kTotalGameSeconds;
      _newBest = false;
      _projectile = null;
      _fxParticles.clear();
      _pops.clear();
      _dragStart = null;
      _dragCurrent = null;
      _targetDrift = 0.0;
      _targetDriftDir = 1.0;
      _t = 0.0;
    });
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanStart: (d) {
          if (_waitingToStart) {
            _startGame();
            return;
          }
          _onDragStart(d);
        },
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onTapDown: (d) {
          if (_waitingToStart) _startGame();
        },
        child: CustomPaint(
          painter: _GravityPuzzlePainter(
            cannonFrac: _cannonFrac,
            level: _currentLevel,
            targetPos: _targetPx(_canvasSize),
            targetRadius: _targetRadius,
            projectile: _projectile,
            fxParticles: _fxParticles,
            pops: _pops,
            preview: _buildPreview(_canvasSize),
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            t: _t,
          ),
          child: Stack(children: [
            // ── HUD ──────────────────────────────────────────────────────
            if (!_waitingToStart && !_gameOver) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Potatuhs.inkDeep.withValues(alpha: 0.92),
                        Potatuhs.inkDeep.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shot pips
                      Row(
                        children: List.generate(
                          _kShotsPerLevel,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: i < _shotsLeft
                                  ? Potatuhs.gold
                                  : Colors.white12,
                            ),
                          ),
                        ),
                      ),
                      // Timer
                      Text(
                        '${_timeLeft.ceil()}s',
                        style: TextStyle(
                          fontFamily: Potatuhs.bodyFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _timeLeft < 8
                              ? Colors.redAccent
                              : Potatuhs.textSecondary,
                        ),
                      ),
                      // Score + level
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_score',
                            style: TextStyle(
                              fontFamily: Potatuhs.bodyFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Potatuhs.textPrimary,
                            ),
                          ),
                          Text(
                            'Lv ${_level + 1}',
                            style: TextStyle(
                              fontFamily: Potatuhs.bodyFont,
                              fontSize: 10,
                              color: Potatuhs.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Hint banner
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentLevel.hint,
                      style: TextStyle(
                        fontFamily: Potatuhs.displayFont,
                        fontSize: 12,
                        color: Potatuhs.gold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── Start screen ─────────────────────────────────────────────
            if (_waitingToStart)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ORBIT CATCH',
                      style: TextStyle(
                        fontFamily: Potatuhs.displayFont,
                        fontSize: 30,
                        color: Potatuhs.gold,
                        shadows: [
                          Shadow(
                              color: Potatuhs.gold.withValues(alpha: 0.6),
                              blurRadius: 18)
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Drag to aim the cannon.\nBig planets = strong gravity.\nCurve the missile to hit the target!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Potatuhs.bodyFont,
                        fontSize: 14,
                        color: Potatuhs.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_highScore > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Best: $_highScore',
                          style: TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontSize: 14,
                            color: Potatuhs.sienna,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: Potatuhs.ctaGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Potatuhs.orange.withValues(alpha: 0.4),
                              blurRadius: 16)
                        ],
                      ),
                      child: Text(
                        'TAP TO PLAY',
                        style: TextStyle(
                          fontFamily: Potatuhs.displayFont,
                          fontSize: 15,
                          color: Potatuhs.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Game over screen ──────────────────────────────────────────
            if (_gameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TIME\'S UP',
                      style: TextStyle(
                        fontFamily: Potatuhs.displayFont,
                        fontSize: 26,
                        color: Potatuhs.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_score pts',
                      style: TextStyle(
                        fontFamily: Potatuhs.displayFont,
                        fontSize: 36,
                        color: Potatuhs.gold,
                        shadows: [
                          Shadow(
                              color: Potatuhs.gold.withValues(alpha: 0.5),
                              blurRadius: 20)
                        ],
                      ),
                    ),
                    if (_newBest)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'NEW BEST!',
                          style: TextStyle(
                            fontFamily: Potatuhs.displayFont,
                            fontSize: 16,
                            color: Potatuhs.orange,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Best: $_highScore',
                      style: TextStyle(
                        fontFamily: Potatuhs.bodyFont,
                        fontSize: 13,
                        color: Potatuhs.textFaint,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: Potatuhs.ctaGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                                color: Potatuhs.orange.withValues(alpha: 0.4),
                                blurRadius: 14)
                          ],
                        ),
                        child: Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            fontFamily: Potatuhs.displayFont,
                            fontSize: 14,
                            color: Potatuhs.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
      );
    });
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _GravityPuzzlePainter extends CustomPainter {
  final Offset cannonFrac;
  final _CannonLevel level;
  final Offset targetPos; // already in canvas px
  final double targetRadius;
  final _Projectile? projectile;
  final List<FxParticle> fxParticles;
  final List<FxPop> pops;
  final List<Offset> preview;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final double t; // seconds clock for atmosphere animation

  _GravityPuzzlePainter({
    required this.cannonFrac,
    required this.level,
    required this.targetPos,
    required this.targetRadius,
    required this.projectile,
    required this.fxParticles,
    required this.pops,
    required this.preview,
    required this.dragStart,
    required this.dragCurrent,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Atmospheric background ─────────────────────────────────────────────
    // Accent: blend of airForce/glaucous — space blue tint
    GameFx.atmosphere(canvas, size, Potatuhs.airForce, t, motes: 48);

    final cannonPx =
        Offset(cannonFrac.dx * size.width, cannonFrac.dy * size.height);

    // ── Gravity bodies — drawn large→small so smaller bodies read on top ───
    final sortedBodies = List<_GravBody>.from(level.bodies)
      ..sort((a, b) => b.radius.compareTo(a.radius)); // large first

    for (final body in sortedBodies) {
      final bPos = Offset(body.pos.dx * size.width, body.pos.dy * size.height);

      // Gravity influence rings — scaled to mass so big bodies show wide reach
      final ringCount = 5;
      final ringSpacing = body.radius * 0.55;
      for (int r = ringCount; r >= 1; r--) {
        canvas.drawCircle(
          bPos,
          body.radius + r * ringSpacing,
          Paint()
            ..color = body.color.withValues(alpha: 0.018 * r)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
      }

      // Atmosphere rim — size signals gravity to player
      canvas.drawCircle(
        bPos,
        body.radius + 10,
        Paint()
          ..color = body.color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Shaded orb body via GameFx.orb
      GameFx.orb(canvas, bPos, body.radius, body.color,
          glow: 1.3, specular: true);

      // Saturn-style ring for the GIANT body (radius > 40)
      if (body.radius >= 40) {
        final ringPaint = Paint()
          ..color = body.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.save();
        canvas.translate(bPos.dx, bPos.dy);
        canvas.scale(1.0, 0.30); // flatten to ellipse
        canvas.drawCircle(Offset.zero, body.radius * 1.55, ringPaint);
        canvas.restore();
      }

      // Size label — tiny, brand font
      if (body.label.isNotEmpty) {
        GameFx.text(
          canvas,
          body.label,
          bPos.translate(0, body.radius + 14),
          9,
          body.color.withValues(alpha: 0.75),
        );
      }
    }

    // ── Target ─────────────────────────────────────────────────────────────
    // Pulsing outer ring (animated via t)
    final pulse = 0.5 + 0.5 * sin(t * 3.5);
    canvas.drawCircle(
      targetPos,
      targetRadius + 10 + pulse * 4,
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.12 + 0.08 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Gold orb as target
    GameFx.orb(canvas, targetPos, targetRadius, Potatuhs.gold,
        glow: 1.5 + pulse * 0.5, rim: Potatuhs.sienna, specular: true);
    // Crosshair
    final ch = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(targetPos.translate(-10, 0), targetPos.translate(10, 0), ch);
    canvas.drawLine(targetPos.translate(0, -10), targetPos.translate(0, 10), ch);

    // ── Cannon — layered orb base + glowing barrel ─────────────────────────
    double barrelAngle = -pi / 4;
    if (dragStart != null && dragCurrent != null) {
      final ddx = dragStart!.dx - dragCurrent!.dx;
      final ddy = dragStart!.dy - dragCurrent!.dy;
      barrelAngle = atan2(ddy, ddx);
    } else if (projectile != null) {
      barrelAngle = atan2(projectile!.vy, projectile!.vx);
    }
    const barrelLen = 30.0;
    final barrelEnd = Offset(
      cannonPx.dx + cos(barrelAngle) * barrelLen,
      cannonPx.dy + sin(barrelAngle) * barrelLen,
    );

    // Barrel glow + core
    GameFx.glowLine(canvas, cannonPx, barrelEnd, Potatuhs.airForce,
        width: 5, progress: 1.0);

    // Cannon base as shaded orb
    GameFx.orb(canvas, cannonPx, 15, Potatuhs.inkPanel,
        glow: 0.6, rim: Potatuhs.airForce, specular: false);

    // ── Drag aim indicator ─────────────────────────────────────────────────
    if (dragStart != null && dragCurrent != null) {
      final ddx = dragStart!.dx - dragCurrent!.dx;
      final ddy = dragStart!.dy - dragCurrent!.dy;
      final dragLen = sqrt(ddx * ddx + ddy * ddy).clamp(1.0, 200.0);
      final powerFrac = (dragLen / 200.0).clamp(0.0, 1.0);
      final aimColor = Color.lerp(Potatuhs.airForce, Potatuhs.gold, powerFrac)!;

      // Drag vector line
      canvas.drawLine(
        dragStart!,
        dragCurrent!,
        Paint()
          ..color = aimColor.withValues(alpha: 0.30)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );

      // Power arc
      final arcRect = Rect.fromCircle(center: cannonPx, radius: 24);
      canvas.drawArc(
        arcRect,
        -pi,
        pi * powerFrac,
        false,
        Paint()
          ..color = aimColor.withValues(alpha: 0.75)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Trajectory preview dots — curvy arc reveals the puzzle ────────────
    if (preview.isNotEmpty) {
      for (int i = 0; i < preview.length; i++) {
        final frac = i / preview.length;
        final alpha = (1.0 - frac) * 0.60;
        final r = (2.8 - frac * 1.8).clamp(0.5, 2.8);
        canvas.drawCircle(
          preview[i],
          r,
          Paint()..color = Potatuhs.airForce.withValues(alpha: alpha),
        );
      }
    }

    // ── Missile trail ──────────────────────────────────────────────────────
    if (projectile != null) {
      final trail = projectile!.trail;
      for (int i = 1; i < trail.length; i++) {
        final frac = i / trail.length;
        // Glow pass
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = Potatuhs.airForce.withValues(alpha: frac * 0.35)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Core
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = Colors.white.withValues(alpha: frac * 0.7)
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round,
        );
      }

      // Missile orb
      if (projectile!.alive) {
        final mPos = Offset(projectile!.x, projectile!.y);
        GameFx.orb(canvas, mPos, _kProjectileRadius, Potatuhs.glaucous,
            glow: 1.8, rim: Colors.white, specular: true);
      }
    }

    // ── FX particles ───────────────────────────────────────────────────────
    FxBurst.paint(canvas, fxParticles);

    // ── Score pops ─────────────────────────────────────────────────────────
    for (final pop in pops) {
      pop.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _GravityPuzzlePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. SolarSortGame — "Scale the System"
// Draw two circles at the right relative size to compare solar system neighbors.
// Score by how close your drawn radius ratio matches the true ratio.
// Finish with a spiral-spam protoplanetary disk finale.
// ═══════════════════════════════════════════════════════════════════════════════

// ── SolarSortGame — "Scale the System" ────────────────────────────────────────
// Relative-size drawing challenge: each round names two bodies; player draws
// two freehand circles. Score = accuracy of the radius ratio on a log scale.
// Spiral finale (original mechanic) closes the game as the protoplanetary disk.
// ──────────────────────────────────────────────────────────────────────────────

// ── Constants ─────────────────────────────────────────────────────────────────
const int _kStsBasePoints = 500;   // max points per size-ratio round
const int _kStsFinaleBasePoints = 100; // per revolution in finale
const double _kStsFinaleDecay = 0.85;  // per-attempt decay in finale
const int _kStsFinaleSeconds = 20;     // duration of the spiral finale
// Intersection skip + tolerance (reused for finale spiral)
const int _kStsSkipHead = 6;
const double _kStsTol = 0.01;

// ── Body data ──────────────────────────────────────────────────────────────────
class _StsBody {
  final String name;
  final double radiusKm;
  final Color color;
  const _StsBody(this.name, this.radiusKm, this.color);
}

const _kStsBodies = <_StsBody>[
  _StsBody('Sun',     696340, Color(0xFFFFD700)),
  _StsBody('Mercury',   2440, Color(0xFFB0A090)),
  _StsBody('Venus',     6052, Color(0xFFE8C56A)),
  _StsBody('Earth',     6371, Color(0xFF4A9EEB)),
  _StsBody('Mars',      3390, Color(0xFFCF6030)),
  _StsBody('Jupiter',  69911, Color(0xFFD4A96A)),
  _StsBody('Saturn',   58232, Color(0xFFC8B870)),
  _StsBody('Uranus',   25362, Color(0xFF7DE8E8)),
  _StsBody('Neptune',  24622, Color(0xFF4060E0)),
];

// Round pairs: adjacent neighbors Sun→Mercury … Uranus→Neptune
const _kStsRoundPairs = <List<int>>[
  [0, 1], // Sun, Mercury
  [1, 2], // Mercury, Venus
  [2, 3], // Venus, Earth
  [3, 4], // Earth, Mars
  [4, 5], // Mars, Jupiter
  [5, 6], // Jupiter, Saturn
  [6, 7], // Saturn, Uranus
  [7, 8], // Uranus, Neptune
];

// One fact per round (index matches _kStsRoundPairs)
const _kStsFacts = <String>[
  '~285 Mercurys would span the Sun — you literally cannot draw this to scale.',
  'Mercury is the smallest planet, smaller than some moons.',
  'Venus is Earth\'s near-twin — almost the same size.',
  'Mars is about half Earth\'s width — smaller than it looks in the night sky.',
  'Jupiter is over 11 Earths wide — a monster.',
  'Saturn\'s rings span wider than the gap between Earth and the Moon.',
  'Uranus rotates on its side — its axis is tilted 98°.',
  'Neptune and Uranus are almost twins — just 740 km apart in radius.',
];

// ── Utility: fit a circle to a list of offsets ────────────────────────────────
// Returns (centroid, meanRadius). Returns null if fewer than 3 points.
(Offset, double)? _fitCircle(List<Offset> pts) {
  if (pts.length < 3) return null;
  double cx = 0, cy = 0;
  for (final p in pts) { cx += p.dx; cy += p.dy; }
  cx /= pts.length;
  cy /= pts.length;
  double r = 0;
  for (final p in pts) {
    final d = sqrt((p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy));
    r += d;
  }
  r /= pts.length;
  return (Offset(cx, cy), r);
}

// ── Draw phase enum ───────────────────────────────────────────────────────────
enum _StsDrawPhase { drawA, drawB }

// ── Game phase enum ───────────────────────────────────────────────────────────
enum _StsGamePhase { start, round, reveal, finale, gameOver }

// ─────────────────────────────────────────────────────────────────────────────

class SolarSortGame extends StatefulWidget {
  const SolarSortGame({Key? key}) : super(key: key);
  @override
  State<SolarSortGame> createState() => _SolarSortGameState();
}

class _SolarSortGameState extends State<SolarSortGame>
    with SingleTickerProviderStateMixin {

  // ── phase / round ──────────────────────────────────────────────────────────
  _StsGamePhase _phase = _StsGamePhase.start;
  int _roundIndex = 0;          // 0..7 for the 8 size rounds
  int _totalScore = 0;

  // ── current round drawing ──────────────────────────────────────────────────
  _StsDrawPhase _drawPhase = _StsDrawPhase.drawA;
  final List<Offset> _currentPath = [];

  // Committed circles for this round
  Offset? _circleACenter;
  double _circleARadius = 0;
  Offset? _circleBCenter;
  double _circleBRadius = 0;

  // Reveal state
  int _lastRoundScore = 0;
  bool _lastWasPerfect = false;
  String _lastRatioText = '';
  String _lastFact = '';

  // ── finale (spiral) state ─────────────────────────────────────────────────
  int _finaleSecondsLeft = _kStsFinaleSeconds;
  bool _finaleTimerActive = false;
  DateTime? _finaleStart;
  int _finaleScore = 0;
  int _finaleAttempt = 0;        // 1-based; for decay
  bool _finaleFlash = false;

  final List<Offset> _spiralPath = [];
  double _spiralAccAngle = 0;
  double? _spiralPrevAngle = 0;
  double _spiralCX = 0, _spiralCY = 0;

  // ── animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── game flow ──────────────────────────────────────────────────────────────

  void _startGame() {
    setState(() {
      _phase = _StsGamePhase.round;
      _roundIndex = 0;
      _totalScore = 0;
      _drawPhase = _StsDrawPhase.drawA;
      _currentPath.clear();
      _circleACenter = null;
      _circleBCenter = null;
    });
  }

  void _restartGame() => _startGame();

  void _advanceRound() {
    if (_roundIndex + 1 >= _kStsRoundPairs.length) {
      // All rounds done — enter finale
      _enterFinale();
    } else {
      setState(() {
        _roundIndex++;
        _phase = _StsGamePhase.round;
        _drawPhase = _StsDrawPhase.drawA;
        _currentPath.clear();
        _circleACenter = null;
        _circleBCenter = null;
      });
    }
  }

  void _enterFinale() {
    setState(() {
      _phase = _StsGamePhase.finale;
      _finaleSecondsLeft = _kStsFinaleSeconds;
      _finaleTimerActive = true;
      _finaleStart = DateTime.now();
      _finaleScore = 0;
      _finaleAttempt = 0;
      _finaleFlash = false;
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
    _finaleTick();
  }

  void _finaleTick() {
    if (!mounted || !_finaleTimerActive) return;
    final elapsed = DateTime.now().difference(_finaleStart!).inSeconds;
    final left = _kStsFinaleSeconds - elapsed;
    if (left <= 0) {
      setState(() {
        _finaleSecondsLeft = 0;
        _finaleTimerActive = false;
        _totalScore += _finaleScore;
        _phase = _StsGamePhase.gameOver;
      });
      return;
    }
    setState(() => _finaleSecondsLeft = left);
    Future.delayed(const Duration(seconds: 1), _finaleTick);
  }

  // ── scoring ────────────────────────────────────────────────────────────────

  int _scoreRound(double drawnA, double drawnB) {
    final pair = _kStsRoundPairs[_roundIndex];
    final trueA = _kStsBodies[pair[0]].radiusKm;
    final trueB = _kStsBodies[pair[1]].radiusKm;
    final trueRatio = trueB / trueA;   // B relative to A
    final drawnRatio = drawnB / drawnA;

    // Log-scale accuracy: log(drawn/true) — 0 is perfect.
    // Tolerance window: ±1 natural-log unit gives ~37%–273% of correct; clamp.
    final logError = (log(drawnRatio) - log(trueRatio)).abs();
    // accuracy: 1 at logError=0, falls to 0 at logError≥1.5
    final accuracy = (1.0 - (logError / 1.5)).clamp(0.0, 1.0);
    return (_kStsBasePoints * accuracy).round();
  }

  bool _isPerfect(double drawnA, double drawnB) {
    final pair = _kStsRoundPairs[_roundIndex];
    final trueA = _kStsBodies[pair[0]].radiusKm;
    final trueB = _kStsBodies[pair[1]].radiusKm;
    final trueRatio = trueB / trueA;
    final drawnRatio = drawnB / drawnA;
    final logError = (log(drawnRatio) - log(trueRatio)).abs();
    return logError < 0.12; // within ~12% log-error → "PERFECT SCALE"
  }

  // ── drawing handlers (size rounds) ────────────────────────────────────────

  void _onSizePanStart(DragStartDetails d) {
    if (_phase != _StsGamePhase.round) return;
    setState(() {
      _currentPath.clear();
      _currentPath.add(d.localPosition);
    });
  }

  void _onSizePanUpdate(DragUpdateDetails d) {
    if (_phase != _StsGamePhase.round) return;
    setState(() => _currentPath.add(d.localPosition));
  }

  void _onSizePanEnd(DragEndDetails _) {
    if (_phase != _StsGamePhase.round) return;
    final fit = _fitCircle(List.of(_currentPath));
    if (fit == null) {
      setState(() => _currentPath.clear());
      return;
    }
    final (center, radius) = fit;
    if (_drawPhase == _StsDrawPhase.drawA) {
      setState(() {
        _circleACenter = center;
        _circleARadius = radius;
        _drawPhase = _StsDrawPhase.drawB;
        _currentPath.clear();
      });
    } else {
      // Both circles drawn — score and reveal
      _circleBCenter = center;
      _circleBRadius = radius;
      final score = _scoreRound(_circleARadius, _circleBRadius);
      final perfect = _isPerfect(_circleARadius, _circleBRadius);
      final pair = _kStsRoundPairs[_roundIndex];
      final trueA = _kStsBodies[pair[0]].radiusKm;
      final trueB = _kStsBodies[pair[1]].radiusKm;
      final ratio = trueB / trueA;
      final ratioText = ratio >= 1
          ? '1 : ${ratio.toStringAsFixed(1)}'
          : '${(1 / ratio).toStringAsFixed(1)} : 1';
      setState(() {
        _lastRoundScore = score;
        _lastWasPerfect = perfect;
        _lastRatioText = ratioText;
        _lastFact = _kStsFacts[_roundIndex];
        _totalScore += score;
        _phase = _StsGamePhase.reveal;
        _currentPath.clear();
      });
    }
  }

  // ── drawing handlers (finale spiral) ──────────────────────────────────────

  void _onSpiralPanStart(DragStartDetails d) {
    if (_phase != _StsGamePhase.finale || !_finaleTimerActive) return;
    _finaleAttempt++;
    setState(() {
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
      _spiralCX = d.localPosition.dx;
      _spiralCY = d.localPosition.dy;
      _spiralPath.add(d.localPosition);
    });
  }

  void _onSpiralPanUpdate(DragUpdateDetails d) {
    if (_phase != _StsGamePhase.finale || !_finaleTimerActive) return;
    final pt = d.localPosition;
    if (_spiralPath.length >= _kStsSkipHead + 1) {
      if (_spiralCheckIntersection(pt)) {
        _triggerFinaleBreak();
        return;
      }
    }
    _spiralPath.add(pt);
    final n = _spiralPath.length.toDouble();
    _spiralCX = (_spiralCX * (n - 1) + pt.dx) / n;
    _spiralCY = (_spiralCY * (n - 1) + pt.dy) / n;
    final dx = pt.dx - _spiralCX;
    final dy = pt.dy - _spiralCY;
    final ang = atan2(dy, dx);
    if (_spiralPrevAngle != null) {
      double delta = ang - _spiralPrevAngle!;
      if (delta > pi) delta -= 2 * pi;
      if (delta <= -pi) delta += 2 * pi;
      _spiralAccAngle += delta;
    }
    _spiralPrevAngle = ang;
    setState(() {
      _finaleScore = _spiralFinaleScore();
    });
  }

  void _onSpiralPanEnd(DragEndDetails _) {
    if (_phase != _StsGamePhase.finale) return;
    setState(() {
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
  }

  void _triggerFinaleBreak() {
    setState(() {
      _finaleFlash = true;
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _finaleFlash = false);
    });
  }

  int get _spiralRevolutions => (_spiralAccAngle.abs() / (2 * pi)).floor();

  int _spiralFinaleScore() {
    final revs = _spiralRevolutions;
    if (revs <= 0) return 0;
    final multiplier = pow(_kStsFinaleDecay, _finaleAttempt - 1).toDouble();
    return (revs * _kStsFinaleBasePoints * multiplier).round();
  }

  bool _spiralCheckIntersection(Offset newPt) {
    if (_spiralPath.length < 2) return false;
    final ax = _spiralPath[_spiralPath.length - 1].dx;
    final ay = _spiralPath[_spiralPath.length - 1].dy;
    final bx = newPt.dx, by = newPt.dy;
    final lastSafe = _spiralPath.length - 1 - _kStsSkipHead;
    if (lastSafe < 1) return false;
    for (int i = 0; i < lastSafe - 1; i++) {
      final cx2 = _spiralPath[i].dx, cy2 = _spiralPath[i].dy;
      final dx2 = _spiralPath[i + 1].dx, dy2 = _spiralPath[i + 1].dy;
      final rX = bx - ax, rY = by - ay;
      final sX = dx2 - cx2, sY = dy2 - cy2;
      final denom = rX * sY - rY * sX;
      if (denom.abs() < 1e-10) continue;
      final qX = cx2 - ax, qY = cy2 - ay;
      final t = (qX * sY - qY * sX) / denom;
      final u = (qX * rY - qY * rX) / denom;
      if (t > _kStsTol && t < 1.0 - _kStsTol &&
          u > _kStsTol && u < 1.0 - _kStsTol) return true;
    }
    return false;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _StsGamePhase.start:    return _buildStart();
      case _StsGamePhase.round:    return _buildRound();
      case _StsGamePhase.reveal:   return _buildReveal();
      case _StsGamePhase.finale:   return _buildFinale();
      case _StsGamePhase.gameOver: return _buildGameOver();
    }
  }

  // ── start screen ──────────────────────────────────────────────────────────

  Widget _buildStart() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Scale the System',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 26,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 16),
              const Text(
                'Each round names two solar system bodies.\n'
                'Draw a circle for each — get the SIZE RATIO right.\n\n'
                'Score by how close your ratio matches reality.\n'
                'Finish with a spinning protoplanetary disk.\n\n'
                'Prepare to be humbled.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                  color: Colors.white60, height: 1.6),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Text('START', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.amberAccent, letterSpacing: 2)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── round screen ─────────────────────────────────────────────────────────

  Widget _buildRound() {
    final pair = _kStsRoundPairs[_roundIndex];
    final bodyA = _kStsBodies[pair[0]];
    final bodyB = _kStsBodies[pair[1]];
    final isDrawingA = _drawPhase == _StsDrawPhase.drawA;
    final activeBody = isDrawingA ? bodyA : bodyB;

    return GestureDetector(
      onPanStart: _onSizePanStart,
      onPanUpdate: _onSizePanUpdate,
      onPanEnd: _onSizePanEnd,
      child: Container(
        color: const Color(0xFF050515),
        child: Stack(children: [
          // Canvas: committed circles + live stroke
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _StsRoundPainter(
                  circleACenter: _circleACenter,
                  circleARadius: _circleARadius,
                  colorA: bodyA.color,
                  circleBCenter: _circleBCenter,
                  circleBRadius: _circleBRadius,
                  colorB: bodyB.color,
                  livePath: List.unmodifiable(_currentPath),
                  activeColor: activeBody.color,
                  pulseValue: _pulseAnim.value,
                  showA: true,
                ),
              ),
            ),
          ),

          // Top HUD
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StsHudChip(
                      label: 'ROUND',
                      value: '${_roundIndex + 1} / ${_kStsRoundPairs.length}',
                      urgent: false,
                    ),
                    _StsHudChip(
                      label: 'SCORE',
                      value: '$_totalScore',
                      urgent: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Prompt
          Positioned(
            bottom: 60, left: 24, right: 24,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: isDrawingA ? 1.0 : _pulseAnim.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    isDrawingA
                        ? 'Draw the ${bodyA.name}'
                        : 'Now draw the ${bodyB.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: activeBody.color,
                    ),
                  ),
                  if (!isDrawingA) ...[
                    const SizedBox(height: 6),
                    Text(
                      'vs ${bodyA.name} (circle already drawn)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 13, color: Colors.white38),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── reveal screen ─────────────────────────────────────────────────────────

  Widget _buildReveal() {
    final pair = _kStsRoundPairs[_roundIndex];
    final bodyA = _kStsBodies[pair[0]];
    final bodyB = _kStsBodies[pair[1]];
    final isLastRound = _roundIndex + 1 >= _kStsRoundPairs.length;

    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Stack(children: [
          // Show the two drawn circles dimmed in background
          Positioned.fill(
            child: CustomPaint(
              painter: _StsRoundPainter(
                circleACenter: _circleACenter,
                circleARadius: _circleARadius,
                colorA: bodyA.color.withValues(alpha: 0.3),
                circleBCenter: _circleBCenter,
                circleBRadius: _circleBRadius,
                colorB: bodyB.color.withValues(alpha: 0.3),
                livePath: const [],
                activeColor: Colors.transparent,
                pulseValue: 0.5,
                showA: true,
              ),
            ),
          ),

          // Reveal card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_lastWasPerfect) ...[
                  Text('PERFECT SCALE',
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                      shadows: [Shadow(color: Colors.amberAccent.withValues(alpha: 0.7), blurRadius: 12)],
                    )),
                  const SizedBox(height: 8),
                ] else ...[
                  Text('+$_lastRoundScore',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 36,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                ],
                if (_lastWasPerfect)
                  Text('+$_lastRoundScore pts',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 22,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                // True ratio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${bodyA.name} : ${bodyB.name}',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 13,
                        color: Colors.white54, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'True ratio  $_lastRatioText',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 17,
                        fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                // Fact
                Text(
                  _lastFact,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Avenir', fontSize: 13,
                    color: Colors.white60, height: 1.5),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _advanceRound,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      isLastRound ? 'FINALE' : 'NEXT ROUND',
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent, letterSpacing: 2),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── finale screen ─────────────────────────────────────────────────────────

  Widget _buildFinale() {
    return GestureDetector(
      onPanStart: _onSpiralPanStart,
      onPanUpdate: _onSpiralPanUpdate,
      onPanEnd: _onSpiralPanEnd,
      child: Container(
        color: _finaleFlash ? const Color(0x22FF4444) : const Color(0xFF050515),
        child: Stack(children: [
          // Spiral canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _StsSpiralPainter(
                  points: List.unmodifiable(_spiralPath),
                  revolutions: _spiralRevolutions,
                  flashBreak: _finaleFlash,
                  pulseValue: _pulseAnim.value,
                ),
              ),
            ),
          ),

          // HUD
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StsHudChip(
                      label: 'TIME',
                      value: '$_finaleSecondsLeft s',
                      urgent: _finaleSecondsLeft <= 8,
                    ),
                    _StsHudChip(
                      label: 'LOOPS',
                      value: '$_spiralRevolutions',
                      urgent: false,
                    ),
                    _StsHudChip(
                      label: 'BONUS',
                      value: '+$_finaleScore',
                      urgent: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Finale label
          Positioned(
            bottom: 60, left: 24, right: 24,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: const Text(
                    'PROTOPLANETARY DISK',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 18,
                      fontWeight: FontWeight.bold, color: Colors.amberAccent,
                      letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spin as many spirals as you can!\nCross your path and it resets.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 13,
                  color: Colors.white38, height: 1.5),
              ),
            ]),
          ),

          if (_finaleFlash)
            Center(
              child: Text('CROSSED!',
                style: TextStyle(
                  fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  letterSpacing: 3)),
            ),

          if (_spiralPath.isEmpty)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: const Text('Draw a spiral',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 18,
                      color: Colors.white24)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── game-over screen ──────────────────────────────────────────────────────

  Widget _buildGameOver() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Scale the System',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 6),
              const Text('COMPLETE',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                  color: Colors.white38, letterSpacing: 3)),
              const SizedBox(height: 24),
              _StsScoreLine(label: 'Final Score', value: '$_totalScore'),
              const SizedBox(height: 4),
              _StsScoreLine(
                label: 'Rounds',
                value: '${_kStsRoundPairs.length}',
              ),
              const SizedBox(height: 4),
              _StsScoreLine(label: 'Spiral Bonus', value: '+$_finaleScore'),
              const SizedBox(height: 12),
              const Text(
                'The Sun is 285× Mercury.\nVenus and Earth are near-twins.\n'
                'Jupiter is over 11 Earths wide.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 12,
                  color: Colors.white38, height: 1.6),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _restartGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Text('PLAY AGAIN', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.amberAccent, letterSpacing: 2)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── HUD chip ──────────────────────────────────────────────────────────────────
class _StsHudChip extends StatelessWidget {
  final String label;
  final String value;
  final bool urgent;
  const _StsHudChip({required this.label, required this.value, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: urgent
              ? Colors.redAccent.withValues(alpha: 0.7)
              : Colors.amberAccent.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          fontFamily: 'Avenir', fontSize: 9, letterSpacing: 1.2,
          color: urgent ? Colors.redAccent : Colors.white38)),
        Text(value, style: TextStyle(
          fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.bold,
          color: urgent ? Colors.redAccent : Colors.amberAccent)),
      ]),
    );
  }
}

// ── Score line ────────────────────────────────────────────────────────────────
class _StsScoreLine extends StatelessWidget {
  final String label;
  final String value;
  const _StsScoreLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(
        fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
      Text(value, style: const TextStyle(
        fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ]);
  }
}

// ── Round painter: draws committed circles A and B + live stroke ─────────────
class _StsRoundPainter extends CustomPainter {
  final Offset? circleACenter;
  final double circleARadius;
  final Color colorA;
  final Offset? circleBCenter;
  final double circleBRadius;
  final Color colorB;
  final List<Offset> livePath;
  final Color activeColor;
  final double pulseValue;
  final bool showA;

  const _StsRoundPainter({
    required this.circleACenter,
    required this.circleARadius,
    required this.colorA,
    required this.circleBCenter,
    required this.circleBRadius,
    required this.colorB,
    required this.livePath,
    required this.activeColor,
    required this.pulseValue,
    required this.showA,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw committed circle A
    if (showA && circleACenter != null && circleARadius > 0) {
      final fillPaint = Paint()
        ..color = colorA.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = colorA.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(circleACenter!, circleARadius, fillPaint);
      canvas.drawCircle(circleACenter!, circleARadius, strokePaint);
      // Label
      _drawLabel(canvas, circleACenter!, 'A', colorA);
    }

    // Draw committed circle B
    if (circleBCenter != null && circleBRadius > 0) {
      final fillPaint = Paint()
        ..color = colorB.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = colorB.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(circleBCenter!, circleBRadius, fillPaint);
      canvas.drawCircle(circleBCenter!, circleBRadius, strokePaint);
      _drawLabel(canvas, circleBCenter!, 'B', colorB);
    }

    // Draw live stroke
    if (livePath.length >= 2) {
      final livePaint = Paint()
        ..color = activeColor.withValues(alpha: 0.55 * pulseValue)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(livePath[0].dx, livePath[0].dy);
      for (int i = 1; i < livePath.length; i++) {
        path.lineTo(livePath[i].dx, livePath[i].dy);
      }
      canvas.drawPath(path, livePaint);
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StsRoundPainter old) => true;
}

// ── Spiral painter (finale) ───────────────────────────────────────────────────
class _StsSpiralPainter extends CustomPainter {
  final List<Offset> points;
  final int revolutions;
  final bool flashBreak;
  final double pulseValue;

  const _StsSpiralPainter({
    required this.points,
    required this.revolutions,
    required this.flashBreak,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final hue = (revolutions * 30.0) % 360;
    final strokeColor = flashBreak
        ? Colors.redAccent
        : HSVColor.fromAHSV(1.0, hue, 0.7, 0.95).toColor();

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.18 * pulseValue)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      points.last, 4,
      Paint()..color = strokeColor.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _StsSpiralPainter old) =>
      old.points.length != points.length ||
      old.revolutions != revolutions ||
      old.flashBreak != flashBreak ||
      old.pulseValue != pulseValue;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. GalaxyCollectorGame — "Star Collector"  (BioScale.galactic)
//    Stars drift across the galaxy — tap them before they escape!
//    Every star telegraphs its escape path with a ghost trail.
//    Tutorial: the first star is slow with a pulsing TAP ME prompt.
//    Escalation: wave 1 = 1 star, grows to 6+ at wave 4+, timing tightens.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Feel constants ─────────────────────────────────────────────────────────
// Game clock
const double _kGcGameDuration     = 60.0;  // total seconds

// Star sizes (pixel radius)
const double _kGcStarRadiusMin    = 18.0;
const double _kGcStarRadiusMax    = 30.0;  // bigger = easier tap target, smaller = harder

// Star lifetime: how many seconds it crosses the screen before escaping
const double _kGcLifeWave1        = 5.5;   // generous at first
const double _kGcLifeMin          = 2.0;   // floor — never instant

// Spawn interval (seconds between new stars)
const double _kGcSpawnWave1       = 3.0;
const double _kGcSpawnMin         = 0.55;

// Max simultaneous stars per wave
const int    _kGcMaxStarsWave1    = 1;
const int    _kGcMaxStarsCap      = 7;

// Tutorial: first N stars are in tutorial mode (slow + labelled)
const int    _kGcTutorialStars    = 1;

// Tap hitbox multiplier (make tap area generously larger than visual radius)
const double _kGcHitMult          = 1.55;

// Points
const int    _kGcPointsBase       = 10;
const int    _kGcBonusPerWave     = 4;
const int    _kGcComboBonus       = 5;   // extra per star when on combo ≥3
const int    _kGcPenaltyEscape    = -6;  // star escaped the screen

// Wave: new wave every N seconds
const double _kGcWaveDuration     = 15.0;
// ────────────────────────────────────────────────────────────────────────────

class GalaxyCollectorGame extends StatefulWidget {
  const GalaxyCollectorGame({Key? key}) : super(key: key);
  @override
  State<GalaxyCollectorGame> createState() => _GalaxyCollectorGameState();
}

enum _GCPhase { start, playing, gameOver }

// A single drifting star
class _GCStar {
  /// Position in normalised [0,1] coords
  double x, y;
  /// Velocity in normalised coords/sec
  final double vx, vy;
  /// Pixel radius of the orb
  final double radius;
  /// Total life when spawned (seconds)
  final double maxLife;
  /// Remaining life before escape
  double life;
  /// Scale-in animation [0→1]
  double scale;
  /// Flash on collection
  double flashGood;
  /// Whether this star has been collected (pending removal)
  bool collected;
  /// Whether this is a tutorial star (labelled)
  final bool isTutorial;
  /// Colour of this star
  final Color color;
  /// A unique index so the painter can derive a stable bob phase
  final int idx;

  _GCStar({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.maxLife,
    required this.color, required this.isTutorial,
    required this.idx,
  }) : life = maxLife, scale = 0.0, flashGood = 0.0, collected = false;
}

class _GalaxyCollectorGameState extends State<GalaxyCollectorGame>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  final Random _rng = Random();
  _GCPhase _phase = _GCPhase.start;

  // Gameplay state
  int _score = 0, _wave = 1, _highScore = 0;
  int _combo = 0, _bestCombo = 0;
  double _spawnTimer = 0.0;
  double _waveTimer  = 0.0;
  double _gameTimer  = 0.0;   // total elapsed seconds
  double _flashGood  = 0.0;
  double _flashBad   = 0.0;
  String? _toastText;
  double _toastTimer = 0.0;
  int    _starsSpawned = 0;   // total ever spawned (used for tutorial gate)
  double _clock = 0.0;        // seconds clock for painter animations

  final List<_GCStar>        _stars     = [];
  final List<FxParticle>     _particles = [];
  final List<FxPop>          _pops      = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)..forward();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _highScore = prefs.getInt('galaxy_collector_hs') ?? 0; });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('galaxy_collector_hs', _score);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _startGame() {
    setState(() {
      _phase = _GCPhase.playing;
      _score = 0; _wave = 1; _combo = 0; _bestCombo = 0;
      _spawnTimer = 0.0; _waveTimer = 0.0; _gameTimer = 0.0; _clock = 0.0;
      _flashGood = 0.0; _flashBad = 0.0;
      _toastText = null; _toastTimer = 0.0;
      _starsSpawned = 0;
      _stars.clear(); _particles.clear(); _pops.clear();
    });
  }

  void _endGame() {
    _saveHighScore();
    setState(() { _phase = _GCPhase.gameOver; });
  }

  // ── Per-wave derived values ──────────────────────────────────────────────
  double get _starLife     => (_kGcLifeWave1  - (_wave - 1) * 0.45).clamp(_kGcLifeMin, _kGcLifeWave1);
  double get _spawnInterval => (_kGcSpawnWave1 - (_wave - 1) * 0.38).clamp(_kGcSpawnMin, _kGcSpawnWave1);
  int    get _maxStars     => (_kGcMaxStarsWave1 + (_wave - 1)).clamp(1, _kGcMaxStarsCap);

  // ── Game loop ────────────────────────────────────────────────────────────
  void _tick() {
    if (_phase != _GCPhase.playing) return;
    const dt = 1 / 60.0;
    setState(() {
      _gameTimer += dt;
      _clock += dt;
      _waveTimer += dt;
      if (_gameTimer >= _kGcGameDuration) { _endGame(); return; }

      // Wave progression every 15s
      if (_waveTimer >= _kGcWaveDuration) {
        _waveTimer = 0.0;
        _wave++;
        _toast('Wave $_wave!');
      }

      // Spawn stars
      _spawnTimer -= dt;
      if (_spawnTimer <= 0.0 && _stars.where((s) => !s.collected).length < _maxStars) {
        _spawnTimer = _spawnInterval * (0.75 + _rng.nextDouble() * 0.5);
        _spawnStar();
      }

      // Update stars
      for (final s in _stars) {
        if (s.collected) {
          s.flashGood = (s.flashGood - dt * 3.0).clamp(0.0, 1.0);
          continue;
        }
        s.scale = (s.scale + dt / 0.30).clamp(0.0, 1.0);
        s.x += s.vx * dt;
        s.y += s.vy * dt;
        s.life -= dt;

        // Escaped?
        if (s.life <= 0.0 || s.x < -0.15 || s.x > 1.15 || s.y < -0.15 || s.y > 1.15) {
          _score = max(0, _score + _kGcPenaltyEscape);
          _combo = 0;
          _flashBad = 0.55;
          s.collected = true; // mark for removal
          _toast('Escaped!');
        }
      }
      _stars.removeWhere((s) => s.collected && s.flashGood <= 0.01);

      // Particles & pops
      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (_flashGood > 0) _flashGood = (_flashGood - dt * 2.8).clamp(0.0, 1.0);
      if (_flashBad  > 0) _flashBad  = (_flashBad  - dt * 2.8).clamp(0.0, 1.0);
      if (_toastTimer > 0) { _toastTimer -= dt; if (_toastTimer <= 0) _toastText = null; }
    });
  }

  void _spawnStar() {
    // Pick an edge and aim across
    final edge = _rng.nextInt(4);
    double sx, sy, tx, ty;
    switch (edge) {
      case 0: // top
        sx = 0.1 + _rng.nextDouble() * 0.8; sy = -0.06;
        tx = 0.1 + _rng.nextDouble() * 0.8; ty = 1.06;
        break;
      case 1: // right
        sx = 1.06; sy = 0.1 + _rng.nextDouble() * 0.8;
        tx = -0.06; ty = 0.1 + _rng.nextDouble() * 0.8;
        break;
      case 2: // bottom
        sx = 0.1 + _rng.nextDouble() * 0.8; sy = 1.06;
        tx = 0.1 + _rng.nextDouble() * 0.8; ty = -0.06;
        break;
      default: // left
        sx = -0.06; sy = 0.1 + _rng.nextDouble() * 0.8;
        tx = 1.06; ty = 0.1 + _rng.nextDouble() * 0.8;
    }

    final isTut = _starsSpawned < _kGcTutorialStars;
    final life = isTut ? _kGcLifeWave1 * 1.8 : _starLife;

    final dx = tx - sx, dy = ty - sy;
    final dist = sqrt(dx * dx + dy * dy).clamp(0.01, 2.5);
    // Velocity to cross the screen in `life` seconds
    final vx = (dx / dist) * (dist / life);
    final vy = (dy / dist) * (dist / life);

    // Radius: tutorial stars are larger; later waves spawn smaller ones
    final radius = isTut
        ? _kGcStarRadiusMax
        : _kGcStarRadiusMax - (_wave - 1) * 1.2;

    // Colour: cycle through a small palette of warm/cool star colours
    final starColors = [
      Potatuhs.gold,
      Potatuhs.orange,
      Potatuhs.airForce,
      Potatuhs.glaucous,
      Potatuhs.sienna,
      const Color(0xFF88CCEE), // pale blue
      const Color(0xFFFFEE88), // pale yellow
    ];
    final col = starColors[_starsSpawned % starColors.length];

    _stars.add(_GCStar(
      x: sx, y: sy, vx: vx, vy: vy,
      radius: radius.clamp(_kGcStarRadiusMin, _kGcStarRadiusMax),
      maxLife: life, color: col,
      isTutorial: isTut, idx: _starsSpawned,
    ));
    _starsSpawned++;
  }

  // ── Tap handling — collect the topmost star under the tap point ──────────
  void _handleTap(Offset localPos, Size screenSize) {
    final w = screenSize.width, h = screenSize.height;
    final tapX = localPos.dx, tapY = localPos.dy;

    _GCStar? hit;
    double bestDist = double.infinity;

    for (final s in _stars) {
      if (s.collected) continue;
      // Distance in pixel space
      final px = s.x * w, py = s.y * h;
      final d = sqrt((tapX - px) * (tapX - px) + (tapY - py) * (tapY - py));
      if (d < s.radius * _kGcHitMult && d < bestDist) {
        bestDist = d;
        hit = s;
      }
    }

    if (hit == null) return;

    setState(() {
      hit!.collected = true;
      hit.flashGood  = 1.0;
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
      final base    = _kGcPointsBase + _kGcBonusPerWave * _wave;
      final comboEx = _combo >= 3 ? _kGcComboBonus * (_combo - 2) : 0;
      final pts     = base + comboEx;
      _score += pts;
      _flashGood = 0.4;

      // Particles
      _particles.addAll(FxBurst.spawn(
        Offset(hit.x * w, hit.y * h),
        hit.color, count: 16, speed: 130, size: 3.5,
      ));
      // Score pop
      _pops.add(FxPop(
        Offset(hit.x * w, hit.y * h),
        _combo >= 3 ? '+$pts ×$_combo!' : '+$pts',
        _combo >= 3 ? Potatuhs.gold : Potatuhs.textPrimary,
      ));

      final comboMsg = _combo >= 3 ? '×$_combo COMBO!' : null;
      if (comboMsg != null) _toast(comboMsg);
    });
  }

  void _toast(String t) { _toastText = t; _toastTimer = 1.3; }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_phase == _GCPhase.start)    return _buildStart();
    if (_phase == _GCPhase.gameOver) return _buildOver();
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth, h = constraints.maxHeight;
      return GestureDetector(
        onTapDown: (d) => _handleTap(d.localPosition, Size(w, h)),
        child: CustomPaint(
          painter: _StarCollectorPainter(
            stars:     _stars,
            particles: _particles,
            pops:      _pops,
            flashGood: _flashGood,
            flashBad:  _flashBad,
            clock:     _clock,
          ),
          child: Stack(children: [
            // ── HUD strip ────────────────────────────────────────────────
            Positioned(top: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.fromLTRB(14, 44, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Potatuhs.inkDeep, Potatuhs.inkDeep.withValues(alpha: 0)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score
                  Text(
                    '$_score',
                    style: Potatuhs.display(size: 26, color: Potatuhs.gold),
                  ),
                  // Time remaining
                  Builder(builder: (_) {
                    final rem = (_kGcGameDuration - _gameTimer).clamp(0.0, _kGcGameDuration);
                    final warn = rem < 6.0;
                    return Text(
                      '${rem.ceil()}s',
                      style: Potatuhs.display(
                        size: 20,
                        color: warn ? const Color(0xFFFF5252) : Potatuhs.textSecondary,
                      ),
                    );
                  }),
                  // Wave
                  Text('W$_wave', style: Potatuhs.label(size: 14, color: Potatuhs.airForce)),
                ],
              ),
            )),
            // ── Instruction banner (wave 1 only while tutorial star is live) ──
            if (_wave == 1 && _starsSpawned <= _kGcTutorialStars)
              Positioned(
                bottom: 32, left: 24, right: 24,
                child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Text(
                    'TAP THE STARS  •  collect them before they escape!',
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
                  ),
                )),
              ),
            // ── Combo banner ─────────────────────────────────────────────
            if (_combo >= 3) Positioned(
              top: 100, left: 0, right: 0,
              child: Center(child: Text(
                '×$_combo COMBO',
                style: Potatuhs.display(size: 22, color: Potatuhs.gold),
              )),
            ),
            // ── Toast ─────────────────────────────────────────────────────
            if (_toastText != null) Positioned(
              top: 130, left: 0, right: 0,
              child: Center(child: Builder(builder: (_) {
                final isGood = !_toastText!.contains('Escaped');
                final fade   = (_toastTimer / 1.3).clamp(0.0, 1.0);
                final col    = (isGood ? Potatuhs.gold : const Color(0xFFFF5252))
                    .withValues(alpha: fade);
                return Text(
                  _toastText!,
                  style: Potatuhs.display(size: 20, color: col),
                );
              })),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildStart() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Potatuhs.inkDeep, Color.lerp(Potatuhs.inkDeep, Potatuhs.glaucous, 0.18)!],
          ),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('STAR COLLECTOR', style: Potatuhs.display(size: 34, color: Potatuhs.gold)),
          const SizedBox(height: 14),
          Text(
            'Stars drift across the galaxy.\nTap them before they escape!',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 16, color: Potatuhs.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Chains of 3+ stars = COMBO bonus',
            textAlign: TextAlign.center,
            style: Potatuhs.label(size: 13, color: Potatuhs.airForce),
          ),
          const SizedBox(height: 28),
          if (_highScore > 0) Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Best: $_highScore',
              style: Potatuhs.display(size: 18, color: Potatuhs.gold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: Potatuhs.ctaGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('TAP TO PLAY', style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
          ),
        ])),
      ),
    );
  }

  Widget _buildOver() {
    final newHigh = _score >= _highScore && _score > 0;
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Potatuhs.inkDeep, Color.lerp(Potatuhs.inkDeep, Potatuhs.glaucous, 0.18)!],
          ),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('TIME\'S UP', style: Potatuhs.display(size: 30, color: Potatuhs.orange)),
          const SizedBox(height: 22),
          Text('$_score', style: Potatuhs.display(size: 52, color: Potatuhs.gold)),
          Text('POINTS', style: Potatuhs.label(size: 13, color: Potatuhs.textFaint)),
          const SizedBox(height: 10),
          if (newHigh) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('NEW HIGH SCORE!', style: Potatuhs.display(size: 20, color: Potatuhs.gold)),
          ),
          if (!newHigh) Text(
            'Best: $_highScore',
            style: Potatuhs.label(size: 15, color: Potatuhs.textFaint),
          ),
          const SizedBox(height: 6),
          Text('Wave Reached: $_wave', style: Potatuhs.body(size: 15, color: Potatuhs.airForce)),
          const SizedBox(height: 4),
          Text('Best Combo: ×$_bestCombo', style: Potatuhs.body(size: 15, color: Potatuhs.sienna)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: Potatuhs.ctaGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('PLAY AGAIN', style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
          ),
        ])),
      ),
    );
  }
}

// ── Canvas painter ────────────────────────────────────────────────────────────
class _StarCollectorPainter extends CustomPainter {
  final List<_GCStar>    stars;
  final List<FxParticle> particles;
  final List<FxPop>      pops;
  final double flashGood, flashBad, clock;

  const _StarCollectorPainter({
    required this.stars,
    required this.particles,
    required this.pops,
    required this.flashGood,
    required this.flashBad,
    required this.clock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // ── Atmospheric background ──────────────────────────────────────────
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, clock, motes: 48);

    // ── Stars ──────────────────────────────────────────────────────────
    for (final s in stars) {
      if (s.scale <= 0) continue;
      final a = s.scale.clamp(0.0, 1.0);
      final px = s.x * w;
      final py = s.y * h;

      // Ghost trail: dots showing where the star is heading
      if (!s.collected) {
        final lifeRatio = (s.life / s.maxLife).clamp(0.0, 1.0);
        // Draw 5 ghost dots along the future path
        for (int gi = 1; gi <= 5; gi++) {
          final frac = gi / 5.0;
          final gx = px + s.vx * w * frac * s.life;
          final gy = py + s.vy * h * frac * s.life;
          // Only draw if still on screen-ish
          if (gx < -20 || gx > w + 20 || gy < -20 || gy > h + 20) break;
          final ga = (0.22 - frac * 0.18) * a * lifeRatio;
          canvas.drawCircle(
            Offset(gx, gy),
            s.radius * (0.20 - frac * 0.03),
            Paint()..color = s.color.withValues(alpha: ga)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }

        // Urgency pulse ring: appears when < 40 % life left
        final urgency = 1.0 - lifeRatio;
        if (urgency > 0.6) {
          final pulseA = (urgency - 0.6) / 0.4;
          final pulse = 0.5 + 0.5 * sin(clock * 8.0 + s.idx.toDouble());
          canvas.drawCircle(
            Offset(px, py),
            s.radius * (1.55 + pulse * 0.25) * a,
            Paint()
              ..color = const Color(0xFFFF5252).withValues(alpha: pulseA * 0.5 * a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }

        // Tutorial label: pulsing "TAP!" arrow above the star
        if (s.isTutorial) {
          final pulse = 0.65 + 0.35 * sin(clock * 4.0);
          GameFx.text(
            canvas,
            '▼ TAP!',
            Offset(px, py - s.radius * 1.8 - 14),
            15,
            Potatuhs.gold.withValues(alpha: pulse * a),
            display: true,
            glow: 0.8 * pulse,
          );
        }
      }

      // ── Star orb ─────────────────────────────────────────────────────
      // Good-flash: brighten on collection
      final effectiveGlow = s.collected ? 0.0 : 1.0;
      if (s.flashGood > 0) {
        canvas.drawCircle(
          Offset(px, py),
          s.radius * 2.2 * a,
          Paint()
            ..color = s.color.withValues(alpha: s.flashGood * 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
      }

      GameFx.orb(
        canvas, Offset(px, py), s.radius * a, s.color,
        glow: effectiveGlow * a,
      );

      // Draw little ray spikes around the star for readability (it's a STAR)
      if (!s.collected) {
        final spikePaint = Paint()
          ..color = s.color.withValues(alpha: 0.45 * a)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        final spokeCount = 6;
        final spikeLen = s.radius * 0.65;
        final bob = clock * 0.8 + s.idx * 0.4; // slow rotation
        for (int sp = 0; sp < spokeCount; sp++) {
          final ang = bob + sp * (2 * pi / spokeCount);
          final inner = s.radius * 1.08 * a;
          final outer = (s.radius + spikeLen) * a;
          canvas.drawLine(
            Offset(px + cos(ang) * inner, py + sin(ang) * inner),
            Offset(px + cos(ang) * outer, py + sin(ang) * outer),
            spikePaint,
          );
        }
      }
    }

    // ── FxBurst particles ──────────────────────────────────────────────
    FxBurst.paint(canvas, particles);

    // ── Score pops ────────────────────────────────────────────────────
    for (final p in pops) { p.paint(canvas); }

    // ── Screen flashes ────────────────────────────────────────────────
    if (flashGood > 0) canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Potatuhs.gold.withValues(alpha: flashGood * 0.12),
    );
    if (flashBad > 0) canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFFF5252).withValues(alpha: flashBad * 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _StarCollectorPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. CosmicWebGame — "Web Weaver"
// ═══════════════════════════════════════════════════════════════════════════════

class CosmicWebGame extends StatefulWidget {
  const CosmicWebGame({Key? key}) : super(key: key);
  @override
  State<CosmicWebGame> createState() => _CosmicWebGameState();
}

enum _CosmicWebPhase { start, playing, levelComplete, gameOver }

class _CosmicWebGameState extends State<CosmicWebGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  final List<_WebNode> _nodes = [];
  final List<_WebEdge> _edges = [];
  final List<_JuiceParticle> _particles = [];

  _CosmicWebPhase _phase = _CosmicWebPhase.start;
  int _level = 1;
  double _timeLeft = 30;
  double _levelCompleteTimer = 0;
  int _highLevel = 0;

  int? _dragFromNode;
  Offset? _dragPos;

  // Level-dependent parameters (pixel values, set per layout)
  double _nodeRadius = 30;
  double _connectRange = 120;
  double _hitTestRadius = 35;

  // Cached layout size for coordinate conversion
  double _layoutW = 1;
  double _layoutH = 1;

  // Level config helpers
  int _nodeCountForLevel(int level) {
    const counts = [0, 5, 6, 7, 8, 9];
    if (level < counts.length) return counts[level];
    return 9 + (level - 5);
  }

  double _nodeRadiusForLevel(int level) {
    const radii = [0.0, 30.0, 26.0, 22.0, 18.0, 15.0];
    if (level < radii.length) return radii[level];
    return 15.0;
  }

  double _connectRangeForLevel(int level) {
    const ranges = [0.0, 120.0, 105.0, 90.0, 80.0, 70.0];
    if (level < ranges.length) return ranges[level];
    return 70.0;
  }

  double _driftSpeedForLevel(int level) {
    if (level <= 2) return 0.0;
    if (level <= 4) return 0.005;
    return 0.005 + (level - 4) * 0.003;
  }

  double _timeLimitForLevel(int level) {
    final t = 30.0 - (level - 1) * 3.0;
    return t < 10 ? 10.0 : t;
  }

  bool _canBreakConnections(int level) => level >= 5;

  @override
  void initState() {
    super.initState();
    _loadHighLevel();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadHighLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highLevel = prefs.getInt('cosmic_web_high_level') ?? 0;
    });
  }

  Future<void> _saveHighLevel() async {
    if (_level > _highLevel) {
      _highLevel = _level;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cosmic_web_high_level', _highLevel);
    }
  }

  void _startGame() {
    setState(() {
      _level = 1;
      _phase = _CosmicWebPhase.playing;
      _particles.clear();
      _startLevel();
    });
  }

  void _startLevel() {
    final count = _nodeCountForLevel(_level);
    _nodeRadius = _nodeRadiusForLevel(_level);
    _connectRange = _connectRangeForLevel(_level);
    _hitTestRadius = _nodeRadius + 8;
    _timeLeft = _timeLimitForLevel(_level);
    _dragFromNode = null;
    _dragPos = null;
    _spawnNodes(count);
  }

  void _spawnNodes(int count) {
    _nodes.clear();
    _edges.clear();
    final drift = _driftSpeedForLevel(_level);
    for (int i = 0; i < count; i++) {
      _nodes.add(_WebNode(
        0.1 + _rng.nextDouble() * 0.8,
        0.15 + _rng.nextDouble() * 0.65,
        drift > 0 ? (_rng.nextDouble() - 0.5) * drift * 2 : 0,
        drift > 0 ? (_rng.nextDouble() - 0.5) * drift * 2 : 0,
      ));
    }
    // Ensure nodes are not too close together
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final dx = _nodes[i].x - _nodes[j].x;
        final dy = _nodes[i].y - _nodes[j].y;
        if (sqrt(dx * dx + dy * dy) < 0.08) {
          _nodes[j].x = 0.1 + _rng.nextDouble() * 0.8;
          _nodes[j].y = 0.15 + _rng.nextDouble() * 0.65;
        }
      }
    }
  }

  void _tick() {
    final dt = 1 / 60.0;

    setState(() {
      // Always update particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // Always pulse nodes
      for (final n in _nodes) {
        n.pulse += dt * 3;
      }

      if (_phase == _CosmicWebPhase.levelComplete) {
        _levelCompleteTimer -= dt;
        if (_levelCompleteTimer <= 0) {
          _level++;
          _phase = _CosmicWebPhase.playing;
          _startLevel();
        }
        return;
      }

      if (_phase != _CosmicWebPhase.playing) return;

      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _phase = _CosmicWebPhase.gameOver;
        _saveHighLevel();
        return;
      }

      // Drift nodes
      final drift = _driftSpeedForLevel(_level);
      if (drift > 0) {
        for (final n in _nodes) {
          n.x += n.vx * dt;
          n.y += n.vy * dt;
          if (n.x < 0.05 || n.x > 0.95) n.vx = -n.vx;
          if (n.y < 0.1 || n.y > 0.85) n.vy = -n.vy;
          n.x = n.x.clamp(0.05, 0.95);
          n.y = n.y.clamp(0.1, 0.85);
        }
      }

      // Break connections that are too far (only level 5+)
      if (_canBreakConnections(_level)) {
        final breakDist = _connectRange * 1.4 / _layoutW.clamp(1, 9999);
        _edges.removeWhere((e) {
          final a = _nodes[e.a];
          final b = _nodes[e.b];
          final dx = a.x - b.x;
          final dy = (a.y - b.y) * (_layoutH / _layoutW.clamp(1, 9999));
          return sqrt(dx * dx + dy * dy) > breakDist;
        });
      }

      // Check win condition: all nodes connected
      if (_nodes.isNotEmpty && _edges.isNotEmpty && _isFullyConnected()) {
        _phase = _CosmicWebPhase.levelComplete;
        _levelCompleteTimer = 1.5;
        _saveHighLevel();
        for (final n in _nodes) {
          _spawnP(n.x, n.y, Colors.cyanAccent, 12);
        }
      }
    });
  }

  bool _isFullyConnected() {
    if (_nodes.isEmpty) return true;
    final visited = <int>{0};
    final queue = [0];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final e in _edges) {
        int neighbor = -1;
        if (e.a == current && !visited.contains(e.b)) neighbor = e.b;
        if (e.b == current && !visited.contains(e.a)) neighbor = e.a;
        if (neighbor >= 0) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    return visited.length == _nodes.length;
  }

  void _spawnP(double x, double y, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: x, y: y,
        vx: (_rng.nextDouble() - 0.5) * 0.3,
        vy: (_rng.nextDouble() - 0.5) * 0.3,
        life: 0.6, color: c,
      ));
    }
  }

  int? _nodeAt(Offset localPos, double w, double h) {
    for (int i = 0; i < _nodes.length; i++) {
      final nx = _nodes[i].x * w;
      final ny = _nodes[i].y * h;
      if ((localPos - Offset(nx, ny)).distance < _hitTestRadius) return i;
    }
    return null;
  }

  Set<int> _validTargets(int fromNode, double w, double h) {
    final targets = <int>{};
    final a = _nodes[fromNode];
    for (int i = 0; i < _nodes.length; i++) {
      if (i == fromNode) continue;
      final b = _nodes[i];
      final dx = (a.x - b.x) * w;
      final dy = (a.y - b.y) * h;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist <= _connectRange) {
        final alreadyConnected = _edges.any((e) =>
            (e.a == fromNode && e.b == i) || (e.a == i && e.b == fromNode));
        if (!alreadyConnected) {
          targets.add(i);
        }
      }
    }
    return targets;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _layoutW = w;
      _layoutH = h;

      if (_phase == _CosmicWebPhase.start) {
        return _buildStartScreen();
      }

      final validTargets = _dragFromNode != null
          ? _validTargets(_dragFromNode!, w, h)
          : <int>{};

      final allConnected = _phase == _CosmicWebPhase.levelComplete;

      return GestureDetector(
        onPanStart: (d) {
          if (_phase != _CosmicWebPhase.playing) return;
          _dragFromNode = _nodeAt(d.localPosition, w, h);
          _dragPos = d.localPosition;
        },
        onPanUpdate: (d) {
          if (_dragFromNode != null) {
            setState(() => _dragPos = d.localPosition);
          }
        },
        onPanEnd: (d) {
          if (_dragFromNode != null && _dragPos != null) {
            final toNode = _nodeAt(_dragPos!, w, h);
            if (toNode != null && toNode != _dragFromNode) {
              final a = _nodes[_dragFromNode!];
              final b = _nodes[toNode];
              final dx = (a.x - b.x) * w;
              final dy = (a.y - b.y) * h;
              final dist = sqrt(dx * dx + dy * dy);
              if (dist <= _connectRange) {
                final exists = _edges.any((e) =>
                    (e.a == _dragFromNode && e.b == toNode) ||
                    (e.a == toNode && e.b == _dragFromNode));
                if (!exists) {
                  setState(() {
                    _edges.add(_WebEdge(_dragFromNode!, toNode));
                    _spawnP((a.x + b.x) / 2, (a.y + b.y) / 2,
                        Colors.cyanAccent, 8);
                  });
                }
              }
            }
          }
          _dragFromNode = null;
          _dragPos = null;
        },
        child: Container(
          color: const Color(0xFF050510),
          child: CustomPaint(
            painter: _CosmicWebPainter(
              nodes: _nodes,
              edges: _edges,
              particles: _particles,
              dragFrom: _dragFromNode,
              dragPos: _dragPos,
              screenW: w,
              screenH: h,
              nodeRadius: _nodeRadius,
              connectRange: _connectRange,
              validTargets: validTargets,
              allConnected: allConnected,
            ),
            child: Stack(
              children: [
                // Top HUD
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_timeLeft.ceil()}s',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 16,
                          color: _timeLeft < 8
                              ? Colors.redAccent
                              : Colors.white70,
                        ),
                      ),
                      Text(
                        'Level $_level',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      Text(
                        '${_edges.length}/${_nodes.length - 1}',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Level complete overlay
                if (_phase == _CosmicWebPhase.levelComplete)
                  Center(
                    child: Text(
                      'Level $_level Complete!',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                // Game over overlay
                if (_phase == _CosmicWebPhase.gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Time Up!',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reached Level $_level',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        if (_level >= _highLevel && _level > 1)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'New Best!',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amberAccent,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _phase = _CosmicWebPhase.start;
                              _particles.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text('Play Again',
                                style: TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 14,
                                    color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Hint on first drag
                if (_phase == _CosmicWebPhase.playing && _edges.isEmpty)
                  const Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Center(
                      child: Text(
                        'Drag between nodes to link them',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStartScreen() {
    return Container(
      color: const Color(0xFF050510),
      child: Center(
        child: GestureDetector(
          onTap: _startGame,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Web Weaver',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect all nodes into a network',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Drag between nodes to link them',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
              if (_highLevel > 0) ...[
                const SizedBox(height: 20),
                Text(
                  'Best: Level $_highLevel',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 15,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Tap to Play',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 16,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebNode {
  double x, y, vx, vy, pulse;
  _WebNode(this.x, this.y, this.vx, this.vy) : pulse = 0;
}

class _WebEdge {
  final int a, b;
  _WebEdge(this.a, this.b);
}

class _CosmicWebPainter extends CustomPainter {
  final List<_WebNode> nodes;
  final List<_WebEdge> edges;
  final List<_JuiceParticle> particles;
  final int? dragFrom;
  final Offset? dragPos;
  final double screenW, screenH;
  final double nodeRadius;
  final double connectRange;
  final Set<int> validTargets;
  final bool allConnected;

  _CosmicWebPainter({
    required this.nodes,
    required this.edges,
    required this.particles,
    required this.dragFrom,
    required this.dragPos,
    required this.screenW,
    required this.screenH,
    required this.nodeRadius,
    required this.connectRange,
    required this.validTargets,
    required this.allConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid
    final gridPaint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final connectedNodes = <int>{};
    for (final e in edges) {
      connectedNodes.add(e.a);
      connectedNodes.add(e.b);
    }

    // Edge glow intensity for "all connected" celebration
    final double edgeGlow = allConnected ? 0.8 : 0.4;
    final double edgeWidth = allConnected ? 3.0 : 2.0;

    // Edges with energy pulse
    for (final e in edges) {
      final a = nodes[e.a];
      final b = nodes[e.b];
      final from = Offset(a.x * size.width, a.y * size.height);
      final to = Offset(b.x * size.width, b.y * size.height);

      // Main edge line
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: edgeGlow)
          ..strokeWidth = edgeWidth
          ..strokeCap = StrokeCap.round,
      );

      // Energy pulse traveling along edge
      final pulseT = (a.pulse % 2) / 2;
      final pulsePos = Offset.lerp(from, to, pulseT)!;
      canvas.drawCircle(
        pulsePos,
        allConnected ? 4 : 2.5,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.8),
      );

      // Second pulse going the other direction
      final pulseT2 = ((a.pulse + 1.0) % 2) / 2;
      final pulsePos2 = Offset.lerp(to, from, pulseT2)!;
      canvas.drawCircle(
        pulsePos2,
        allConnected ? 3 : 2,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.5),
      );
    }

    // Drag line
    if (dragFrom != null && dragPos != null) {
      final from = Offset(
        nodes[dragFrom!].x * size.width,
        nodes[dragFrom!].y * size.height,
      );
      canvas.drawLine(
        from,
        dragPos!,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.6)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Nodes
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final pos = Offset(n.x * size.width, n.y * size.height);
      final isConnected = connectedNodes.contains(i);
      final isValidTarget = validTargets.contains(i);
      final isDragSource = dragFrom == i;

      if (allConnected) {
        // Celebration: all nodes glow brightly together
        final celebPulse = 0.5 + 0.3 * sin(n.pulse * 2);
        canvas.drawCircle(
          pos,
          nodeRadius * 1.8,
          Paint()..color = Colors.cyanAccent.withValues(alpha: celebPulse * 0.3),
        );
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.8),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 0.5,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      } else if (isValidTarget) {
        // Pulsing glow for valid connection targets
        final glowPulse = 0.4 + 0.4 * sin(n.pulse * 4);
        canvas.drawCircle(
          pos,
          nodeRadius * 2.2,
          Paint()..color = Colors.greenAccent.withValues(alpha: glowPulse * 0.25),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 1.5,
          Paint()..color = Colors.greenAccent.withValues(alpha: glowPulse * 0.3),
        );
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = Colors.greenAccent.withValues(alpha: 0.7),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      } else if (isDragSource) {
        // Highlight the drag source node
        canvas.drawCircle(
          pos,
          nodeRadius * 1.6,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3),
        );
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.8),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      } else if (isConnected) {
        // Connected nodes glow brighter
        final connPulse = 0.6 + 0.15 * sin(n.pulse);
        canvas.drawCircle(
          pos,
          nodeRadius * 1.5,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.1 + 0.05 * sin(n.pulse)),
        );
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = Colors.cyanAccent.withValues(alpha: connPulse),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      } else {
        // Unconnected: dim "lonely" pulse
        final lonelyPulse = 0.15 + 0.1 * sin(n.pulse * 1.5);
        canvas.drawCircle(
          pos,
          nodeRadius * 1.3,
          Paint()..color = Colors.white.withValues(alpha: lonelyPulse * 0.3),
        );
        canvas.drawCircle(
          pos,
          nodeRadius,
          Paint()..color = Colors.white.withValues(alpha: lonelyPulse + 0.1),
        );
        canvas.drawCircle(
          pos,
          nodeRadius * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.4),
        );
      }
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height),
          2.5,
          Paint()
            ..color = p.color.withValues(
                alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicWebPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. MultiverseChoiceGame — "Branch"
// ═══════════════════════════════════════════════════════════════════════════════

class MultiverseChoiceGame extends StatefulWidget {
  const MultiverseChoiceGame({Key? key}) : super(key: key);
  @override
  State<MultiverseChoiceGame> createState() => _MultiverseChoiceGameState();
}

class _MultiverseChoiceGameState extends State<MultiverseChoiceGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  int _currentDepth = 0;
  int _totalScore = 0;
  double _choiceTimer = 5;
  bool _finished = false;
  static const int _maxDepth = 10;

  // Tree structure
  final List<_BranchNode> _tree = [];

  // Current choice options
  late List<_ChoiceOption> _currentOptions;

  // Pre-generated choice pairs
  final List<List<_ChoiceOption>> _allChoices = [];

  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _generateAllChoices();
    _currentOptions = _allChoices[0];
    // Root node
    _tree.add(_BranchNode(0.5, 0.05, null, 0, '', true));
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _generateAllChoices() {
    final choicePairs = [
      [_ChoiceOption('Explore the cave', 'Courage: +3', 3), _ChoiceOption('Stay on the path', 'Safety: +1', 1)],
      [_ChoiceOption('Help the stranger', 'Karma: +4', 4), _ChoiceOption('Keep walking', 'Speed: +2', 2)],
      [_ChoiceOption('Take the red door', 'Mystery: +5', 5), _ChoiceOption('Take the blue door', 'Wisdom: +3', 3)],
      [_ChoiceOption('Plant a seed', 'Growth: +2', 2), _ChoiceOption('Build a shelter', 'Security: +4', 4)],
      [_ChoiceOption('Cross the bridge', 'Adventure: +3', 3), _ChoiceOption('Swim across', 'Strength: +5', 5)],
      [_ChoiceOption('Read the scroll', 'Knowledge: +4', 4), _ChoiceOption('Burn the scroll', 'Chaos: +6', 6)],
      [_ChoiceOption('Follow the light', 'Faith: +3', 3), _ChoiceOption('Trust the dark', 'Power: +5', 5)],
      [_ChoiceOption('Share your food', 'Compassion: +4', 4), _ChoiceOption('Save it', 'Survival: +2', 2)],
      [_ChoiceOption('Forgive', 'Peace: +5', 5), _ChoiceOption('Remember', 'Resolve: +3', 3)],
      [_ChoiceOption('Leap', 'Transcendence: +7', 7), _ChoiceOption('Look back', 'Reflection: +4', 4)],
    ];
    _allChoices.addAll(choicePairs);
  }

  void _tick() {
    if (_finished) return;
    final dt = 1 / 60.0;
    setState(() {
      if (_currentDepth < _maxDepth) {
        _choiceTimer -= dt;
        if (_choiceTimer <= 0) {
          // Auto-pick randomly
          _makeChoice(_rng.nextInt(2));
        }
      }

      // Animate tree growth
      for (final n in _tree) {
        if (n.growthProgress < 1.0) {
          n.growthProgress = (n.growthProgress + dt * 2).clamp(0.0, 1.0);
        }
      }

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _makeChoice(int idx) {
    if (_currentDepth >= _maxDepth) return;
    final chosen = _currentOptions[idx];
    final unchosen = _currentOptions[1 - idx];

    final parentY = 0.05 + _currentDepth * 0.08;
    final parentNode = _tree.lastWhere((n) => n.chosen);
    final parentX = parentNode.x;

    // Calculate spread based on depth
    final spread = 0.15 / (1 + _currentDepth * 0.3);

    // Chosen branch
    final chosenX = (parentX + (idx == 0 ? -spread : spread)).clamp(0.05, 0.95);
    final chosenY = parentY + 0.08;
    _tree.add(_BranchNode(chosenX, chosenY, _tree.length - 1, chosen.value, chosen.label, true));

    // Unchosen branch (faded)
    final unchosenX = (parentX + (idx == 0 ? spread : -spread)).clamp(0.05, 0.95);
    _tree.add(_BranchNode(unchosenX, chosenY, _tree.length - 2, unchosen.value, unchosen.label, false));

    _totalScore += chosen.value;
    _currentDepth++;
    _choiceTimer = 5;

    // Particles at chosen branch
    for (int i = 0; i < 8; i++) {
      _particles.add(_JuiceParticle(
        x: chosenX, y: chosenY,
        vx: (_rng.nextDouble() - 0.5) * 0.2,
        vy: (_rng.nextDouble() - 0.5) * 0.2,
        life: 0.5, color: Colors.amberAccent,
      ));
    }

    if (_currentDepth >= _maxDepth) {
      _finished = true;
    } else {
      _currentOptions = _allChoices[_currentDepth];
    }
  }

  void _restart() {
    setState(() {
      _currentDepth = 0;
      _totalScore = 0;
      _choiceTimer = 5;
      _finished = false;
      _tree.clear();
      _tree.add(_BranchNode(0.5, 0.05, null, 0, '', true));
      _currentOptions = _allChoices[0];
      _particles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Container(
        color: const Color(0xFF080818),
        child: Stack(
          children: [
            // Tree visualization
            CustomPaint(
              size: Size(w, h),
              painter: _BranchTreePainter(_tree, _particles),
            ),

            // HUD
            Positioned(
              top: 8, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Choice ${_currentDepth + 1}/$_maxDepth', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
                  Text('Score: $_totalScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                ],
              ),
            ),

            // Choice UI at bottom
            if (!_finished)
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer bar
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        value: (_choiceTimer / 5).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(_choiceTimer < 2 ? Colors.redAccent : Colors.amberAccent),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: _choiceButton(0)),
                        const SizedBox(width: 12),
                        Expanded(child: _choiceButton(1)),
                      ],
                    ),
                  ],
                ),
              ),

            // Finished screen
            if (_finished)
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Every branch is a universe that exists.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38)),
                    const SizedBox(height: 4),
                    Text('Your path scored: $_totalScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                        child: const Text('Play Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _choiceButton(int idx) {
    final opt = _currentOptions[idx];
    return GestureDetector(
      onTap: () => _makeChoice(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(opt.label, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(opt.consequence, style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.amberAccent.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _ChoiceOption {
  final String label, consequence;
  final int value;
  _ChoiceOption(this.label, this.consequence, this.value);
}

class _BranchNode {
  final double x, y;
  final int? parentIdx;
  final int value;
  final String label;
  final bool chosen;
  double growthProgress;
  _BranchNode(this.x, this.y, this.parentIdx, this.value, this.label, this.chosen) : growthProgress = 0;
}

class _BranchTreePainter extends CustomPainter {
  final List<_BranchNode> tree;
  final List<_JuiceParticle> particles;

  _BranchTreePainter(this.tree, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges
    for (int i = 1; i < tree.length; i++) {
      final node = tree[i];
      if (node.parentIdx == null) continue;
      final parent = tree[node.parentIdx!];

      final from = Offset(parent.x * size.width, parent.y * size.height);
      final to = Offset(
        ui.lerpDouble(parent.x, node.x, node.growthProgress)! * size.width,
        ui.lerpDouble(parent.y, node.y, node.growthProgress)! * size.height,
      );

      final alpha = node.chosen ? 0.6 : 0.15;
      final color = node.chosen ? Colors.amberAccent : Colors.grey;
      canvas.drawLine(from, to, Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = node.chosen ? 2.5 : 1
        ..strokeCap = StrokeCap.round);
    }

    // Draw nodes
    for (int i = 0; i < tree.length; i++) {
      final node = tree[i];
      final pos = Offset(node.x * size.width, node.y * size.height);
      final alpha = node.chosen ? 0.8 : 0.2;
      final nodeColor = node.chosen ? Colors.amberAccent : Colors.grey;

      if (node.chosen) {
        canvas.drawCircle(pos, 10, Paint()..color = nodeColor.withValues(alpha: alpha * 0.2));
      }
      canvas.drawCircle(pos, 5, Paint()..color = nodeColor.withValues(alpha: alpha));

      // Label for chosen nodes
      if (node.chosen && node.label.isNotEmpty && node.growthProgress >= 1.0) {
        final tp = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(fontFamily: 'Avenir', fontSize: 8, color: Colors.white.withValues(alpha: 0.4)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pos.dx + 8, pos.dy - 4));
      }
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), 2,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BranchTreePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. InfinityCounterGame — "Count Forever"  (BioScale.infinities)
//
// FEEL CONSTANTS — tune here without touching game logic
// ─────────────────────────────────────────────────────
// Game duration
const double _kICGameDuration = 60.0; // seconds total
// Tap value — how much each tap adds (or subtracts when reversed)
const double _kICBaseTapValue = 1.0;
// Milestone interval — event fires every N taps
const int _kICMilestoneInterval = 10;
// Choices at each milestone: milestone 1 → 1 choice (auto-granted),
// milestone 2 → 2, milestone 3 → 4, milestone 4 → 8 … (2^(n-1))
// Capped at 64 to stay readable.
const int _kICMaxChoices = 64;
// Base auto-tapper rate (taps/sec added per AUTO_TAPPER stack)
const double _kICAutoTapRate = 1.0;
// Multiplier factor per TAP_MULTIPLIER stack
const double _kICMultiplierFactor = 1.5;
// Chaos-reverse: every X seconds a reversed count flips direction again
const double _kICChaosReverseInterval = 5.0;
// Number of particles on tap / milestone
const int _kICTapParticles = 4;
const int _kICMilestoneParticles = 60;
// Power-up card display duration (seconds player has to pick; auto-picks #0 on timeout)
const double _kICPickTimeout = 6.0;
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Power-up enum ────────────────────────────────────────────────────────────
enum _ICPowerUpType {
  autoTapper,      // +1 auto-tap/sec (stacks)
  tapReverse,      // flip tap direction: taps now subtract
  multiplier,      // tap value ×1.5 (stacks multiplicatively)
  doubleDown,      // milestone interval halved — events fire twice as fast
  chaosReverse,    // direction flips every 5 s automatically
  giantTap,        // next 5 manual taps worth ×10
  tapForEnemy,     // taps add to a rival counter instead of yours for 8 s
  timeSlow,        // game timer ticks at half speed for 10 s
  countReset,      // YOUR count resets to zero (chaotic!)
  bonusBurst,      // instantly add +50 to your count
}

// ─── Power-up definition ──────────────────────────────────────────────────────
class _ICPowerUp {
  final _ICPowerUpType type;
  final String label;
  final String emoji;
  final String desc;
  const _ICPowerUp(this.type, this.label, this.emoji, this.desc);
}

const List<_ICPowerUp> _kICAllPowerUps = [
  _ICPowerUp(_ICPowerUpType.autoTapper,   'AUTO-TAPPER',   '🤖', '+${_kICAutoTapRate} tap/s forever'),
  _ICPowerUp(_ICPowerUpType.tapReverse,   'TAP-REVERSE',   '🔄', 'Taps now go the other way'),
  _ICPowerUp(_ICPowerUpType.multiplier,   '×MULTIPLIER',   '⚡', 'Tap value ×${_kICMultiplierFactor}'),
  _ICPowerUp(_ICPowerUpType.doubleDown,   'DOUBLE-DOWN',   '⚡⚡', 'Events fire 2× as often'),
  _ICPowerUp(_ICPowerUpType.chaosReverse, 'CHAOS-FLIP',    '🌀', 'Direction reverses every 5 s'),
  _ICPowerUp(_ICPowerUpType.giantTap,     'GIANT TAP',     '💥', 'Next 5 taps worth ×10'),
  _ICPowerUp(_ICPowerUpType.tapForEnemy,  'WRONG TEAM',    '😈', 'Taps feed rival for 8 s'),
  _ICPowerUp(_ICPowerUpType.timeSlow,     'TIME SLOW',     '🐢', 'Clock at ½ speed for 10 s'),
  _ICPowerUp(_ICPowerUpType.countReset,   'RESET!',        '💀', 'Your count → 0'),
  _ICPowerUp(_ICPowerUpType.bonusBurst,   'BONUS BURST',   '🎁', 'Instant +50'),
];

// ─── Active modifier state ────────────────────────────────────────────────────
class _ICModifiers {
  int autoTappers = 0;        // number of stacked auto-tappers
  bool tapReversed = false;   // taps subtract
  double tapMultiplier = 1.0; // multiplicative tap value
  int milestoneIntervalDiv = 1; // milestone every (base/this) taps
  bool chaosReverse = false;  // periodic auto-flip active
  double chaosTimer = 0;
  int giantTapCharges = 0;    // remaining ×10 taps
  bool tapForEnemy = false;
  double tapForEnemyTimer = 0;
  bool timeSlow = false;
  double timeSlowTimer = 0;

  // Describe all active mods as short strings for the HUD
  List<String> activeLabels() {
    final out = <String>[];
    if (autoTappers > 0) out.add('AUTO ×$autoTappers');
    if (tapReversed) out.add('REVERSED');
    if (tapMultiplier > 1.01) out.add('×${tapMultiplier.toStringAsFixed(1)}');
    if (milestoneIntervalDiv > 1) out.add('2× EVENTS');
    if (chaosReverse) out.add('CHAOS');
    if (giantTapCharges > 0) out.add('GIANT($giantTapCharges)');
    if (tapForEnemy) out.add('WRONG TEAM');
    if (timeSlow) out.add('SLOW CLK');
    return out;
  }
}

// ─── Floating pop label ("+7", "REVERSED!", etc.) ────────────────────────────
class _ICPop {
  double x, y, life, maxLife;
  final String text;
  final Color color;
  _ICPop({required this.x, required this.y, required this.text, required this.color, double life = 0.9})
      : life = life, maxLife = life;
}

// ─── Main widget ──────────────────────────────────────────────────────────────
class InfinityCounterGame extends StatefulWidget {
  const InfinityCounterGame({Key? key}) : super(key: key);
  @override
  State<InfinityCounterGame> createState() => _InfinityCounterGameState();
}

class _InfinityCounterGameState extends State<InfinityCounterGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // ── Core counters ──
  double _count = 0;       // player's count (float for smooth multipliers)
  double _enemyCount = 0;  // rival counter (WRONG TEAM power-up feeds this)
  int _tapsTotal = 0;      // total taps this game

  // ── Game clock ──
  double _elapsed = 0;
  bool _gameOver = false;

  // ── Milestone tracking ──
  int _milestoneIndex = 0;   // how many milestones have fired
  int _nextMilestone = _kICMilestoneInterval; // tap count for next event

  // ── Power-up selection ──
  bool _choosingPowerUp = false;
  List<_ICPowerUp> _choices = [];
  double _pickTimer = 0;

  // ── Active modifiers ──
  final _ICModifiers _mods = _ICModifiers();

  // ── Juice ──
  double _bgHue = 220;
  double _digitBounce = 0;
  double _shockwaveRadius = 0;
  double _shockwaveAlpha = 0;
  final List<_JuiceParticle> _particles = [];
  final List<_ICPop> _pops = [];

  // Auto-tap accumulator
  double _autoTapAccum = 0;

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

  // ── Tick ──────────────────────────────────────────────────────────────────
  void _tick() {
    if (_gameOver) return;
    // nominal dt; kept small by animation controller 60fps
    const double nomDt = 1 / 60.0;
    final double dt = _mods.timeSlow ? nomDt * 0.5 : nomDt;

    setState(() {
      _elapsed += dt;
      if (_elapsed >= _kICGameDuration) {
        _elapsed = _kICGameDuration;
        _gameOver = true;
        return;
      }

      // ── Timers for temporary mods ──
      if (_mods.timeSlow) {
        _mods.timeSlowTimer -= nomDt;
        if (_mods.timeSlowTimer <= 0) _mods.timeSlow = false;
      }
      if (_mods.tapForEnemy) {
        _mods.tapForEnemyTimer -= nomDt;
        if (_mods.tapForEnemyTimer <= 0) _mods.tapForEnemy = false;
      }

      // ── Chaos reverse timer ──
      if (_mods.chaosReverse) {
        _mods.chaosTimer += dt;
        if (_mods.chaosTimer >= _kICChaosReverseInterval) {
          _mods.chaosTimer = 0;
          _mods.tapReversed = !_mods.tapReversed;
          _spawnPop('FLIP!', Colors.purpleAccent);
        }
      }

      // ── Auto-tappers ──
      if (_mods.autoTappers > 0) {
        _autoTapAccum += _mods.autoTappers * _kICAutoTapRate * dt;
        while (_autoTapAccum >= 1.0) {
          _autoTapAccum -= 1.0;
          _applyTap(isAuto: true);
        }
      }

      // ── Power-up pick timeout ──
      if (_choosingPowerUp) {
        _pickTimer -= nomDt;
        if (_pickTimer <= 0) {
          // Auto-pick the first choice (player ran out of time)
          _applyPowerUp(_choices[0]);
          _choosingPowerUp = false;
        }
      }

      // ── Shockwave ──
      if (_shockwaveAlpha > 0) {
        _shockwaveRadius += 200 * nomDt;
        _shockwaveAlpha -= nomDt * 2.5;
        if (_shockwaveAlpha < 0) _shockwaveAlpha = 0;
      }

      // ── Digit bounce ──
      _digitBounce *= 0.88;

      // ── BG hue ──
      _bgHue += nomDt * (3 + _milestoneIndex * 0.4);
      if (_bgHue > 360) _bgHue -= 360;

      // ── Particles ──
      for (final p in _particles) {
        p.x += p.vx * nomDt;
        p.y += p.vy * nomDt;
        p.vy += 60 * nomDt;
        p.life -= nomDt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // ── Pops ──
      for (final p in _pops) {
        p.y -= 28 * nomDt;
        p.life -= nomDt;
      }
      _pops.removeWhere((p) => p.life <= 0);
    });
  }

  // ── Apply a single tap unit ───────────────────────────────────────────────
  void _applyTap({bool isAuto = false}) {
    // Giant tap multiplier
    double extra = 1.0;
    if (!isAuto && _mods.giantTapCharges > 0) {
      extra = 10.0;
      _mods.giantTapCharges--;
    }
    final double value = _kICBaseTapValue * _mods.tapMultiplier * extra;

    if (_mods.tapForEnemy) {
      _enemyCount += value;
    } else if (_mods.tapReversed) {
      _count -= value;
    } else {
      _count += value;
    }

    if (!isAuto) {
      _tapsTotal++;
      _shockwaveRadius = 0;
      _shockwaveAlpha = 0.45;
      _digitBounce = 1.0;
      _spawnTapParticles();
      _checkMilestone();
    }
  }

  // ── Check / fire milestone ─────────────────────────────────────────────────
  void _checkMilestone() {
    if (_choosingPowerUp) return; // don't stack events
    if (_tapsTotal >= _nextMilestone) {
      _fireMilestone();
    }
  }

  void _fireMilestone() {
    _milestoneIndex++;
    // Next milestone: interval may have been halved by DOUBLE-DOWN
    final int effectiveInterval =
        (_kICMilestoneInterval / _mods.milestoneIntervalDiv).round().clamp(1, 9999);
    _nextMilestone = _tapsTotal + effectiveInterval;

    // Number of choices: 2^(milestoneIndex-1), capped at _kICMaxChoices
    // Milestone 1 → 1 (auto-granted), 2 → 2, 3 → 4, 4 → 8 …
    final int numChoices = min(_kICMaxChoices, 1 << (_milestoneIndex - 1)).toInt();

    _spawnMilestoneExplosion();

    if (numChoices == 1) {
      // Auto-grant a random power-up
      final pu = _kICAllPowerUps[_rng.nextInt(_kICAllPowerUps.length)];
      _applyPowerUp(pu);
      _spawnPop(pu.emoji + ' ' + pu.label, Colors.amberAccent, big: true);
    } else {
      // Build unique choices (shuffle pool, take numChoices)
      final pool = List<_ICPowerUp>.from(_kICAllPowerUps)..shuffle(_rng);
      _choices = pool.take(numChoices).toList();
      _pickTimer = _kICPickTimeout;
      _choosingPowerUp = true;
    }
  }

  // ── Apply chosen power-up ─────────────────────────────────────────────────
  void _applyPowerUp(_ICPowerUp pu) {
    switch (pu.type) {
      case _ICPowerUpType.autoTapper:
        _mods.autoTappers++;
        break;
      case _ICPowerUpType.tapReverse:
        _mods.tapReversed = !_mods.tapReversed;
        break;
      case _ICPowerUpType.multiplier:
        _mods.tapMultiplier *= _kICMultiplierFactor;
        break;
      case _ICPowerUpType.doubleDown:
        _mods.milestoneIntervalDiv = min(_mods.milestoneIntervalDiv * 2, 8);
        break;
      case _ICPowerUpType.chaosReverse:
        _mods.chaosReverse = true;
        _mods.chaosTimer = 0;
        break;
      case _ICPowerUpType.giantTap:
        _mods.giantTapCharges += 5;
        break;
      case _ICPowerUpType.tapForEnemy:
        _mods.tapForEnemy = true;
        _mods.tapForEnemyTimer = 8.0;
        break;
      case _ICPowerUpType.timeSlow:
        _mods.timeSlow = true;
        _mods.timeSlowTimer = 10.0;
        break;
      case _ICPowerUpType.countReset:
        _count = 0;
        _spawnMilestoneExplosion();
        break;
      case _ICPowerUpType.bonusBurst:
        _count += 50;
        _spawnPop('+50!', Colors.greenAccent, big: true);
        break;
    }
  }

  // ── Player taps the game screen ───────────────────────────────────────────
  void _onTap() {
    if (_gameOver || _choosingPowerUp) return;
    setState(() => _applyTap());
  }

  // ── Player picks a power-up card ──────────────────────────────────────────
  void _onPickPowerUp(_ICPowerUp pu) {
    setState(() {
      _applyPowerUp(pu);
      _choosingPowerUp = false;
      _spawnPop(pu.emoji + ' ' + pu.label, Colors.cyanAccent, big: true);
    });
  }

  // ── Juice helpers ──────────────────────────────────────────────────────────
  void _spawnTapParticles() {
    for (int i = 0; i < _kICTapParticles; i++) {
      _particles.add(_JuiceParticle(
        x: (_rng.nextDouble() - 0.5) * 80,
        y: (_rng.nextDouble() - 0.5) * 50,
        vx: (_rng.nextDouble() - 0.5) * 80,
        vy: -40 - _rng.nextDouble() * 60,
        life: 0.55,
        color: HSVColor.fromAHSV(1, _bgHue + _rng.nextDouble() * 40 - 20, 0.7, 1.0).toColor(),
        radius: 2.5 + _rng.nextDouble() * 2,
      ));
    }
  }

  void _spawnMilestoneExplosion() {
    for (int i = 0; i < _kICMilestoneParticles; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 100 + _rng.nextDouble() * 200;
      _particles.add(_JuiceParticle(
        x: 0, y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 60,
        life: 1.4,
        color: HSVColor.fromAHSV(1, _rng.nextDouble() * 360, 0.9, 1.0).toColor(),
        radius: 3.5 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _spawnPop(String text, Color color, {bool big = false}) {
    _pops.add(_ICPop(
      x: (_rng.nextDouble() - 0.5) * 80,
      y: -20 - _rng.nextDouble() * 30,
      text: text,
      color: color,
      life: big ? 1.4 : 0.9,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bgColor = HSVColor.fromAHSV(1, _bgHue, 0.18, 0.05).toColor();

    return LayoutBuilder(builder: (context, constraints) {
      final centerX = constraints.maxWidth / 2;
      final centerY = constraints.maxHeight * 0.38;
      final timeLeft = max(0.0, _kICGameDuration - _elapsed);
      final timerFraction = 1.0 - (_elapsed / _kICGameDuration).clamp(0.0, 1.0);

      return GestureDetector(
        onTapDown: (_choosingPowerUp || _gameOver) ? null : (_) => _onTap(),
        child: Container(
          color: bgColor,
          child: Stack(
            children: [
              // ── Timer bar (top) ──────────────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                height: 4,
                child: FractionallySizedBox(
                  widthFactor: timerFraction,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    color: HSVColor.fromAHSV(1, (1 - timerFraction) * 60, 0.9, 1.0).toColor(),
                  ),
                ),
              ),

              // ── Time remaining label ──────────────────────────────────────
              Positioned(
                top: 8, right: 14,
                child: Text(
                  '${timeLeft.ceil()}s',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),

              // ── Milestone counter (top-left) ──────────────────────────────
              Positioned(
                top: 8, left: 14,
                child: Text(
                  'EVENT $_milestoneIndex  •  next in ${max(0, _nextMilestone - _tapsTotal)}',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: Colors.amberAccent.withValues(alpha: 0.65),
                  ),
                ),
              ),

              // ── Shockwave ring ────────────────────────────────────────────
              if (_shockwaveAlpha > 0)
                Positioned(
                  left: centerX - _shockwaveRadius,
                  top: centerY - _shockwaveRadius,
                  child: IgnorePointer(
                    child: Container(
                      width: _shockwaveRadius * 2,
                      height: _shockwaveRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HSVColor.fromAHSV(_shockwaveAlpha.clamp(0.0, 1.0), _bgHue, 0.6, 1.0).toColor(),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Particles ─────────────────────────────────────────────────
              ..._particles.where((p) => p.life > 0).map((p) => Positioned(
                left: centerX + p.x - p.radius,
                top: centerY + p.y - p.radius,
                child: IgnorePointer(
                  child: Container(
                    width: p.radius * 2,
                    height: p.radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              )),

              // ── Big count number ──────────────────────────────────────────
              Positioned(
                left: 0, right: 0,
                top: centerY - 80,
                child: IgnorePointer(
                  child: Transform.scale(
                    scaleY: (1.0 + _digitBounce * 0.25).clamp(0.7, 1.5),
                    child: Text(
                      _count < 0
                          ? '-${(-_count).round()}'
                          : '${_count.round()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: _countFontSize(),
                        fontWeight: FontWeight.w900,
                        color: _mods.tapReversed
                            ? Colors.redAccent.withValues(alpha: 0.9)
                            : HSVColor.fromAHSV(0.92, _bgHue, 0.25, 1.0).toColor(),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Floating pop labels ───────────────────────────────────────
              ..._pops.where((p) => p.life > 0).map((p) => Positioned(
                left: centerX + p.x - 60,
                top: centerY + p.y,
                width: 120,
                child: IgnorePointer(
                  child: Text(
                    p.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              )),

              // ── Active mods HUD strip ─────────────────────────────────────
              Positioned(
                bottom: 120, left: 8, right: 8,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: _mods.activeLabels().map((label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Colors.white70),
                    ),
                  )).toList(),
                ),
              ),

              // ── Enemy count (visible when WRONG TEAM active) ──────────────
              if (_mods.tapForEnemy)
                Positioned(
                  bottom: 155, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'RIVAL: ${_enemyCount.round()}',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ),

              // ── Tap prompt ────────────────────────────────────────────────
              Positioned(
                bottom: 52, left: 0, right: 0,
                child: Center(
                  child: Text(
                    _mods.tapReversed ? 'TAP  (counts DOWN)' : 'TAP  to count up',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),

              // ── Power-up choice overlay ───────────────────────────────────
              if (_choosingPowerUp)
                _buildChoiceOverlay(constraints),

              // ── Game over overlay ─────────────────────────────────────────
              if (_gameOver)
                _buildGameOverOverlay(),
            ],
          ),
        ),
      );
    });
  }

  // ── Font size grows with count ─────────────────────────────────────────────
  double _countFontSize() {
    final abs = _count.abs();
    if (abs < 50) return 72;
    if (abs < 200) return 80;
    if (abs < 1000) return 92;
    return 104.0;
  }

  // ── Power-up choice overlay ────────────────────────────────────────────────
  Widget _buildChoiceOverlay(BoxConstraints constraints) {
    final numChoices = _choices.length;

    // Column count: 1–2 → single row; 3–4 → 2 cols; 5–16 → 4 cols; 17+ → 5 cols.
    // Fewer cols means larger cards which are easier to tap.
    final cols = numChoices <= 2
        ? numChoices
        : numChoices <= 4
            ? 2
            : numChoices <= 16
                ? 4
                : 5;

    // Card aspect ratio: tall cards at low counts, more square at high counts so
    // many cards fit. Min 0.72 keeps the desc text readable.
    final double aspect = numChoices <= 4
        ? 1.3
        : numChoices <= 8
            ? 1.05
            : numChoices <= 16
                ? 0.88
                : 0.72;

    final pickFrac = (_pickTimer / _kICPickTimeout).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.80),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Header
              Text(
                'EVENT $_milestoneIndex  —  PICK A POWER-UP',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.amberAccent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Pick timer bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: LinearProgressIndicator(
                  value: pickFrac,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    Color.lerp(Colors.redAccent, Colors.greenAccent, pickFrac)!,
                  ),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 4),
              // Scroll hint — only shown when many cards are present
              if (numChoices > 8)
                Text(
                  'scroll to see all options',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              const SizedBox(height: 4),
              // Cards grid — ALWAYS scrollable so 16/32/64 options never overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    // Scrollable — items at the bottom remain reachable even at 64 cards
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: numChoices > 8 ? 6 : 8,
                      mainAxisSpacing: numChoices > 8 ? 6 : 8,
                      childAspectRatio: aspect,
                    ),
                    itemCount: numChoices,
                    itemBuilder: (_, i) => _buildPowerUpCard(_choices[i], compact: numChoices > 8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerUpCard(_ICPowerUp pu, {bool compact = false}) {
    // Scale down typography and padding when many cards are on screen so
    // everything stays readable without needing massive screen real estate.
    final double emojiFontSize = compact ? 16.0 : 22.0;
    final double labelFontSize = compact ? 9.0 : 11.0;
    final double descFontSize = compact ? 8.0 : 9.0;
    final EdgeInsets pad = compact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 10);

    return GestureDetector(
      onTapDown: (_) => _onPickPowerUp(pu),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        ),
        padding: pad,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pu.emoji, style: TextStyle(fontSize: emojiFontSize)),
            SizedBox(height: compact ? 2 : 4),
            Text(
              pu.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: labelFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: compact ? 1 : 2),
            Text(
              pu.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: descFontSize,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game over screen ───────────────────────────────────────────────────────
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FINAL COUNT',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_count.round()}',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 88,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_tapsTotal taps  •  event $_milestoneIndex',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              if (_mods.activeLabels().isNotEmpty)
                Text(
                  _mods.activeLabels().join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: Colors.amberAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ClusterGravityGame — "Gravity Sling"
// Slingshot a small galaxy around clusters to reach a target. Golf-style scoring.
// ═══════════════════════════════════════════════════════════════════════════════

class _GravCluster {
  double x, y, mass;
  _GravCluster(this.x, this.y, this.mass);
}

class ClusterGravityGame extends StatefulWidget {
  const ClusterGravityGame({Key? key}) : super(key: key);
  @override
  State<ClusterGravityGame> createState() => _ClusterGravityGameState();
}

class _ClusterGravityGameState extends State<ClusterGravityGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // Galaxy (the player projectile)
  double _gx = 0, _gy = 0, _gvx = 0, _gvy = 0;
  bool _launched = false;
  bool _dragging = false;
  Offset _dragStart = Offset.zero;
  Offset _dragCurrent = Offset.zero;
  final List<Offset> _trail = [];

  // Clusters (gravity wells)
  List<_GravCluster> _clusters = [];

  // Target
  double _tx = 0, _ty = 0;

  // Scoring
  int _slings = 0;
  int _level = 1;
  int _score = 0;
  bool _levelComplete = false;
  bool _outOfBounds = false;
  double _lastTime = 0;

  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setupLevel(double w, double h) {
    _gx = 0.1;
    _gy = 0.8;
    _gvx = 0;
    _gvy = 0;
    _launched = false;
    _levelComplete = false;
    _outOfBounds = false;
    _slings = 0;
    _trail.clear();
    _particles.clear();
    _clusters.clear();

    if (_level == 1) {
      // Level 1: single cluster in the middle, target directly above it — easy slingshot
      _clusters.add(_GravCluster(0.5, 0.5, 0.5));
      _tx = 0.85;
      _ty = 0.15;
    } else if (_level == 2) {
      // Level 2: two clusters, target requires curving around one
      _clusters.add(_GravCluster(0.4, 0.45, 0.45));
      _clusters.add(_GravCluster(0.7, 0.3, 0.35));
      _tx = 0.85;
      _ty = 0.12;
    } else {
      // Level 3+: random clusters, increasing count and mass
      final count = 2 + ((_level - 2) ~/ 2).clamp(0, 4);
      for (int i = 0; i < count; i++) {
        _clusters.add(_GravCluster(
          0.2 + _rng.nextDouble() * 0.6,
          0.15 + _rng.nextDouble() * 0.55,
          0.3 + _rng.nextDouble() * 0.5,
        ));
      }
      _tx = 0.7 + _rng.nextDouble() * 0.2;
      _ty = 0.08 + _rng.nextDouble() * 0.2;
    }
  }

  bool _needsSetup = true;

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      if (_launched && !_levelComplete && !_outOfBounds) {
        // Apply gravity from each cluster
        for (final c in _clusters) {
          final dx = c.x - _gx;
          final dy = c.y - _gy;
          final dist = sqrt(dx * dx + dy * dy).clamp(0.03, 2.0);
          final force = c.mass * 0.08 / (dist * dist);
          _gvx += dx / dist * force * dt;
          _gvy += dy / dist * force * dt;
        }
        _gx += _gvx * dt;
        _gy += _gvy * dt;

        // Trail
        _trail.add(Offset(_gx, _gy));
        if (_trail.length > 80) _trail.removeAt(0);

        // Check target hit
        final tdx = _gx - _tx;
        final tdy = _gy - _ty;
        if (sqrt(tdx * tdx + tdy * tdy) < 0.04) {
          _levelComplete = true;
          final bonus = max(0, 30 - _slings * 5);
          _score += 10 + bonus;
          for (int i = 0; i < 20; i++) {
            final a = _rng.nextDouble() * 2 * pi;
            _particles.add(_JuiceParticle(
              x: _tx, y: _ty,
              vx: cos(a) * 0.3, vy: sin(a) * 0.3,
              life: 0.8, color: Colors.amberAccent,
            ));
          }
        }

        // Out of bounds
        if (_gx < -0.15 || _gx > 1.15 || _gy < -0.15 || _gy > 1.15) {
          _outOfBounds = true;
        }

        // Check collision with cluster (too close = crash)
        for (final c in _clusters) {
          final dx = _gx - c.x;
          final dy = _gy - c.y;
          if (sqrt(dx * dx + dy * dy) < 0.03) {
            _outOfBounds = true;
            for (int i = 0; i < 10; i++) {
              final a = _rng.nextDouble() * 2 * pi;
              _particles.add(_JuiceParticle(
                x: c.x, y: c.y,
                vx: cos(a) * 0.2, vy: sin(a) * 0.2,
                life: 0.5, color: Colors.redAccent,
              ));
            }
          }
        }
      }

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _launch() {
    if (_levelComplete || _outOfBounds) return;
    final dx = _dragStart.dx - _dragCurrent.dx;
    final dy = _dragStart.dy - _dragCurrent.dy;
    _gvx = dx / 200.0 * 0.8;
    _gvy = dy / 200.0 * 0.8;
    _launched = true;
    _slings++;
    _dragging = false;
  }

  void _resetShot() {
    setState(() {
      _gx = 0.1;
      _gy = 0.8;
      _gvx = 0;
      _gvy = 0;
      _launched = false;
      _outOfBounds = false;
      _trail.clear();
    });
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _needsSetup = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      if (_needsSetup) {
        _setupLevel(w, h);
        _needsSetup = false;
      }
      return GestureDetector(
        onPanStart: (d) {
          if (_launched || _levelComplete) return;
          final gxPx = _gx * w;
          final gyPx = _gy * h;
          if ((d.localPosition - Offset(gxPx, gyPx)).distance < 50) {
            _dragging = true;
            _dragStart = d.localPosition;
            _dragCurrent = d.localPosition;
          }
        },
        onPanUpdate: (d) {
          if (_dragging) setState(() => _dragCurrent = d.localPosition);
        },
        onPanEnd: (d) {
          if (_dragging) _launch();
        },
        child: Container(
          color: const Color(0xFF030310),
          child: CustomPaint(
            painter: _GravitySlingPainter(
              gx: _gx, gy: _gy, trail: _trail,
              clusters: _clusters, tx: _tx, ty: _ty,
              particles: _particles, dragging: _dragging,
              dragStart: _dragStart, dragCurrent: _dragCurrent,
              launched: _launched, slings: _slings,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level $_level', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
                      Text('Slings: $_slings', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                      Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
                if (_levelComplete)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Target Reached!', style: TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                        Text('$_slings sling${_slings == 1 ? "" : "s"}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _nextLevel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.amber.withValues(alpha: 0.2), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5))),
                            child: const Text('Next Level', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_outOfBounds && !_levelComplete)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Lost in space!', style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _resetShot,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                            child: const Text('Try Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_launched && !_levelComplete && !_dragging)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Drag from your galaxy to slingshot', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white24))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _GravitySlingPainter extends CustomPainter {
  final double gx, gy;
  final List<Offset> trail;
  final List<_GravCluster> clusters;
  final double tx, ty;
  final List<_JuiceParticle> particles;
  final bool dragging, launched;
  final Offset dragStart, dragCurrent;
  final int slings;

  _GravitySlingPainter({
    required this.gx, required this.gy, required this.trail,
    required this.clusters, required this.tx, required this.ty,
    required this.particles, required this.dragging,
    required this.dragStart, required this.dragCurrent,
    required this.launched, required this.slings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Stars
    final rng = Random(77);
    for (int i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.3 + rng.nextDouble() * 0.6,
        Paint()..color = Colors.white.withValues(alpha: 0.08 + rng.nextDouble() * 0.15),
      );
    }

    // Clusters (gravity wells)
    for (final c in clusters) {
      final cx = c.x * size.width;
      final cy = c.y * size.height;
      final r = 12 + c.mass * 20;
      // Gravity field visualization
      canvas.drawCircle(Offset(cx, cy), r * 3, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.04));
      canvas.drawCircle(Offset(cx, cy), r * 2, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.06));
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF7B1FA2).withValues(alpha: 0.5));
      canvas.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.6));
    }

    // Target
    final txPx = tx * size.width;
    final tyPx = ty * size.height;
    canvas.drawCircle(Offset(txPx, tyPx), 18, Paint()..color = Colors.amber.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(txPx, tyPx), 12, Paint()..color = Colors.amber.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(txPx, tyPx), 6, Paint()..color = Colors.amberAccent);
    // Crosshair
    final cp = Paint()..color = Colors.amberAccent.withValues(alpha: 0.4)..strokeWidth = 1;
    canvas.drawLine(Offset(txPx - 16, tyPx), Offset(txPx + 16, tyPx), cp);
    canvas.drawLine(Offset(txPx, tyPx - 16), Offset(txPx, tyPx + 16), cp);

    // Trail
    if (trail.length > 1) {
      for (int i = 1; i < trail.length; i++) {
        final alpha = i / trail.length * 0.5;
        canvas.drawLine(
          Offset(trail[i - 1].dx * size.width, trail[i - 1].dy * size.height),
          Offset(trail[i].dx * size.width, trail[i].dy * size.height),
          Paint()..color = Colors.cyanAccent.withValues(alpha: alpha)..strokeWidth = 1.5,
        );
      }
    }

    // Galaxy (player)
    final gpx = gx * size.width;
    final gpy = gy * size.height;
    canvas.drawCircle(Offset(gpx, gpy), 12, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(gpx, gpy), 7, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.5));
    canvas.drawCircle(Offset(gpx, gpy), 3.5, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Drag arrow
    if (dragging) {
      final dx = dragStart.dx - dragCurrent.dx;
      final dy = dragStart.dy - dragCurrent.dy;
      canvas.drawLine(
        Offset(gpx, gpy),
        Offset(gpx + dx, gpy + dy),
        Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round,
      );
      // Power indicator
      final power = sqrt(dx * dx + dy * dy).clamp(0.0, 200.0) / 200.0;
      canvas.drawCircle(
        Offset(gpx, gpy), 10 + power * 20,
        Paint()..color = Color.lerp(Colors.cyanAccent, Colors.redAccent, power)!.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), 2.5,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GravitySlingPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// NeuronConnectGame — "Neural Signal Web" time-trial
// Tap neurons to rotate their axon gate direction. Fire the signal from source
// to target. Each cleared puzzle spawns a harder one. 60-second time trial.
// ═══════════════════════════════════════════════════════════════════════════════

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tweak here without touching game logic
// ---------------------------------------------------------------------------

/// Total seconds for the time-trial run.
const double _ncTrialDuration = 60.0;

/// How fast the signal moves across one cell (cells per second).
const double _ncSignalSpeed = 3.2;

/// Starfield: number of background stars.
const int _ncStarCount = 110;

/// Glow bloom radius on the signal dot (used by the signal pulse painter).
const double _ncSignalGlowBlur = 12.0;

/// Particle count burst on puzzle clear.
const int _ncClearParticles = 28;

/// Particle count burst on signal death.
const int _ncDeadParticles = 14;

/// Particle lifetime on clear (seconds).
const double _ncClearParticleLife = 1.1;

/// Particle lifetime on death (seconds).
const double _ncDeadParticleLife = 0.7;

/// Easing exponent for particle spread (higher = tighter burst).
const double _ncParticleSpeedMax = 2.4;

/// Points awarded per cleared puzzle (multiplied by puzzle index for escalation).
const int _ncBasePoints = 100;

/// Connection beam stroke width (dp).
const double _ncBeamWidth = 3.5;

/// Animated beam shimmer cycle duration (seconds).
const double _ncBeamShimmerPeriod = 1.4;

// Neuron accent colour (electric violet — the scale accent for BioScale.cosmicStructures).
const Color _ncAccent = Color(0xFF9C6FFF); // vivid indigo-violet
const Color _ncSourceColor = Color(0xFF40C4FF); // electric cyan — SOURCE neuron
const Color _ncTargetColor = Color(0xFFFF6B6B); // warm coral — TARGET neuron
const Color _ncNormalColor = Color(0xFF7E57C2); // muted violet — relay neuron
const Color _ncSignalColor = Color(0xFFE0F7FA); // near-white signal pulse
const Color _ncDeadColor   = Color(0xFFFF5252); // signal-failure red

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// Direction a node's exit gate points.
enum _GateDir { up, right, down, left }

/// Grid offset for each direction.
const Map<_GateDir, List<int>> _gateDelta = {
  _GateDir.up: [0, -1],
  _GateDir.right: [1, 0],
  _GateDir.down: [0, 1],
  _GateDir.left: [-1, 0],
};

/// Node type on the puzzle grid.
enum _SRNodeType { normal, source, target, blocker }

/// A single node in the grid.
class _SRNode {
  _SRNodeType type;
  _GateDir dir;
  final _GateDir initialDir;
  final bool locked;
  _SRNode({required this.type, required this.dir, this.locked = false})
      : initialDir = dir;
  void resetDir() => dir = initialDir;
}

/// One puzzle layout.
class _SRLevel {
  final int cols;
  final int rows;
  final List<_SRNode> nodes;
  final int minRotations;
  _SRLevel({required this.cols, required this.rows, required this.nodes, required this.minRotations});
}

/// A live signal travelling through the grid.
class _SRSignal {
  int col, row, nextCol, nextRow;
  double t;
  bool dead, arrived;
  final List<List<int>> trail;
  final int id;
  _SRSignal({required this.col, required this.row, required this.id})
      : nextCol = col, nextRow = row, t = 0, dead = false, arrived = false,
        trail = [[col, row]];
}

/// One star in the animated starfield background.
class _NCStar {
  final double x, y, radius, brightness, twinklePhase, twinkleSpeed;
  const _NCStar({required this.x, required this.y, required this.radius,
      required this.brightness, required this.twinklePhase, required this.twinkleSpeed});
}

// ---------------------------------------------------------------------------
// Level generation
// ---------------------------------------------------------------------------

/// Returns an escalating level for the given index (0-based).
/// Grids grow from 3×3 up to 7×6 and blocker/lock density increases.
_SRLevel _ncGenerateLevel(int idx, Random rng) {
  // Grid size escalation: starts 3×3, grows every 2 puzzles
  final cols = (3 + (idx ~/ 2)).clamp(3, 7);
  final rows = (3 + (idx ~/ 3)).clamp(3, 6);
  final total = cols * rows;
  final blockerChance = (0.05 + idx * 0.015).clamp(0.0, 0.22);
  final lockChance = (0.0 + idx * 0.01).clamp(0.0, 0.15);
  final dirs = _GateDir.values;

  final nodes = List<_SRNode>.generate(total, (i) {
    final col = i % cols;
    final row = i ~/ cols;
    if (col == 0 && row == 0) return _SRNode(type: _SRNodeType.source, dir: _GateDir.right);
    if (col == cols - 1 && row == rows - 1) return _SRNode(type: _SRNodeType.target, dir: _GateDir.left);
    if (col > 0 && row > 0 && col < cols - 1 && row < rows - 1 && rng.nextDouble() < blockerChance) {
      return _SRNode(type: _SRNodeType.blocker, dir: _GateDir.right);
    }
    final locked = rng.nextDouble() < lockChance;
    return _SRNode(type: _SRNodeType.normal, dir: dirs[rng.nextInt(4)], locked: locked);
  });

  // BFS to find a solvable path, then scramble directions by 1-3 rotations
  final visited = List<bool>.filled(total, false);
  final parent = List<int>.filled(total, -1);
  final queue = <int>[0];
  visited[0] = true;
  bool found = false;
  while (queue.isNotEmpty && !found) {
    final cur = queue.removeAt(0);
    final cx = cur % cols;
    final cy = cur ~/ cols;
    for (final d in _GateDir.values) {
      final nx = cx + _gateDelta[d]![0];
      final ny = cy + _gateDelta[d]![1];
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
      final ni = ny * cols + nx;
      if (visited[ni] || nodes[ni].type == _SRNodeType.blocker) continue;
      visited[ni] = true;
      parent[ni] = cur;
      queue.add(ni);
      if (ni == total - 1) { found = true; break; }
    }
  }
  if (found) {
    int cur = total - 1;
    while (parent[cur] != -1) {
      final prev = parent[cur];
      final dx = (cur % cols) - (prev % cols);
      final dy = (cur ~/ cols) - (prev ~/ cols);
      _GateDir needed;
      if (dx == 1) { needed = _GateDir.right; }
      else if (dx == -1) { needed = _GateDir.left; }
      else if (dy == 1) { needed = _GateDir.down; }
      else { needed = _GateDir.up; }
      if (nodes[prev].type != _SRNodeType.target && !nodes[prev].locked) {
        final rotations = 1 + rng.nextInt(3);
        final scrambled = (_GateDir.values.indexOf(needed) + rotations) % 4;
        nodes[prev] = _SRNode(type: nodes[prev].type, dir: _GateDir.values[scrambled], locked: false);
      } else if (nodes[prev].type != _SRNodeType.target && nodes[prev].locked) {
        nodes[prev] = _SRNode(type: nodes[prev].type, dir: needed, locked: true);
      }
      cur = prev;
    }
  }
  return _SRLevel(cols: cols, rows: rows, nodes: nodes, minRotations: 2 + idx);
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class NeuronConnectGame extends StatefulWidget {
  const NeuronConnectGame({Key? key}) : super(key: key);
  @override
  State<NeuronConnectGame> createState() => _NeuronConnectGameState();
}

class _NeuronConnectGameState extends State<NeuronConnectGame>
    with SingleTickerProviderStateMixin {

  // ── state machine ─────────────────────────────────────────────────────────
  _NCPhase _phase = _NCPhase.intro;

  // ── timer ─────────────────────────────────────────────────────────────────
  double _elapsed = 0;
  double _lastWallTime = 0;

  // ── puzzle state ──────────────────────────────────────────────────────────
  int _puzzleIndex = 0;
  int _puzzlesCleared = 0;
  int _score = 0;
  late _SRLevel _level;
  List<_SRNode> _playNodes = [];
  List<_SRSignal> _activeSignals = [];
  bool _signalAnimating = false;
  bool _signalDead = false;

  // ── cosmetics ─────────────────────────────────────────────────────────────
  final List<_JuiceParticle> _particles = [];
  final List<FxPop> _scorePops = [];
  late List<_NCStar> _stars;
  double _beamPhase = 0;
  double _completionFlashAlpha = 0;
  // Per-node pulse offset so each neuron has a unique idle phase.
  late List<double> _nodePhaseOffset;

  // ── misc ──────────────────────────────────────────────────────────────────
  final Random _rng = Random();
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(_ncStarCount, (_) => _NCStar(
      x: _rng.nextDouble(), y: _rng.nextDouble(),
      radius: 0.5 + _rng.nextDouble() * 1.8,
      brightness: 0.3 + _rng.nextDouble() * 0.7,
      twinklePhase: _rng.nextDouble() * 2 * pi,
      twinkleSpeed: 0.5 + _rng.nextDouble() * 1.5,
    ));
    _nodePhaseOffset = List.generate(64, (_) => _rng.nextDouble() * 2 * pi);
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── phase transitions ─────────────────────────────────────────────────────

  void _startTrial() {
    _puzzleIndex = 0;
    _puzzlesCleared = 0;
    _score = 0;
    _elapsed = 0;
    _lastWallTime = _now();
    _spawnNextPuzzle();
    setState(() => _phase = _NCPhase.trial);
    _ctrl.forward(from: 0);
  }

  void _spawnNextPuzzle() {
    _level = _ncGenerateLevel(_puzzleIndex, Random(_puzzleIndex * 31 + 7));
    _playNodes = _level.nodes.map((n) => _SRNode(type: n.type, dir: n.dir, locked: n.locked)).toList();
    _activeSignals.clear();
    _signalAnimating = false;
    _signalDead = false;
  }

  void _endTrial() {
    setState(() => _phase = _NCPhase.done);
    _ctrl.stop();
  }

  // ── input ─────────────────────────────────────────────────────────────────

  void _rotateNode(int index) {
    if (_phase != _NCPhase.trial || _signalAnimating) return;
    final node = _playNodes[index];
    if (node.type == _SRNodeType.blocker || node.locked) return;
    setState(() {
      node.dir = _GateDir.values[(_GateDir.values.indexOf(node.dir) + 1) % 4];
      _signalDead = false;
    });
  }

  void _sendSignal() {
    if (_phase != _NCPhase.trial || _signalAnimating) return;
    setState(() {
      _activeSignals.clear();
      _signalDead = false;
      _signalAnimating = true;
      int sigId = 0;
      for (int i = 0; i < _playNodes.length; i++) {
        if (_playNodes[i].type == _SRNodeType.source) {
          _activeSignals.add(_SRSignal(col: i % _level.cols, row: i ~/ _level.cols, id: sigId++));
        }
      }
    });
  }

  // ── tick ──────────────────────────────────────────────────────────────────

  void _tick() {
    final now = _now();
    final dt = (now - _lastWallTime).clamp(0.001, 0.05);
    _lastWallTime = now;

    setState(() {
      _beamPhase += dt;
      if (_completionFlashAlpha > 0) {
        _completionFlashAlpha = (_completionFlashAlpha - dt * 3).clamp(0.0, 1.0);
      }

      // ── advance particles ──────────────────────────────────────────────
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
      _scorePops.removeWhere((sp) => !sp.step(dt));

      if (_phase == _NCPhase.trial) {
        _elapsed += dt;
        if (_elapsed >= _ncTrialDuration) {
          _elapsed = _ncTrialDuration;
          _endTrial();
          return;
        }

        if (!_signalAnimating) return;
        bool anyMoving = false;
        for (final sig in _activeSignals) {
          if (sig.dead || sig.arrived) continue;
          anyMoving = true;
          sig.t += dt * _ncSignalSpeed;
          if (sig.t >= 1.0) {
            sig.col = sig.nextCol;
            sig.row = sig.nextRow;
            sig.t = 0;
            sig.trail.add([sig.col, sig.row]);

            final ni = sig.row * _level.cols + sig.col;
            if (_playNodes[ni].type == _SRNodeType.target) {
              sig.arrived = true;
              _spawnClearParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows);
              continue;
            }
            final delta = _gateDelta[_playNodes[ni].dir]!;
            final nc = sig.col + delta[0];
            final nr = sig.row + delta[1];
            if (nc < 0 || nr < 0 || nc >= _level.cols || nr >= _level.rows) {
              sig.dead = true;
              _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows);
              continue;
            }
            final nni = nr * _level.cols + nc;
            if (_playNodes[nni].type == _SRNodeType.blocker) {
              sig.dead = true;
              _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows);
              continue;
            }
            if (sig.trail.any((p) => p[0] == nc && p[1] == nr)) {
              sig.dead = true;
              _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows);
              continue;
            }
            sig.nextCol = nc;
            sig.nextRow = nr;
          }
        }

        final allDone = !anyMoving || _activeSignals.every((s) => s.dead || s.arrived);
        if (allDone) {
          if (_activeSignals.isNotEmpty && _activeSignals.every((s) => s.arrived)) {
            _puzzlesCleared++;
            final timeBonus = ((_ncTrialDuration - _elapsed) / _ncTrialDuration * 50).round();
            final pts = _ncBasePoints * (_puzzleIndex + 1) + timeBonus;
            _score += pts;
            _completionFlashAlpha = 0.6;
            // Score pop above the target neuron — computed in pixel space later
            // by the painter; we store a unit-space anchor the painter reads.
            _scorePops.add(FxPop(
              Offset(0.5, 0.45), // recomputed in painter via _ncPopOffset
              '+$pts',
              _ncAccent,
            ));
            _puzzleIndex++;
            _spawnNextPuzzle();
          } else if (_activeSignals.any((s) => s.dead)) {
            _signalDead = true;
            _signalAnimating = false;
          }
        }
      }
    });
  }

  // ── particle helpers ──────────────────────────────────────────────────────

  void _spawnClearParticles(double gc, double gr, int cols, int rows) {
    for (int i = 0; i < _ncClearParticles; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 0.4 + _rng.nextDouble() * (_ncParticleSpeedMax - 0.4);
      final nx = (gc + 0.5) / cols;
      final ny = (gr + 0.5) / rows;
      final pick = i % 3;
      _particles.add(_JuiceParticle(
        x: nx, y: ny,
        vx: cos(a) * spd / cols,
        vy: sin(a) * spd / rows,
        life: _ncClearParticleLife,
        color: pick == 0 ? _ncAccent : pick == 1 ? _ncSourceColor : Colors.white,
        radius: 2.5 + _rng.nextDouble() * 2.0,
      ));
    }
  }

  void _spawnDeadParticles(double gc, double gr, int cols, int rows) {
    for (int i = 0; i < _ncDeadParticles; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 0.2 + _rng.nextDouble() * 1.2;
      final nx = (gc + 0.5) / cols;
      final ny = (gr + 0.5) / rows;
      _particles.add(_JuiceParticle(
        x: nx, y: ny,
        vx: cos(a) * spd / cols,
        vy: sin(a) * spd / rows,
        life: _ncDeadParticleLife,
        color: _ncDeadColor,
        radius: 2.0 + _rng.nextDouble() * 1.5,
      ));
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _NCPhase.intro: return _buildIntro();
      case _NCPhase.trial: return _buildTrial();
      case _NCPhase.done:  return _buildDone();
    }
  }

  // ── intro screen ──────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkDeep,
            Color.lerp(Potatuhs.inkDeep, _ncAccent, 0.14)!,
            Potatuhs.inkDeep,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // ── title ────────────────────────────────────────────────────
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [_ncSourceColor, _ncAccent],
            ).createShader(b),
            child: Text(
              'NEURAL WEB',
              style: Potatuhs.display(size: 34, color: Colors.white, spacing: 4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'SIGNAL ROUTING TRIAL',
            style: Potatuhs.label(size: 13, color: Potatuhs.textFaint),
          ),
          const SizedBox(height: 44),

          // ── instruction cards ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(children: [
              _instrRow(Icons.touch_app_outlined, 'Tap neurons to rotate the axon gate'),
              const SizedBox(height: 14),
              _instrRow(Icons.bolt_outlined, 'Route CYAN source → CORAL target'),
              const SizedBox(height: 14),
              _instrRow(Icons.flash_on_outlined, 'Hit FIRE — signal travels the path'),
              const SizedBox(height: 14),
              _instrRow(Icons.timer_outlined,
                  'Each clear scores +points. ${_ncTrialDuration.toInt()}s — go deep.'),
            ]),
          ),
          const SizedBox(height: 52),

          // ── CTA ───────────────────────────────────────────────────────
          GestureDetector(
            onTap: _startTrial,
            child: Container(
              width: 210, height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_ncSourceColor, _ncAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: Potatuhs.glow(_ncAccent, strength: 0.5, blur: 22),
              ),
              alignment: Alignment.center,
              child: Text(
                'LAUNCH TRIAL',
                style: Potatuhs.body(size: 17, weight: FontWeight.w700,
                    color: Colors.white, spacing: 2.5),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _instrRow(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 20, color: _ncAccent.withValues(alpha: 0.8)),
      const SizedBox(width: 14),
      Expanded(
        child: Text(label,
          style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
      ),
    ]);
  }

  // ── trial screen ──────────────────────────────────────────────────────────

  Widget _buildTrial() {
    final timeLeft = (_ncTrialDuration - _elapsed).clamp(0.0, _ncTrialDuration);
    final timeFrac = timeLeft / _ncTrialDuration;
    final timerColor = timeFrac > 0.4
        ? _ncSourceColor
        : timeFrac > 0.15
            ? Potatuhs.gold
            : _ncDeadColor;

    return LayoutBuilder(builder: (ctx, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      return Stack(children: [
        // ── background + puzzle canvas ────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (d) {
              if (!_signalAnimating) {
                final idx = _ncNodeAtPos(d.localPosition, w, h);
                if (idx != null) _rotateNode(idx);
              }
            },
            child: CustomPaint(
              painter: _NCPainter(
                level: _level,
                nodes: _playNodes,
                signals: _activeSignals,
                particles: _particles,
                scorePops: _scorePops,
                stars: _stars,
                beamPhase: _beamPhase,
                completionFlash: _completionFlashAlpha,
                nodePhaseOffset: _nodePhaseOffset,
              ),
            ),
          ),
        ),

        // ── top HUD bar ───────────────────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Potatuhs.inkDeep.withValues(alpha: 0.92),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // timer ring
              SizedBox(width: 46, height: 46,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: timeFrac,
                    strokeWidth: 3.5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(timerColor),
                  ),
                  Text(
                    timeLeft.ceil().toString(),
                    style: Potatuhs.body(size: 13, weight: FontWeight.w800,
                        color: timerColor),
                  ),
                ]),
              ),
              const SizedBox(width: 14),
              // puzzle info
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CIRCUIT  #${_puzzleIndex + 1}',
                  style: Potatuhs.label(size: 12, color: _ncAccent)),
                Text('${_level.cols}×${_level.rows} grid  ·  $_puzzlesCleared cleared',
                  style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
              const Spacer(),
              // score
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$_score',
                  style: Potatuhs.display(size: 22, color: Potatuhs.textPrimary)),
                Text('pts',
                  style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
            ]),
          ),
        ),

        // ── instruction banner (first puzzle only) ─────────────────────
        if (_puzzleIndex == 0 && !_signalAnimating && !_signalDead)
          Positioned(
            top: 80, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: _ncAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _ncAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'TAP neurons to spin the axon gate — route CYAN to CORAL, then FIRE',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary),
              ),
            ),
          ),

        // ── fire button + dead hint ────────────────────────────────────
        Positioned(bottom: 18, left: 20, right: 20,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_signalDead && !_signalAnimating)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _ncDeadColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _ncDeadColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.warning_amber_rounded, size: 15,
                        color: _ncDeadColor.withValues(alpha: 0.85)),
                    const SizedBox(width: 8),
                    Text('Signal lost — reroute the axons and fire again',
                      style: Potatuhs.body(size: 12,
                          color: _ncDeadColor.withValues(alpha: 0.9))),
                  ]),
                ),
              ),
            GestureDetector(
              onTap: _signalAnimating ? null : _sendSignal,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                decoration: BoxDecoration(
                  gradient: _signalAnimating
                    ? null
                    : LinearGradient(
                        colors: [_ncSourceColor, _ncAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                  color: _signalAnimating ? Colors.white10 : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _signalAnimating
                    ? []
                    : Potatuhs.glow(_ncAccent, strength: 0.55, blur: 20),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (!_signalAnimating) ...[
                    const Icon(Icons.bolt, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _signalAnimating ? 'TRANSMITTING...' : 'FIRE SIGNAL',
                    style: Potatuhs.body(
                      size: 16,
                      weight: FontWeight.w700,
                      color: _signalAnimating
                          ? Colors.white38
                          : Colors.white,
                      spacing: 1.5,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]);
    });
  }

  // ── done screen ───────────────────────────────────────────────────────────

  Widget _buildDone() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkDeep,
            Color.lerp(Potatuhs.inkDeep, _ncAccent, 0.18)!,
            Potatuhs.inkDeep,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(
            shaderCallback: (b) =>
                LinearGradient(colors: [_ncSourceColor, _ncAccent]).createShader(b),
            child: Text(
              'TRIAL COMPLETE',
              style: Potatuhs.display(size: 30, color: Colors.white, spacing: 3),
            ),
          ),
          const SizedBox(height: 36),
          _resultRow('Score', '$_score', highlight: true),
          const SizedBox(height: 12),
          _resultRow('Circuits Cleared', '$_puzzlesCleared'),
          const SizedBox(height: 12),
          _resultRow('Furthest Grid', '${_level.cols}×${_level.rows}'),
          const SizedBox(height: 52),
          GestureDetector(
            onTap: () => setState(() {
              _phase = _NCPhase.intro;
              _particles.clear();
              _scorePops.clear();
            }),
            child: Container(
              width: 190, height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_ncSourceColor, _ncAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: Potatuhs.glow(_ncAccent, strength: 0.45, blur: 20),
              ),
              alignment: Alignment.center,
              child: Text(
                'PLAY AGAIN',
                style: Potatuhs.body(size: 17, weight: FontWeight.w700,
                    color: Colors.white, spacing: 2.5),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('$label  ',
        style: Potatuhs.body(size: 14, color: Potatuhs.textFaint)),
      Text(value,
        style: highlight
            ? Potatuhs.display(size: 26, color: _ncAccent)
            : Potatuhs.body(size: 20, weight: FontWeight.w700,
                color: Potatuhs.textPrimary)),
    ]);
  }

  // ── hit-test ──────────────────────────────────────────────────────────────

  int? _ncNodeAtPos(Offset pos, double w, double h) {
    final cellSize = _ncCellSize(w, h, _level.cols, _level.rows);
    final ox = (w - _level.cols * cellSize) / 2;
    final oy = (h - _level.rows * cellSize) / 2 + 20;
    for (int i = 0; i < _playNodes.length; i++) {
      final cx = ox + (i % _level.cols) * cellSize + cellSize / 2;
      final cy = oy + (i ~/ _level.cols) * cellSize + cellSize / 2;
      if ((pos - Offset(cx, cy)).distance <= cellSize * 0.40 + 8) return i;
    }
    return null;
  }

  double _ncCellSize(double w, double h, int cols, int rows) {
    final cw = (w - 32) / cols;
    final ch = (h - 160) / rows;
    return cw < ch ? cw : ch;
  }
}

// ---------------------------------------------------------------------------
// Phase enum for the time-trial state machine
// ---------------------------------------------------------------------------
enum _NCPhase { intro, trial, done }

// ---------------------------------------------------------------------------
// Painter — premium neuron visual system
// Layers per neuron: atmosphere glow → soma orb → dendrite tendrils → axon
// direction arc → synaptic spark dot (source/target only).
// ---------------------------------------------------------------------------

class _NCPainter extends CustomPainter {
  final _SRLevel level;
  final List<_SRNode> nodes;
  final List<_SRSignal> signals;
  final List<_JuiceParticle> particles;
  final List<FxPop> scorePops;
  final List<_NCStar> stars;
  final double beamPhase;
  final double completionFlash;
  final List<double> nodePhaseOffset;

  _NCPainter({
    required this.level,
    required this.nodes,
    required this.signals,
    required this.particles,
    required this.scorePops,
    required this.stars,
    required this.beamPhase,
    required this.completionFlash,
    required this.nodePhaseOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Atmospheric background (GameFx handles gradient + glow blooms + motes)
    GameFx.atmosphere(canvas, size, _ncAccent, beamPhase, motes: 44);

    // ── 2. Faint cosmic-web grid filaments ─────────────────────────────
    final cols = level.cols;
    final rows = level.rows;
    final cellSize = _cellSize(size, cols, rows);
    final ox = (size.width - cols * cellSize) / 2;
    final oy = (size.height - rows * cellSize) / 2 + 20;

    // Animated filament alpha — slow gentle pulse
    final filamentAlpha = 0.04 + 0.02 * sin(beamPhase * 0.6);
    final filP = Paint()
      ..color = _ncAccent.withValues(alpha: filamentAlpha)
      ..strokeWidth = 0.9;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final x = ox + c * cellSize + cellSize / 2;
        final y = oy + r * cellSize + cellSize / 2;
        if (c < cols - 1) {
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), filP);
        }
        if (r < rows - 1) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), filP);
        }
      }
    }

    // ── 3. Synaptic signal trails ──────────────────────────────────────
    for (final sig in signals) {
      if (sig.trail.length < 2) continue;
      Color beamColor;
      if (sig.arrived) {
        beamColor = _ncSourceColor;
      } else if (sig.dead) {
        beamColor = _ncDeadColor;
      } else {
        final shimmer = 0.5 + 0.5 * sin(beamPhase * (2 * pi / _ncBeamShimmerPeriod));
        beamColor = Color.lerp(_ncSourceColor, _ncAccent, shimmer)!;
      }

      // Draw trail using glowLine segment-by-segment so the entire path glows.
      for (int k = 0; k < sig.trail.length - 1; k++) {
        final ax = ox + sig.trail[k][0] * cellSize + cellSize / 2;
        final ay = oy + sig.trail[k][1] * cellSize + cellSize / 2;
        final bx = ox + sig.trail[k + 1][0] * cellSize + cellSize / 2;
        final by = oy + sig.trail[k + 1][1] * cellSize + cellSize / 2;
        GameFx.glowLine(canvas, Offset(ax, ay), Offset(bx, by), beamColor,
            width: _ncBeamWidth);
      }
      // Active leading segment (partial).
      if (!sig.dead && !sig.arrived && sig.t > 0) {
        final fx = ox + sig.col * cellSize + cellSize / 2;
        final fy = oy + sig.row * cellSize + cellSize / 2;
        final tx = ox + sig.nextCol * cellSize + cellSize / 2;
        final ty = oy + sig.nextRow * cellSize + cellSize / 2;
        final tipX = fx + (tx - fx) * sig.t;
        final tipY = fy + (ty - fy) * sig.t;
        GameFx.glowLine(canvas, Offset(fx, fy), Offset(tipX, tipY), beamColor,
            width: _ncBeamWidth, progress: 1.0);
      }
    }

    // ── 4. Neurons (the core visual) ─────────────────────────────────────
    final somaRadius = cellSize * 0.30;
    for (int i = 0; i < nodes.length; i++) {
      final c = i % cols;
      final r = i ~/ cols;
      final cx = ox + c * cellSize + cellSize / 2;
      final cy = oy + r * cellSize + cellSize / 2;
      final center = Offset(cx, cy);
      final node = nodes[i];

      if (node.type == _SRNodeType.blocker) {
        _drawBlocker(canvas, center, somaRadius);
        continue;
      }

      final phaseOff = nodePhaseOffset.length > i ? nodePhaseOffset[i] : 0.0;
      final isSource = node.type == _SRNodeType.source;
      final isTarget = node.type == _SRNodeType.target;

      Color somaColor;
      if (isSource) {
        somaColor = _ncSourceColor;
      } else if (isTarget) {
        somaColor = _ncTargetColor;
      } else {
        somaColor = _ncNormalColor;
      }

      // 4a. Outer atmosphere halo (wider for source/target)
      final haloR = somaRadius * (isSource || isTarget ? 2.0 : 1.55);
      final haloAlpha = isSource || isTarget
          ? 0.18 + 0.10 * sin(beamPhase * 1.8 + phaseOff)
          : 0.08 + 0.04 * sin(beamPhase * 1.2 + phaseOff);
      canvas.drawCircle(
        center, haloR,
        Paint()
          ..color = somaColor.withValues(alpha: haloAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );

      // 4b. Dendrite tendrils — 4-6 short radiating strokes from the soma edge
      _drawDendrites(canvas, center, somaRadius, node.dir, somaColor, phaseOff);

      // 4c. Soma — layered orb (glow + gradient body + rim + specular)
      final glowStrength = isSource
          ? 1.0 + 0.4 * sin(beamPhase * 2.2 + phaseOff)
          : isTarget
              ? 0.9 + 0.35 * sin(beamPhase * 1.7 + phaseOff)
              : node.locked
                  ? 0.3
                  : 0.7 + 0.2 * sin(beamPhase * 1.1 + phaseOff);
      GameFx.orb(canvas, center, somaRadius,
          node.locked ? somaColor.withValues(alpha: 0.45) : somaColor,
          glow: glowStrength.clamp(0.0, 1.5),
          specular: !node.locked);

      // 4d. Axon direction arc — a glowing arc at the soma edge pointing the
      // gate direction. This replaces the bare flat arrow with something that
      // reads as an actual axon output.
      if (!node.locked || isSource) {
        _drawAxonArc(canvas, center, somaRadius, node.dir,
            node.locked ? somaColor.withValues(alpha: 0.4) : somaColor);
      } else {
        // Locked: draw a faint direction hint + lock marker.
        _drawAxonArc(canvas, center, somaRadius, node.dir,
            somaColor.withValues(alpha: 0.22));
        _drawLockBadge(canvas, center, somaRadius);
      }

      // 4e. Source / target identity: concentric pulse ring and label badge.
      if (isSource) {
        // Pulsing outer ring — reads "active emitter".
        final pulseR = somaRadius * (1.45 + 0.22 * sin(beamPhase * 2.5 + phaseOff));
        canvas.drawCircle(
          center, pulseR,
          Paint()
            ..color = _ncSourceColor.withValues(
                alpha: (0.55 * (1 - (pulseR - somaRadius * 1.45) /
                    (somaRadius * 0.22))).clamp(0.0, 0.55))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        // Small dot label: "SRC"
        GameFx.text(canvas, 'SRC',
            center.translate(0, somaRadius + 11),
            9, _ncSourceColor.withValues(alpha: 0.8));
      } else if (isTarget) {
        // Double halo rings — reads "destination".
        for (int ring = 0; ring < 2; ring++) {
          final rr = somaRadius * (1.5 + ring * 0.35)
              + (ring == 0 ? 0.0 : somaRadius * 0.12 * sin(beamPhase * 1.3));
          canvas.drawCircle(
            center, rr,
            Paint()
              ..color = _ncTargetColor.withValues(alpha: ring == 0 ? 0.55 : 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = ring == 0 ? 2.0 : 1.2,
          );
        }
        GameFx.text(canvas, 'TGT',
            center.translate(0, somaRadius + 11),
            9, _ncTargetColor.withValues(alpha: 0.8));
      }

      // 4f. Synaptic spark dot at axon tip — shows gate direction clearly.
      final axonAngle = _gateAngle(node.dir);
      final sparkPos = Offset(
        cx + cos(axonAngle) * (somaRadius + 6),
        cy + sin(axonAngle) * (somaRadius + 6),
      );
      final sparkPulse = 0.5 + 0.5 * sin(beamPhase * 3.0 + phaseOff);
      final sparkR = (isSource ? 4.2 : 2.8) * (node.locked ? 0.4 : 1.0);
      canvas.drawCircle(
        sparkPos, sparkR + 2,
        Paint()
          ..color = somaColor.withValues(
              alpha: (0.4 * sparkPulse * (node.locked ? 0.3 : 1.0))
                  .clamp(0.0, 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        sparkPos, sparkR,
        Paint()..color = Colors.white.withValues(
            alpha: (0.9 * (node.locked ? 0.2 : 1.0)).clamp(0.0, 0.9)),
      );
    }

    // ── 5. Active signal pulse dots ────────────────────────────────────
    for (final sig in signals) {
      if (sig.dead || sig.arrived) continue;
      double sx, sy;
      if (sig.t > 0 && (sig.nextCol != sig.col || sig.nextRow != sig.row)) {
        final fx = ox + sig.col * cellSize + cellSize / 2;
        final fy = oy + sig.row * cellSize + cellSize / 2;
        final tx = ox + sig.nextCol * cellSize + cellSize / 2;
        final ty = oy + sig.nextRow * cellSize + cellSize / 2;
        // Ease the pulse along the synapse.
        final eased = Curves.easeInOut.transform(sig.t.clamp(0.0, 1.0));
        sx = fx + (tx - fx) * eased;
        sy = fy + (ty - fy) * eased;
      } else {
        sx = ox + sig.col * cellSize + cellSize / 2;
        sy = oy + sig.row * cellSize + cellSize / 2;
      }
      // Outer halo.
      canvas.drawCircle(Offset(sx, sy), _ncSignalGlowBlur,
        Paint()
          ..color = _ncSignalColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _ncSignalGlowBlur));
      // Glowing orb.
      GameFx.orb(canvas, Offset(sx, sy), 7.5, _ncSourceColor,
          glow: 1.2, specular: true);
    }

    // ── 6. Juice particles ─────────────────────────────────────────────
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius * (0.4 + 0.6 * alpha),
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // ── 7. Score pops (FxPop) ─────────────────────────────────────────
    for (final sp in scorePops) {
      // Convert the unit-space anchor to actual pixel coords.
      final pixPos = Offset(sp.pos.dx * size.width, sp.pos.dy * size.height);
      final mockPop = FxPop(pixPos, sp.text, sp.color);
      mockPop.life = sp.life;
      mockPop.paint(canvas);
    }

    // ── 8. Completion flash ────────────────────────────────────────────
    if (completionFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _ncAccent.withValues(alpha: completionFlash * 0.14),
      );
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Blocker cell: dark inscribed X with rim.
  void _drawBlocker(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center, r,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF1A1530),
          const Color(0xFF0D0B1A),
        ]).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final xr = r * 0.36;
    final xp = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center.translate(-xr, -xr), center.translate(xr, xr), xp);
    canvas.drawLine(
        center.translate(xr, -xr), center.translate(-xr, xr), xp);
  }

  /// 4-6 short dendrite tendrils radiating from soma edge.
  void _drawDendrites(Canvas canvas, Offset center, double somaR,
      _GateDir axonDir, Color color, double phaseOff) {
    final axonAngle = _gateAngle(axonDir);
    // Draw 4 dendritic stubs offset 45°–135° from the axon direction.
    const dendAngles = [pi * 0.6, pi * 0.85, -pi * 0.6, -pi * 0.85, pi];
    final dp = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int k = 0; k < dendAngles.length; k++) {
      final ang = axonAngle + dendAngles[k];
      final wobble = 0.04 * sin(phaseOff + beamPhase * 0.8 + k * 1.1);
      final a = ang + wobble;
      final startR = somaR * 0.95;
      final endR   = somaR * (1.55 + 0.12 * sin(phaseOff + k));
      final startPt = center.translate(cos(a) * startR, sin(a) * startR);
      final endPt   = center.translate(cos(a) * endR,   sin(a) * endR);
      // Taper: outer end thinner.
      final alpha = 0.22 + 0.12 * sin(phaseOff + beamPhase * 0.5 + k * 0.7);
      dp.color = color.withValues(alpha: alpha.clamp(0.0, 0.4));
      canvas.drawLine(startPt, endPt, dp);
      // Small terminal bulb.
      canvas.drawCircle(
        endPt, 1.5,
        Paint()..color = color.withValues(alpha: (alpha * 0.6).clamp(0.0, 0.3)),
      );
    }
  }

  /// Axon output: a glowing arc at the soma perimeter plus a short shaft line,
  /// clearly indicating the exit direction.
  void _drawAxonArc(Canvas canvas, Offset center, double somaR,
      _GateDir dir, Color color) {
    final angle = _gateAngle(dir);
    // Short axon shaft from soma edge outward.
    final shaftStart = center.translate(cos(angle) * somaR, sin(angle) * somaR);
    final shaftEnd   = center.translate(cos(angle) * (somaR + 9), sin(angle) * (somaR + 9));
    canvas.drawLine(
      shaftStart, shaftEnd,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Glow around shaft.
    canvas.drawLine(
      shaftStart, shaftEnd,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Arrowhead chevron at tip.
    const hl = 6.0;
    final tip = shaftEnd;
    canvas.drawLine(
      tip,
      Offset(tip.dx + cos(angle + pi * 0.75) * hl,
             tip.dy + sin(angle + pi * 0.75) * hl),
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      tip,
      Offset(tip.dx + cos(angle - pi * 0.75) * hl,
             tip.dy + sin(angle - pi * 0.75) * hl),
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Tiny padlock icon for locked relay neurons.
  void _drawLockBadge(Canvas canvas, Offset center, double somaR) {
    final lc = center.translate(somaR * 0.55, -somaR * 0.55);
    final ls = somaR * 0.3;
    canvas.drawCircle(lc, ls * 0.85,
      Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.75));
    final lp = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: lc.translate(0, ls * 0.1), width: ls, height: ls * 0.7),
        const Radius.circular(1.5)),
      lp,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: lc.translate(0, -ls * 0.25),
          width: ls * 0.65, height: ls * 0.65),
      pi, pi, false, lp,
    );
  }

  double _gateAngle(_GateDir dir) {
    switch (dir) {
      case _GateDir.up:    return -pi / 2;
      case _GateDir.right: return 0.0;
      case _GateDir.down:  return pi / 2;
      case _GateDir.left:  return pi;
    }
  }

  double _cellSize(Size size, int cols, int rows) {
    final cw = (size.width - 32) / cols;
    final ch = (size.height - 160) / rows;
    return cw < ch ? cw : ch;
  }

  @override
  bool shouldRepaint(covariant _NCPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RealityMergeGame — "Multiverse Expansion"
// Single-player frantic tap game: grow your universe bubbles, shrink AI rivals.
// ═══════════════════════════════════════════════════════════════════════════════

// ── Feel constants ────────────────────────────────────────────────────────────
// Tap your own bubble to grow it by this many radius units.
const double _kPlayerTapGrowth = 5.0;
// Tapping empty space creates a new player bubble with this initial radius.
const double _kNewBubbleRadius = 22.0;
// Max player bubbles on screen at once (prevents canvas clutter).
const int _kMaxPlayerBubbles = 6;
// How fast rival bubbles grow per second (linear) at game start.
const double _kRivalGrowRateBase = 3.5;
// Rivals ramp up growth speed every second by this much (added to base).
const double _kRivalGrowRamp = 0.055;
// Tapping a rival shrinks its radius by this amount.
const double _kRivalShrinkPerTap = 12.0;
// Rivals are killed (popped) when their radius drops below this.
const double _kRivalMinRadius = 10.0;
// Rival max radius — if a rival exceeds this it triggers a penalty pop.
const double _kRivalMaxRadius = 90.0;
// How often (seconds) a new rival spawns initially; decreases over time.
const double _kRivalSpawnRateBase = 5.0;
// Minimum rival spawn interval (gets here by escalation).
const double _kRivalSpawnRateMin = 1.6;
// Total game duration in seconds.
const double _kClusterGameDuration = 60.0;
// Score is accumulated area: π·r² per player bubble, sampled each second.
const double _kScoreTickInterval = 1.0;
// Particle burst count on grow tap (visual feedback).
const int _kGrowParticleCount = 6;
// Particle burst count on pop/shrink.
const int _kPopParticleCount = 12;
// Squish: overlap fraction of the smaller bubble's radius at which swallow fires.
// e.g. 0.55 = bigger bubble's center is past 55% into the smaller bubble.
const double _kSwallowOverlapFraction = 0.55;
// How much radius the absorbing (bigger) bubble gains when swallowing.
const double _kSwallowGrowBonus = 6.0;
// Squish spring: how fast squishAmt decays back to 0 when not pressed.
const double _kSquishDecay = 8.0;
// ─────────────────────────────────────────────────────────────────────────────

// Palette: player = cool indigo/violet tones, rivals = hot warm tones.
const List<Color> _kPlayerColors = [
  Color(0xFF7C4DFF), // deep violet
  Color(0xFF448AFF), // electric blue
  Color(0xFF00E5FF), // cyan
  Color(0xFF69F0AE), // mint
];
const List<Color> _kRivalColors = [
  Color(0xFFFF1744), // hot red
  Color(0xFFFF6D00), // amber
  Color(0xFFFFD600), // gold
  Color(0xFFE040FB), // magenta
];

class _UniverseBubble {
  double x, y, radius;
  double pulsePhase;
  double popAnim; // 0 = alive; >0 = popping; removed when > 1
  Color color;
  bool isPlayer;
  double vx, vy; // gentle drift velocity

  // Squish state: how squished this bubble currently is (0 = round, 1 = max squish).
  // Driven by overlap from a bigger bubble pressing into it.
  double squishAmt = 0.0;
  // Direction of the squish force (from the pressing bubble toward this one).
  double squishAngle = 0.0;

  _UniverseBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.isPlayer,
    this.vx = 0,
    this.vy = 0,
  })  : pulsePhase = 0,
        popAnim = 0;
}

class RealityMergeGame extends StatefulWidget {
  const RealityMergeGame({Key? key}) : super(key: key);

  @override
  State<RealityMergeGame> createState() => _RealityMergeGameState();
}

class _RealityMergeGameState extends State<RealityMergeGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  final List<_UniverseBubble> _bubbles = [];
  final List<_JuiceParticle> _particles = [];

  Size _size = Size.zero;
  bool _started = false;
  bool _gameOver = false;

  double _elapsed = 0;
  double _lastTime = 0;
  int _score = 0;
  double _scoreTick = 0; // timer for periodic area scoring

  double _rivalSpawnTimer = 0;
  int _rivalColorIdx = 0;

  // Flash overlay for satisfying pop feedback
  double _popFlash = 0;
  Color _popFlashColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _initGame() {
    _bubbles.clear();
    _particles.clear();
    _elapsed = 0;
    _score = 0;
    _scoreTick = 0;
    _rivalSpawnTimer = _kRivalSpawnRateBase;
    _rivalColorIdx = 0;
    _gameOver = false;
    _started = true;
    _popFlash = 0;

    // Seed with two player bubbles near center to give immediate ownership.
    if (_size != Size.zero) {
      final cx = _size.width / 2;
      final cy = _size.height / 2;
      _bubbles.add(_UniverseBubble(
        x: cx - 45,
        y: cy,
        radius: _kNewBubbleRadius,
        color: _kPlayerColors[0],
        isPlayer: true,
        vx: (_rng.nextDouble() - 0.5) * 12,
        vy: (_rng.nextDouble() - 0.5) * 12,
      )..pulsePhase = _rng.nextDouble() * pi * 2);
      _bubbles.add(_UniverseBubble(
        x: cx + 45,
        y: cy,
        radius: _kNewBubbleRadius,
        color: _kPlayerColors[1],
        isPlayer: true,
        vx: (_rng.nextDouble() - 0.5) * 12,
        vy: (_rng.nextDouble() - 0.5) * 12,
      )..pulsePhase = _rng.nextDouble() * pi * 2);

      // Two rivals immediately to create pressure.
      _spawnRival();
      _spawnRival();
    }
  }

  void _spawnRival() {
    if (_size == Size.zero) return;
    final ci = _rivalColorIdx % _kRivalColors.length;
    _rivalColorIdx++;
    // Spawn from a random edge, drifting inward.
    final side = _rng.nextInt(4);
    double sx, sy;
    switch (side) {
      case 0: sx = _rng.nextDouble() * _size.width; sy = 0; break;
      case 1: sx = _size.width; sy = _rng.nextDouble() * _size.height; break;
      case 2: sx = _rng.nextDouble() * _size.width; sy = _size.height; break;
      default: sx = 0; sy = _rng.nextDouble() * _size.height;
    }
    final tx = _size.width / 2 + (_rng.nextDouble() - 0.5) * _size.width * 0.5;
    final ty = _size.height / 2 + (_rng.nextDouble() - 0.5) * _size.height * 0.5;
    final ddx = tx - sx; final ddy = ty - sy;
    final dist = sqrt(ddx * ddx + ddy * ddy).clamp(1.0, 9999.0);
    final spd = 8 + _rng.nextDouble() * 10;
    _bubbles.add(_UniverseBubble(
      x: sx,
      y: sy,
      radius: _kRivalMinRadius + 6,
      color: _kRivalColors[ci],
      isPlayer: false,
      vx: ddx / dist * spd,
      vy: ddy / dist * spd,
    )..pulsePhase = _rng.nextDouble() * pi * 2);
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (!_started || _gameOver) return;

    setState(() {
      _elapsed += dt;

      // ── Timer end ────────────────────────────────────────────────────────
      if (_elapsed >= _kClusterGameDuration) {
        _gameOver = true;
        return;
      }

      // ── Rival spawn with escalating pace ─────────────────────────────────
      _rivalSpawnTimer -= dt;
      final spawnInterval = max(
        _kRivalSpawnRateMin,
        _kRivalSpawnRateBase - _elapsed * 0.04,
      );
      if (_rivalSpawnTimer <= 0) {
        _rivalSpawnTimer = spawnInterval;
        _spawnRival();
        // Double-spawn after halfway point.
        if (_elapsed > _kClusterGameDuration * 0.5) _spawnRival();
      }

      // ── Rival growth + max-radius penalty ────────────────────────────────
      final rivalGrowRate = _kRivalGrowRateBase + _elapsed * _kRivalGrowRamp;
      for (final b in _bubbles) {
        if (b.popAnim > 0) continue;
        if (!b.isPlayer) {
          b.radius += rivalGrowRate * dt;
          if (b.radius > _kRivalMaxRadius) {
            // Rival got too big — pop it with a penalty flash.
            b.popAnim = 0.001;
            _emitParticles(b.x, b.y, b.color, _kPopParticleCount, speed: 160);
            _triggerFlash(b.color);
          }
        }
        // Pulse phase advances for all bubbles.
        b.pulsePhase += dt * 1.8;
      }

      // ── Gentle drift + soft bounce ────────────────────────────────────────
      for (final b in _bubbles) {
        if (b.popAnim > 0) continue;
        b.x += b.vx * dt;
        b.y += b.vy * dt;
        // Damping — bubbles gradually slow down.
        b.vx *= (1 - 0.3 * dt);
        b.vy *= (1 - 0.3 * dt);
        // Add tiny random cosmic drift.
        b.vx += (_rng.nextDouble() - 0.5) * 2.0 * dt;
        b.vy += (_rng.nextDouble() - 0.5) * 2.0 * dt;
        // Bounce off edges.
        final top = b.isPlayer ? 50.0 : 0.0;
        if (b.x < b.radius) { b.x = b.radius; b.vx = b.vx.abs(); }
        if (b.x > _size.width - b.radius) { b.x = _size.width - b.radius; b.vx = -b.vx.abs(); }
        if (b.y < b.radius + top) { b.y = b.radius + top; b.vy = b.vy.abs(); }
        if (b.y > _size.height - b.radius) { b.y = _size.height - b.radius; b.vy = -b.vy.abs(); }
      }

      // ── Squish + swallow collisions between all bubbles ─────────────────
      // Reset squish each frame; we'll re-drive it from current overlaps.
      for (final b in _bubbles) {
        if (b.popAnim == 0) {
          b.squishAmt = (b.squishAmt - _kSquishDecay * dt).clamp(0.0, 1.0);
        }
      }

      // Collect indices of bubbles to swallow (done after the loop to avoid
      // modifying the list while iterating).
      final List<int> _toSwallow = [];

      for (int i = 0; i < _bubbles.length; i++) {
        if (_bubbles[i].popAnim > 0) continue;
        for (int j = i + 1; j < _bubbles.length; j++) {
          if (_bubbles[j].popAnim > 0) continue;
          final a = _bubbles[i]; final bub = _bubbles[j];
          final ddx = bub.x - a.x; final ddy = bub.y - a.y;
          final dist = sqrt(ddx * ddx + ddy * ddy);
          final minD = a.radius + bub.radius;

          if (dist >= minD || dist < 0.1) continue;

          // Identify bigger / smaller.
          final _UniverseBubble bigger = a.radius >= bub.radius ? a : bub;
          final _UniverseBubble smaller = a.radius >= bub.radius ? bub : a;

          // How deep the bigger bubble's surface penetrates the smaller one.
          // penetration = minD - dist  (positive when overlapping)
          final double penetration = minD - dist;

          // Squish the smaller bubble proportional to penetration relative to its radius.
          final double squishForce = (penetration / smaller.radius).clamp(0.0, 1.0);
          if (squishForce > smaller.squishAmt) {
            smaller.squishAmt = squishForce;
            // Squish direction: from bigger toward smaller (away from the press).
            if (dist > 0.1) {
              // angle from bigger center to smaller center
              smaller.squishAngle = atan2(smaller.y - bigger.y, smaller.x - bigger.x);
            }
          }

          // ── Swallow threshold ────────────────────────────────────────────
          // Fire when overlap depth exceeds a fraction of the smaller bubble's radius.
          if (penetration >= smaller.radius * _kSwallowOverlapFraction &&
              !_toSwallow.contains(_bubbles.indexOf(smaller))) {
            _toSwallow.add(_bubbles.indexOf(smaller));
          }

          // ── Standard push-apart to prevent full interpenetration ─────────
          final nx = ddx / dist; final ny = ddy / dist;
          // Use a weaker push so the bigger bubble can visibly squish in before
          // the swallow threshold is reached.
          final double pushStrength = squishForce < _kSwallowOverlapFraction ? 0.8 : 0.2;
          final push = (minD - dist) * pushStrength;
          a.vx -= nx * push; a.vy -= ny * push;
          bub.vx += nx * push; bub.vy += ny * push;
        }
      }

      // ── Execute swallows ─────────────────────────────────────────────────
      for (final idx in _toSwallow.reversed) {
        if (idx < 0 || idx >= _bubbles.length) continue;
        final small = _bubbles[idx];
        if (small.popAnim > 0) continue;

        // Find the biggest overlapping bubble (the swallower).
        _UniverseBubble? swallower;
        double bestR = -1;
        for (final other in _bubbles) {
          if (other == small || other.popAnim > 0) continue;
          final dx = other.x - small.x; final dy = other.y - small.y;
          final d = sqrt(dx * dx + dy * dy);
          if (d < other.radius + small.radius && other.radius > bestR) {
            bestR = other.radius;
            swallower = other;
          }
        }
        if (swallower == null) continue;

        // Only swallow if swallower is bigger.
        if (swallower.radius <= small.radius) continue;

        // Absorb: swallower grows a bit.
        swallower.radius = (swallower.radius + _kSwallowGrowBonus).clamp(0, _kRivalMaxRadius + _kSwallowGrowBonus);

        // Satisfying pop + FxBurst particles.
        _emitParticles(small.x, small.y, small.color, _kPopParticleCount + 6, speed: 180);
        _triggerFlash(small.color);

        // Score: player swallowing a rival = bonus points.
        if (swallower.isPlayer && !small.isPlayer) {
          _score += 15;
        } else if (!swallower.isPlayer && small.isPlayer) {
          // Rival eats player bubble — minor penalty visual only.
          _triggerFlash(Colors.redAccent);
        }

        // Trigger pop animation on the consumed bubble.
        small.popAnim = 0.001;
      }

      // ── Pop animations ────────────────────────────────────────────────────
      for (final b in _bubbles) {
        if (b.popAnim > 0) b.popAnim += dt * 2.5;
      }
      _bubbles.removeWhere((b) => b.popAnim > 1.0);

      // ── Periodic area-based scoring ───────────────────────────────────────
      _scoreTick += dt;
      if (_scoreTick >= _kScoreTickInterval) {
        _scoreTick -= _kScoreTickInterval;
        double area = 0;
        for (final b in _bubbles) {
          if (b.isPlayer && b.popAnim == 0) area += pi * b.radius * b.radius;
        }
        // Score = area / 500 (keeps numbers readable at typical radii).
        final pts = (area / 500).round();
        _score += pts;
      }

      // ── Pop flash decay ───────────────────────────────────────────────────
      if (_popFlash > 0) _popFlash = (_popFlash - dt * 3).clamp(0.0, 1.0);

      // ── Particles ─────────────────────────────────────────────────────────
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _emitParticles(double cx, double cy, Color color, int count,
      {double speed = 100}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final spd = speed * (0.5 + _rng.nextDouble() * 0.5);
      _particles.add(_JuiceParticle(
        x: cx,
        y: cy,
        vx: cos(angle) * spd,
        vy: sin(angle) * spd,
        life: 0.5 + _rng.nextDouble() * 0.3,
        color: color,
        radius: 2.5 + _rng.nextDouble() * 2,
      ));
    }
  }

  void _triggerFlash(Color c) {
    _popFlash = 0.7;
    _popFlashColor = c;
  }

  void _onTap(Offset pos) {
    if (!_started || _gameOver) {
      _initGame();
      return;
    }

    // Check if tap lands on an existing bubble.
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      if (b.popAnim > 0) continue;
      if ((Offset(b.x, b.y) - pos).distance <= b.radius + 10) {
        if (b.isPlayer) {
          // Grow player bubble.
          setState(() {
            b.radius += _kPlayerTapGrowth;
            _emitParticles(b.x, b.y, b.color, _kGrowParticleCount, speed: 70);
          });
        } else {
          // Shrink rival.
          setState(() {
            b.radius -= _kRivalShrinkPerTap;
            if (b.radius <= _kRivalMinRadius) {
              // Pop the rival.
              b.popAnim = 0.001;
              _emitParticles(b.x, b.y, b.color, _kPopParticleCount, speed: 140);
              _triggerFlash(b.color);
              _score += 10; // bonus for popping a rival
            } else {
              _emitParticles(b.x, b.y, b.color, 4, speed: 60);
            }
          });
        }
        return;
      }
    }

    // Empty space — spawn a new player bubble (up to cap).
    final playerCount = _bubbles.where((b) => b.isPlayer && b.popAnim == 0).length;
    if (playerCount < _kMaxPlayerBubbles) {
      setState(() {
        final ci = _rng.nextInt(_kPlayerColors.length);
        _bubbles.add(_UniverseBubble(
          x: pos.dx,
          y: pos.dy,
          radius: _kNewBubbleRadius,
          color: _kPlayerColors[ci],
          isPlayer: true,
          vx: (_rng.nextDouble() - 0.5) * 20,
          vy: (_rng.nextDouble() - 0.5) * 20,
        )..pulsePhase = _rng.nextDouble() * pi * 2);
        _emitParticles(pos.dx, pos.dy, _kPlayerColors[ci], 8, speed: 50);
      });
    }
  }

  String get _timeLeft {
    final secs = (_kClusterGameDuration - _elapsed).ceil().clamp(0, 60);
    return '$secs';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _onTap(d.localPosition),
        child: Container(
          color: const Color(0xFF050510),
          child: CustomPaint(
            painter: _RealityMergePainter(
              bubbles: _bubbles,
              particles: _particles,
              popFlash: _popFlash,
              popFlashColor: _popFlashColor,
              elapsed: _elapsed,
            ),
            child: Stack(children: [
              // ── Start screen ──────────────────────────────────────────────
              if (!_started)
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                      'Multiverse Expansion',
                      style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap your bubbles to grow them',
                      style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.38)),
                    ),
                    Text(
                      'Tap rivals (red/orange) to shrink them',
                      style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.38)),
                    ),
                    Text(
                      'Tap empty space to spawn a new universe',
                      style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.38)),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Tap to start',
                      style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ]),
                ),

              // ── HUD ───────────────────────────────────────────────────────
              if (_started && !_gameOver)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_score',
                        style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C4DFF)),
                      ),
                      Text(
                        ':$_timeLeft',
                        style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 15,
                            color: double.parse(_timeLeft) <= 10
                                ? Colors.redAccent
                                : Colors.white38),
                      ),
                      Text(
                        '${_bubbles.where((b) => !b.isPlayer && b.popAnim == 0).length} rivals',
                        style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 12,
                            color: Color(0xFFFF5252)),
                      ),
                    ],
                  ),
                ),

              // ── Game-over screen ──────────────────────────────────────────
              if (_gameOver)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.82),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(
                          'Expansion Complete',
                          style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C4DFF)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_score',
                          style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 52,
                              fontWeight: FontWeight.w200,
                              color: Colors.white),
                        ),
                        const Text(
                          'universe mass',
                          style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 12,
                              color: Colors.white38),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Tap to restart',
                          style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.28)),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }
}

class _RealityMergePainter extends CustomPainter {
  final List<_UniverseBubble> bubbles;
  final List<_JuiceParticle> particles;
  final double popFlash;
  final Color popFlashColor;
  final double elapsed;

  _RealityMergePainter({
    required this.bubbles,
    required this.particles,
    required this.popFlash,
    required this.popFlashColor,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Starfield background ─────────────────────────────────────────────────
    // Static cosmic dust dots; use elapsed for twinkling variation.
    final dustPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final rand = Random(42); // fixed seed for stable field
    for (int i = 0; i < 80; i++) {
      final sx = rand.nextDouble() * size.width;
      final sy = rand.nextDouble() * size.height;
      final sr = 0.5 + rand.nextDouble() * 1.0;
      final twinkle = (sin(elapsed * 1.2 + i * 0.7) * 0.015 + 0.025).clamp(0.0, 0.06);
      canvas.drawCircle(Offset(sx, sy), sr, Paint()..color = Colors.white.withValues(alpha: twinkle));
      canvas.drawCircle(Offset(sx, sy), sr * 0.5, dustPaint);
    }

    // ── Pop flash overlay ────────────────────────────────────────────────────
    if (popFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = popFlashColor.withValues(alpha: popFlash * 0.12),
      );
    }

    // ── Bubbles ──────────────────────────────────────────────────────────────
    for (int i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final pos = Offset(b.x, b.y);

      if (b.popAnim > 0) {
        // Expanding ring pop animation.
        final t = b.popAnim.clamp(0.0, 1.0);
        canvas.drawCircle(
          pos,
          b.radius * (1 + t * 2.5),
          Paint()
            ..color = b.color.withValues(alpha: (1 - t) * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        // Second ring slightly delayed.
        if (t > 0.2) {
          canvas.drawCircle(
            pos,
            b.radius * (1 + (t - 0.2) * 2),
            Paint()
              ..color = Colors.white.withValues(alpha: (1 - t) * 0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        continue;
      }

      final pulse = sin(b.pulsePhase) * 0.06 + 1.0;

      // ── Squish deformation ────────────────────────────────────────────────
      // When squishAmt > 0 the bubble is being pressed by a bigger one.
      // We apply a canvas transform: compress along the press axis, expand
      // perpendicularly (volume-conserving oval).
      final bool hasSquish = b.squishAmt > 0.005;
      if (hasSquish) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(b.squishAngle);
        // Along press axis (x after rotation): compress; perpendicular (y): expand.
        final double sqX = 1.0 - b.squishAmt * 0.38; // compress up to 38%
        final double sqY = 1.0 + b.squishAmt * 0.28; // expand up to 28%
        canvas.scale(sqX, sqY);
        canvas.translate(-pos.dx, -pos.dy);
      }

      if (b.isPlayer) {
        // ── Player bubble: layered translucent glow ─────────────────────────
        // Outer corona.
        canvas.drawCircle(
          pos,
          (b.radius + 18) * pulse,
          Paint()..color = b.color.withValues(alpha: 0.05),
        );
        // Mid glow.
        canvas.drawCircle(
          pos,
          (b.radius + 8) * pulse,
          Paint()..color = b.color.withValues(alpha: 0.12),
        );
        // Body fill — radial gradient effect via two circles.
        canvas.drawCircle(
          pos,
          b.radius,
          Paint()..color = b.color.withValues(alpha: 0.22),
        );
        // Rim.
        canvas.drawCircle(
          pos,
          b.radius,
          Paint()
            ..color = b.color.withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        // Inner highlight.
        canvas.drawCircle(
          Offset(pos.dx - b.radius * 0.22, pos.dy - b.radius * 0.22),
          b.radius * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.16),
        );
        // Tiny core dot.
        canvas.drawCircle(
          pos,
          3.5,
          Paint()..color = b.color.withValues(alpha: 0.6),
        );
      } else {
        // ── Rival bubble: aggressive hot glow ──────────────────────────────
        // Pulsing outer corona — grows with rival radius.
        canvas.drawCircle(
          pos,
          (b.radius + 14) * pulse,
          Paint()..color = b.color.withValues(alpha: 0.07),
        );
        canvas.drawCircle(
          pos,
          (b.radius + 5) * pulse,
          Paint()..color = b.color.withValues(alpha: 0.14),
        );
        // Body.
        canvas.drawCircle(
          pos,
          b.radius,
          Paint()..color = b.color.withValues(alpha: 0.18),
        );
        // Jagged rim via thick dashed stroke approximation (solid stroke).
        canvas.drawCircle(
          pos,
          b.radius,
          Paint()
            ..color = b.color.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        // Danger cross-hatch: two thin lines through center.
        final linePaint = Paint()
          ..color = b.color.withValues(alpha: 0.20)
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(pos.dx - b.radius * 0.6, pos.dy),
            Offset(pos.dx + b.radius * 0.6, pos.dy),
            linePaint);
        canvas.drawLine(
            Offset(pos.dx, pos.dy - b.radius * 0.6),
            Offset(pos.dx, pos.dy + b.radius * 0.6),
            linePaint);
        // Inner highlight.
        canvas.drawCircle(
          Offset(pos.dx - b.radius * 0.2, pos.dy - b.radius * 0.2),
          b.radius * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.10),
        );
      }

      // Restore squish transform.
      if (hasSquish) canvas.restore();

      // ── Squish stress ring (visible indicator of squish intensity) ───────
      if (hasSquish && b.squishAmt > 0.15) {
        // A bright stress ring around the compressed bubble so the effect reads.
        canvas.drawCircle(
          pos,
          b.radius * 1.05,
          Paint()
            ..color = Colors.white.withValues(alpha: b.squishAmt * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // ── Particles ─────────────────────────────────────────────────────────────
    for (final p in particles) {
      if (p.life > 0) {
        final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.radius,
          Paint()..color = p.color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealityMergePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DarkMatterGame — "Dark Matter Detector"
// Tap/hold to activate detector, reveal and capture invisible particles.
// ═══════════════════════════════════════════════════════════════════════════════

class _DarkParticle {
  double x, y, vx, vy;
  bool captured;
  _DarkParticle({required this.x, required this.y, required this.vx, required this.vy}) : captured = false;
}

class DarkMatterGame extends StatefulWidget {
  const DarkMatterGame({Key? key}) : super(key: key);
  @override
  State<DarkMatterGame> createState() => _DarkMatterGameState();
}

class _DarkMatterGameState extends State<DarkMatterGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  final List<_DarkParticle> _darkParticles = [];
  bool _detecting = false;
  Offset _detectorPos = Offset.zero;
  double _detectorRadius = 0;
  static const double _maxDetectorR = 80;
  static const double _captureR = 25;

  int _score = 0;
  double _spawnTimer = 0;
  double _lastTime = 0;
  Size _size = Size.zero;

  // Capture flash
  double _captureFlash = 0;
  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      // Spawn dark matter
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _darkParticles.length < 15) {
        _spawnTimer = 0.8 + _rng.nextDouble() * 1.0;
        if (_size != Size.zero) {
          _darkParticles.add(_DarkParticle(
            x: _rng.nextDouble() * _size.width,
            y: _rng.nextDouble() * _size.height,
            vx: (_rng.nextDouble() - 0.5) * 30,
            vy: (_rng.nextDouble() - 0.5) * 30,
          ));
        }
      }

      // Move particles
      for (final p in _darkParticles) {
        if (p.captured) continue;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        // Gentle random drift
        p.vx += (_rng.nextDouble() - 0.5) * 20 * dt;
        p.vy += (_rng.nextDouble() - 0.5) * 20 * dt;
        // Wrap around
        if (p.x < 0) p.x += _size.width;
        if (p.x > _size.width) p.x -= _size.width;
        if (p.y < 0) p.y += _size.height;
        if (p.y > _size.height) p.y -= _size.height;
      }
      _darkParticles.removeWhere((p) => p.captured);

      // Detector radius animation
      if (_detecting) {
        _detectorRadius = (_detectorRadius + dt * 200).clamp(0, _maxDetectorR);
      } else {
        _detectorRadius = (_detectorRadius - dt * 300).clamp(0, _maxDetectorR);
      }

      // Flash decay
      if (_captureFlash > 0) _captureFlash = (_captureFlash - dt * 4).clamp(0.0, 1.0);

      // Juice particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _tryCapture(Offset pos) {
    for (final p in _darkParticles) {
      if (p.captured) continue;
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < _captureR) {
        p.captured = true;
        _score++;
        _captureFlash = 1;
        for (int i = 0; i < 8; i++) {
          final a = _rng.nextDouble() * 2 * pi;
          _particles.add(_JuiceParticle(
            x: p.x, y: p.y,
            vx: cos(a) * 60, vy: sin(a) * 60,
            life: 0.5, color: Colors.purpleAccent,
          ));
        }
        return; // One capture per tap
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTapDown: (d) {
          _tryCapture(d.localPosition);
        },
        onLongPressStart: (d) {
          _detecting = true;
          _detectorPos = d.localPosition;
        },
        onLongPressMoveUpdate: (d) {
          _detectorPos = d.localPosition;
        },
        onLongPressEnd: (d) {
          _detecting = false;
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _DarkMatterPainter(
              darkParticles: _darkParticles,
              detecting: _detecting || _detectorRadius > 1,
              detectorPos: _detectorPos,
              detectorRadius: _detectorRadius,
              captureFlash: _captureFlash,
              score: _score,
              juiceParticles: _particles,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(
                    child: Text('Captured: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.purpleAccent)),
                  ),
                ),
                if (_score == 0)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Hold to scan, tap to capture', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white12))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _DarkMatterPainter extends CustomPainter {
  final List<_DarkParticle> darkParticles;
  final bool detecting;
  final Offset detectorPos;
  final double detectorRadius;
  final double captureFlash;
  final int score;
  final List<_JuiceParticle> juiceParticles;

  _DarkMatterPainter({
    required this.darkParticles, required this.detecting,
    required this.detectorPos, required this.detectorRadius,
    required this.captureFlash, required this.score,
    required this.juiceParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Capture flash
    if (captureFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.purpleAccent.withValues(alpha: captureFlash * 0.08),
      );
    }

    // Detector glow
    if (detecting && detectorRadius > 1) {
      final gradient = ui.Gradient.radial(
        detectorPos, detectorRadius,
        [Colors.purpleAccent.withValues(alpha: 0.12), Colors.transparent],
      );
      canvas.drawCircle(detectorPos, detectorRadius, Paint()..shader = gradient);
      canvas.drawCircle(detectorPos, detectorRadius, Paint()
        ..color = Colors.purpleAccent.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      // Inner ring
      canvas.drawCircle(detectorPos, 25, Paint()
        ..color = Colors.purpleAccent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Dark matter particles — only visible near detector
    for (final p in darkParticles) {
      if (p.captured) continue;
      final pos = Offset(p.x, p.y);
      double visibility = 0;
      if (detecting && detectorRadius > 10) {
        final dist = (pos - detectorPos).distance;
        if (dist < detectorRadius) {
          visibility = (1.0 - dist / detectorRadius).clamp(0.0, 1.0);
        }
      }
      if (visibility > 0) {
        // Revealed
        canvas.drawCircle(pos, 8, Paint()..color = Colors.purpleAccent.withValues(alpha: visibility * 0.15));
        canvas.drawCircle(pos, 4, Paint()..color = Colors.purpleAccent.withValues(alpha: visibility * 0.5));
        canvas.drawCircle(pos, 2, Paint()..color = Colors.white.withValues(alpha: visibility * 0.4));
      } else {
        // Completely invisible — maybe a very faint hint
        canvas.drawCircle(pos, 1.5, Paint()..color = Colors.white.withValues(alpha: 0.015));
      }
    }

    // Juice particles
    for (final p in juiceParticles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x, p.y), 2.5,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DarkMatterPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// EverythingGame — "Everything Everywhere"
// Multilingual word-finder: type the English meaning of a word shown in many
// rotating foreign-language forms.  Three concentric wheels of related forms
// orbit the center at different speeds for cosmic visual flavor.
// ═══════════════════════════════════════════════════════════════════════════════

// ---------------------------------------------------------------------------
// Feel constants — tweak here without hunting through the logic below
// ---------------------------------------------------------------------------

/// Total game duration in seconds.
const double _ewTotalSeconds = 60.0;

/// Starting time budget per word (seconds).  Shrinks each round by [_ewTimeDecay].
const double _ewWordTimeStart = 12.0;

/// How many seconds are subtracted from the per-word budget each round.
const double _ewTimeDecay = 0.6;

/// Minimum per-word budget (seconds) regardless of decay.
const double _ewWordTimeMin = 4.0;

/// Points awarded for a correct answer.
const int _ewPointsCorrect = 10;

/// Points per second remaining when the answer is given (bonus).
const int _ewPointsTimeBonus = 2;

/// First hint reveals after this many seconds into the word (the category).
const double _ewHint1Delay = 3.0;

/// Second hint: on round >= this round number hints come 1 s faster per round.
const int _ewHintEscalationRound = 4;

/// Second hint reveals a letter after this many seconds into the word.
const double _ewHint2Delay = 6.0;

/// Seconds between language cycling on the center display.
const double _ewLangCycleBase = 1.4;

/// Minimum language cycle speed (at high escalation).
const double _ewLangCycleMin = 0.55;

/// Outer wheel rotation speed (radians/s).
const double _ewWheelSpeedOuter = 0.22;

/// Middle wheel rotation speed (radians/s).
const double _ewWheelSpeedMiddle = -0.15; // opposite direction

/// Inner (decorative) ring rotation speed (radians/s).
const double _ewWheelSpeedInner = 0.35;

// ---------------------------------------------------------------------------
// Word dataset — English answer + forms in other languages/scripts
// ---------------------------------------------------------------------------

class _EWWord {
  final String answer;       // English word the player must type
  final String category;     // shown as Hint 1 (e.g. "Nature", "Body")
  final List<String> forms;  // foreign-language renderings shown in center
  const _EWWord({required this.answer, required this.category, required this.forms});
}

const List<_EWWord> _ewWords = [
  _EWWord(answer: 'water', category: 'Nature',
    forms: ['agua', 'eau', 'wasser', 'mizu (水)', 'acqua', 'voda', 'pani', 'uisce', 'vatten', 'mae nam']),
  _EWWord(answer: 'fire', category: 'Nature',
    forms: ['fuego', 'feu', 'feuer', 'hi (火)', 'fuoco', 'ogon', 'agni', 'tine', 'eld', 'nar']),
  _EWWord(answer: 'star', category: 'Cosmos',
    forms: ['estrella', 'étoile', 'stern', 'hoshi (星)', 'stella', 'zvezda', 'tara', 'réalta', 'stjärna', 'dara']),
  _EWWord(answer: 'moon', category: 'Cosmos',
    forms: ['luna', 'lune', 'mond', 'tsuki (月)', 'luna', 'luna', 'chand', 'gealach', 'måne', 'ay']),
  _EWWord(answer: 'sun', category: 'Cosmos',
    forms: ['sol', 'soleil', 'sonne', 'taiyō (太陽)', 'sole', 'solntse', 'suraj', 'grian', 'sol', 'güneş']),
  _EWWord(answer: 'earth', category: 'Cosmos',
    forms: ['tierra', 'terre', 'erde', 'chi (地)', 'terra', 'zemlya', 'dharti', 'an domhan', 'jord', 'dünya']),
  _EWWord(answer: 'life', category: 'Existence',
    forms: ['vida', 'vie', 'leben', 'inochi (命)', 'vita', 'zhizn', 'jeevan', 'saol', 'liv', 'hayat']),
  _EWWord(answer: 'time', category: 'Existence',
    forms: ['tiempo', 'temps', 'zeit', 'jikan (時間)', 'tempo', 'vremya', 'samay', 'am', 'tid', 'zaman']),
  _EWWord(answer: 'love', category: 'Feeling',
    forms: ['amor', 'amour', 'liebe', 'ai (愛)', 'amore', 'lyubov', 'pyar', 'grá', 'kärlek', 'aşk']),
  _EWWord(answer: 'light', category: 'Cosmos',
    forms: ['luz', 'lumière', 'licht', 'hikari (光)', 'luce', 'svet', 'prakash', 'solas', 'ljus', 'ışık']),
  _EWWord(answer: 'wind', category: 'Nature',
    forms: ['viento', 'vent', 'wind', 'kaze (風)', 'vento', 'veter', 'hawa', 'gaoth', 'vind', 'rüzgar']),
  _EWWord(answer: 'tree', category: 'Nature',
    forms: ['árbol', 'arbre', 'baum', 'ki (木)', 'albero', 'derevo', 'ped', 'crann', 'träd', 'ağaç']),
  _EWWord(answer: 'dream', category: 'Mind',
    forms: ['sueño', 'rêve', 'traum', 'yume (夢)', 'sogno', 'son', 'sapna', 'brionglóid', 'dröm', 'rüya']),
  _EWWord(answer: 'heart', category: 'Body',
    forms: ['corazón', 'coeur', 'herz', 'kokoro (心)', 'cuore', 'serdtse', 'dil', 'croí', 'hjärta', 'kalp']),
  _EWWord(answer: 'sky', category: 'Nature',
    forms: ['cielo', 'ciel', 'himmel', 'sora (空)', 'cielo', 'nebo', 'aakash', 'spéir', 'himmel', 'gökyüzü']),
  _EWWord(answer: 'ocean', category: 'Nature',
    forms: ['océano', 'océan', 'ozean', 'umi (海)', 'oceano', 'okean', 'sagar', 'aigéan', 'hav', 'okyanus']),
  _EWWord(answer: 'peace', category: 'Feeling',
    forms: ['paz', 'paix', 'frieden', 'heiwa (平和)', 'pace', 'mir', 'shanti', 'síocháin', 'fred', 'barış']),
  _EWWord(answer: 'voice', category: 'Mind',
    forms: ['voz', 'voix', 'stimme', 'koe (声)', 'voce', 'golos', 'awaaz', 'guth', 'röst', 'ses']),
];

// ---------------------------------------------------------------------------
// Wheel-ring word entries (decorative; unrelated to the answer)
// ---------------------------------------------------------------------------

const List<String> _ewWheelTokens = [
  'cosmos', 'alma', 'âme', 'seele', 'tamashii', 'anima', 'ruh',
  'infinito', 'unendlich', 'mugen', 'infini', 'sonsuz',
  'origen', 'origin', 'ursprung', 'kigen', 'menşe',
  'todo', 'tout', 'alles', 'subete', 'tutto',
  'nada', 'rien', 'nichts', 'mu', 'niente',
  'luz', 'licht', 'hikari', 'lumière', 'ışık',
  'tiempo', 'temps', 'zeit', 'jikan', 'zaman',
];

// ---------------------------------------------------------------------------
// EverythingGame widget
// ---------------------------------------------------------------------------

class EverythingGame extends StatefulWidget {
  const EverythingGame({Key? key}) : super(key: key);
  @override
  State<EverythingGame> createState() => _EverythingGameState();
}

class _EverythingGameState extends State<EverythingGame>
    with SingleTickerProviderStateMixin {

  // --- animation / timing ---
  late AnimationController _ctrl;
  double _lastWallTime = 0;

  // --- game state ---
  double _gameTimeLeft = _ewTotalSeconds;
  bool _gameOver = false;
  int _score = 0;
  int _round = 0;             // increments each new word
  List<_EWWord> _deck = [];   // shuffled copy, cycled through

  // --- current word ---
  late _EWWord _current;
  double _wordTimeLeft = _ewWordTimeStart;
  double _wordTimeBudget = _ewWordTimeStart;
  int _langIndex = 0;
  double _langTimer = 0;
  bool _hint1Shown = false;   // category
  bool _hint2Shown = false;   // first letter
  bool _correct = false;
  double _correctFlash = 0;   // >0 = still flashing

  // --- typing ---
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // --- wheels ---
  double _wheelAngle0 = 0; // inner
  double _wheelAngle1 = 0; // middle
  double _wheelAngle2 = 0; // outer
  // Slight "slow-down" pulse on outer wheel
  double _outerPulse = 0;

  // --- particles ---
  final List<_JuiceParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _buildDeck();
    _loadWord();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )
      ..addListener(_tick)
      ..forward();
    _lastWallTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Build a shuffled deck; refill when exhausted.
  void _buildDeck() {
    _deck = List<_EWWord>.from(_ewWords)..shuffle(_rng);
  }

  void _loadWord() {
    if (_deck.isEmpty) _buildDeck();
    _current = _deck.removeLast();
    final timeThisRound = (_ewWordTimeStart - _round * _ewTimeDecay)
        .clamp(_ewWordTimeMin, _ewWordTimeStart);
    _wordTimeBudget = timeThisRound;
    _wordTimeLeft = timeThisRound;
    _langIndex = 0;
    _langTimer = 0;
    _hint1Shown = false;
    _hint2Shown = false;
    _correct = false;
    _correctFlash = 0;
    _textCtrl.clear();
    // Auto-focus keyboard on each word
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_gameOver) _focusNode.requestFocus();
    });
  }

  // Compute effective hint timings for current round (escalation: hints come
  // progressively later as rounds advance to keep pressure up).
  double get _effectiveHint1Delay {
    final extra = (_round - _ewHintEscalationRound).clamp(0, 999) * 0.4;
    return (_ewHint1Delay + extra).clamp(0, _wordTimeBudget - 0.5);
  }

  double get _effectiveHint2Delay {
    final extra = (_round - _ewHintEscalationRound).clamp(0, 999) * 0.4;
    return (_ewHint2Delay + extra).clamp(0, _wordTimeBudget - 0.2);
  }

  double get _effectiveLangCycle {
    final speedup = _round * 0.08;
    return (_ewLangCycleBase - speedup).clamp(_ewLangCycleMin, _ewLangCycleBase);
  }

  void _tick() {
    if (_gameOver) return;
    final now = _now();
    final dt = (now - _lastWallTime).clamp(0.001, 0.05);
    _lastWallTime = now;

    setState(() {
      // --- wheels ---
      _outerPulse += dt * 1.1;
      final outerMod = 0.6 + 0.4 * (0.5 + 0.5 * sin(_outerPulse)); // [0.6..1.0]
      _wheelAngle0 += _ewWheelSpeedInner * dt;
      _wheelAngle1 += _ewWheelSpeedMiddle * dt;
      _wheelAngle2 += _ewWheelSpeedOuter * outerMod * dt;

      // --- particles ---
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // --- flash timer ---
      if (_correctFlash > 0) {
        _correctFlash -= dt;
        return; // brief freeze while flashing
      }

      // --- game clock ---
      _gameTimeLeft -= dt;
      if (_gameTimeLeft <= 0) {
        _gameTimeLeft = 0;
        _gameOver = true;
        _focusNode.unfocus();
        return;
      }

      // --- word clock ---
      _wordTimeLeft -= dt;

      // Hints
      final elapsed = _wordTimeBudget - _wordTimeLeft;
      if (!_hint1Shown && elapsed >= _effectiveHint1Delay) _hint1Shown = true;
      if (!_hint2Shown && elapsed >= _effectiveHint2Delay) _hint2Shown = true;

      // Language cycling
      _langTimer += dt;
      if (_langTimer >= _effectiveLangCycle) {
        _langTimer = 0;
        _langIndex = (_langIndex + 1) % _current.forms.length;
      }

      // Timeout → advance, no points
      if (_wordTimeLeft <= 0) {
        _round++;
        _loadWord();
      }
    });
  }

  void _onTextChanged(String val) {
    if (_gameOver || _correct) return;
    if (val.trim().toLowerCase() == _current.answer.toLowerCase()) {
      // Correct!
      final timeBonus = (_wordTimeLeft * _ewPointsTimeBonus).round();
      final earned = _ewPointsCorrect + timeBonus;
      setState(() {
        _score += earned;
        _correct = true;
        _correctFlash = 0.55;
        // Burst particles from center-ish
        for (int i = 0; i < 20; i++) {
          final a = _rng.nextDouble() * 2 * pi;
          final spd = 0.15 + _rng.nextDouble() * 0.25;
          _particles.add(_JuiceParticle(
            x: 0.5, y: 0.45,
            vx: cos(a) * spd, vy: sin(a) * spd,
            life: 0.6 + _rng.nextDouble() * 0.4,
            color: const Color(0xFFFFD54F),
            radius: 3 + _rng.nextDouble() * 3,
          ));
        }
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _round++;
            _loadWord();
          });
        }
      });
    }
  }

  String get _hint1Text => _hint1Shown ? _current.category : '';
  String get _hint2Text {
    if (!_hint2Shown) return '';
    final a = _current.answer;
    if (a.isEmpty) return '';
    return '${a[0].toUpperCase()}_ _ _';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping anywhere outside the TextField re-focuses it.
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: const Color(0xFF050510),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // --- Background wheel painter ---
              CustomPaint(
                size: Size(w, h),
                painter: _EverythingWheelPainter(
                  angle0: _wheelAngle0,
                  angle1: _wheelAngle1,
                  angle2: _wheelAngle2,
                  tokens: _ewWheelTokens,
                  particles: _particles,
                  correctFlash: _correctFlash,
                ),
              ),

              if (!_gameOver) ...[
                // --- Top bar: score + timer ---
                Positioned(
                  top: 10, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_score pts',
                        style: const TextStyle(
                          fontFamily: 'Avenir', fontSize: 18,
                          fontWeight: FontWeight.bold, color: Colors.white70,
                        ),
                      ),
                      _TimerArc(
                        fraction: _gameTimeLeft / _ewTotalSeconds,
                        seconds: _gameTimeLeft.ceil(),
                      ),
                    ],
                  ),
                ),

                // --- Central language display ---
                Positioned(
                  top: h * 0.24, left: 24, right: 24,
                  child: Column(
                    children: [
                      // Word-timer progress bar
                      _WordTimerBar(
                        fraction: (_wordTimeLeft / _wordTimeBudget).clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 14),
                      // Current foreign-language form
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Text(
                          _current.forms[_langIndex],
                          key: ValueKey(_langIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: _correctFlash > 0
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF7E57C2).withValues(alpha: 0.8),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Language flag (form index / total)
                      Text(
                        '${_langIndex + 1} / ${_current.forms.length}',
                        style: const TextStyle(
                          fontFamily: 'Avenir', fontSize: 11, color: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Hints row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_hint1Text.isNotEmpty)
                            _HintChip(label: _hint1Text),
                          if (_hint1Text.isNotEmpty && _hint2Text.isNotEmpty)
                            const SizedBox(width: 8),
                          if (_hint2Text.isNotEmpty)
                            _HintChip(label: _hint2Text, bright: true),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Typing field ---
                Positioned(
                  bottom: h * 0.22, left: 32, right: 32,
                  child: Column(
                    children: [
                      const Text(
                        'Type the English word',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 12, color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EWTextField(
                        controller: _textCtrl,
                        focusNode: _focusNode,
                        onChanged: _onTextChanged,
                        correct: _correctFlash > 0,
                        enabled: !_gameOver && _correctFlash <= 0,
                      ),
                    ],
                  ),
                ),

                // --- Round indicator ---
                Positioned(
                  bottom: h * 0.15, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'Word ${_round + 1}',
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 11, color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],

              // --- Game Over overlay ---
              if (_gameOver)
                _EWGameOverPanel(
                  score: _score,
                  rounds: _round,
                  onRestart: () => setState(() {
                    _gameTimeLeft = _ewTotalSeconds;
                    _score = 0;
                    _round = 0;
                    _gameOver = false;
                    _particles.clear();
                    _buildDeck();
                    _loadWord();
                  }),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TextField wrapper
// ---------------------------------------------------------------------------

class _EWTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool correct;
  final bool enabled;

  const _EWTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.correct,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      enabled: enabled,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(
        fontFamily: 'Avenir',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: correct ? const Color(0xFFFFD54F) : Colors.white,
        letterSpacing: 2,
      ),
      cursorColor: const Color(0xFF7E57C2),
      decoration: InputDecoration(
        hintText: '???',
        hintStyle: const TextStyle(
          fontFamily: 'Avenir', fontSize: 22, color: Colors.white24,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: correct ? 0.08 : 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: correct
                ? const Color(0xFFFFD54F)
                : const Color(0xFF7E57C2).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: correct
                ? const Color(0xFFFFD54F)
                : const Color(0xFF7E57C2),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hint chip widget
// ---------------------------------------------------------------------------

class _HintChip extends StatelessWidget {
  final String label;
  final bool bright;
  const _HintChip({required this.label, this.bright = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: bright
                ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
                : const Color(0xFF7E57C2).withValues(alpha: 0.5),
          ),
          color: (bright ? const Color(0xFFFFD54F) : const Color(0xFF7E57C2))
              .withValues(alpha: 0.07),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            color: bright
                ? const Color(0xFFFFD54F).withValues(alpha: 0.9)
                : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Word timer bar
// ---------------------------------------------------------------------------

class _WordTimerBar extends StatelessWidget {
  final double fraction; // 1.0 = full, 0.0 = empty
  const _WordTimerBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final Color barColor = fraction > 0.5
          ? const Color(0xFF7E57C2)
          : fraction > 0.25
              ? const Color(0xFFFFB300)
              : const Color(0xFFEF5350);
      return Stack(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 4,
            width: w * fraction,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: barColor,
            ),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Game-clock arc (top-right)
// ---------------------------------------------------------------------------

class _TimerArc extends StatelessWidget {
  final double fraction;
  final int seconds;
  const _TimerArc({required this.fraction, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _TimerArcPainter(fraction: fraction),
        child: Center(
          child: Text(
            '$seconds',
            style: const TextStyle(
              fontFamily: 'Avenir', fontSize: 12,
              fontWeight: FontWeight.bold, color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double fraction;
  const _TimerArcPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 3;
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    final Color arcColor = fraction > 0.4
        ? const Color(0xFF7E57C2)
        : fraction > 0.2
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);
    final fgPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * fraction,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter old) =>
      old.fraction != fraction;
}

// ---------------------------------------------------------------------------
// Game-over panel
// ---------------------------------------------------------------------------

class _EWGameOverPanel extends StatelessWidget {
  final int score;
  final int rounds;
  final VoidCallback onRestart;
  const _EWGameOverPanel({required this.score, required this.rounds, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Everything ends.',
              style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 12),
            Text(
              '$score',
              style: const TextStyle(
                fontFamily: 'Avenir', fontSize: 52,
                fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            const Text(
              'points',
              style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 6),
            Text(
              '$rounds words decoded',
              style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.6)),
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                ),
                child: const Text(
                  'Again',
                  style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 16,
                    fontWeight: FontWeight.bold, color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Three-wheel background painter
// ---------------------------------------------------------------------------

class _EverythingWheelPainter extends CustomPainter {
  final double angle0, angle1, angle2;
  final List<String> tokens;
  final List<_JuiceParticle> particles;
  final double correctFlash;

  const _EverythingWheelPainter({
    required this.angle0,
    required this.angle1,
    required this.angle2,
    required this.tokens,
    required this.particles,
    required this.correctFlash,
  });

  void _drawRing(Canvas canvas, Size size, double angle, double radius,
      List<String> words, Color color, double fontSize, double alpha) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final n = words.length;
    for (int i = 0; i < n; i++) {
      final a = angle + i / n * 2 * pi;
      final x = cx + cos(a) * radius;
      final y = cy + sin(a) * radius;
      final tp = TextPainter(
        text: TextSpan(
          text: words[i],
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: fontSize,
            color: color.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Subtle glow at center
    final flashAlpha = (correctFlash / 0.55).clamp(0.0, 1.0);
    final glowColor = Color.lerp(
      const Color(0xFF7E57C2).withValues(alpha: 0.07),
      const Color(0xFFFFD54F).withValues(alpha: 0.18),
      flashAlpha,
    )!;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55,
        Paint()..color = glowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));

    // Three orbital rings (decorative arcs)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const ringRadii = [85.0, 145.0, 210.0];
    const ringAlphas = [0.08, 0.06, 0.04];
    for (int i = 0; i < 3; i++) {
      ringPaint.color = Colors.white.withValues(alpha: ringAlphas[i]);
      canvas.drawCircle(Offset(cx, cy), ringRadii[i], ringPaint);
    }

    // Determine ring word subsets
    final n = tokens.length;
    final inner = tokens.sublist(0, (n * 0.3).round().clamp(1, n));
    final middle = tokens.sublist(inner.length, (n * 0.65).round().clamp(inner.length, n));
    final outer = tokens.sublist(middle.length.clamp(0, n));

    _drawRing(canvas, size, angle0, ringRadii[0], inner,
        const Color(0xFFCE93D8), 8.5, 0.22);
    _drawRing(canvas, size, angle1, ringRadii[1], middle,
        const Color(0xFF9575CD), 9.0, 0.18);
    _drawRing(canvas, size, angle2, ringRadii[2], outer,
        const Color(0xFF7E57C2), 9.5, 0.14);

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height),
          p.radius,
          Paint()
            ..color = p.color
                .withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EverythingWheelPainter old) => true;
}
