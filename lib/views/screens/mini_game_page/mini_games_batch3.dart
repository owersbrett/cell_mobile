import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ---------------------------------------------------------------------------
// Market event for leading-indicator event log
// ---------------------------------------------------------------------------
class _MarketEvent {
  final double timestamp;
  final String leadingText;
  final String actualText;
  final double priceImpact;
  final Color color;
  bool isRevealed = false;
  final double revealDelay;

  _MarketEvent({
    required this.timestamp,
    required this.leadingText,
    required this.actualText,
    required this.priceImpact,
    required this.color,
    required this.revealDelay,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. FinancialTradingGame — "Potato Futures"
// ═══════════════════════════════════════════════════════════════════════════════

class FinancialTradingGame extends StatefulWidget {
  const FinancialTradingGame({Key? key}) : super(key: key);
  @override
  State<FinancialTradingGame> createState() => _FinancialTradingGameState();
}

class _LeveragedPosition {
  final double entryPrice;
  final int quantity;
  double get liquidationPrice => entryPrice * 0.80;
  double get marginCallPrice => entryPrice * 0.85;
  _LeveragedPosition({required this.entryPrice, required this.quantity});
}

class _FinancialTradingGameState extends State<FinancialTradingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // Market state
  double _price = 50;
  double _momentum = 0;
  double _cash = 500;
  int _inventory = 0;
  double _startNetWorth = 500;
  final List<double> _priceHistory = [];
  double _timeLeft = 60;
  bool _gameOver = false;

  // Leverage state
  bool _leverageMode = false;
  final List<_LeveragedPosition> _leveragedPositions = [];
  double _liquidationFlashTimer = 0;
  double _liquidationTextScale = 0;
  bool _marginCallWarning = false;
  bool _rugPullActive = false;
  double _rugPullTimer = 0;

  // HODL tracking
  double _hodlTimer = 0;
  double _hodlStartPrice = 0;
  bool _isHodling = false;
  double _diamondHandsTimer = 0;

  // Limit orders
  double? _limitBuyPrice;
  double? _limitSellPrice;

  // News headlines
  String _headline = '';
  double _headlineTimer = 0;
  double _eventImpact = 0;
  double _newsFlashTimer = 0; // visual flash when news breaks
  double _nextNewsTimer = 2.0; // first news comes fast

  // Market manipulation
  double _manipCooldown = 0;
  static const double _manipCooldownMax = 12.0;

  // High scores
  List<Map<String, dynamic>> _highScores = [];
  double _bestScore = 0;
  bool _newHighScore = false;
  double _newHighScoreTimer = 0;

  final List<String> _bullishNews = [
    'BREAKING: Drought wipes out Idaho harvest!',
    'ALERT: Potato blight spreads across 5 states!',
    'SURGE: Japan triples import orders overnight!',
    'CRISIS: Major supply chain collapse!',
    'SHORTAGE: French fry chains rationing potatoes!',
    'SHOCK: Warehouse fire destroys 10M lbs of stock!',
    'FLASH: EU bans competing imports!',
    'BOOM: Fast food demand hits all-time high!',
    'REPORT: Cold snap freezes planting season!',
    'VIRAL: Celebrity chef sparks potato craze!',
    'PANIC: Seed potato shortage confirmed!',
    'DEAL: China signs massive potato trade deal!',
  ];
  final List<String> _bearishNews = [
    'DUMP: Record bumper harvest flooding market!',
    'CRASH: Lab-grown potatoes hit grocery shelves!',
    'ALERT: New GMO yields 3x normal crop!',
    'GLUT: Warehouses at 200% capacity!',
    'TREND: Sweet potato craze kills demand!',
    'SHOCK: Major buyer cancels all orders!',
    'REPORT: Government releases strategic reserves!',
    'SLUMP: Fast food chains switch to rice!',
    'BUST: Speculator panic sell-off underway!',
    'LEAK: New synthetic potato substitute approved!',
    'DROP: Consumer confidence at all-time low!',
    'FLOOD: Three countries dump surplus simultaneously!',
  ];

  // Market event log
  final List<_MarketEvent> _eventLog = [];
  double _nextEventTimer = 5.0; // first event comes quickly
  double _elapsedTime = 0;

  static const List<Map<String, dynamic>> _eventTemplates = [
    {
      'leading': '\u{1F4E1} Weather report incoming...',
      'actual': '\u{1F327}\u{FE0F} Drought in Idaho! Supply down.',
      'impact': 6.0,
      'hintBullish': true,
    },
    {
      'leading': '\u{1F4E1} Trade data pending...',
      'actual': '\u{1F4E6} Record exports to Japan!',
      'impact': 4.5,
      'hintBullish': true,
    },
    {
      'leading': '\u{1F4E1} USDA report due...',
      'actual': '\u{1F4CA} Potato glut \u2014 oversupply!',
      'impact': -6.0,
      'hintBullish': false,
    },
    {
      'leading': '\u{1F4E1} Lab results coming...',
      'actual': '\u{1F9EC} New blight-resistant variety!',
      'impact': 3.0,
      'hintBullish': true,
    },
    {
      'leading': '\u{1F4E1} Policy alert...',
      'actual': '\u{1F3DB}\u{FE0F} Tariff on imports!',
      'impact': 5.5,
      'hintBullish': true,
    },
  ];

  // Particles for visual juice
  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _priceHistory.addAll(List.generate(60, (_) => 50.0));
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _loadHighScores();
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('potato_futures_high_scores');
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      if (mounted) {
        setState(() {
          _highScores = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_highScores.isNotEmpty) {
            _bestScore = (_highScores.first['score'] as num).toDouble();
          }
        });
      }
    }
  }

  Future<void> _saveHighScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'score': score,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    };
    _highScores.add(entry);
    _highScores.sort(
        (a, b) => (b['score'] as num).compareTo(a['score'] as num));
    if (_highScores.length > 5) {
      _highScores = _highScores.sublist(0, 5);
    }
    await prefs.setString(
        'potato_futures_high_scores', jsonEncode(_highScores));
    if (_highScores.isNotEmpty) {
      _bestScore = (_highScores.first['score'] as num).toDouble();
    }
  }

  void _checkAndSaveHighScore() {
    final nw = _netWorth;
    final qualifies = _highScores.length < 5 ||
        nw > (_highScores.last['score'] as num).toDouble();
    if (qualifies) {
      _newHighScore = true;
      _newHighScoreTimer = 3.0;
      _saveHighScore(nw);
    }
  }

  int get _leveragedInventory {
    int total = 0;
    for (final pos in _leveragedPositions) {
      total += pos.quantity;
    }
    return total;
  }

  double get _leveragedPnl {
    double total = 0;
    for (final pos in _leveragedPositions) {
      total += pos.quantity * (_price - pos.entryPrice);
    }
    return total;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _gameOver = true;
        _checkAndSaveHighScore();
        return;
      }

      // Liquidation flash animation
      if (_liquidationFlashTimer > 0) {
        _liquidationFlashTimer -= dt;
        _liquidationTextScale =
            (1.0 - (_liquidationFlashTimer / 2.0)).clamp(0.0, 1.0);
      }

      // New high score animation timer
      if (_newHighScoreTimer > 0) _newHighScoreTimer -= dt;

      // Rug pull animation
      if (_rugPullActive) {
        _rugPullTimer -= dt;
        if (_rugPullTimer <= 0) _rugPullActive = false;
      }

      // News events — frequent and impactful
      _headlineTimer -= dt;
      if (_newsFlashTimer > 0) _newsFlashTimer -= dt;
      if (_manipCooldown > 0) _manipCooldown -= dt;
      _nextNewsTimer -= dt;
      if (_nextNewsTimer <= 0) {
        _nextNewsTimer = 3 + _rng.nextDouble() * 3; // every 3-6s
        if (_rng.nextBool()) {
          _headline = _bullishNews[_rng.nextInt(_bullishNews.length)];
          _eventImpact = 5 + _rng.nextDouble() * 8;
        } else {
          _headline = _bearishNews[_rng.nextInt(_bearishNews.length)];
          _eventImpact = -(5 + _rng.nextDouble() * 8);
        }
        _headlineTimer = 4;
        _newsFlashTimer = 0.6;
      }

      // Price physics
      if (!_rugPullActive) {
        final noise = (_rng.nextDouble() - 0.5) * 2;
        final meanReversion = (50 - _price) * 0.005;
        _momentum = _momentum * 0.95 + noise * 0.3 + _eventImpact * 0.1;
        _eventImpact *= 0.95;
        _price += _momentum + meanReversion;
      } else {
        _price -= 2.0;
        _momentum = -3;
      }
      _price = _price.clamp(5.0, 200.0);
      _priceHistory.add(_price);
      if (_priceHistory.length > 120) _priceHistory.removeAt(0);

      // HODL tracking
      if (_inventory > 0 || _leveragedInventory > 0) {
        if (!_isHodling) {
          _isHodling = true;
          _hodlTimer = 0;
          _hodlStartPrice = _price;
        }
        _hodlTimer += dt;
        if (_hodlTimer >= 10 && _price > _hodlStartPrice && _diamondHandsTimer <= 0) {
          _diamondHandsTimer = 2.5;
        }
      } else {
        _isHodling = false;
        _hodlTimer = 0;
      }
      if (_diamondHandsTimer > 0) _diamondHandsTimer -= dt;

      // Margin call / liquidation check
      _marginCallWarning = false;
      bool shouldLiquidate = false;
      for (final pos in _leveragedPositions) {
        if (_price <= pos.liquidationPrice) {
          shouldLiquidate = true;
          break;
        }
        if (_price <= pos.marginCallPrice) {
          _marginCallWarning = true;
        }
      }
      if (shouldLiquidate && _leveragedPositions.isNotEmpty) {
        _performLiquidation();
      }

      // Check limit orders
      if (_limitBuyPrice != null && _price <= _limitBuyPrice!) {
        if (_leverageMode) {
          final cost = _price * 0.2;
          if (_cash >= cost) {
            _cash -= cost;
            _leveragedPositions.add(
                _LeveragedPosition(entryPrice: _price, quantity: 1));
            _spawnParticles(_rng.nextDouble() * 200, 200, Colors.orangeAccent, 5);
            _limitBuyPrice = null;
          }
        } else if (_cash >= _price) {
          _cash -= _price;
          _inventory++;
          _spawnParticles(_rng.nextDouble() * 200, 200, Colors.green, 5);
          _limitBuyPrice = null;
        }
      }
      if (_limitSellPrice != null && _price >= _limitSellPrice!) {
        if (_leveragedPositions.isNotEmpty) {
          final pos = _leveragedPositions.removeLast();
          _cash += _price * pos.quantity;
          _spawnParticles(_rng.nextDouble() * 200, 200, Colors.red, 5);
          if (_leveragedPositions.isEmpty) _limitSellPrice = null;
        } else if (_inventory > 0) {
          _cash += _price;
          _inventory--;
          _spawnParticles(_rng.nextDouble() * 200, 200, Colors.red, 5);
          _limitSellPrice = null;
        }
      }

      // --- Market event log system ---
      _elapsedTime += dt;
      _nextEventTimer -= dt;
      if (_nextEventTimer <= 0) {
        _nextEventTimer = 8 + _rng.nextDouble() * 4; // 8-12s between events
        final template = _eventTemplates[_rng.nextInt(_eventTemplates.length)];
        final isFakeout = _rng.nextDouble() < 0.20; // 20% chance of fake-out
        double impact = (template['impact'] as double);
        if (isFakeout) impact = -impact;
        final revealDelay = 3.0 + _rng.nextDouble() * 2.0; // 3-5s
        final isBullish = impact > 0;
        _eventLog.insert(
          0,
          _MarketEvent(
            timestamp: _elapsedTime,
            leadingText: template['leading'] as String,
            actualText: template['actual'] as String,
            priceImpact: impact,
            color: isBullish ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
            revealDelay: revealDelay,
          ),
        );
        // Keep max 12 events in memory
        if (_eventLog.length > 12) _eventLog.removeLast();
      }
      // Reveal events whose delay has expired and apply price impact
      for (final ev in _eventLog) {
        if (!ev.isRevealed && (_elapsedTime - ev.timestamp) >= ev.revealDelay) {
          ev.isRevealed = true;
          _eventImpact += ev.priceImpact;
        }
      }

      // Update particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _performLiquidation() {
    double proceeds = 0;
    double totalCost = 0;
    for (final pos in _leveragedPositions) {
      proceeds += pos.quantity * _price;
      totalCost += pos.quantity * pos.entryPrice;
    }
    final loss = totalCost - proceeds;
    _cash = (_cash - loss).clamp(0.0, 999999.0);
    _leveragedPositions.clear();
    _liquidationFlashTimer = 2.0;
    _liquidationTextScale = 0;
    _marginCallWarning = false;
    _rugPullActive = true;
    _rugPullTimer = 0.5;
    for (int i = 0; i < 30; i++) {
      _spawnParticles(_rng.nextDouble() * 300, _rng.nextDouble() * 400, Colors.red, 3);
    }
    if (_cash <= 0 && _inventory == 0) {
      _gameOver = true;
      _checkAndSaveHighScore();
    }
  }

  void _spawnParticles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      _particles.add(_JuiceParticle(
        x: x, y: y,
        vx: (_rng.nextDouble() - 0.5) * 100,
        vy: (_rng.nextDouble() - 0.5) * 100 - 40,
        life: 0.8, color: color,
      ));
    }
  }

  double get _netWorth => _cash + _inventory * _price + _leveragedPnl;
  double get _pnl => _netWorth - _startNetWorth;

  double? get _lowestLiquidationPrice {
    if (_leveragedPositions.isEmpty) return null;
    double lowest = double.infinity;
    for (final pos in _leveragedPositions) {
      if (pos.liquidationPrice < lowest) lowest = pos.liquidationPrice;
    }
    return lowest;
  }

  void _restart() {
    setState(() {
      _price = 50;
      _momentum = 0;
      _cash = 500;
      _inventory = 0;
      _startNetWorth = 500;
      _priceHistory.clear();
      _priceHistory.addAll(List.generate(60, (_) => 50.0));
      _timeLeft = 60;
      _gameOver = false;
      _limitBuyPrice = null;
      _limitSellPrice = null;
      _headline = '';
      _headlineTimer = 0;
      _eventImpact = 0;
      _particles.clear();
      _leverageMode = false;
      _leveragedPositions.clear();
      _liquidationFlashTimer = 0;
      _liquidationTextScale = 0;
      _marginCallWarning = false;
      _rugPullActive = false;
      _rugPullTimer = 0;
      _hodlTimer = 0;
      _hodlStartPrice = 0;
      _isHodling = false;
      _diamondHandsTimer = 0;
      _newHighScore = false;
      _newHighScoreTimer = 0;
      _eventLog.clear();
      _nextEventTimer = 5.0;
      _elapsedTime = 0;
      _newsFlashTimer = 0;
      _nextNewsTimer = 2.0;
      _manipCooldown = 0;
    });
  }

  void _triggerManipulation(String name, double cost, double impact, String headline) {
    if (_gameOver || _cash < cost || _manipCooldown > 0) return;
    setState(() {
      _cash -= cost;
      _headline = headline;
      _headlineTimer = 5;
      _newsFlashTimer = 1.0;
      _eventImpact += impact;
      _manipCooldown = _manipCooldownMax;
      _nextNewsTimer += 3; // delay next random news
      _spawnParticles(200, 300, impact > 0 ? Colors.greenAccent : Colors.deepOrange, 15);
    });
  }

  static const List<Map<String, dynamic>> _manipActions = [
    {
      'name': 'Corner Market',
      'cost': 200.0,
      'impact': 12.0,
      'icon': Icons.shopping_cart,
      'headline': 'YOU: Bought up all available supply!',
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Fund Startup',
      'cost': 300.0,
      'impact': 15.0,
      'icon': Icons.rocket_launch,
      'headline': 'YOU: Funded potato tech startup — hype surges!',
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Lobby Tariffs',
      'cost': 400.0,
      'impact': 18.0,
      'icon': Icons.account_balance,
      'headline': 'YOU: Lobbied for import tariffs — prices soar!',
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'Spread FUD',
      'cost': 150.0,
      'impact': -12.0,
      'icon': Icons.campaign,
      'headline': 'YOU: Planted bearish rumors in the press!',
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Dump Supply',
      'cost': 250.0,
      'impact': -15.0,
      'icon': Icons.local_shipping,
      'headline': 'YOU: Flooded the market with cheap imports!',
      'color': Color(0xFF9C27B0),
    },
    {
      'name': 'Switch Supplier',
      'cost': 180.0,
      'impact': -10.0,
      'icon': Icons.swap_horiz,
      'headline': 'YOU: Switched suppliers — old partner dumping stock!',
      'color': Color(0xFF795548),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = constraints.maxHeight * 0.30;
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            if (_liquidationFlashTimer > 0)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withValues(alpha: (_liquidationFlashTimer / 2.0).clamp(0.0, 0.6)),
                ),
              ),
            // News flash overlay
            if (_newsFlashTimer > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: (_eventImpact > 0 ? Colors.green : Colors.red)
                        .withValues(alpha: (_newsFlashTimer * 0.15).clamp(0.0, 0.15)),
                  ),
                ),
              ),
            Column(
              children: [
                // Timer + P&L
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${_timeLeft.toInt()}s',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 16,
                          color: _timeLeft < 10 ? Colors.redAccent : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_bestScore > 0)
                        Text(
                          'Best: \$${_bestScore.toStringAsFixed(0)}',
                          style: const TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Colors.white30),
                        ),
                      const Spacer(),
                      Text(
                        'P&L: ${_pnl >= 0 ? "+" : ""}\$${_pnl.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold,
                          color: _pnl >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Breaking news banner
                if (_headlineTimer > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: _newsFlashTimer > 0
                        ? (_eventImpact > 0 ? const Color(0xFF1B5E20) : const Color(0xFF7F0000))
                        : (_eventImpact > 0 ? const Color(0xFF0D2E10) : const Color(0xFF3E0000)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _eventImpact > 0 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _eventImpact > 0 ? 'BULL' : 'BEAR',
                            style: const TextStyle(fontFamily: 'Avenir', fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _headline,
                            style: TextStyle(
                              fontFamily: 'Avenir', fontSize: 13, fontWeight: FontWeight.bold,
                              color: _eventImpact > 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Leveraged P&L display
                if (_leveragedPositions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '5x Pos: $_leveragedInventory  '
                        'P&L: ${_leveragedPnl >= 0 ? "+" : ""}\$${_leveragedPnl.toStringAsFixed(0)}  '
                        'Liq: \$${_lowestLiquidationPrice?.toStringAsFixed(1) ?? "-"}',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 10,
                          color: _leveragedPnl >= 0 ? Colors.orangeAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ),

                // Margin call warning banner
                if (_marginCallWarning && !_gameOver)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color: Colors.red.withValues(alpha: 0.3),
                    child: const Text(
                      'MARGIN CALL WARNING',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),

                // Price chart
                GestureDetector(
                  onTapDown: (details) {
                    if (_gameOver) return;
                    final fraction = 1 - (details.localPosition.dy / chartHeight);
                    final allPrices = List<double>.from(_priceHistory);
                    final liqPrice = _lowestLiquidationPrice;
                    if (liqPrice != null) allPrices.add(liqPrice);
                    final minP = allPrices.reduce(min) - 5;
                    final maxP = allPrices.reduce(max) + 5;
                    final tappedPrice = minP + fraction * (maxP - minP);
                    setState(() {
                      if (tappedPrice < _price) {
                        _limitBuyPrice = tappedPrice;
                      } else {
                        _limitSellPrice = tappedPrice;
                      }
                    });
                  },
                  child: SizedBox(
                    height: chartHeight,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TradingChartPainter(
                        _priceHistory, _limitBuyPrice, _limitSellPrice, _price,
                        liquidationPrices: _leveragedPositions.map((p) => p.liquidationPrice).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Current price
                Text(
                  '\$${_price.toStringAsFixed(1)} / potato',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),

                // Inventory + cash
                Text(
                  'Cash: \$${_cash.toStringAsFixed(0)}   Potatoes: $_inventory'
                  '${_leveragedInventory > 0 ? "   5x: $_leveragedInventory" : ""}',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white54),
                ),

                // HODL counter
                if (_isHodling && _hodlTimer > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'HODL: ${_hodlTimer.toInt()}s',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 10,
                        color: _hodlTimer >= 10 ? Colors.amberAccent : Colors.white30),
                    ),
                  ),

                if (_limitBuyPrice != null || _limitSellPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_limitBuyPrice != null ? "Limit BUY @ \$${_limitBuyPrice!.toStringAsFixed(1)}" : ""}'
                      '${_limitBuyPrice != null && _limitSellPrice != null ? "  |  " : ""}'
                      '${_limitSellPrice != null ? "Limit SELL @ \$${_limitSellPrice!.toStringAsFixed(1)}" : ""}',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Colors.amberAccent),
                    ),
                  ),
                const SizedBox(height: 8),

                // Buy / Leverage toggle / Sell buttons
                if (!_gameOver)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tradeButton(
                        _leverageMode ? 'BUY 5x' : 'BUY',
                        _leverageMode ? Colors.orange : Colors.green,
                        _leverageMode
                            ? (_cash >= _price * 0.2 ? () {
                                setState(() {
                                  _cash -= _price * 0.2;
                                  _leveragedPositions.add(_LeveragedPosition(entryPrice: _price, quantity: 1));
                                  _spawnParticles(constraints.maxWidth * 0.2, constraints.maxHeight * 0.7, Colors.orange, 8);
                                });
                              } : null)
                            : (_cash >= _price ? () {
                                setState(() {
                                  _cash -= _price;
                                  _inventory++;
                                  _spawnParticles(constraints.maxWidth * 0.2, constraints.maxHeight * 0.7, Colors.green, 8);
                                });
                              } : null),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(() => _leverageMode = !_leverageMode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: _leverageMode ? Colors.orange.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _leverageMode ? Colors.orangeAccent : Colors.grey.withValues(alpha: 0.3),
                              width: _leverageMode ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '5x',
                            style: TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold,
                              color: _leverageMode ? Colors.orangeAccent : Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _tradeButton(
                        'SELL', Colors.red,
                        (_inventory > 0 || _leveragedPositions.isNotEmpty) ? () {
                          setState(() {
                            if (_leveragedPositions.isNotEmpty) {
                              final pos = _leveragedPositions.removeLast();
                              _cash += _price * pos.quantity;
                            } else {
                              _cash += _price;
                              _inventory--;
                            }
                            _spawnParticles(constraints.maxWidth * 0.8, constraints.maxHeight * 0.7, Colors.red, 8);
                          });
                        } : null,
                      ),
                    ],
                  ),

                const SizedBox(height: 6),

                // Market manipulation actions
                if (!_gameOver && _netWorth >= 150)
                  Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Text(
                            _manipCooldown > 0
                                ? 'MOVE THE MARKET (${_manipCooldown.toInt()}s)'
                                : 'MOVE THE MARKET',
                            style: TextStyle(
                              fontFamily: 'Avenir', fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _manipCooldown > 0 ? Colors.white24 : Colors.amberAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: _manipActions.map((action) {
                            final cost = action['cost'] as double;
                            final impact = action['impact'] as double;
                            final canAfford = _cash >= cost && _manipCooldown <= 0;
                            final actionColor = action['color'] as Color;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: canAfford
                                    ? () => _triggerManipulation(
                                          action['name'] as String,
                                          cost,
                                          impact,
                                          action['headline'] as String,
                                        )
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: canAfford
                                        ? actionColor.withValues(alpha: 0.25)
                                        : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: canAfford
                                          ? actionColor.withValues(alpha: 0.6)
                                          : Colors.grey.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(action['icon'] as IconData, size: 12,
                                            color: canAfford ? actionColor : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            action['name'] as String,
                                            style: TextStyle(
                                              fontFamily: 'Avenir', fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: canAfford ? actionColor : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${cost.toInt()}  ${impact > 0 ? "+$impact" : "$impact"}',
                                        style: TextStyle(
                                          fontFamily: 'Avenir', fontSize: 8,
                                          color: canAfford ? Colors.white38 : Colors.white12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 4),

                // Net worth
                Text(
                  'Net Worth: \$${_netWorth.toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE19816)),
                ),

                if (_gameOver) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pnl >= 0 ? 'Nice trades!' : 'Better luck next time!',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: _pnl >= 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
                  if (_highScores.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text('TOP SCORES', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    const SizedBox(height: 2),
                    ..._highScores.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '${i + 1}. \$${(s['score'] as num).toStringAsFixed(0)}  (${s['date']})',
                          style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white54),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _restart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                      child: const Text('Play Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                    ),
                  ),
                ],
              ],
            ),

            // Particles overlay
            ..._particles.where((p) => p.life > 0).map((p) => Positioned(
              left: p.x - 3, top: p.y - 3,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0) * 0.8),
                ),
              ),
            )),

            // LIQUIDATED text overlay
            if (_liquidationFlashTimer > 0)
              Center(
                child: Transform.scale(
                  scale: 0.5 + _liquidationTextScale * 1.5,
                  child: Text(
                    'LIQUIDATED',
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 40, fontWeight: FontWeight.w900,
                      color: Colors.red.withValues(alpha: (_liquidationFlashTimer / 2.0).clamp(0.0, 1.0)),
                      shadows: const [
                        Shadow(color: Colors.redAccent, blurRadius: 20),
                        Shadow(color: Colors.red, blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),

            // Diamond Hands text
            if (_diamondHandsTimer > 0)
              Positioned(
                top: constraints.maxHeight * 0.4, left: 0, right: 0,
                child: Center(
                  child: Text(
                    'Diamond Hands \u{1F48E}',
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent.withValues(alpha: (_diamondHandsTimer / 2.5).clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              ),

            // NEW HIGH SCORE overlay
            if (_newHighScore && _newHighScoreTimer > 0)
              Positioned(
                top: constraints.maxHeight * 0.25, left: 0, right: 0,
                child: Center(
                  child: Transform.scale(
                    scale: 0.8 + (1.0 - (_newHighScoreTimer / 3.0).clamp(0.0, 1.0)) * 0.4,
                    child: Text(
                      'NEW HIGH SCORE!',
                      style: TextStyle(
                        fontFamily: 'Avenir', fontSize: 28, fontWeight: FontWeight.w900,
                        color: Colors.amberAccent.withValues(alpha: (_newHighScoreTimer / 3.0).clamp(0.0, 1.0)),
                        shadows: const [
                          Shadow(color: Colors.orange, blurRadius: 20),
                          Shadow(color: Colors.amber, blurRadius: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Margin call floating warning
            if (_marginCallWarning && !_gameOver)
              Positioned(
                top: constraints.maxHeight * 0.15, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Text(
                      'MARGIN CALL',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),
                ),
              ),

            // Market event log panel
            if (!_gameOver && _eventLog.isNotEmpty)
              Positioned(
                left: 4,
                bottom: 50,
                child: Container(
                  width: 170,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MARKET INTEL',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 9,
                          fontWeight: FontWeight.bold, color: Colors.white38,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _eventLog.take(8).map((ev) {
                              final age = _elapsedTime - ev.timestamp;
                              final timeLabel = age < 60
                                  ? '${age.toInt()}s'
                                  : '${(age / 60).toInt()}m';
                              final text = ev.isRevealed
                                  ? ev.actualText
                                  : ev.leadingText;
                              final textColor = ev.isRevealed
                                  ? ev.color
                                  : Colors.amberAccent.withValues(alpha: 0.7);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeLabel,
                                      style: TextStyle(
                                        fontFamily: 'Avenir', fontSize: 8,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontFamily: 'Avenir', fontSize: 9,
                                          color: textColor,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _tradeButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: onTap != null ? color : Colors.grey),
        ),
      ),
    );
  }
}

class _TradingChartPainter extends CustomPainter {
  final List<double> data;
  final double? limitBuy;
  final double? limitSell;
  final double currentPrice;
  final List<double> liquidationPrices;

  _TradingChartPainter(
    this.data, this.limitBuy, this.limitSell, this.currentPrice, {
    this.liquidationPrices = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    // Compute range including liquidation prices
    double minV = data.reduce(min);
    double maxV = data.reduce(max);
    for (final lp in liquidationPrices) {
      if (lp < minV) minV = lp;
      if (lp > maxV) maxV = lp;
    }
    minV -= 5;
    maxV += 5;
    final range = maxV - minV;
    if (range <= 0) return;

    // Grid lines
    final gridPaint = Paint()..color = const Color(0x11FFFFFF)..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Price line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill under chart
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final gradient = ui.Gradient.linear(
      Offset(0, 0), Offset(0, size.height),
      [const Color(0x33E19816), const Color(0x00E19816)],
    );
    canvas.drawPath(fillPath, Paint()..shader = gradient);

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFE19816)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Limit order lines
    if (limitBuy != null) {
      final y = size.height - ((limitBuy! - minV) / range) * size.height;
      if (y > 0 && y < size.height) {
        final dashedPaint = Paint()..color = Colors.greenAccent..strokeWidth = 1;
        for (double x = 0; x < size.width; x += 8) {
          canvas.drawLine(Offset(x, y), Offset(x + 4, y), dashedPaint);
        }
      }
    }
    if (limitSell != null) {
      final y = size.height - ((limitSell! - minV) / range) * size.height;
      if (y > 0 && y < size.height) {
        final dashedPaint = Paint()..color = Colors.redAccent..strokeWidth = 1;
        for (double x = 0; x < size.width; x += 8) {
          canvas.drawLine(Offset(x, y), Offset(x + 4, y), dashedPaint);
        }
      }
    }

    // Liquidation price lines (red dashed)
    for (final liqPrice in liquidationPrices) {
      final y = size.height - ((liqPrice - minV) / range) * size.height;
      if (y > 0 && y < size.height) {
        final dashedPaint = Paint()..color = const Color(0xCCFF0000)..strokeWidth = 1.5;
        for (double x = 0; x < size.width; x += 10) {
          canvas.drawLine(Offset(x, y), Offset(x + 5, y), dashedPaint);
        }
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'LIQ \$${liqPrice.toStringAsFixed(1)}',
            style: const TextStyle(color: Color(0xCCFF0000), fontSize: 9, fontFamily: 'Avenir'),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, y - 12));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TradingChartPainter old) => true;
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
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak these without touching game logic
// ─────────────────────────────────────────────────────────────────────────────
// Simulation runs at ~60 fps; all units are logical pixels / second unless noted.

// Cannon
const double _kMaxLaunchSpeed = 900.0; // px/s — maximum projectile speed
const double _kMinLaunchSpeed = 200.0; // px/s — minimum launch speed (short drag)
const double _kDragToSpeedScale = 2.2; // drag distance in px → speed multiplier
const double _kProjectileRadius = 7.0; // visual + hit radius of the projectile

// Gravity
const double _kGravityConstant = 38000.0; // G — base pull strength (px³/s²)
// Per-body mass is defined in _CannonLevel; G * mass = actual pull force constant.

// Trajectory preview
const int _kPreviewSteps = 80; // simulation steps for the dotted preview arc
const double _kPreviewDt = 0.025; // seconds per preview step (~2s of flight shown)

// Target
const double _kTargetBaseRadius = 26.0; // hit zone radius on level 1
const double _kTargetRadiusShrinkPerLevel = 2.0; // target shrinks each level

// Levels & scoring
const int _kPointsPerHit = 100; // base score per successful hit
const int _kBonusPerExtraShot = 20; // bonus for spare shots left in ammo (unused)
const int _kShotsPerLevel = 5; // shots available per level
const double _kTotalGameSeconds = 60.0; // game ends after this many seconds

// Moving target (unlocks from level 4)
const double _kTargetMoveSpeed = 60.0; // px/s lateral speed of moving target
// ─────────────────────────────────────────────────────────────────────────────

/// One gravity body in a level layout.
class _GravBody {
  final Offset pos; // fraction of canvas [0..1]
  final double mass; // multiplied by _kGravityConstant
  final Color color;
  final double radius; // visual radius in px
  _GravBody({required this.pos, required this.mass, required this.color, required this.radius});
}

/// Static description of a single level.
class _CannonLevel {
  final List<_GravBody> bodies;
  final Offset targetPos; // fraction of canvas
  final bool targetMoves;
  _CannonLevel({required this.bodies, required this.targetPos, this.targetMoves = false});
}

/// Live projectile in flight.
class _Projectile {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  final List<Offset> trail; // for tail rendering (canvas px)
  _Projectile({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true, trail = [];
}

class PlanetCatchGame extends StatefulWidget {
  const PlanetCatchGame({Key? key}) : super(key: key);
  @override
  State<PlanetCatchGame> createState() => _PlanetCatchGameState();
}

class _PlanetCatchGameState extends State<PlanetCatchGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // ── state ──────────────────────────────────────────────────────────────────
  bool _waitingToStart = true;
  bool _gameOver = false;
  int _score = 0;
  int _level = 0; // index into _levels list (clamped when beyond)
  int _shotsLeft = _kShotsPerLevel;
  double _timeLeft = _kTotalGameSeconds;
  int _highScore = 0;
  bool _newBest = false;

  // ── aiming ─────────────────────────────────────────────────────────────────
  Offset? _dragStart; // where the drag began (canvas px)
  Offset? _dragCurrent; // current drag position (canvas px)
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  Size _canvasSize = Size.zero;

  // ── live sim ───────────────────────────────────────────────────────────────
  _Projectile? _projectile;
  final List<_JuiceParticle> _particles = [];

  // moving-target offset (px, signed)
  double _targetDrift = 0.0;
  double _targetDriftDir = 1.0;

  // ── level table ────────────────────────────────────────────────────────────
  late List<_CannonLevel> _levels;

  // cannon origin (bottom-left corner, fraction)
  static const Offset _cannonFrac = Offset(0.12, 0.82);

  @override
  void initState() {
    super.initState();
    _buildLevels();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
    _loadHighScore();
  }

  void _buildLevels() {
    _levels = [
      // Level 1 — one medium planet, stationary target
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.5, 0.45), mass: 1.0, color: const Color(0xFF42A5F5), radius: 22),
      ], targetPos: const Offset(0.82, 0.25)),

      // Level 2 — two bodies, target tucked behind them
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.4, 0.5), mass: 0.9, color: const Color(0xFF66BB6A), radius: 20),
        _GravBody(pos: const Offset(0.65, 0.35), mass: 0.7, color: const Color(0xFFAB47BC), radius: 16),
      ], targetPos: const Offset(0.78, 0.70)),

      // Level 3 — heavy central body (slingshot required)
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.52, 0.42), mass: 2.0, color: const Color(0xFFFFA726), radius: 30),
      ], targetPos: const Offset(0.15, 0.18)),

      // Level 4 — moving target
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.45, 0.48), mass: 1.2, color: const Color(0xFF26C6DA), radius: 24),
        _GravBody(pos: const Offset(0.70, 0.60), mass: 0.6, color: const Color(0xFFEF5350), radius: 14),
      ], targetPos: const Offset(0.82, 0.22), targetMoves: true),

      // Level 5 — three-body chaos
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.35, 0.38), mass: 1.1, color: const Color(0xFF7E57C2), radius: 22),
        _GravBody(pos: const Offset(0.62, 0.30), mass: 0.8, color: const Color(0xFF26A69A), radius: 18),
        _GravBody(pos: const Offset(0.55, 0.65), mass: 0.9, color: const Color(0xFFF06292), radius: 18),
      ], targetPos: const Offset(0.80, 0.75)),

      // Level 6 — very heavy star, target in tight spot, moves
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.50, 0.44), mass: 2.8, color: const Color(0xFFFFCA28), radius: 36),
        _GravBody(pos: const Offset(0.28, 0.32), mass: 0.5, color: const Color(0xFF8D6E63), radius: 12),
      ], targetPos: const Offset(0.85, 0.50), targetMoves: true),

      // Level 7 — four bodies, moving target, tiny goal
      _CannonLevel(bodies: [
        _GravBody(pos: const Offset(0.40, 0.35), mass: 1.0, color: const Color(0xFF42A5F5), radius: 20),
        _GravBody(pos: const Offset(0.65, 0.40), mass: 1.0, color: const Color(0xFF66BB6A), radius: 20),
        _GravBody(pos: const Offset(0.52, 0.62), mass: 1.0, color: const Color(0xFFFFA726), radius: 20),
        _GravBody(pos: const Offset(0.30, 0.58), mass: 0.8, color: const Color(0xFFEF5350), radius: 16),
      ], targetPos: const Offset(0.82, 0.18), targetMoves: true),
    ];
  }

  _CannonLevel get _currentLevel => _levels[_level.clamp(0, _levels.length - 1)];
  double get _targetRadius => (_kTargetBaseRadius - _level * _kTargetRadiusShrinkPerLevel).clamp(10.0, _kTargetBaseRadius);

  // Effective target position in canvas px (accounts for drift on moving levels)
  Offset _targetPx(Size size) {
    final base = _currentLevel.targetPos;
    if (_currentLevel.targetMoves) {
      return Offset(base.dx * size.width + _targetDrift, base.dy * size.height);
    }
    return Offset(base.dx * size.width, base.dy * size.height);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _highScore = prefs.getInt('orbit_catch_high_score') ?? 0; });
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
      _particles.clear();
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
      // Countdown timer
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _endGame();
        return;
      }

      // Move target drift
      if (_currentLevel.targetMoves && _canvasSize != Size.zero) {
        _targetDrift += _targetDriftDir * _kTargetMoveSpeed * dt;
        final maxDrift = _canvasSize.width * 0.12;
        if (_targetDrift.abs() > maxDrift) {
          _targetDriftDir = -_targetDriftDir;
          _targetDrift = _targetDrift.sign * maxDrift;
        }
      }

      // Advance projectile physics
      if (_projectile != null && _projectile!.alive) {
        _advanceProjectile(_projectile!, dt);
      }

      // Age particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _advanceProjectile(_Projectile proj, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;

    // Sub-step for accuracy
    const subSteps = 4;
    final subDt = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      // Gravity from each body
      for (final body in _currentLevel.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final dx = bx - proj.x;
        final dy = by - proj.y;
        final distSq = (dx * dx + dy * dy).clamp(100.0, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        proj.vx += (dx / dist) * force * subDt;
        proj.vy += (dy / dist) * force * subDt;

        // Collide with body
        if (dist < body.radius + _kProjectileRadius) {
          proj.alive = false;
          _spawnParticles(proj.x, proj.y, Colors.orangeAccent, 12);
          return;
        }
      }

      proj.x += proj.vx * subDt;
      proj.y += proj.vy * subDt;

      // Record trail (throttled)
      if (s == 0) {
        proj.trail.add(Offset(proj.x, proj.y));
        if (proj.trail.length > 40) proj.trail.removeAt(0);
      }

      // Hit target?
      final tpx = _targetPx(size);
      final tdx = proj.x - tpx.dx;
      final tdy = proj.y - tpx.dy;
      final tdist = sqrt(tdx * tdx + tdy * tdy);
      if (tdist < _targetRadius + _kProjectileRadius) {
        proj.alive = false;
        _onHit();
        return;
      }

      // Out of bounds — add generous margin
      if (proj.x < -80 || proj.x > size.width + 80 || proj.y < -80 || proj.y > size.height + 80) {
        proj.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _onHit() {
    final size = _canvasSize;
    final tpx = _targetPx(size);
    // Score: base + time bonus + shot bonus
    final timeBonus = (_timeLeft / _kTotalGameSeconds * 50).round();
    final shotBonus = _shotsLeft * _kBonusPerExtraShot;
    _score += _kPointsPerHit + timeBonus + shotBonus;
    _spawnParticles(tpx.dx / size.width, tpx.dy / size.height, Colors.cyanAccent, 20, normalized: true);
    _spawnParticles(tpx.dx / size.width, tpx.dy / size.height, Colors.amberAccent, 12, normalized: true);
    // Advance level
    _level++;
    _shotsLeft = _kShotsPerLevel;
    _targetDrift = 0.0;
    _targetDriftDir = 1.0;
    _projectile = null;
  }

  void _onMiss() {
    _shotsLeft--;
    if (_shotsLeft <= 0) {
      // No shots left — lose a level (floor 0) and refill shots
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
    if (_projectile != null && _projectile!.alive) return; // busy
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() { _dragCurrent = d.localPosition; });
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragStart == null || _dragCurrent == null) return;
    if (_canvasSize == Size.zero) return;

    final cannonPx = Offset(_cannonFrac.dx * _canvasSize.width, _cannonFrac.dy * _canvasSize.height);

    // Vector FROM drag current TO drag start gives launch direction (pull-back slingshot feel)
    final dx = _dragStart!.dx - _dragCurrent!.dx;
    final dy = _dragStart!.dy - _dragCurrent!.dy;
    final dragLen = sqrt(dx * dx + dy * dy).clamp(1.0, 200.0);
    final rawSpeed = (dragLen * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    final nx = dx / dragLen;
    final ny = dy / dragLen;

    setState(() {
      _projectile = _Projectile(
        x: cannonPx.dx, y: cannonPx.dy,
        vx: nx * rawSpeed, vy: ny * rawSpeed,
      );
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  // ── trajectory preview ─────────────────────────────────────────────────────
  List<Offset> _buildPreview(Size size) {
    if (!_isDragging) return [];
    final cannonPx = Offset(_cannonFrac.dx * size.width, _cannonFrac.dy * size.height);
    final dx = _dragStart!.dx - _dragCurrent!.dx;
    final dy = _dragStart!.dy - _dragCurrent!.dy;
    final dragLen = sqrt(dx * dx + dy * dy).clamp(1.0, 200.0);
    final rawSpeed = (dragLen * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
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
        final distSq = (ddx * ddx + ddy * ddy).clamp(100.0, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        vx += (ddx / dist) * force * _kPreviewDt;
        vy += (ddy / dist) * force * _kPreviewDt;
      }
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      if (px < -80 || px > size.width + 80 || py < -80 || py > size.height + 80) break;
    }
    return pts;
  }

  // ── particles ──────────────────────────────────────────────────────────────
  void _spawnParticles(double fx, double fy, Color c, int n, {bool normalized = false}) {
    final cx = normalized ? fx * _canvasSize.width : fx;
    final cy = normalized ? fy * _canvasSize.height : fy;
    for (int i = 0; i < n; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 40 + _rng.nextDouble() * 120;
      _particles.add(_JuiceParticle(
        x: cx / (_canvasSize.width.clamp(1, double.infinity)),
        y: cy / (_canvasSize.height.clamp(1, double.infinity)),
        vx: cos(angle) * speed / _canvasSize.width,
        vy: sin(angle) * speed / _canvasSize.height,
        life: 0.6 + _rng.nextDouble() * 0.4,
        color: c,
        radius: 2.5 + _rng.nextDouble() * 2,
      ));
    }
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
      _particles.clear();
      _dragStart = null;
      _dragCurrent = null;
      _targetDrift = 0.0;
      _targetDriftDir = 1.0;
    });
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanStart: (d) {
          if (_waitingToStart) { _startGame(); return; }
          _onDragStart(d);
        },
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onTapDown: (d) {
          if (_waitingToStart) _startGame();
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _CannonGravityPainter(
              cannonFrac: _cannonFrac,
              level: _currentLevel,
              targetPos: _targetPx(_canvasSize),
              targetRadius: _targetRadius,
              projectile: _projectile,
              particles: _particles,
              preview: _buildPreview(_canvasSize),
              dragStart: _dragStart,
              dragCurrent: _dragCurrent,
              canvasSize: _canvasSize,
            ),
            child: Stack(children: [
              // ── HUD ──────────────────────────────────────────────────────
              if (!_waitingToStart && !_gameOver)
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shot pips
                      Row(children: List.generate(_kShotsPerLevel, (i) => Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(Icons.circle, size: 11,
                          color: i < _shotsLeft ? Colors.cyanAccent : Colors.white12),
                      ))),
                      // Timer
                      Text(
                        '${_timeLeft.ceil()}s',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 16,
                          color: _timeLeft < 10 ? Colors.redAccent : Colors.white70,
                          fontWeight: _timeLeft < 10 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      // Score + level
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('$_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white70)),
                        Text('Lv ${_level + 1}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white30)),
                      ]),
                    ],
                  ),
                ),

              // ── Start screen ─────────────────────────────────────────────
              if (_waitingToStart)
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Orbit Catch', style: TextStyle(fontFamily: 'Avenir', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const SizedBox(height: 14),
                  const Text('Drag from the cannon to aim.\nGravity will bend your shot.\nHit the target to level up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
                  const SizedBox(height: 20),
                  if (_highScore > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.amberAccent)),
                    ),
                  const Text('Tap or drag to Play', style: TextStyle(fontFamily: 'Avenir', fontSize: 17, color: Colors.white70)),
                ])),

              // ── Game over screen ──────────────────────────────────────────
              if (_gameOver)
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Time\'s Up!  $_score pts',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_newBest)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('NEW BEST!', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    ),
                  const SizedBox(height: 8),
                  Text('Best: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _restart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                      child: const Text('Play Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                    ),
                  ),
                ])),
            ]),
          ),
        ),
      );
    });
  }
}

class _CannonGravityPainter extends CustomPainter {
  final Offset cannonFrac;
  final _CannonLevel level;
  final Offset targetPos; // already in canvas px
  final double targetRadius;
  final _Projectile? projectile;
  final List<_JuiceParticle> particles;
  final List<Offset> preview;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Size canvasSize;

  _CannonGravityPainter({
    required this.cannonFrac,
    required this.level,
    required this.targetPos,
    required this.targetRadius,
    required this.projectile,
    required this.particles,
    required this.preview,
    required this.dragStart,
    required this.dragCurrent,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background stars (static seed) ────────────────────────────────────
    final starRng = Random(42);
    for (int i = 0; i < 90; i++) {
      final alpha = 0.15 + starRng.nextDouble() * 0.35;
      canvas.drawCircle(
        Offset(starRng.nextDouble() * size.width, starRng.nextDouble() * size.height),
        0.5 + starRng.nextDouble() * 1.2,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }

    final cannonPx = Offset(cannonFrac.dx * size.width, cannonFrac.dy * size.height);

    // ── Gravity bodies ─────────────────────────────────────────────────────
    for (final body in level.bodies) {
      final bx = body.pos.dx * size.width;
      final by = body.pos.dy * size.height;
      final bPos = Offset(bx, by);

      // Influence rings
      for (int r = 4; r >= 1; r--) {
        canvas.drawCircle(bPos, body.radius + r * 18.0,
          Paint()
            ..color = body.color.withValues(alpha: 0.025 * r)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
      }
      // Glow
      canvas.drawCircle(bPos, body.radius + 6,
        Paint()..color = body.color.withValues(alpha: 0.18));
      // Body
      canvas.drawCircle(bPos, body.radius,
        Paint()..color = body.color);
      // Highlight
      canvas.drawCircle(Offset(bx - body.radius * 0.3, by - body.radius * 0.3), body.radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.22));
    }

    // ── Target ─────────────────────────────────────────────────────────────
    // Outer pulse ring
    canvas.drawCircle(targetPos, targetRadius + 8,
      Paint()..color = Colors.amberAccent.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Target zone
    canvas.drawCircle(targetPos, targetRadius,
      Paint()..color = Colors.amberAccent.withValues(alpha: 0.25));
    canvas.drawCircle(targetPos, targetRadius,
      Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);
    // Crosshair
    final ch = Paint()..color = Colors.amberAccent.withValues(alpha: 0.6)..strokeWidth = 1.2;
    canvas.drawLine(Offset(targetPos.dx - 10, targetPos.dy), Offset(targetPos.dx + 10, targetPos.dy), ch);
    canvas.drawLine(Offset(targetPos.dx, targetPos.dy - 10), Offset(targetPos.dx, targetPos.dy + 10), ch);

    // ── Cannon ─────────────────────────────────────────────────────────────
    // Determine barrel angle from drag or default upward-right
    double barrelAngle = -pi / 4;
    if (dragStart != null && dragCurrent != null) {
      final ddx = dragStart!.dx - dragCurrent!.dx;
      final ddy = dragStart!.dy - dragCurrent!.dy;
      barrelAngle = atan2(ddy, ddx);
    } else if (projectile != null) {
      barrelAngle = atan2(projectile!.vy, projectile!.vx);
    }
    final barrelLen = 28.0;
    final barrelEnd = Offset(
      cannonPx.dx + cos(barrelAngle) * barrelLen,
      cannonPx.dy + sin(barrelAngle) * barrelLen,
    );
    // Base
    canvas.drawCircle(cannonPx, 14, Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(cannonPx, 10, Paint()..color = const Color(0xFF546E7A));
    // Barrel
    canvas.drawLine(cannonPx, barrelEnd,
      Paint()..color = const Color(0xFF90A4AE)..strokeWidth = 8..strokeCap = StrokeCap.round);
    canvas.drawLine(cannonPx, barrelEnd,
      Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = 4..strokeCap = StrokeCap.round);

    // ── Drag aim line ──────────────────────────────────────────────────────
    if (dragStart != null && dragCurrent != null) {
      final ddx = dragStart!.dx - dragCurrent!.dx;
      final ddy = dragStart!.dy - dragCurrent!.dy;
      final dragLen = sqrt(ddx * ddx + ddy * ddy).clamp(1.0, 200.0);
      final powerFrac = (dragLen / 200.0).clamp(0.0, 1.0);
      final aimColor = Color.lerp(Colors.cyanAccent, Colors.orangeAccent, powerFrac)!;

      // Drag line from start to current
      canvas.drawLine(dragStart!, dragCurrent!,
        Paint()..color = aimColor.withValues(alpha: 0.35)..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // Power bar arc
      final arcRect = Rect.fromCircle(center: cannonPx, radius: 22);
      canvas.drawArc(arcRect, -pi, pi * powerFrac, false,
        Paint()..color = aimColor.withValues(alpha: 0.7)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    // ── Trajectory preview dots ────────────────────────────────────────────
    if (preview.isNotEmpty) {
      for (int i = 0; i < preview.length; i++) {
        final alpha = (1.0 - i / preview.length) * 0.55;
        final r = 2.5 - (i / preview.length) * 1.5;
        canvas.drawCircle(preview[i], r.clamp(0.5, 2.5),
          Paint()..color = Colors.cyanAccent.withValues(alpha: alpha));
      }
    }

    // ── Projectile trail ───────────────────────────────────────────────────
    if (projectile != null) {
      final trail = projectile!.trail;
      for (int i = 1; i < trail.length; i++) {
        final alpha = (i / trail.length) * 0.6;
        canvas.drawLine(trail[i - 1], trail[i],
          Paint()..color = Colors.cyanAccent.withValues(alpha: alpha)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      }

      // Projectile itself
      if (projectile!.alive) {
        canvas.drawCircle(Offset(projectile!.x, projectile!.y), _kProjectileRadius + 3,
          Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3));
        canvas.drawCircle(Offset(projectile!.x, projectile!.y), _kProjectileRadius,
          Paint()..color = Colors.cyanAccent);
        canvas.drawCircle(Offset(projectile!.x, projectile!.y), _kProjectileRadius * 0.45,
          Paint()..color = Colors.white.withValues(alpha: 0.8));
      }
    }

    // ── Particles ──────────────────────────────────────────────────────────
    for (final p in particles) {
      if (p.life > 0 && size.width > 0 && size.height > 0) {
        final px2 = p.x * size.width;
        final py2 = p.y * size.height;
        canvas.drawCircle(
          Offset(px2, py2), p.radius,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CannonGravityPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. SolarSortGame — "Solar Architect" (Tower of Hanoi with Planets)
// Move all planets from the leftmost tower to the rightmost tower.
// Tap a tower to pick up its top planet, tap another to place it.
// A larger planet can never be placed on a smaller one.
// Progressive stages: each win adds a tower or a planet, alternating.
// ═══════════════════════════════════════════════════════════════════════════════

// ── SolarSortGame — "Orbital Mechanic" ────────────────────────────────────────
// REPLACED: spiral-drawing game. Draw a continuous spiral; score = total
// full revolutions (2π accumulated angle) across attempts. 60-second session.
// ──────────────────────────────────────────────────────────────────────────────

// ── Feel constants ────────────────────────────────────────────────────────────
// Minimum number of points already in the path before intersection checks
// start (skip the first N segments — they can't cross anything meaningful yet).
const int _kSpiralSkipHeadSegments = 6;

// Segment-segment intersection tolerance: two segments are only flagged as
// crossing when the crossing parameter t/u are strictly inside (tol, 1-tol).
// Keeping this small avoids false positives from adjacent/near-touching segs
// while still catching genuine crossings.
const double _kIntersectTol = 0.01;

// Points awarded per completed revolution on attempt 1.
// Each subsequent attempt reduces the reward by this factor (escalation).
const int _kBasePointsPerRev = 100;
const double _kAttemptDecayFactor = 0.85;

// ─────────────────────────────────────────────────────────────────────────────

class SolarSortGame extends StatefulWidget {
  const SolarSortGame({Key? key}) : super(key: key);
  @override
  State<SolarSortGame> createState() => _SolarSortGameState();
}

class _SpiralPoint {
  final double x, y;
  const _SpiralPoint(this.x, this.y);
  Offset get offset => Offset(x, y);
}

class _SolarSortGameState extends State<SolarSortGame>
    with SingleTickerProviderStateMixin {
  // ── game state ──────────────────────────────────────────────────────────────
  static const int _gameDuration = 60; // seconds

  bool _running = false;
  bool _gameOver = false;
  int _secondsLeft = _gameDuration;
  int _totalScore = 0;
  int _attemptScore = 0;   // score for current live attempt
  int _attemptNumber = 0;  // 1-based; increments on each break/restart
  double _bestRevs = 0;    // best single-attempt revolution count (display)

  // Current drawn path for this attempt.
  final List<_SpiralPoint> _path = [];

  // Accumulated angle (radians) around the running centroid — used for
  // revolution counting.  Resets to 0 on each new attempt.
  double _accumulatedAngle = 0;

  // Previous angle relative to current centroid, needed to compute delta.
  double? _prevAngle;

  // Running centroid of the drawn path (updated incrementally).
  double _centroidX = 0;
  double _centroidY = 0;

  // Flash-break animation state.
  bool _flashBreak = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Timer handle.
  DateTime? _startTime;
  bool _timerActive = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── timer ───────────────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _running = true;
      _gameOver = false;
      _secondsLeft = _gameDuration;
      _totalScore = 0;
      _attemptScore = 0;
      _attemptNumber = 0;
      _bestRevs = 0;
      _timerActive = true;
      _startTime = DateTime.now();
    });
    _resetAttempt(bankScore: false);
    _tick();
  }

  void _tick() {
    if (!mounted || !_timerActive) return;
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    final left = _gameDuration - elapsed;
    if (left <= 0) {
      setState(() {
        _secondsLeft = 0;
        _running = false;
        _gameOver = true;
        _timerActive = false;
        // Bank any partial score from current attempt.
        _bankCurrentAttempt();
      });
      return;
    }
    setState(() => _secondsLeft = left);
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  // ── attempt helpers ─────────────────────────────────────────────────────────

  /// How many full revolutions (integer) the current path has completed.
  int get _currentRevolutions => (_accumulatedAngle.abs() / (2 * pi)).floor();

  /// Score value for the current attempt's completed revolutions.
  int _scoreForRevs(int revs) {
    if (revs <= 0) return 0;
    final multiplier = pow(_kAttemptDecayFactor, _attemptNumber - 1).toDouble();
    return (revs * _kBasePointsPerRev * multiplier).round();
  }

  void _bankCurrentAttempt() {
    final revs = _currentRevolutions;
    final score = _scoreForRevs(revs);
    _totalScore += score;
    if (revs > _bestRevs) _bestRevs = revs.toDouble();
  }

  void _resetAttempt({required bool bankScore}) {
    if (bankScore) _bankCurrentAttempt();
    _attemptNumber++;
    _path.clear();
    _accumulatedAngle = 0;
    _prevAngle = null;
    _centroidX = 0;
    _centroidY = 0;
    _attemptScore = 0;
  }

  // ── drawing logic ────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (!_running) return;
    _resetAttempt(bankScore: false);
    final pt = d.localPosition;
    _path.add(_SpiralPoint(pt.dx, pt.dy));
    _centroidX = pt.dx;
    _centroidY = pt.dy;
    _prevAngle = null;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_running) return;
    final pt = d.localPosition;
    final newPt = _SpiralPoint(pt.dx, pt.dy);

    // ── check self-intersection BEFORE committing the new point ──────────────
    if (_path.length >= _kSpiralSkipHeadSegments + 1) {
      if (_checkIntersection(newPt)) {
        // Break! Flash and restart this attempt.
        _triggerBreak();
        return;
      }
    }

    // Commit point.
    _path.add(newPt);

    // ── update running centroid ───────────────────────────────────────────────
    final n = _path.length.toDouble();
    _centroidX = (_centroidX * (n - 1) + pt.dx) / n;
    _centroidY = (_centroidY * (n - 1) + pt.dy) / n;

    // ── accumulate angle for revolution counting ──────────────────────────────
    final dx = pt.dx - _centroidX;
    final dy = pt.dy - _centroidY;
    final ang = atan2(dy, dx);
    if (_prevAngle != null) {
      double delta = ang - _prevAngle!;
      // Wrap delta into (-π, π] — handles the ±π discontinuity.
      if (delta > pi) delta -= 2 * pi;
      if (delta <= -pi) delta += 2 * pi;
      _accumulatedAngle += delta;
    }
    _prevAngle = ang;

    // Update live attempt score display.
    setState(() {
      _attemptScore = _scoreForRevs(_currentRevolutions);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    // Finger lifted: bank what was drawn, start fresh on next touch.
    if (!_running) return;
    setState(() { _bankCurrentAttempt(); _resetAttempt(bankScore: false); });
  }

  void _triggerBreak() {
    setState(() {
      _flashBreak = true;
      _bankCurrentAttempt();
      _resetAttempt(bankScore: false);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _flashBreak = false);
    });
  }

  // ── self-intersection ─────────────────────────────────────────────────────
  //
  // Test the prospective new segment (last path point → newPt) against all
  // earlier non-adjacent segments.  Uses standard parametric segment-segment
  // intersection with tolerance guards to avoid false positives.
  //
  // Two segments AB and CD intersect when:
  //   t = ((C-A)×(D-C)) / ((B-A)×(D-C))
  //   u = ((C-A)×(B-A)) / ((B-A)×(D-C))
  // and both t, u ∈ (tol, 1-tol).
  //
  // We skip the last _kSpiralSkipHeadSegments segments (adjacent + near
  // neighbours) because a tight-but-valid spiral will always come close to
  // itself; only a genuine crossing (both params strictly interior) fires.
  bool _checkIntersection(_SpiralPoint newPt) {
    if (_path.length < 2) return false;
    final ax = _path[_path.length - 1].x;
    final ay = _path[_path.length - 1].y;
    final bx = newPt.x;
    final by = newPt.y;

    // Check against all segments [i, i+1] except the last
    // _kSpiralSkipHeadSegments ones (including the one we're extending).
    final lastSafe = _path.length - 1 - _kSpiralSkipHeadSegments;
    if (lastSafe < 1) return false;

    for (int i = 0; i < lastSafe - 1; i++) {
      final cx2 = _path[i].x;
      final cy2 = _path[i].y;
      final dx2 = _path[i + 1].x;
      final dy2 = _path[i + 1].y;

      // (B-A)
      final rX = bx - ax, rY = by - ay;
      // (D-C)
      final sX = dx2 - cx2, sY = dy2 - cy2;

      final denom = rX * sY - rY * sX; // cross(r, s)
      if (denom.abs() < 1e-10) continue; // parallel

      // (C-A)
      final qX = cx2 - ax, qY = cy2 - ay;

      final t = (qX * sY - qY * sX) / denom;
      final u = (qX * rY - qY * rX) / denom;

      if (t > _kIntersectTol && t < 1.0 - _kIntersectTol &&
          u > _kIntersectTol && u < 1.0 - _kIntersectTol) {
        return true; // genuine crossing
      }
    }
    return false;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();
    if (!_running) return _buildStart();
    return _buildGame();
  }

  Widget _buildStart() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Orbital Mechanic',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 26,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 16),
              const Text(
                'Draw a continuous spiral with your finger.\n'
                'Score points for every full loop you complete.\n\n'
                'Cross your own path and it resets — '
                'your best loops are banked.\n\n'
                '60 seconds. Go.',
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

  Widget _buildGame() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: _flashBreak ? const Color(0x33FF4444) : const Color(0xFF050515),
        child: Stack(children: [
          // Canvas for the spiral.
          Positioned.fill(
            child: CustomPaint(
              painter: _SpiralPainter(
                points: List.unmodifiable(_path),
                revolutions: _currentRevolutions,
                flashBreak: _flashBreak,
                pulseValue: _pulseAnim.value,
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
                    // Timer
                    _HudChip(
                      label: 'TIME',
                      value: '$_secondsLeft s',
                      urgent: _secondsLeft <= 10,
                    ),
                    // Current attempt loops
                    _HudChip(
                      label: 'LOOPS',
                      value: '$_currentRevolutions',
                      urgent: false,
                    ),
                    // Total score
                    _HudChip(
                      label: 'SCORE',
                      value: '${_totalScore + _attemptScore}',
                      urgent: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Break flash label
          if (_flashBreak)
            Center(
              child: Text('CROSSED!',
                style: TextStyle(
                  fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  letterSpacing: 3,
                )),
            ),

          // Instruction hint when no path yet
          if (_path.isEmpty)
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

  Widget _buildGameOver() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Time\'s Up!',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 28,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 20),
              _ScoreLine(label: 'Final Score', value: '$_totalScore'),
              const SizedBox(height: 6),
              _ScoreLine(label: 'Best Attempt', value: '${_bestRevs.floor()} loops'),
              const SizedBox(height: 6),
              _ScoreLine(label: 'Attempts', value: '$_attemptNumber'),
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

// ── Small HUD chip ─────────────────────────────────────────────────────────
class _HudChip extends StatelessWidget {
  final String label;
  final String value;
  final bool urgent;
  const _HudChip({required this.label, required this.value, required this.urgent});

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

// ── Score line for game-over screen ────────────────────────────────────────
class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
      Text(value, style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ]);
  }
}

// ── Spiral painter ─────────────────────────────────────────────────────────
class _SpiralPainter extends CustomPainter {
  final List<_SpiralPoint> points;
  final int revolutions;
  final bool flashBreak;
  final double pulseValue;

  const _SpiralPainter({
    required this.points,
    required this.revolutions,
    required this.flashBreak,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Color cycles gently through revolutions for visual feedback.
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
    path.moveTo(points[0].x, points[0].y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw a small dot at the current tip.
    if (points.isNotEmpty) {
      canvas.drawCircle(
        points.last.offset, 4,
        Paint()..color = strokeColor.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter old) =>
      old.points.length != points.length ||
      old.revolutions != revolutions ||
      old.flashBreak != flashBreak ||
      old.pulseValue != pulseValue;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. GalaxyCollectorGame — "Star Deflector"
//    Draw circles around incoming threats: match the required RADIUS and
//    DIRECTION (CW / CCW) to deflect them. Wrong answer = penalty.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Feel constants ─────────────────────────────────────────────────────────
// Required circle radius range (fraction of screen short-side, normalised 0-1)
const double _kMinReqRadius = 0.08; // smallest ring the player must draw
const double _kMaxReqRadius = 0.22; // largest ring at game start

// Tolerance: how close the player's radius must be (fraction of req radius).
// Starts loose, tightens with wave. Clamps to a floor so it stays humanly possible.
const double _kToleranceBase = 0.45;   // ±45 % at wave 1
const double _kToleranceFloor = 0.15;  // ±15 % at high waves (tightest)
const double _kToleranceStep = 0.04;   // tolerance shrinks by this per wave

// Collision timer: how long (seconds) a threat lives before it "hits"
const double _kBaseCollisionTime = 4.5; // wave 1
const double _kMinCollisionTime  = 1.6; // absolute minimum at extreme waves

// Spawn: average gap between new threats (seconds).
const double _kBaseSpawnInterval = 2.8; // wave 1
const double _kMinSpawnInterval  = 0.5; // absolute floor at extreme waves
const double _kSpawnAccelPerWave = 0.25; // seconds removed per wave

// Points
const int _kPointsCorrect    = 10;  // base points for a valid deflection
const int _kBonusPerWave     = 3;   // extra pts per current wave for correct
const int _kPenaltyWrongDir  = -5;  // drew correct size but wrong direction
const int _kPenaltyWrongSize = -3;  // drew correct direction but wrong size
const int _kPenaltyBothWrong = -2;  // both wrong (gesture counted but useless)
const int _kPenaltyCollision = -8;  // threat hit impact zone (never deflected)

// Gesture: minimum number of sampled points for a gesture to be evaluated
const int _kMinGesturePoints = 12;

// Minimum arc: gesture must sweep at least this many radians total (unsigned)
// to be considered a circular gesture vs a straight swipe.
const double _kMinGestureArc = 3.5; // ~200 degrees
// ────────────────────────────────────────────────────────────────────────────

class GalaxyCollectorGame extends StatefulWidget {
  const GalaxyCollectorGame({Key? key}) : super(key: key);
  @override
  State<GalaxyCollectorGame> createState() => _GalaxyCollectorGameState();
}

enum _GCPhase { start, playing, gameOver }
enum _GCDir { cw, ccw }

// A threat on a collision course with the centre
class _GCThreat {
  /// Normalised position (0-1 coords)
  double x, y;
  /// Normalised velocity (per second)
  double vx, vy;
  /// Required circle radius (normalised 0-1 of screen short-side)
  double reqRadius;
  /// Required draw direction
  _GCDir reqDir;
  /// Time remaining before impact
  double timeLeft;
  double maxTime;
  /// Scale-in animation [0,1]
  double scale;
  /// Deflection result flash
  double flashGood, flashBad;
  bool deflected;
  Color color;

  _GCThreat({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.reqRadius, required this.reqDir,
    required this.timeLeft, required this.color,
  }) : maxTime = timeLeft, scale = 0.0,
       flashGood = 0.0, flashBad = 0.0, deflected = false;
}

// Stores a completed gesture stroke with its analysis result
class _GCGesture {
  final Offset centroid;
  final double radius;   // normalised
  final _GCDir dir;
  double life;           // display lifetime in seconds
  final bool good;

  _GCGesture({required this.centroid, required this.radius,
    required this.dir, required this.good}) : life = 0.5;
}

// ─── Gesture accumulator (raw points in normalised coords) ──────────────────
class _GCStroke {
  final List<Offset> pts = [];
  bool active = false;

  void start(Offset p) { pts.clear(); pts.add(p); active = true; }
  void add(Offset p)   { if (active) pts.add(p); }
  void end()           { active = false; }
}

class _GalaxyCollectorGameState extends State<GalaxyCollectorGame>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  final Random _rng = Random();
  _GCPhase _phase = _GCPhase.start;

  // Gameplay state
  int _score = 0, _wave = 1, _highScore = 0;
  int _lives = 3, _streak = 0, _bestStreak = 0;
  double _spawnTimer = 0.0;
  double _waveTimer  = 0.0;       // time in current wave (seconds)
  double _flashGood  = 0.0;       // full-screen green flash
  double _flashBad   = 0.0;       // full-screen red flash
  String? _toastText;
  double _toastTimer = 0.0;
  DateTime? _startTime;

  final List<_GCThreat>  _threats  = [];
  final List<_JuiceParticle> _particles = [];
  final List<_GCGesture> _gestures = [];

  // Active stroke being drawn
  final _GCStroke _stroke = _GCStroke();
  // Last resolved stroke shown on-screen until next gesture starts
  List<Offset> _lastStrokePts = [];

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
      _score = 0; _wave = 1; _lives = 3; _streak = 0; _bestStreak = 0;
      _spawnTimer = 0.0; _waveTimer = 0.0;
      _flashGood = 0.0; _flashBad = 0.0;
      _toastText = null; _toastTimer = 0.0;
      _threats.clear(); _particles.clear(); _gestures.clear();
      _lastStrokePts = [];
      _startTime = DateTime.now();
    });
  }

  void _endGame() { _saveHighScore(); setState(() { _phase = _GCPhase.gameOver; }); }

  // ── Per-wave derived constants ───────────────────────────────────────────
  double get _spawnInterval => (_kBaseSpawnInterval - (_wave - 1) * _kSpawnAccelPerWave).clamp(_kMinSpawnInterval, _kBaseSpawnInterval);
  double get _collisionTime => (_kBaseCollisionTime - (_wave - 1) * 0.2).clamp(_kMinCollisionTime, _kBaseCollisionTime);
  double get _tolerance     => (_kToleranceBase - (_wave - 1) * _kToleranceStep).clamp(_kToleranceFloor, _kToleranceBase);
  int    get _maxThreats    => 1 + _wave ~/ 2;  // 1 at wave1, grows by 1 every 2 waves

  // ── Game loop ────────────────────────────────────────────────────────────
  void _tick() {
    if (_phase != _GCPhase.playing) return;
    const dt = 1 / 60.0;
    setState(() {
      _waveTimer += dt;
      // Advance wave every 20 seconds
      if (_waveTimer >= 20.0) { _waveTimer = 0.0; _wave++; _toast('Wave $_wave!'); }

      // Spawn threats
      _spawnTimer -= dt;
      if (_spawnTimer <= 0.0 && _threats.length < _maxThreats) {
        _spawnTimer = _spawnInterval * (0.7 + _rng.nextDouble() * 0.6);
        _spawnThreat();
      }

      // Update threats
      for (final t in _threats) {
        if (t.deflected) { t.flashGood = (t.flashGood - dt * 2).clamp(0.0, 1.0); continue; }
        t.scale = (t.scale + dt / 0.35).clamp(0.0, 1.0);
        t.x += t.vx * dt;
        t.y += t.vy * dt;
        t.timeLeft -= dt;
        if (t.flashBad > 0) t.flashBad = (t.flashBad - dt * 3).clamp(0.0, 1.0);
        if (t.flashGood > 0) t.flashGood = (t.flashGood - dt * 2).clamp(0.0, 1.0);

        // Check if threat reached the danger zone (within 0.08 of centre)
        final dx = t.x - 0.5, dy = t.y - 0.5;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 0.08 || t.timeLeft <= 0.0) {
          // Collision!
          _score = max(0, _score + _kPenaltyCollision);
          _lives--;
          _flashBad = 0.7;
          _streak = 0;
          _spawnBurst(t.x, t.y, Colors.redAccent, 14);
          t.deflected = true; // reuse flag to mark for removal
          _toast('Miss!');
          if (_lives <= 0) { _endGame(); return; }
        }
      }
      _threats.removeWhere((t) => t.deflected && t.flashGood <= 0.01);

      // Particles & gestures
      for (final p in _particles) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; }
      _particles.removeWhere((p) => p.life <= 0);
      for (final g in _gestures) { g.life -= dt; }
      _gestures.removeWhere((g) => g.life <= 0);

      if (_flashGood > 0) _flashGood = (_flashGood - dt * 2.5).clamp(0.0, 1.0);
      if (_flashBad  > 0) _flashBad  = (_flashBad  - dt * 2.5).clamp(0.0, 1.0);
      if (_toastTimer > 0) { _toastTimer -= dt; if (_toastTimer <= 0) _toastText = null; }
    });
  }

  void _spawnThreat() {
    // Pick an edge to spawn from
    final edge = _rng.nextInt(4);
    double sx, sy;
    switch (edge) {
      case 0: sx = _rng.nextDouble(); sy = -0.06; break;
      case 1: sx = 1.06; sy = _rng.nextDouble(); break;
      case 2: sx = _rng.nextDouble(); sy = 1.06; break;
      default: sx = -0.06; sy = _rng.nextDouble();
    }
    // Aim roughly at centre with some scatter
    final scatter = (_rng.nextDouble() - 0.5) * 0.25;
    double tx = 0.5 + scatter, ty = 0.5 + scatter;
    double dx = tx - sx, dy = ty - sy;
    final dist = sqrt(dx * dx + dy * dy).clamp(0.01, 2.0);
    final colTime = _collisionTime * (0.85 + _rng.nextDouble() * 0.3);
    final spd = dist / colTime;
    final vx = dx / dist * spd, vy = dy / dist * spd;

    // Required radius: widen range a little at higher waves
    final rLo = _kMinReqRadius;
    final rHi = _kMaxReqRadius - (_wave - 1) * 0.005; // range narrows very slightly
    final reqR = rLo + _rng.nextDouble() * (rHi - rLo).clamp(0.0, rHi - rLo);
    final reqDir = _rng.nextBool() ? _GCDir.cw : _GCDir.ccw;

    // Colour by direction
    final col = reqDir == _GCDir.cw
        ? const Color(0xFF64B5F6)   // blue for CW
        : const Color(0xFFFFB74D);  // amber for CCW

    _threats.add(_GCThreat(
      x: sx, y: sy, vx: vx, vy: vy,
      reqRadius: reqR, reqDir: reqDir,
      timeLeft: colTime, color: col,
    ));
  }

  // ── Gesture evaluation ───────────────────────────────────────────────────

  /// Analyse the stroke and attempt to deflect a nearby threat.
  void _evaluateStroke(Size screenSize) {
    final pts = _stroke.pts;
    if (pts.length < _kMinGesturePoints) return;

    // Compute centroid in normalised coords
    double sumX = 0, sumY = 0;
    for (final p in pts) { sumX += p.dx; sumY += p.dy; }
    final cx = sumX / pts.length;
    final cy = sumY / pts.length;
    final centroidNorm = Offset(cx, cy);

    // Mean radius (normalised by screen short-side so it matches reqRadius units)
    final shortSide = min(screenSize.width, screenSize.height);
    double sumR = 0;
    for (final p in pts) {
      sumR += sqrt((p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy));
    }
    final meanRadNorm = (sumR / pts.length) / shortSide;

    // Rotation direction via accumulated signed angle (shoelace-style).
    // For each consecutive triplet of points compute the signed cross product
    // of (B-A) × (C-B); summing these gives the winding sense.
    double signedArea = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      signedArea += (pts[i].dx * pts[i + 1].dy) - (pts[i + 1].dx * pts[i].dy);
    }
    final detectedDir = signedArea < 0 ? _GCDir.cw : _GCDir.ccw;
    // (In Flutter screen coords Y-down: CW rotation gives negative shoelace area)

    // Minimum arc check — ensure the stroke actually sweeps enough angle
    double totalArc = 0.0;
    for (int i = 1; i < pts.length - 1; i++) {
      final ax = pts[i].dx - cx,     ay = pts[i].dy - cy;
      final bx = pts[i+1].dx - cx, by = pts[i+1].dy - cy;
      final rA = sqrt(ax*ax + ay*ay).clamp(1e-9, double.infinity);
      final rB = sqrt(bx*bx + by*by).clamp(1e-9, double.infinity);
      final cosA = ((ax*bx + ay*by) / (rA * rB)).clamp(-1.0, 1.0);
      totalArc += acos(cosA);
    }
    if (totalArc < _kMinGestureArc) return; // too short — ignore

    // Find the closest undeflected threat within a generous spatial window
    _GCThreat? best;
    double bestDist = double.infinity;
    for (final t in _threats) {
      if (t.deflected) continue;
      final d = sqrt((t.x - cx) * (t.x - cx) + (t.y - cy) * (t.y - cy));
      if (d < bestDist) { bestDist = d; best = t; }
    }
    if (best == null || bestDist > 0.45) return; // no plausible target

    // Evaluate match
    final tol = _tolerance;
    final sizeOk = (meanRadNorm - best.reqRadius).abs() <= best.reqRadius * tol;
    final dirOk  = detectedDir == best.reqDir;
    final good   = sizeOk && dirOk;

    if (good) {
      final pts2 = _kPointsCorrect + _kBonusPerWave * _wave;
      _score += pts2;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      best.deflected = true;
      best.flashGood = 1.0;
      _flashGood = 0.5;
      _spawnBurst(best.x, best.y, best.color, 12);
      final extra = _streak >= 3 ? ' ${_streak}x streak!' : '';
      _toast('+$pts2$extra');
    } else {
      int pen;
      if (sizeOk && !dirOk) { pen = _kPenaltyWrongDir; _toast('Wrong direction!'); }
      else if (!sizeOk && dirOk) { pen = _kPenaltyWrongSize; _toast('Wrong size!'); }
      else { pen = _kPenaltyBothWrong; _toast('Miss!'); }
      _score = max(0, _score + pen);
      _streak = 0;
      best.flashBad = 1.0;
      _flashBad = 0.4;
    }

    _gestures.add(_GCGesture(
      centroid: centroidNorm,
      radius: meanRadNorm,
      dir: detectedDir,
      good: good,
    ));
  }

  void _toast(String t) { _toastText = t; _toastTimer = 1.4; }
  void _spawnBurst(double x, double y, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: x, y: y,
        vx: (_rng.nextDouble() - 0.5) * 0.5,
        vy: (_rng.nextDouble() - 0.5) * 0.5,
        life: 0.4 + _rng.nextDouble() * 0.35,
        color: c, radius: 2.5,
      ));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_phase == _GCPhase.start)   return _buildStart();
    if (_phase == _GCPhase.gameOver) return _buildOver();
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth, h = constraints.maxHeight;
      final shortSide = min(w, h);
      return GestureDetector(
        onPanStart: (d) {
          final norm = Offset(d.localPosition.dx / w, d.localPosition.dy / h);
          setState(() { _stroke.start(norm); _lastStrokePts = []; });
        },
        onPanUpdate: (d) {
          final norm = Offset(d.localPosition.dx / w, d.localPosition.dy / h);
          setState(() { _stroke.add(norm); });
        },
        onPanEnd: (_) {
          setState(() {
            _stroke.end();
            _lastStrokePts = List.unmodifiable(_stroke.pts);
            _evaluateStroke(Size(w, h));
          });
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _StarDeflectorPainter(
              threats: _threats,
              particles: _particles,
              gestures: _gestures,
              strokePts: _stroke.active ? _stroke.pts : _lastStrokePts,
              shortSide: shortSide,
              flashGood: _flashGood,
              flashBad: _flashBad,
            ),
            child: Stack(children: [
              // HUD
              Positioned(top: 8, left: 12, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    Text('Wave $_wave', style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white54)),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      'Draw circles: match SIZE & DIRECTION',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 9, color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      ...List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(Icons.favorite, size: 14,
                          color: i < _lives ? const Color(0xFFFF5252) : Colors.white12),
                      )),
                    ]),
                  ]),
                  if (_streak >= 3) Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Streak: $_streak', style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.cyanAccent)),
                  ),
                ]),
              )),
              // Toast
              if (_toastText != null) Positioned(
                top: 90, left: 0, right: 0,
                child: Center(child: Text(
                  _toastText!,
                  style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold,
                    color: (_toastText!.startsWith('+') ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: (_toastTimer / 1.4).clamp(0.0, 1.0)),
                  ),
                )),
              ),
              // Direction legend bottom
              Positioned(bottom: 12, left: 0, right: 0, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DirLegend(color: const Color(0xFF64B5F6), label: 'CW', clockwise: true),
                  const SizedBox(width: 24),
                  _DirLegend(color: const Color(0xFFFFB74D), label: 'CCW', clockwise: false),
                ],
              )),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildStart() {
    return GestureDetector(onTap: _startGame, child: Container(
      color: Colors.black,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Star Deflector', style: TextStyle(fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text(
          'Stars are on a collision course!\nDraw a circle around each one:\nmatch its SIZE and DIRECTION arrow.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _DirLegend(color: const Color(0xFF64B5F6), label: 'BLUE = clockwise', clockwise: true),
          const SizedBox(width: 20),
          _DirLegend(color: const Color(0xFFFFB74D), label: 'AMBER = counter-CW', clockwise: false),
        ]),
        const SizedBox(height: 20),
        if (_highScore > 0) Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.amberAccent)),
        ),
        const Text('Tap to Play', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.cyanAccent)),
      ])),
    ));
  }

  Widget _buildOver() {
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    final mins = elapsed.inMinutes, secs = elapsed.inSeconds % 60;
    return GestureDetector(onTap: _startGame, child: Container(
      color: Colors.black,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Collision!', style: TextStyle(fontFamily: 'Avenir', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 20),
        Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.amberAccent)),
        const SizedBox(height: 4),
        Text('Wave Reached: $_wave', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.cyanAccent)),
        const SizedBox(height: 4),
        Text('Best Streak: $_bestStreak', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.orangeAccent)),
        const SizedBox(height: 4),
        Text('Time: ${mins}m ${secs}s', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.white54)),
        const SizedBox(height: 12),
        if (_score >= _highScore && _score > 0)
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('New High Score!', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent))),
        Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38)),
        const SizedBox(height: 20),
        const Text('Play Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.cyanAccent)),
      ])),
    ));
  }
}

// ── Small legend widget ──────────────────────────────────────────────────────
class _DirLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool clockwise;
  const _DirLegend({required this.color, required this.label, required this.clockwise});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      CustomPaint(size: const Size(20, 20), painter: _ArrowCirclePainter(color: color, clockwise: clockwise)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: color)),
    ]);
  }
}

class _ArrowCirclePainter extends CustomPainter {
  final Color color;
  final bool clockwise;
  const _ArrowCirclePainter({required this.color, required this.clockwise});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, clockwise ? pi * 1.5 : -pi * 1.5, false, paint);
    // Arrowhead
    final endAngle = clockwise ? pi : -pi / 2;
    final ax = c.dx + cos(endAngle) * r;
    final ay = c.dy + sin(endAngle) * r;
    final headAngle = clockwise ? endAngle + pi / 2 : endAngle - pi / 2;
    canvas.drawLine(
      Offset(ax, ay),
      Offset(ax + cos(headAngle - 0.5) * 4, ay + sin(headAngle - 0.5) * 4),
      paint,
    );
    canvas.drawLine(
      Offset(ax, ay),
      Offset(ax + cos(headAngle + 0.5) * 4, ay + sin(headAngle + 0.5) * 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowCirclePainter old) => old.clockwise != clockwise || old.color != color;
}

// ── Main canvas painter ──────────────────────────────────────────────────────
class _StarDeflectorPainter extends CustomPainter {
  final List<_GCThreat> threats;
  final List<_JuiceParticle> particles;
  final List<_GCGesture> gestures;
  final List<Offset> strokePts;
  final double shortSide, flashGood, flashBad;

  const _StarDeflectorPainter({
    required this.threats, required this.particles,
    required this.gestures, required this.strokePts,
    required this.shortSide, required this.flashGood, required this.flashBad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Background starfield
    final rng = Random(99);
    for (int i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        0.3 + rng.nextDouble() * 0.7,
        Paint()..color = Colors.white.withValues(alpha: 0.05 + rng.nextDouble() * 0.05),
      );
    }

    // Danger zone at centre
    final cx = w * 0.5, cy = h * 0.5;
    canvas.drawCircle(Offset(cx, cy), 22, Paint()..color = Colors.redAccent.withValues(alpha: 0.08));
    canvas.drawCircle(Offset(cx, cy), 22, Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0);
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = Colors.redAccent.withValues(alpha: 0.5));

    // Threats
    for (final t in threats) {
      final tx = t.x * w, ty = t.y * h;
      final a = t.scale.clamp(0.0, 1.0);
      final col = t.color;

      // Body
      if (t.flashGood > 0) {
        canvas.drawCircle(Offset(tx, ty), 18 * a, Paint()..color = Colors.greenAccent.withValues(alpha: t.flashGood * 0.6));
      }
      if (t.flashBad > 0) {
        canvas.drawCircle(Offset(tx, ty), 18 * a, Paint()..color = Colors.redAccent.withValues(alpha: t.flashBad * 0.5));
      }

      canvas.drawCircle(Offset(tx, ty), 14 * a, Paint()..color = col.withValues(alpha: a * 0.15));
      canvas.drawCircle(Offset(tx, ty), 8 * a, Paint()..color = col.withValues(alpha: a * 0.5));
      canvas.drawCircle(Offset(tx, ty), 4 * a, Paint()..color = Colors.white.withValues(alpha: a * 0.9));

      // Required-radius ring
      if (!t.deflected && t.scale > 0.5) {
        final reqPx = t.reqRadius * shortSide;
        final ringAlpha = a * 0.55;
        canvas.drawCircle(Offset(tx, ty), reqPx, Paint()
          ..color = col.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
        // Dashed tick marks at N/S/E/W for size reference
        for (int q = 0; q < 4; q++) {
          final ang = q * pi / 2;
          final ox = cos(ang), oy = sin(ang);
          canvas.drawLine(
            Offset(tx + ox * (reqPx - 4), ty + oy * (reqPx - 4)),
            Offset(tx + ox * (reqPx + 4), ty + oy * (reqPx + 4)),
            Paint()..color = col.withValues(alpha: ringAlpha * 0.9)..strokeWidth = 2.0..strokeCap = StrokeCap.round,
          );
        }

        // Direction arrow arcing around the ring
        final arrowPaint = Paint()..color = col.withValues(alpha: a * 0.9)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
        final isCw = t.reqDir == _GCDir.cw;
        // Draw a 120-degree arc as direction hint
        canvas.drawArc(
          Rect.fromCircle(center: Offset(tx, ty), radius: reqPx),
          -pi / 2, isCw ? pi * 0.67 : -pi * 0.67, false, arrowPaint,
        );
        // Arrowhead
        final endAng = isCw ? -pi / 2 + pi * 0.67 : -pi / 2 - pi * 0.67;
        final eax = tx + cos(endAng) * reqPx;
        final eay = ty + sin(endAng) * reqPx;
        final headAng = endAng + (isCw ? pi / 2 : -pi / 2);
        canvas.drawLine(
          Offset(eax, eay),
          Offset(eax + cos(headAng - 0.45) * 6, eay + sin(headAng - 0.45) * 6),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(eax, eay),
          Offset(eax + cos(headAng + 0.45) * 6, eay + sin(headAng + 0.45) * 6),
          arrowPaint,
        );

        // Urgency countdown ring (shrinks towards zero)
        final urgency = (t.timeLeft / t.maxTime).clamp(0.0, 1.0);
        if (urgency < 0.6) {
          canvas.drawCircle(Offset(tx, ty), 20 * a, Paint()
            ..color = Colors.redAccent.withValues(alpha: (1.0 - urgency) * 0.35 * a)
            ..style = PaintingStyle.stroke..strokeWidth = 1.0);
        }
      }
    }

    // Past gestures (resolved strokes drawn as fading rings)
    for (final g in gestures) {
      final gc = g.centroid;
      final gx = gc.dx * w, gy = gc.dy * h;
      final gpx = g.radius * shortSide;
      final ga = (g.life / 0.5).clamp(0.0, 1.0);
      final gcol = g.good ? Colors.greenAccent : Colors.redAccent;
      canvas.drawCircle(Offset(gx, gy), gpx, Paint()
        ..color = gcol.withValues(alpha: ga * 0.5)
        ..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }

    // Active stroke being drawn
    if (strokePts.length > 1) {
      final path = Path();
      path.moveTo(strokePts.first.dx * w, strokePts.first.dy * h);
      for (int i = 1; i < strokePts.length; i++) {
        path.lineTo(strokePts[i].dx * w, strokePts[i].dy * h);
      }
      canvas.drawPath(path, Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * w, p.y * h), p.radius,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }

    // Full-screen flashes
    if (flashGood > 0) canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.greenAccent.withValues(alpha: flashGood * 0.15));
    if (flashBad  > 0) canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.redAccent.withValues(alpha: flashBad  * 0.25));
  }

  @override
  bool shouldRepaint(covariant _StarDeflectorPainter old) => true;
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
                        child: const Text('Explore Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
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
// 8. InfinityCounterGame — "Infinity"
// ═══════════════════════════════════════════════════════════════════════════════

class InfinityCounterGame extends StatefulWidget {
  const InfinityCounterGame({Key? key}) : super(key: key);
  @override
  State<InfinityCounterGame> createState() => _InfinityCounterGameState();
}

class _InfinityCounterGameState extends State<InfinityCounterGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  BigInt _count = BigInt.zero;
  double _fontSize = 48;
  double _shockwaveRadius = 0;
  double _shockwaveAlpha = 0;
  double _bgHue = 220;
  double _digitStretch = 1.0;
  double _digitBounce = 0;
  bool _autoClickerUnlocked = false;
  double _autoClickerTimer = 0;
  int _tapsInLastSecond = 0;
  double _tapTrackTimer = 0;
  final List<int> _recentTapCounts = [];

  // Milestones
  final Set<int> _milestonesHit = {};

  final List<_JuiceParticle> _particles = [];

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

  void _tick() {
    final dt = 1 / 60.0;
    setState(() {
      // Shockwave decay
      if (_shockwaveAlpha > 0) {
        _shockwaveRadius += 200 * dt;
        _shockwaveAlpha -= dt * 2;
        if (_shockwaveAlpha < 0) _shockwaveAlpha = 0;
      }

      // Digit bounce/stretch decay
      _digitBounce *= 0.92;
      _digitStretch = 1.0 + _digitBounce * 0.3;

      // Background hue shift
      _bgHue += dt * 2;
      if (_bgHue > 360) _bgHue -= 360;

      // Tap speed tracking
      _tapTrackTimer += dt;
      if (_tapTrackTimer >= 1.0) {
        _recentTapCounts.add(_tapsInLastSecond);
        if (_recentTapCounts.length > 3) _recentTapCounts.removeAt(0);
        // Unlock auto-clicker if tapping 5+/sec for 3 seconds
        if (!_autoClickerUnlocked && _recentTapCounts.length >= 3 && _recentTapCounts.every((c) => c >= 5)) {
          _autoClickerUnlocked = true;
          _spawnMilestoneExplosion();
        }
        _tapsInLastSecond = 0;
        _tapTrackTimer = 0;
      }

      // Auto-clicker
      if (_autoClickerUnlocked) {
        _autoClickerTimer += dt;
        if (_autoClickerTimer >= 1.0) {
          _autoClickerTimer = 0;
          _incrementCount();
        }
      }

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 50 * dt; // gravity
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _incrementCount() {
    _count += BigInt.one;
    // Grow font size slowly
    final countVal = _count.toInt().clamp(0, 999999);
    if (countVal < 100) {
      _fontSize = 48 + countVal * 0.5;
    } else if (countVal < 1000) {
      _fontSize = 98 + (countVal - 100) * 0.1;
    } else {
      _fontSize = min(188, 188.0 + (countVal - 1000) * 0.01);
    }

    // Check milestones
    final milestones = [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000];
    for (final m in milestones) {
      if (countVal == m && !_milestonesHit.contains(m)) {
        _milestonesHit.add(m);
        _spawnMilestoneExplosion();
      }
    }
  }

  void _spawnMilestoneExplosion() {
    for (int i = 0; i < 40; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 150;
      _particles.add(_JuiceParticle(
        x: 0, y: 0, // will be offset in paint
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 50,
        life: 1.2,
        color: HSVColor.fromAHSV(1, _rng.nextDouble() * 360, 0.8, 1.0).toColor(),
        radius: 3 + _rng.nextDouble() * 3,
      ));
    }
  }

  void _onTap() {
    setState(() {
      _incrementCount();
      _tapsInLastSecond++;
      _shockwaveRadius = 0;
      _shockwaveAlpha = 0.5;
      _digitBounce = 1.0;

      // Small tap particles
      for (int i = 0; i < 3; i++) {
        _particles.add(_JuiceParticle(
          x: (_rng.nextDouble() - 0.5) * 60,
          y: (_rng.nextDouble() - 0.5) * 40,
          vx: (_rng.nextDouble() - 0.5) * 60,
          vy: -30 - _rng.nextDouble() * 40,
          life: 0.6,
          color: HSVColor.fromAHSV(1, _bgHue, 0.6, 1.0).toColor(),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = HSVColor.fromAHSV(1, _bgHue, 0.15, 0.06).toColor();

    return LayoutBuilder(builder: (context, constraints) {
      final centerX = constraints.maxWidth / 2;
      final centerY = constraints.maxHeight * 0.4;

      return GestureDetector(
        onTapDown: (_) => _onTap(),
        child: Container(
          color: bgColor,
          child: Stack(
            children: [
              // Shockwave
              if (_shockwaveAlpha > 0)
                Positioned(
                  left: centerX - _shockwaveRadius,
                  top: centerY - _shockwaveRadius,
                  child: Container(
                    width: _shockwaveRadius * 2,
                    height: _shockwaveRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: HSVColor.fromAHSV(_shockwaveAlpha.clamp(0.0, 1.0), _bgHue, 0.5, 0.8).toColor(),
                        width: 2,
                      ),
                    ),
                  ),
                ),

              // Particles (centered on number)
              ..._particles.where((p) => p.life > 0).map((p) => Positioned(
                left: centerX + p.x - p.radius,
                top: centerY + p.y - p.radius,
                child: Container(
                  width: p.radius * 2,
                  height: p.radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                  ),
                ),
              )),

              // The number (with physics)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: constraints.maxHeight * 0.2),
                  child: Transform.scale(
                    scaleX: 1.0,
                    scaleY: _digitStretch.clamp(0.7, 1.5),
                    child: Text(
                      '$_count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: _fontSize.clamp(20, 200),
                        fontWeight: FontWeight.bold,
                        color: HSVColor.fromAHSV(0.7, _bgHue, 0.3, 1.0).toColor(),
                      ),
                    ),
                  ),
                ),
              ),

              // Auto-clicker indicator
              if (_autoClickerUnlocked)
                Positioned(
                  top: 8, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Text('AUTO +1/s', style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.greenAccent)),
                  ),
                ),

              // Instructions
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_autoClickerUnlocked)
                        Text(
                          'Tap fast (5/sec for 3s) to unlock auto-clicker',
                          style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'It never ends.',
                        style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ],
                  ),
                ),
              ),

              // Milestones display
              if (_milestonesHit.isNotEmpty)
                Positioned(
                  top: 8, left: 16,
                  child: Text(
                    'Milestones: ${_milestonesHit.length}',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.amberAccent.withValues(alpha: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      );
    });
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
// NeuronConnectGame — "Cosmic Web" time-trial
// Route signals through an escalating sequence of cosmic-web puzzles as fast
// as you can within the time limit. Each solved puzzle instantly spawns a harder
// one. Score is puzzles cleared × speed bonus. Impossible to fully master.
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

/// Glow bloom radius on nodes (logical pixels added to node radius for blur).
const double _ncNodeGlowBlur = 14.0;

/// Glow bloom radius on the signal dot.
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
  // Phase: intro → trial → done
  _NCPhase _phase = _NCPhase.intro;

  // ── timer ─────────────────────────────────────────────────────────────────
  double _elapsed = 0; // seconds elapsed in trial
  double _lastWallTime = 0;

  // ── puzzle state ──────────────────────────────────────────────────────────
  int _puzzleIndex = 0; // how many puzzles spawned so far
  int _puzzlesCleared = 0;
  int _score = 0;
  late _SRLevel _level;
  List<_SRNode> _playNodes = [];
  List<_SRSignal> _activeSignals = [];
  bool _signalAnimating = false;
  bool _signalDead = false;

  // ── cosmetics ─────────────────────────────────────────────────────────────
  final List<_JuiceParticle> _particles = [];
  late List<_NCStar> _stars;
  double _beamPhase = 0; // drives shimmer on connection trails
  double _completionFlashAlpha = 0; // white flash on clear

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
      if (_completionFlashAlpha > 0) _completionFlashAlpha = (_completionFlashAlpha - dt * 3).clamp(0.0, 1.0);

      // ── advance particles ──────────────────────────────────────────────
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      if (_phase == _NCPhase.trial) {
        // ── advance clock ──────────────────────────────────────────────
        _elapsed += dt;
        if (_elapsed >= _ncTrialDuration) {
          _elapsed = _ncTrialDuration;
          _endTrial();
          return;
        }

        // ── advance signal ─────────────────────────────────────────────
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
              sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows); continue;
            }
            final nni = nr * _level.cols + nc;
            if (_playNodes[nni].type == _SRNodeType.blocker) {
              sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows); continue;
            }
            if (sig.trail.any((p) => p[0] == nc && p[1] == nr)) {
              sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble(), _level.cols, _level.rows); continue;
            }
            sig.nextCol = nc;
            sig.nextRow = nr;
          }
        }

        final allDone = !anyMoving || _activeSignals.every((s) => s.dead || s.arrived);
        if (allDone) {
          if (_activeSignals.isNotEmpty && _activeSignals.every((s) => s.arrived)) {
            // ── puzzle cleared ─────────────────────────────────────────
            _puzzlesCleared++;
            final timeBonus = ((_ncTrialDuration - _elapsed) / _ncTrialDuration * 50).round();
            _score += _ncBasePoints * (_puzzleIndex + 1) + timeBonus;
            _completionFlashAlpha = 0.5;
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
      // store in normalised [0,1] space that the painter converts
      final nx = (gc + 0.5) / cols;
      final ny = (gr + 0.5) / rows;
      _particles.add(_JuiceParticle(
        x: nx, y: ny,
        vx: cos(a) * spd / cols,
        vy: sin(a) * spd / rows,
        life: _ncClearParticleLife,
        color: i % 3 == 0 ? Colors.cyanAccent : i % 3 == 1 ? Colors.purpleAccent : Colors.white,
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
        color: Colors.redAccent,
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
      color: const Color(0xFF04040F),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // title
          const Text('COSMIC WEB', style: TextStyle(fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 4)),
          const SizedBox(height: 8),
          Text('NEURAL SIGNAL TRIAL', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, letterSpacing: 3, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 40),
          // instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(children: [
              _instrRow(Icons.touch_app, 'Tap nodes to rotate their exit gate'),
              const SizedBox(height: 12),
              _instrRow(Icons.send, 'Hit FIRE to send the signal'),
              const SizedBox(height: 12),
              _instrRow(Icons.bolt, 'Clear each puzzle — next one spawns instantly'),
              const SizedBox(height: 12),
              _instrRow(Icons.timer, 'You have ${_ncTrialDuration.toInt()}s. Go as far as you can.'),
            ]),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _startTrial,
            child: Container(
              width: 200, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF7B2FBE)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF00B4D8).withValues(alpha: 0.45), blurRadius: 20, spreadRadius: 2)],
              ),
              alignment: Alignment.center,
              child: const Text('LAUNCH', style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _instrRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.cyanAccent.withValues(alpha: 0.7)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.65)))),
    ]);
  }

  // ── trial screen ──────────────────────────────────────────────────────────

  Widget _buildTrial() {
    final timeLeft = (_ncTrialDuration - _elapsed).clamp(0.0, _ncTrialDuration);
    final timeFrac = timeLeft / _ncTrialDuration;
    final timerColor = timeFrac > 0.4 ? Colors.cyanAccent : timeFrac > 0.15 ? Colors.amber : Colors.redAccent;

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
                stars: _stars,
                beamPhase: _beamPhase,
                completionFlash: _completionFlashAlpha,
              ),
            ),
          ),
        ),

        // ── top bar ───────────────────────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [const Color(0xCC04040F), Colors.transparent],
              ),
            ),
            child: Row(children: [
              // timer ring + number
              SizedBox(width: 42, height: 42,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: timeFrac,
                    strokeWidth: 3,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(timerColor),
                  ),
                  Text(timeLeft.ceil().toString(),
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 13, fontWeight: FontWeight.bold, color: timerColor)),
                ]),
              ),
              const SizedBox(width: 12),
              // puzzle counter
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WEB #${_puzzleIndex + 1}',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.5)),
                Text('${_level.cols}×${_level.rows} grid',
                  style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
              ]),
              const Spacer(),
              // score
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${_puzzlesCleared} cleared',
                  style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
              ]),
            ]),
          ),
        ),

        // ── fire button + dead msg ─────────────────────────────────────
        Positioned(bottom: 14, left: 20, right: 20,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_signalDead && !_signalAnimating)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Signal lost — reroute and fire again',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.redAccent.withValues(alpha: 0.85))),
              ),
            GestureDetector(
              onTap: _signalAnimating ? null : _sendSignal,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 50,
                decoration: BoxDecoration(
                  gradient: _signalAnimating
                    ? null
                    : const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF7B2FBE)]),
                  color: _signalAnimating ? Colors.white10 : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _signalAnimating ? [] : [
                    BoxShadow(color: const Color(0xFF00B4D8).withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 1),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(_signalAnimating ? 'TRANSMITTING...' : 'FIRE SIGNAL',
                  style: TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold,
                    color: _signalAnimating ? Colors.white38 : Colors.white, letterSpacing: 2)),
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
      color: const Color(0xFF04040F),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('TRIAL COMPLETE', style: TextStyle(fontFamily: 'Avenir', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 3)),
          const SizedBox(height: 30),
          _resultRow('Score', '$_score'),
          const SizedBox(height: 10),
          _resultRow('Webs Cleared', '$_puzzlesCleared'),
          const SizedBox(height: 10),
          _resultRow('Furthest Web', 'Grid ${_level.cols}×${_level.rows}'),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => setState(() {
              _phase = _NCPhase.intro;
              _particles.clear();
            }),
            child: Container(
              width: 180, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF7B2FBE)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.35), blurRadius: 18)],
              ),
              alignment: Alignment.center,
              child: const Text('PLAY AGAIN', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('$label  ', style: TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.white.withValues(alpha: 0.45))),
      Text(value, style: const TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
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
      if ((pos - Offset(cx, cy)).distance <= cellSize * 0.38 + 6) return i;
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
// Painter: starfield + cosmic grid + glowing nodes + beam trails + particles
// ---------------------------------------------------------------------------

class _NCPainter extends CustomPainter {
  final _SRLevel level;
  final List<_SRNode> nodes;
  final List<_SRSignal> signals;
  final List<_JuiceParticle> particles;
  final List<_NCStar> stars;
  final double beamPhase;
  final double completionFlash;

  _NCPainter({
    required this.level,
    required this.nodes,
    required this.signals,
    required this.particles,
    required this.stars,
    required this.beamPhase,
    required this.completionFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── deep-space background ──────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero, Offset(size.width, size.height),
        [const Color(0xFF04040F), const Color(0xFF080820), const Color(0xFF0D0628)],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── starfield ─────────────────────────────────────────────────────
    for (final s in stars) {
      final twinkle = 0.5 + 0.5 * sin(s.twinklePhase + beamPhase * s.twinkleSpeed);
      final alpha = (s.brightness * twinkle).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }

    // ── cosmic web faint connection lines (background) ─────────────────
    final cols = level.cols;
    final rows = level.rows;
    final cellSize = _cellSize(size, cols, rows);
    final ox = (size.width - cols * cellSize) / 2;
    final oy = (size.height - rows * cellSize) / 2 + 20;

    final cosmicPaint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.035)..strokeWidth = 0.8;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final x = ox + c * cellSize + cellSize / 2;
        final y = oy + r * cellSize + cellSize / 2;
        if (c < cols - 1) canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), cosmicPaint);
        if (r < rows - 1) canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), cosmicPaint);
      }
    }

    // ── nodes ──────────────────────────────────────────────────────────
    final nodeRadius = cellSize * 0.32;
    for (int i = 0; i < nodes.length; i++) {
      final c = i % cols;
      final r = i ~/ cols;
      final cx = ox + c * cellSize + cellSize / 2;
      final cy = oy + r * cellSize + cellSize / 2;
      final center = Offset(cx, cy);
      final node = nodes[i];

      if (node.type == _SRNodeType.blocker) {
        // dark hexagonal blocker
        canvas.drawCircle(center, nodeRadius, Paint()..color = const Color(0xFF0E0E20));
        canvas.drawCircle(center, nodeRadius,
          Paint()..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        final xp = Paint()..color = Colors.white.withValues(alpha: 0.18)..strokeWidth = 2..strokeCap = StrokeCap.round;
        final xr = nodeRadius * 0.38;
        canvas.drawLine(Offset(cx - xr, cy - xr), Offset(cx + xr, cy + xr), xp);
        canvas.drawLine(Offset(cx + xr, cy - xr), Offset(cx - xr, cy + xr), xp);
        continue;
      }

      Color coreColor;
      Color glowColor;
      switch (node.type) {
        case _SRNodeType.source:
          coreColor = const Color(0xFF00E5FF); glowColor = Colors.cyanAccent; break;
        case _SRNodeType.target:
          coreColor = const Color(0xFFEA00FF); glowColor = Colors.purpleAccent; break;
        default:
          coreColor = const Color(0xFF4DFFDB); glowColor = const Color(0xFF4DFFDB);
      }

      // outer glow bloom
      canvas.drawCircle(center, nodeRadius + _ncNodeGlowBlur,
        Paint()..color = glowColor.withValues(alpha: 0.10)..maskFilter = MaskFilter.blur(BlurStyle.normal, _ncNodeGlowBlur));

      // filled core
      canvas.drawCircle(center, nodeRadius,
        Paint()..color = coreColor.withValues(alpha: node.locked ? 0.2 : 0.35));

      // rim
      canvas.drawCircle(center, nodeRadius,
        Paint()..color = coreColor.withValues(alpha: node.locked ? 0.5 : 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.8);

      // arrow
      _drawArrow(canvas, center, node.dir, nodeRadius * 0.52, coreColor.withValues(alpha: node.locked ? 0.35 : 0.9));

      // S / T label
      if (node.type == _SRNodeType.source || node.type == _SRNodeType.target) {
        final label = node.type == _SRNodeType.source ? 'S' : 'T';
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(fontFamily: 'Avenir', fontSize: nodeRadius * 0.62, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      }

      // lock icon
      if (node.locked && node.type == _SRNodeType.normal) {
        final ls = nodeRadius * 0.28;
        final lp = Paint()..color = Colors.white38..strokeWidth = 1.1..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + nodeRadius * 0.26), width: ls, height: ls * 0.8), const Radius.circular(1)), lp);
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + nodeRadius * 0.26 - ls * 0.38), width: ls * 0.68, height: ls * 0.68), pi, pi, false, lp);
      }
    }

    // ── signal trails (animated beam) ─────────────────────────────────
    for (final sig in signals) {
      if (sig.trail.length < 2) continue;
      Color beamColor;
      if (sig.arrived) {
        beamColor = Colors.cyanAccent;
      } else if (sig.dead) {
        beamColor = Colors.redAccent;
      } else {
        // shimmer: oscillate between cyan and purple
        final shimmer = 0.5 + 0.5 * sin(beamPhase * (2 * pi / _ncBeamShimmerPeriod));
        beamColor = Color.lerp(Colors.cyanAccent, Colors.purpleAccent, shimmer)!;
      }

      // glow pass
      final glowPaint = Paint()
        ..color = beamColor.withValues(alpha: 0.18)
        ..strokeWidth = _ncBeamWidth + 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      // core pass
      final corePaint = Paint()
        ..color = beamColor.withValues(alpha: sig.arrived ? 0.7 : 0.55)
        ..strokeWidth = _ncBeamWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final paint in [glowPaint, corePaint]) {
        final path = ui.Path();
        for (int k = 0; k < sig.trail.length; k++) {
          final tx = ox + sig.trail[k][0] * cellSize + cellSize / 2;
          final ty = oy + sig.trail[k][1] * cellSize + cellSize / 2;
          if (k == 0) { path.moveTo(tx, ty); } else { path.lineTo(tx, ty); }
        }
        if (!sig.dead && !sig.arrived && sig.t > 0) {
          final fx = ox + sig.col * cellSize + cellSize / 2;
          final fy = oy + sig.row * cellSize + cellSize / 2;
          final tx = ox + sig.nextCol * cellSize + cellSize / 2;
          final ty = oy + sig.nextRow * cellSize + cellSize / 2;
          path.lineTo(fx + (tx - fx) * sig.t, fy + (ty - fy) * sig.t);
        }
        canvas.drawPath(path, paint);
      }
    }

    // ── signal dots ───────────────────────────────────────────────────
    for (final sig in signals) {
      if (sig.dead || sig.arrived) continue;
      double sx, sy;
      if (sig.t > 0 && (sig.nextCol != sig.col || sig.nextRow != sig.row)) {
        final fx = ox + sig.col * cellSize + cellSize / 2;
        final fy = oy + sig.row * cellSize + cellSize / 2;
        final tx = ox + sig.nextCol * cellSize + cellSize / 2;
        final ty = oy + sig.nextRow * cellSize + cellSize / 2;
        sx = fx + (tx - fx) * sig.t;
        sy = fy + (ty - fy) * sig.t;
      } else {
        sx = ox + sig.col * cellSize + cellSize / 2;
        sy = oy + sig.row * cellSize + cellSize / 2;
      }
      // outer glow
      canvas.drawCircle(Offset(sx, sy), _ncSignalGlowBlur,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.20)..maskFilter = MaskFilter.blur(BlurStyle.normal, _ncSignalGlowBlur));
      // mid ring
      canvas.drawCircle(Offset(sx, sy), 7,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.55));
      // hot core
      canvas.drawCircle(Offset(sx, sy), 3.5,
        Paint()..color = Colors.white);
    }

    // ── particles ─────────────────────────────────────────────────────
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius * alpha,
        Paint()..color = p.color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // ── completion flash ──────────────────────────────────────────────
    if (completionFlash > 0) {
      canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.cyanAccent.withValues(alpha: completionFlash * 0.18));
    }
  }

  void _drawArrow(Canvas canvas, Offset center, _GateDir dir, double length, Color color) {
    final paint = Paint()..color = color..strokeWidth = 2.2..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final angle = switch (dir) {
      _GateDir.up => -pi / 2,
      _GateDir.right => 0.0,
      _GateDir.down => pi / 2,
      _GateDir.left => pi,
    };
    final tip = Offset(center.dx + cos(angle) * length, center.dy + sin(angle) * length);
    final tail = Offset(center.dx - cos(angle) * length * 0.38, center.dy - sin(angle) * length * 0.38);
    canvas.drawLine(tail, tip, paint);
    final hl = length * 0.38;
    canvas.drawLine(tip, Offset(tip.dx + cos(angle + pi * 0.78) * hl, tip.dy + sin(angle + pi * 0.78) * hl), paint);
    canvas.drawLine(tip, Offset(tip.dx + cos(angle - pi * 0.78) * hl, tip.dy + sin(angle - pi * 0.78) * hl), paint);
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
const double _kGameDuration = 60.0;
// Score is accumulated area: π·r² per player bubble, sampled each second.
const double _kScoreTickInterval = 1.0;
// Particle burst count on grow tap (visual feedback).
const int _kGrowParticleCount = 6;
// Particle burst count on pop/shrink.
const int _kPopParticleCount = 12;
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
      if (_elapsed >= _kGameDuration) {
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
        if (_elapsed > _kGameDuration * 0.5) _spawnRival();
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

      // ── Soft repulsion between all bubbles ───────────────────────────────
      for (int i = 0; i < _bubbles.length; i++) {
        if (_bubbles[i].popAnim > 0) continue;
        for (int j = i + 1; j < _bubbles.length; j++) {
          if (_bubbles[j].popAnim > 0) continue;
          final a = _bubbles[i]; final bub = _bubbles[j];
          final ddx = bub.x - a.x; final ddy = bub.y - a.y;
          final dist = sqrt(ddx * ddx + ddy * ddy);
          final minD = a.radius + bub.radius;
          if (dist < minD && dist > 0.1) {
            final nx = ddx / dist; final ny = ddy / dist;
            final push = (minD - dist) * 1.5;
            a.vx -= nx * push; a.vy -= ny * push;
            bub.vx += nx * push; bub.vy += ny * push;
          }
        }
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
    final secs = (_kGameDuration - _elapsed).ceil().clamp(0, 60);
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
