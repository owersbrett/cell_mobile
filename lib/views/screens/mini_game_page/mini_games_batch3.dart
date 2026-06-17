import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HanoiPlanet {
  final String name;
  final Color color;
  final int sizeRank; // 0 = smallest, higher = larger

  const _HanoiPlanet({
    required this.name,
    required this.color,
    required this.sizeRank,
  });
}

class SolarSortGame extends StatefulWidget {
  const SolarSortGame({Key? key}) : super(key: key);
  @override
  State<SolarSortGame> createState() => _SolarSortGameState();
}

class _SolarSortGameState extends State<SolarSortGame>
    with TickerProviderStateMixin {
  static const _planetNames = ['Jupiter', 'Saturn', 'Neptune', 'Uranus', 'Earth', 'Mars', 'Venus', 'Mercury'];
  static const _planetColors = [Color(0xFFCC9966), Color(0xFFDDCC88), Color(0xFF4466AA), Color(0xFF88CCDD), Color(0xFF4488CC), Color(0xFFCC5533), Color(0xFFE8A84C), Color(0xFFB0B0B0)];

  // Stage config: [numTowers, numPlanets]
  static List<int> _stageConfig(int stage) {
    // Stages 1-3: 3 planets, 3 towers
    // Stages 4-5: 4 planets, 3 towers
    // Stages 6-7: 5 planets, 3 towers
    // Stages 8-9: 5 planets, 4 towers
    // Stages 10+: 6-7 planets, 4 towers
    if (stage <= 3) return [3, 3];
    if (stage <= 5) return [3, 4];
    if (stage <= 7) return [3, 5];
    if (stage <= 9) return [4, 5];
    if (stage <= 11) return [4, 6];
    return [4, min(7, 3 + (stage ~/ 2))];
  }

  int _stage = 1;
  int _moveCount = 0;
  int? _selectedTower;
  bool _won = false;
  bool _showMenu = true;
  Map<int, int> _bestMoves = {};

  late List<List<_HanoiPlanet>> _towers; // current state
  late List<List<_HanoiPlanet>> _goalTowers; // target state
  late List<_HanoiPlanet> _activePlanets;
  int _numTowers = 3;
  int _numPlanets = 3;

  AnimationController? _shakeCtrl;
  Animation<double>? _shakeAnim;
  int? _shakeTower;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _towers = List.generate(3, (_) => <_HanoiPlanet>[]);
    _goalTowers = List.generate(3, (_) => <_HanoiPlanet>[]);
    _activePlanets = [];
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shakeCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStage = prefs.getInt('solar_architect_stage') ?? 1;
    final bestJson = prefs.getString('solar_architect_best_moves');
    Map<int, int> best = {};
    if (bestJson != null) {
      final decoded = jsonDecode(bestJson) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        best[int.parse(e.key)] = e.value as int;
      }
    }
    if (!mounted) return;
    setState(() {
      _stage = savedStage;
      _bestMoves = best;
      _showMenu = true;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('solar_architect_stage', _stage);
    final bestJson = <String, int>{};
    for (final e in _bestMoves.entries) {
      bestJson[e.key.toString()] = e.value;
    }
    await prefs.setString('solar_architect_best_moves', jsonEncode(bestJson));
  }

  /// Generate a valid Hanoi state: distribute planets across towers,
  /// ensuring each tower has planets in decreasing size (largest at bottom).
  /// Uses a deterministic seed so each stage always generates the same puzzle.
  List<List<_HanoiPlanet>> _generateValidState(int seed, List<_HanoiPlanet> planets, int numTowers) {
    final rng = Random(seed);
    final towers = List.generate(numTowers, (_) => <_HanoiPlanet>[]);
    // Sort planets by sizeRank descending (largest first)
    final sorted = List<_HanoiPlanet>.from(planets);
    sorted.sort((a, b) => b.sizeRank.compareTo(a.sizeRank));
    // Assign each planet (from largest to smallest) to a random tower
    for (final planet in sorted) {
      final towerIdx = rng.nextInt(numTowers);
      towers[towerIdx].insert(0, planet); // insert at top (smallest on top)
    }
    return towers;
  }

  void _initStage(int stage) {
    final cfg = _stageConfig(stage);
    _numTowers = cfg[0];
    _numPlanets = cfg[1];
    _activePlanets = [];
    for (int i = 0; i < _numPlanets; i++) {
      final defIdx = _planetNames.length - _numPlanets + i;
      _activePlanets.add(_HanoiPlanet(
        name: _planetNames[defIdx],
        color: _planetColors[defIdx],
        sizeRank: _numPlanets - 1 - i,
      ));
    }

    // Initial state: all planets stacked on tower 0
    _towers = List.generate(_numTowers, (_) => <_HanoiPlanet>[]);
    // Stack largest at bottom (index 0 is top of tower in our model)
    final startSorted = List<_HanoiPlanet>.from(_activePlanets);
    startSorted.sort((a, b) => b.sizeRank.compareTo(a.sizeRank));
    _towers[0] = startSorted.toList(); // largest at index 0 (bottom), smallest last (top)
    // Actually in our model, index 0 = top, so we want smallest at index 0
    _towers[0] = startSorted.reversed.toList();

    // Goal state: generate a valid configuration that's different from start
    // Use stage * 1000 + attempt as seed to ensure different goals
    int attempt = 0;
    do {
      _goalTowers = _generateValidState(stage * 1000 + attempt, _activePlanets, _numTowers);
      attempt++;
    } while (_statesMatch(_towers, _goalTowers) && attempt < 100);

    _moveCount = 0;
    _selectedTower = null;
    _won = false;
    _shakeTower = null;
  }

  bool _statesMatch(List<List<_HanoiPlanet>> a, List<List<_HanoiPlanet>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (int j = 0; j < a[i].length; j++) {
        if (a[i][j].sizeRank != b[i][j].sizeRank) return false;
      }
    }
    return true;
  }

  void _startStage(int stage) {
    setState(() { _stage = stage; _showMenu = false; _initStage(stage); });
  }

  void _onTapTower(int towerIdx) {
    if (_won) return;
    setState(() {
      if (_selectedTower == null) {
        if (_towers[towerIdx].isNotEmpty) _selectedTower = towerIdx;
      } else if (_selectedTower == towerIdx) {
        _selectedTower = null;
      } else {
        final fromTower = _towers[_selectedTower!];
        final toTower = _towers[towerIdx];
        final planet = fromTower.first; // top of tower
        if (toTower.isEmpty || toTower.first.sizeRank > planet.sizeRank) {
          fromTower.removeAt(0);
          toTower.insert(0, planet);
          _moveCount++;
          _selectedTower = null;
          // Check win: current matches goal
          if (_statesMatch(_towers, _goalTowers)) {
            _won = true;
            final prev = _bestMoves[_stage];
            if (prev == null || _moveCount < prev) _bestMoves[_stage] = _moveCount;
            _saveProgress();
          }
        } else {
          _triggerShake(_selectedTower!);
          _selectedTower = null;
        }
      }
    });
  }

  void _triggerShake(int towerIdx) {
    _shakeTower = towerIdx;
    _shakeCtrl?.dispose();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl!, curve: Curves.elasticIn));
    _shakeCtrl!.addStatusListener((s) { if (s == AnimationStatus.completed && mounted) setState(() => _shakeTower = null); });
    _shakeCtrl!.addListener(() { if (mounted) setState(() {}); });
    _shakeCtrl!.forward();
  }

  double _shakeOffset() {
    if (_shakeTower == null || _shakeAnim == null) return 0;
    final t = _shakeAnim!.value;
    return sin(t * pi * 6) * 8 * (1.0 - t);
  }

  @override
  Widget build(BuildContext context) {
    if (_showMenu) return _buildMenu();
    return _buildGame();
  }

  Widget _buildMenu() {
    final maxStage = _bestMoves.isEmpty ? 1 : _bestMoves.keys.fold<int>(1, (mx, k) => k > mx ? k : mx) + 1;
    final highestUnlocked = max(maxStage, _stage);
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 24),
          const Text('Orbital Mechanic', style: TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          const Text('Match the target orbital configuration', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: highestUnlocked,
              itemBuilder: (context, i) {
                final stage = i + 1;
                final cfg = _stageConfig(stage);
                final best = _bestMoves[stage];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _startStage(stage),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Text('Puzzle $stage', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(width: 12),
                        Text('${cfg[0]} pillars / ${cfg[1]} planets', style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white38)),
                        const Spacer(),
                        if (best != null) Text('Best: $best', style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.amberAccent))
                        else const Text('unsolved', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white24)),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGame() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      // Goal preview takes top area
      final goalHeight = 90.0;
      final towerAreaTop = goalHeight + 10;
      final towerAreaBottom = h - 40;
      final towerAreaHeight = towerAreaBottom - towerAreaTop;
      final towerSpacing = w / (_numTowers + 1);
      final maxDiskWidth = (towerSpacing * 0.85).clamp(30.0, 120.0);
      final minDiskWidth = maxDiskWidth * 0.3;
      final diskHeight = (towerAreaHeight / (_numPlanets + 3)).clamp(14.0, 28.0);
      return GestureDetector(
        onTapDown: (details) {
          if (_won) return;
          final tapX = details.localPosition.dx;
          final tapY = details.localPosition.dy;
          if (tapY < goalHeight) return; // ignore taps on goal area
          for (int i = 0; i < _numTowers; i++) {
            final cx = towerSpacing * (i + 1);
            if ((tapX - cx).abs() < towerSpacing * 0.45) { _onTapTower(i); return; }
          }
        },
        child: Container(color: const Color(0xFF050515), child: Stack(children: [
          CustomPaint(size: Size(w, h), painter: _HanoiStarsPainter()),

          // Goal configuration preview
          Positioned(
            top: 0, left: 0, right: 0, height: goalHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A25),
                border: Border(bottom: BorderSide(color: Color(0xFF333355))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  const Text('TARGET CONFIGURATION', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 10, color: Colors.amberAccent,
                    letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Expanded(child: _buildGoalPreview(w, goalHeight - 24)),
                ],
              ),
            ),
          ),

          // HUD below goal
          Positioned(top: goalHeight + 2, left: 16, right: 16, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: () => setState(() => _showMenu = true),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white38, size: 18)),
              Text('Puzzle $_stage', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amberAccent)),
              Text('Moves: $_moveCount', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
              GestureDetector(
                onTap: () => _startStage(_stage),
                child: const Icon(Icons.refresh, color: Colors.white38, size: 18),
              ),
            ],
          )),

          // Tower poles
          for (int i = 0; i < _numTowers; i++)
            Positioned(left: towerSpacing * (i + 1) - 3, top: towerAreaTop + 30,
              child: Container(width: 6, height: towerAreaHeight - 30,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF333344), Color(0xFF555566)])))),
          // Bases
          for (int i = 0; i < _numTowers; i++)
            Positioned(left: towerSpacing * (i + 1) - maxDiskWidth / 2 - 4, top: towerAreaBottom - 4,
              child: Container(width: maxDiskWidth + 8, height: 6,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: const Color(0xFF666677)))),

          // Planet disks
          for (int ti = 0; ti < _numTowers; ti++)
            for (int pi2 = 0; pi2 < _towers[ti].length; pi2++)
              _buildPlanetDisk(tower: ti, stackIndex: pi2, planet: _towers[ti][pi2],
                towerSpacing: towerSpacing, towerAreaBottom: towerAreaBottom,
                diskHeight: diskHeight, maxDiskWidth: maxDiskWidth, minDiskWidth: minDiskWidth),

          // Match indicators per tower
          for (int i = 0; i < _numTowers; i++)
            Positioned(
              left: towerSpacing * (i + 1) - 8, top: towerAreaBottom + 4,
              child: Icon(
                _towerMatches(i) ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: _towerMatches(i) ? Colors.greenAccent : Colors.white12,
              ),
            ),

          if (_won) _buildWinOverlay(),
        ])),
      );
    });
  }

  bool _towerMatches(int towerIdx) {
    if (towerIdx >= _towers.length || towerIdx >= _goalTowers.length) return false;
    final current = _towers[towerIdx];
    final goal = _goalTowers[towerIdx];
    if (current.length != goal.length) return false;
    for (int i = 0; i < current.length; i++) {
      if (current[i].sizeRank != goal[i].sizeRank) return false;
    }
    return true;
  }

  Widget _buildGoalPreview(double totalWidth, double previewHeight) {
    final spacing = totalWidth / (_numTowers + 1);
    final miniDiskH = min(10.0, (previewHeight - 10) / (_numPlanets + 1));
    final miniMaxW = (spacing * 0.7).clamp(20.0, 60.0);
    final miniMinW = miniMaxW * 0.3;
    return Stack(
      children: [
        // Mini tower poles
        for (int i = 0; i < _numTowers; i++)
          Positioned(
            left: spacing * (i + 1) - 1,
            top: 4,
            child: Container(width: 2, height: previewHeight - 8,
              color: const Color(0xFF444466)),
          ),
        // Mini bases
        for (int i = 0; i < _numTowers; i++)
          Positioned(
            left: spacing * (i + 1) - miniMaxW / 2 - 2,
            bottom: 2,
            child: Container(width: miniMaxW + 4, height: 3,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(1.5), color: const Color(0xFF555577))),
          ),
        // Mini planet disks for goal state
        for (int ti = 0; ti < _numTowers; ti++)
          for (int pi2 = 0; pi2 < _goalTowers[ti].length; pi2++)
            Builder(builder: (context) {
              final planet = _goalTowers[ti][pi2];
              final fraction = (planet.sizeRank + 1) / _numPlanets;
              final diskW = miniMinW + (miniMaxW - miniMinW) * fraction;
              final cx = spacing * (ti + 1);
              final totalInTower = _goalTowers[ti].length;
              final fromBottom = totalInTower - 1 - pi2;
              final baseY = previewHeight - 6 - (fromBottom + 1) * (miniDiskH + 1);
              return Positioned(
                left: cx - diskW / 2,
                top: baseY,
                child: Container(
                  width: diskW, height: miniDiskH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(miniDiskH / 2),
                    color: planet.color,
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildWinOverlay() {
    return Center(child: Container(
      padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: const Color(0xDD101025), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Puzzle Solved!', style: TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        const SizedBox(height: 8),
        Text('Moves: $_moveCount', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white70)),
        if (_bestMoves[_stage] != null) Text('Best: ${_bestMoves[_stage]} moves', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(onTap: () => _startStage(_stage), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)), child: const Text('Retry', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)))),
          const SizedBox(width: 12),
          GestureDetector(onTap: () => _startStage(_stage + 1), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.amber.withValues(alpha: 0.2), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5))), child: const Text('Next Puzzle', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)))),
        ]),
        const SizedBox(height: 8),
        GestureDetector(onTap: () => setState(() => _showMenu = true), child: const Text('Puzzle Select', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white38, decoration: TextDecoration.underline))),
      ]),
    ));
  }

  Widget _buildPlanetDisk({required int tower, required int stackIndex, required _HanoiPlanet planet, required double towerSpacing, required double towerAreaBottom, required double diskHeight, required double maxDiskWidth, required double minDiskWidth}) {
    final isSelected = _selectedTower == tower && stackIndex == 0;
    final isShaking = _shakeTower == tower && stackIndex == 0;
    final fraction = (planet.sizeRank + 1) / _numPlanets;
    final diskWidth = minDiskWidth + (maxDiskWidth - minDiskWidth) * fraction;
    final cx = towerSpacing * (tower + 1);
    final totalDisks = _towers[tower].length;
    final diskFromBottom = totalDisks - 1 - stackIndex;
    final baseY = towerAreaBottom - 6 - (diskFromBottom + 1) * (diskHeight + 2);
    final liftY = isSelected ? -30.0 : 0.0;
    final shakeX = isShaking ? _shakeOffset() : 0.0;
    return Positioned(left: cx - diskWidth / 2 + shakeX, top: baseY + liftY,
      child: AnimatedBuilder(animation: _glowAnim, builder: (context, child) {
        return Container(width: diskWidth, height: diskHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(diskHeight / 2),
            boxShadow: isSelected ? [BoxShadow(color: planet.color.withValues(alpha: _glowAnim.value * 0.7), blurRadius: 12, spreadRadius: 3)] : [BoxShadow(color: planet.color.withValues(alpha: 0.3), blurRadius: 4)],
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(planet.color, Colors.white, 0.3)!, planet.color, Color.lerp(planet.color, Colors.black, 0.3)!]),
          ),
          child: Center(child: Text(planet.name, style: TextStyle(fontFamily: 'Avenir', fontSize: (diskHeight * 0.45).clamp(8.0, 12.0), fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)), overflow: TextOverflow.ellipsis)),
        );
      }),
    );
  }
}

class _HanoiStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 100; i++) {
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height), 0.3 + rng.nextDouble() * 0.8, Paint()..color = Colors.white.withValues(alpha: 0.05 + rng.nextDouble() * 0.15));
    }
  }

  @override
  bool shouldRepaint(covariant _HanoiStarsPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. GalaxyCollectorGame — "Galaxy Builder"
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyCollectorGame extends StatefulWidget {
  const GalaxyCollectorGame({Key? key}) : super(key: key);
  @override
  State<GalaxyCollectorGame> createState() => _GalaxyCollectorGameState();
}

enum _GBPhase { start, playing, gameOver }

class _GBStar {
  double x, y, life, maxLife;
  Color color;
  int points;
  bool collected;
  double scale;
  bool hostile;
  _GBStar(this.x, this.y, this.life, this.color, this.points, {this.hostile = false}) : maxLife = life, collected = false, scale = 0.0;
}

class _GBBlackHole {
  double x, y, life;
  _GBBlackHole(this.x, this.y, this.life);
}

class _GBZipTrail {
  double sx, sy, tx, ty, t;
  Color color;
  _GBZipTrail(this.sx, this.sy, this.tx, this.ty, this.color) : t = 0.0;
}

class _GBCreature {
  double x, y, vx, vy, size, age;
  _GBCreature(this.x, this.y, this.vx, this.vy) : size = 0.02, age = 0;
}

class _GalaxyCollectorGameState extends State<GalaxyCollectorGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();
  final FocusNode _focusNode = FocusNode();
  _GBPhase _phase = _GBPhase.start;
  double _cx = 0.5, _cy = 0.5, _kbDx = 0, _kbDy = 0;
  int _score = 0, _galaxyStars = 0, _missCount = 0, _streak = 0, _bestStreak = 0;
  int _multiplier = 1, _multiplierRemaining = 0, _galaxyLevel = 1, _highScore = 0;
  int _lives = 3;
  double _playerSize = 0.035;
  double _galaxyAngle = 0, _milestoneTimer = 0, _darkFlash = 0;
  String? _milestoneText;
  DateTime? _startTime;
  final List<_GBStar> _stars = [];
  final List<_GBBlackHole> _blackHoles = [];
  final List<_GBCreature> _creatures = [];
  final List<_JuiceParticle> _particles = [];
  final List<_GBZipTrail> _zipTrails = [];
  int get _spiralArms => _galaxyLevel.clamp(1, 8);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))..addListener(_tick)..forward();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _highScore = prefs.getInt('galaxy_builder_high_score') ?? 0; });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('galaxy_builder_high_score', _score);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _focusNode.dispose(); super.dispose(); }

  void _startGame() {
    setState(() {
      _phase = _GBPhase.playing; _cx = 0.5; _cy = 0.5; _kbDx = 0; _kbDy = 0;
      _score = 0; _galaxyStars = 0; _missCount = 0; _streak = 0; _bestStreak = 0;
      _multiplier = 1; _multiplierRemaining = 0; _galaxyLevel = 1; _galaxyAngle = 0;
      _lives = 3; _playerSize = 0.035;
      _milestoneText = null; _milestoneTimer = 0; _darkFlash = 0;
      _stars.clear(); _blackHoles.clear(); _creatures.clear(); _particles.clear(); _zipTrails.clear();
      _startTime = DateTime.now();
    });
    _focusNode.requestFocus();
  }

  void _endGame() { _saveHighScore(); setState(() { _phase = _GBPhase.gameOver; }); }

  void _tick() {
    if (_phase != _GBPhase.playing) return;
    const dt = 1 / 60.0;
    setState(() {
      _galaxyAngle += dt * 0.3;
      if (_kbDx != 0 || _kbDy != 0) { _cx += _kbDx * dt * 0.8; _cy += _kbDy * dt * 0.8; }

      // Stars spawn faster and fade faster as level increases
      final spawnChance = 0.04 + _galaxyLevel * 0.014;
      if (_rng.nextDouble() < spawnChance) {
        final roll = _rng.nextDouble();
        Color c; int pts; bool hostile = false;
        final hostileChance = (_galaxyLevel - 1) * 0.05; // 0% at lv1, ~20% at lv5
        if (_rng.nextDouble() < hostileChance) {
          c = const Color(0xFFFF1744); pts = 0; hostile = true;
        } else if (roll < 0.5) { c = Colors.white; pts = 1; }
        else if (roll < 0.8) { c = Colors.yellowAccent; pts = 2; }
        else { c = const Color(0xFF88CCFF); pts = 3; }
        double sx = _rng.nextDouble() * 0.95 + 0.025;
        double sy = _rng.nextDouble() * 0.85 + 0.12;
        if (sx > 0.75 && sy < 0.2) sx = _rng.nextDouble() * 0.7 + 0.025;
        final starLife = hostile
            ? 3.0 + _rng.nextDouble() * 2.0
            : (2.5 - _galaxyLevel * 0.12).clamp(1.3, 2.5) + _rng.nextDouble() * 0.5;
        _stars.add(_GBStar(sx, sy, starLife, c, pts, hostile: hostile));
      }

      final maxBH = 1 + (_galaxyLevel ~/ 2);
      if (_rng.nextDouble() < 0.002 + _galaxyLevel * 0.001 && _blackHoles.length < maxBH) {
        _blackHoles.add(_GBBlackHole(_rng.nextDouble() * 0.8 + 0.1, _rng.nextDouble() * 0.7 + 0.2, 5.0));
      }

      for (final s in _stars) { if (s.scale < 1.0) s.scale = (s.scale + dt / 0.3).clamp(0.0, 1.0); s.life -= dt; }
      for (final s in _stars) {
        if (s.life <= 0 && !s.collected && !s.hostile) {
          _missCount++; _streak = 0; _multiplier = 1; _multiplierRemaining = 0;
          if (_missCount >= 15) { _endGame(); return; }
        }
      }
      _stars.removeWhere((s) => s.life <= 0);

      for (final bh in _blackHoles) {
        final dx = bh.x - _cx; final dy = bh.y - _cy;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.05, 2.0);
        _cx += dx / dist * (0.0008 / (dist * dist)); _cy += dy / dist * (0.0008 / (dist * dist));
        if (dist < 0.05) {
          final stolen = min(_galaxyStars, 5);
          if (stolen > 0) { _galaxyStars -= stolen; _score = max(0, _score - stolen); _darkFlash = 0.5; _spawnBurst(bh.x, bh.y, Colors.purpleAccent, 10); _galaxyLevel = _calcLevel(_galaxyStars); }
        }
        bh.life -= dt;
      }
      _blackHoles.removeWhere((bh) => bh.life <= 0);

      // Creature spawning — dark matter entities from level 3+
      if (_galaxyLevel >= 3 && _rng.nextDouble() < 0.003 + (_galaxyLevel - 3) * 0.002 && _creatures.length < _galaxyLevel - 1) {
        final edge = _rng.nextInt(4);
        double cx2, cy2;
        switch (edge) {
          case 0: cx2 = _rng.nextDouble(); cy2 = -0.05; break;
          case 1: cx2 = 1.05; cy2 = _rng.nextDouble(); break;
          case 2: cx2 = _rng.nextDouble(); cy2 = 1.05; break;
          default: cx2 = -0.05; cy2 = _rng.nextDouble();
        }
        _creatures.add(_GBCreature(cx2, cy2, 0, 0));
      }

      // Creature AI — chase player
      for (final cr in _creatures) {
        cr.age += dt;
        final cdx = _cx - cr.x; final cdy = _cy - cr.y;
        final cdist = sqrt(cdx * cdx + cdy * cdy).clamp(0.01, 2.0);
        final chaseSpeed = 0.15 + _galaxyLevel * 0.02;
        cr.vx += (cdx / cdist) * chaseSpeed * dt;
        cr.vy += (cdy / cdist) * chaseSpeed * dt;
        final spd = sqrt(cr.vx * cr.vx + cr.vy * cr.vy);
        final maxSpd = 0.12 + _galaxyLevel * 0.01;
        if (spd > maxSpd) { cr.vx = cr.vx / spd * maxSpd; cr.vy = cr.vy / spd * maxSpd; }
        cr.x += cr.vx * dt; cr.y += cr.vy * dt;
        cr.size = (0.02 + cr.age * 0.002).clamp(0.02, 0.04);
        if (cdist < _playerSize + cr.size * 0.5) {
          _lives--; _darkFlash = 0.5; _streak = 0; _multiplier = 1; _multiplierRemaining = 0;
          _spawnBurst(cr.x, cr.y, Colors.deepPurple, 12);
          cr.x = -2; // mark for removal
          if (_lives <= 0) { _endGame(); return; }
        }
      }
      _creatures.removeWhere((c) => c.x < -1 || c.x > 2 || c.y < -1 || c.y > 2);

      // Star collection
      for (final s in _stars) {
        if (s.collected) continue;
        if (sqrt((_cx - s.x) * (_cx - s.x) + (_cy - s.y) * (_cy - s.y)) < _playerSize) {
          s.collected = true;
          if (s.hostile) {
            // Hostile star — damage!
            _lives--; _darkFlash = 0.4; _streak = 0; _multiplier = 1; _multiplierRemaining = 0;
            _spawnBurst(s.x, s.y, const Color(0xFFFF1744), 8);
            if (_lives <= 0) { _endGame(); return; }
          } else {
            _score += s.points * _multiplier; _galaxyStars++; _streak++;
            if (_streak > _bestStreak) _bestStreak = _streak;
            if (_streak % 5 == 0 && _streak > 0) { _multiplier = 2; _multiplierRemaining = 5; }
            if (_multiplierRemaining > 0 && _multiplier == 2) { _multiplierRemaining--; if (_multiplierRemaining <= 0) _multiplier = 1; }
            _zipTrails.add(_GBZipTrail(s.x, s.y, 0.92, 0.08, s.color));
            _spawnBurst(s.x, s.y, s.color, 4);
            // Player grows as they collect
            _playerSize = (0.035 + _galaxyStars * 0.0008).clamp(0.035, 0.07);
            final ol = _galaxyLevel; _galaxyLevel = _calcLevel(_galaxyStars);
            if (_galaxyLevel > ol) _showMs('Galaxy Level $_galaxyLevel!');
            if (_galaxyStars == 10) _showMs('10 Stars! Galaxy forming...');
            if (_galaxyStars == 25) _showMs('25 Stars! Spiral emerging!');
            if (_galaxyStars == 50) _showMs('50 Stars! Beautiful galaxy!');
            if (_galaxyStars == 100) _showMs('100 Stars! Magnificent!');
          }
        }
      }
      _cx = _cx.clamp(0.02, 0.98); _cy = _cy.clamp(0.02, 0.98);
      for (final z in _zipTrails) z.t += dt * 3.0;
      _zipTrails.removeWhere((z) => z.t >= 1.0);
      for (final p in _particles) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; }
      _particles.removeWhere((p) => p.life <= 0);
      if (_milestoneTimer > 0) { _milestoneTimer -= dt; if (_milestoneTimer <= 0) _milestoneText = null; }
      if (_darkFlash > 0) _darkFlash = (_darkFlash - dt * 2).clamp(0.0, 1.0);
    });
  }

  int _calcLevel(int s) { if (s >= 100) return 5 + (s - 100) ~/ 25; if (s >= 50) return 4; if (s >= 25) return 3; if (s >= 10) return 2; return 1; }
  void _showMs(String t) { _milestoneText = t; _milestoneTimer = 2.0; }
  void _spawnBurst(double x, double y, Color c, int n) { for (int i = 0; i < n; i++) _particles.add(_JuiceParticle(x: x, y: y, vx: (_rng.nextDouble() - 0.5) * 0.4, vy: (_rng.nextDouble() - 0.5) * 0.4, life: 0.4 + _rng.nextDouble() * 0.3, color: c, radius: 2)); }
  String _fmtDur(Duration d) => '${d.inMinutes}m ${d.inSeconds % 60}s';

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey; final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    double dx = 0, dy = 0;
    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) dy = -1;
    if (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown) dy = 1;
    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) dx = -1;
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.arrowRight) dx = 1;
    if (dx != 0 || dy != 0) { setState(() { if (isDown) { _kbDx = dx; _kbDy = dy; } else { if (dx != 0) _kbDx = 0; if (dy != 0) _kbDy = 0; } }); return KeyEventResult.handled; }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, autofocus: true, onKeyEvent: _handleKey,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth, h = constraints.maxHeight;
        if (_phase == _GBPhase.start) return _buildStart();
        if (_phase == _GBPhase.gameOver) return _buildOver();
        return GestureDetector(
          onPanStart: (d) => setState(() { _cx = (d.localPosition.dx / w).clamp(0.02, 0.98); _cy = (d.localPosition.dy / h).clamp(0.02, 0.98); }),
          onPanUpdate: (d) => setState(() { _cx = (d.localPosition.dx / w).clamp(0.02, 0.98); _cy = (d.localPosition.dy / h).clamp(0.02, 0.98); }),
          onTapDown: (d) => setState(() { _cx = (d.localPosition.dx / w).clamp(0.02, 0.98); _cy = (d.localPosition.dy / h).clamp(0.02, 0.98); }),
          child: Container(color: Colors.black, child: CustomPaint(
            painter: _GalaxyBuilderPainter(cx: _cx, cy: _cy, stars: _stars, blackHoles: _blackHoles, creatures: _creatures, particles: _particles, zipTrails: _zipTrails, galaxyStars: _galaxyStars, galaxyAngle: _galaxyAngle, spiralArms: _spiralArms, darkFlash: _darkFlash, playerSize: _playerSize, lives: _lives),
            child: Stack(children: [
              Positioned(top: 8, left: 12, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Stars: $_score${_multiplier > 1 ? '  ${_multiplier}x!' : ''}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    Text('Galaxy Lv $_galaxyLevel', style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white54)),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('GOAL: Catch glowing stars before they fade', style: TextStyle(fontFamily: 'Avenir', fontSize: 9, color: Colors.white.withValues(alpha: 0.35))),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      ...List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(Icons.favorite, size: 14, color: i < _lives ? const Color(0xFFFF5252) : Colors.white12),
                      )),
                      const SizedBox(width: 6),
                      ...List.generate(15, (i) => Container(
                        margin: const EdgeInsets.only(left: 1), width: 3, height: 3,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i < (15 - _missCount) ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.1)),
                      )),
                    ]),
                  ]),
                ]),
              )),
              if (_milestoneText != null) Positioned(top: 80, left: 0, right: 0, child: Center(child: Text(_milestoneText!, style: TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent.withValues(alpha: (_milestoneTimer / 2.0).clamp(0.0, 1.0)))))),
            ]),
          )),
        );
      }),
    );
  }

  Widget _buildStart() {
    return GestureDetector(onTap: _startGame, child: Container(color: Colors.black, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Galaxy Builder', style: TextStyle(fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 12),
      const Text('Catch stars before they fade.\nAvoid red stars and dark matter.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.white54)),
      const SizedBox(height: 20),
      if (_highScore > 0) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.amberAccent))),
      const Text('Tap to Play', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.cyanAccent)),
    ]))));
  }

  Widget _buildOver() {
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    return GestureDetector(onTap: _startGame, child: Container(color: Colors.black, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('The universe went dark...', style: TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70)),
      const SizedBox(height: 20),
      Text('Stars Collected: $_galaxyStars', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.amberAccent)),
      const SizedBox(height: 4),
      Text('Galaxy Level: $_galaxyLevel', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.cyanAccent)),
      const SizedBox(height: 4),
      Text('Best Streak: $_bestStreak', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.orangeAccent)),
      const SizedBox(height: 4),
      Text('Time: ${_fmtDur(elapsed)}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
      const SizedBox(height: 12),
      if (_score >= _highScore && _score > 0) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('New High Score!', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent))),
      Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.white38)),
      const SizedBox(height: 20),
      const Text('Build Again', style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.cyanAccent)),
    ]))));
  }
}

class _GalaxyBuilderPainter extends CustomPainter {
  final double cx, cy, playerSize;
  final List<_GBStar> stars;
  final List<_GBBlackHole> blackHoles;
  final List<_GBCreature> creatures;
  final List<_JuiceParticle> particles;
  final List<_GBZipTrail> zipTrails;
  final int galaxyStars, spiralArms, lives;
  final double galaxyAngle, darkFlash;
  _GalaxyBuilderPainter({required this.cx, required this.cy, required this.stars, required this.blackHoles, required this.creatures, required this.particles, required this.zipTrails, required this.galaxyStars, required this.galaxyAngle, required this.spiralArms, required this.darkFlash, required this.playerSize, required this.lives});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    for (int i = 0; i < 60; i++) canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height), 0.3 + rng.nextDouble() * 0.6, Paint()..color = Colors.white.withValues(alpha: 0.06 + rng.nextDouble() * 0.04));

    final gc = Offset(size.width - 45, 50);
    if (galaxyStars > 0) canvas.drawCircle(gc, 15.0 + min(galaxyStars.toDouble(), 100.0) * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.03));
    for (int i = 0; i < min(galaxyStars, 300); i++) {
      final arm = i % spiralArms;
      final aa = galaxyAngle + arm * (2 * pi / spiralArms);
      final r = 3.0 + i * 0.15;
      final sa = aa + r * 0.12;
      final sr = Random(i * 7 + 3);
      final sc = sr.nextDouble() * 3.0 - 1.5;
      canvas.drawCircle(Offset(gc.dx + cos(sa) * (r + sc), gc.dy + sin(sa) * (r + sc)), 0.8 + sr.nextDouble() * 0.6, Paint()..color = HSVColor.fromAHSV(0.7, (i * 25.0 + arm * 60) % 360, 0.4, 0.9).toColor());
    }
    if (galaxyStars > 0) { canvas.drawCircle(gc, 3, Paint()..color = Colors.white.withValues(alpha: 0.6)); canvas.drawCircle(gc, 5, Paint()..color = Colors.white.withValues(alpha: 0.15)); }

    for (final s in stars) {
      if (s.collected) continue;
      final lr = (s.life / s.maxLife).clamp(0.0, 1.0);
      final fade = lr < 0.3 ? lr / 0.3 : 1.0;
      final a = fade * s.scale;
      final sx = s.x * size.width, sy = s.y * size.height;
      final sr = 3.0 * s.scale;
      if (s.hostile) {
        // Hostile star — spiky red with pulsing glow
        canvas.drawCircle(Offset(sx, sy), sr * 3.0, Paint()..color = const Color(0xFFFF1744).withValues(alpha: a * 0.12));
        final spikePath = Path();
        const spikes = 6;
        for (int i = 0; i < spikes * 2; i++) {
          final ag = i * pi / spikes - pi / 2;
          final r = i.isEven ? sr * 2.2 : sr * 0.8;
          final px = sx + cos(ag) * r, py = sy + sin(ag) * r;
          if (i == 0) spikePath.moveTo(px, py); else spikePath.lineTo(px, py);
        }
        spikePath.close();
        canvas.drawPath(spikePath, Paint()..color = const Color(0xFFFF1744).withValues(alpha: a * 0.7));
        canvas.drawPath(spikePath, Paint()..color = const Color(0xFFFF5252).withValues(alpha: a * 0.5)..style = PaintingStyle.stroke..strokeWidth = 1);
        canvas.drawCircle(Offset(sx, sy), sr * 0.5, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
      } else {
        canvas.drawCircle(Offset(sx, sy), sr * 2.5, Paint()..color = s.color.withValues(alpha: a * 0.15));
        canvas.drawCircle(Offset(sx, sy), sr * 1.5, Paint()..color = s.color.withValues(alpha: a * 0.3));
        canvas.drawCircle(Offset(sx, sy), sr, Paint()..color = s.color.withValues(alpha: a));
      }
    }

    for (final bh in blackHoles) {
      final bx = bh.x * size.width, by = bh.y * size.height;
      final la = (bh.life / 5.0).clamp(0.0, 1.0);
      final pp = Paint()..color = Colors.purple.withValues(alpha: 0.08 * la)..strokeWidth = 0.5;
      for (int i = 0; i < 12; i++) { final ag = i * pi / 6; canvas.drawLine(Offset(bx + cos(ag) * 35, by + sin(ag) * 35), Offset(bx + cos(ag) * 10, by + sin(ag) * 10), pp); }
      canvas.drawCircle(Offset(bx, by), 22, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.06 * la));
      canvas.drawCircle(Offset(bx, by), 14, Paint()..color = Colors.deepPurple.withValues(alpha: 0.25 * la));
      canvas.drawCircle(Offset(bx, by), 7, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(bx, by), 8, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.5 * la)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // Dark matter creatures
    for (final cr in creatures) {
      final crx = cr.x * size.width, cry = cr.y * size.height;
      final crr = cr.size * size.width * 0.5;
      final ca = (cr.age * 2).clamp(0.0, 1.0);
      // Tendrils
      for (int i = 0; i < 5; i++) {
        final ag = cr.age * 1.5 + i * pi * 2 / 5;
        final tx = crx + cos(ag) * crr * 2.5;
        final ty = cry + sin(ag) * crr * 2.5;
        canvas.drawLine(Offset(crx, cry), Offset(tx, ty), Paint()..color = Colors.deepPurple.withValues(alpha: 0.3 * ca)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
      }
      canvas.drawCircle(Offset(crx, cry), crr * 1.8, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.06 * ca));
      canvas.drawCircle(Offset(crx, cry), crr, Paint()..color = Colors.deepPurple.withValues(alpha: 0.6 * ca));
      canvas.drawCircle(Offset(crx, cry), crr * 0.5, Paint()..color = const Color(0xFFFF1744).withValues(alpha: 0.5 * ca));
      canvas.drawCircle(Offset(crx, cry), crr, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.4 * ca)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    for (final z in zipTrails) {
      final t = z.t.clamp(0.0, 1.0); final et = t * t;
      final ta = (1.0 - t).clamp(0.0, 1.0);
      for (int i = 0; i < 4; i++) { final tt = (t - i * 0.05).clamp(0.0, 1.0); final te = tt * tt; canvas.drawCircle(Offset((z.sx + (z.tx - z.sx) * te) * size.width, (z.sy + (z.ty - z.sy) * te) * size.height), 1.5 - i * 0.3, Paint()..color = z.color.withValues(alpha: ta * (1.0 - i * 0.2))); }
      canvas.drawCircle(Offset((z.sx + (z.tx - z.sx) * et) * size.width, (z.sy + (z.ty - z.sy) * et) * size.height), 2.5, Paint()..color = z.color.withValues(alpha: ta));
    }

    // Player — grows with stars collected
    final cx2 = cx * size.width, cy2 = cy * size.height;
    final pr = playerSize * size.width; // player radius in pixels
    canvas.drawCircle(Offset(cx2, cy2), pr * 1.4, Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(Offset(cx2, cy2), pr, Paint()..color = Colors.white.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(Offset(cx2, cy2), pr * 0.6, Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawCircle(Offset(cx2, cy2), pr * 0.35, Paint()..color = Colors.white);

    for (final p in particles) { if (p.life > 0) canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.radius, Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0))); }

    if (darkFlash > 0) canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withValues(alpha: darkFlash * 0.6));
  }

  @override
  bool shouldRepaint(covariant _GalaxyBuilderPainter old) => true;
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
// NeuronConnectGame — "Signal Router"
// Route electrical signals through a neural network by rotating gate directions
// ═══════════════════════════════════════════════════════════════════════════════

/// Direction a gate routes the signal.
enum _GateDir { up, right, down, left }

/// Grid offset produced by each direction.
const Map<_GateDir, List<int>> _gateDelta = {
  _GateDir.up: [0, -1],
  _GateDir.right: [1, 0],
  _GateDir.down: [0, 1],
  _GateDir.left: [-1, 0],
};

/// Type of a node on the puzzle grid.
enum _SRNodeType { normal, source, target, blocker }

/// A single node in the puzzle grid.
class _SRNode {
  _SRNodeType type;
  _GateDir dir;
  final _GateDir initialDir;
  final bool locked;
  _SRNode({
    required this.type,
    required this.dir,
    this.locked = false,
  }) : initialDir = dir;

  void resetDir() => dir = initialDir;
}

/// Definition of a single level.
class _SRLevel {
  final int cols;
  final int rows;
  final List<_SRNode> nodes;
  final int minRotations;
  final String? tutorialText;

  _SRLevel({
    required this.cols,
    required this.rows,
    required this.nodes,
    required this.minRotations,
    this.tutorialText,
  });
}

/// One signal travelling through the grid during animation.
class _SRSignal {
  int col, row;
  int nextCol, nextRow;
  double t;
  bool dead;
  bool arrived;
  final List<List<int>> trail;
  final int id;
  _SRSignal({
    required this.col,
    required this.row,
    required this.id,
  })  : nextCol = col,
        nextRow = row,
        t = 0,
        dead = false,
        arrived = false,
        trail = [
          [col, row]
        ];
}

// ---------------------------------------------------------------------------
// Level definitions
// ---------------------------------------------------------------------------

List<_SRLevel> _buildHandcraftedLevels() {
  _SRNode n(_SRNodeType type, _GateDir dir, {bool locked = false}) =>
      _SRNode(type: type, dir: dir, locked: locked);

  const normal = _SRNodeType.normal;
  const source = _SRNodeType.source;
  const target = _SRNodeType.target;
  const blocker = _SRNodeType.blocker;
  const up = _GateDir.up;
  const right = _GateDir.right;
  const down = _GateDir.down;
  const left = _GateDir.left;

  return [
    // Level 1: 3x3, source top-left, target bottom-right, 2 rotations
    _SRLevel(
      cols: 3, rows: 3, minRotations: 2,
      tutorialText: 'Tap nodes to rotate arrows.\nGuide the signal to the red node.',
      nodes: [
        n(source, right), n(normal, up),    n(normal, down),
        n(normal, down),  n(normal, right), n(normal, left),
        n(normal, right), n(normal, up),    n(target, left),
      ],
    ),
    // Level 2: 3x3, source top-right, target bottom-left, 3 rotations
    _SRLevel(
      cols: 3, rows: 3, minRotations: 3,
      nodes: [
        n(normal, down),  n(normal, up),   n(source, down),
        n(normal, right), n(normal, up),   n(normal, up),
        n(target, right), n(normal, left), n(normal, left),
      ],
    ),
    // Level 3: 4x3, blockers introduced
    _SRLevel(
      cols: 4, rows: 3, minRotations: 3,
      nodes: [
        n(source, right), n(normal, right),  n(normal, up),     n(normal, down),
        n(normal, up),    n(blocker, right), n(normal, up),     n(normal, down),
        n(normal, right), n(normal, right),  n(blocker, right), n(target, left),
      ],
    ),
    // Level 4: 4x4, locked nodes, single valid path
    _SRLevel(
      cols: 4, rows: 4, minRotations: 4,
      nodes: [
        n(source, down),             n(normal, left, locked: true), n(normal, down),  n(normal, left),
        n(normal, right),            n(normal, up),                 n(blocker, right), n(normal, down),
        n(normal, up, locked: true), n(normal, right),              n(normal, down),  n(normal, left),
        n(normal, right),            n(blocker, right),             n(normal, right), n(target, left),
      ],
    ),
    // Level 5: 5x4, two sources, two targets, both must arrive
    _SRLevel(
      cols: 5, rows: 4, minRotations: 5,
      nodes: [
        n(source, down),  n(normal, up),    n(blocker, right), n(normal, down),  n(source, down),
        n(normal, right), n(normal, right), n(normal, down),   n(normal, left),  n(normal, left),
        n(normal, up),    n(normal, down),  n(normal, right),  n(normal, up),    n(normal, down),
        n(target, up),    n(normal, right), n(blocker, right), n(normal, left),  n(target, up),
      ],
    ),
  ];
}

/// Procedurally generate a level for indices >= 5.
_SRLevel _generateProceduralLevel(int levelIndex, Random rng) {
  final cols = 4 + ((levelIndex - 5) ~/ 2).clamp(0, 4);
  final rows = 4 + ((levelIndex - 4) ~/ 3).clamp(0, 3);
  final dirs = _GateDir.values;
  final totalNodes = cols * rows;

  final nodes = List<_SRNode>.generate(totalNodes, (i) {
    final col = i % cols;
    final row = i ~/ cols;
    if (col == 0 && row == 0) {
      return _SRNode(type: _SRNodeType.source, dir: _GateDir.right);
    }
    if (col == cols - 1 && row == rows - 1) {
      return _SRNode(type: _SRNodeType.target, dir: _GateDir.left);
    }
    if (col > 0 && row > 0 && col < cols - 1 && row < rows - 1 && rng.nextDouble() < 0.12) {
      return _SRNode(type: _SRNodeType.blocker, dir: _GateDir.right);
    }
    final locked = rng.nextDouble() < 0.10;
    return _SRNode(type: _SRNodeType.normal, dir: dirs[rng.nextInt(4)], locked: locked);
  });

  // BFS to find a valid path, then scramble directions along it
  final visited = List<bool>.filled(totalNodes, false);
  final parent = List<int>.filled(totalNodes, -1);
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
      if (visited[ni]) continue;
      if (nodes[ni].type == _SRNodeType.blocker) continue;
      visited[ni] = true;
      parent[ni] = cur;
      queue.add(ni);
      if (ni == totalNodes - 1) { found = true; break; }
    }
  }

  if (found) {
    int cur = totalNodes - 1;
    while (parent[cur] != -1) {
      final prev = parent[cur];
      final px = prev % cols;
      final py = prev ~/ cols;
      final cx2 = cur % cols;
      final cy2 = cur ~/ cols;
      final dx = cx2 - px;
      final dy = cy2 - py;
      _GateDir needed;
      if (dx == 1) { needed = _GateDir.right; }
      else if (dx == -1) { needed = _GateDir.left; }
      else if (dy == 1) { needed = _GateDir.down; }
      else { needed = _GateDir.up; }

      if (nodes[prev].type != _SRNodeType.target && !nodes[prev].locked) {
        final rotations = 1 + rng.nextInt(3);
        int idx = _GateDir.values.indexOf(needed);
        idx = (idx + rotations) % 4;
        nodes[prev] = _SRNode(type: nodes[prev].type, dir: _GateDir.values[idx], locked: nodes[prev].locked);
      } else if (nodes[prev].type != _SRNodeType.target && nodes[prev].locked) {
        nodes[prev] = _SRNode(type: nodes[prev].type, dir: needed, locked: true);
      }
      cur = prev;
    }
  }

  return _SRLevel(cols: cols, rows: rows, nodes: nodes, minRotations: 3 + levelIndex);
}

class NeuronConnectGame extends StatefulWidget {
  const NeuronConnectGame({Key? key}) : super(key: key);
  @override
  State<NeuronConnectGame> createState() => _NeuronConnectGameState();
}

class _NeuronConnectGameState extends State<NeuronConnectGame>
    with SingleTickerProviderStateMixin {
  static const _prefsKey = 'neuron_connect_stars';
  static const int _totalLevelsShown = 12;

  late AnimationController _ctrl;
  final Random _rng = Random();

  Map<int, int> _starData = {};
  bool _onLevelSelect = true;
  int _currentLevel = 0;
  late _SRLevel _level;
  int _moveCount = 0;
  List<_SRNode> _playNodes = [];
  List<_SRSignal> _activeSignals = [];
  bool _animating = false;
  double _lastTime = 0;
  bool _levelComplete = false;
  bool _signalDead = false;
  final List<_JuiceParticle> _particles = [];

  int get _unlockedUpTo {
    int m = 0;
    for (int i = 0; i < _totalLevelsShown; i++) {
      if (_starData.containsKey(i)) { m = i + 1; } else { break; }
    }
    return m.clamp(0, _totalLevelsShown - 1);
  }

  int get _totalStars => _starData.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
    _lastTime = _now();
    _loadStars();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadStars() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _starData = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveStars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_starData.map((k, v) => MapEntry(k.toString(), v))));
  }

  void _loadLevel(int index) {
    final handcrafted = _buildHandcraftedLevels();
    _level = index < handcrafted.length ? handcrafted[index] : _generateProceduralLevel(index, Random(index * 7 + 42));
    _playNodes = _level.nodes.map((n) => _SRNode(type: n.type, dir: n.dir, locked: n.locked)).toList();
    _moveCount = 0;
    _activeSignals.clear();
    _particles.clear();
    _animating = false;
    _levelComplete = false;
    _signalDead = false;
  }

  void _resetLevel() {
    setState(() {
      for (int i = 0; i < _playNodes.length; i++) {
        if (!_playNodes[i].locked) _playNodes[i].dir = _level.nodes[i].dir;
      }
      _moveCount = 0;
      _activeSignals.clear();
      _particles.clear();
      _animating = false;
      _levelComplete = false;
      _signalDead = false;
    });
  }

  void _rotateNode(int index) {
    if (_animating || _levelComplete) return;
    final node = _playNodes[index];
    if (node.type == _SRNodeType.blocker || node.locked) return;
    setState(() {
      node.dir = _GateDir.values[(_GateDir.values.indexOf(node.dir) + 1) % 4];
      _moveCount++;
      _signalDead = false;
    });
  }

  void _sendSignal() {
    if (_animating || _levelComplete) return;
    setState(() {
      _activeSignals.clear();
      _particles.clear();
      _signalDead = false;
      _animating = true;
      _lastTime = _now();
      int sigId = 0;
      for (int i = 0; i < _playNodes.length; i++) {
        if (_playNodes[i].type == _SRNodeType.source) {
          _activeSignals.add(_SRSignal(col: i % _level.cols, row: i ~/ _level.cols, id: sigId++));
        }
      }
      _ctrl.forward(from: 0);
    });
  }

  void _tick() {
    if (!_animating) return;
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      for (final p in _particles) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; }
      _particles.removeWhere((p) => p.life <= 0);

      bool anyMoving = false;
      for (final sig in _activeSignals) {
        if (sig.dead || sig.arrived) continue;
        anyMoving = true;
        sig.t += dt * 2.8;
        if (sig.t >= 1.0) {
          sig.col = sig.nextCol;
          sig.row = sig.nextRow;
          sig.t = 0;
          sig.trail.add([sig.col, sig.row]);

          final ni = sig.row * _level.cols + sig.col;
          if (_playNodes[ni].type == _SRNodeType.target) {
            sig.arrived = true;
            for (int i = 0; i < 12; i++) {
              final a = _rng.nextDouble() * 2 * pi;
              _particles.add(_JuiceParticle(x: sig.col.toDouble(), y: sig.row.toDouble(), vx: cos(a) * 1.5, vy: sin(a) * 1.5, life: 0.8, color: Colors.greenAccent));
            }
            continue;
          }

          final delta = _gateDelta[_playNodes[ni].dir]!;
          final ncol = sig.col + delta[0];
          final nrow = sig.row + delta[1];

          if (ncol < 0 || nrow < 0 || ncol >= _level.cols || nrow >= _level.rows) {
            sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble()); continue;
          }
          final nni = nrow * _level.cols + ncol;
          if (_playNodes[nni].type == _SRNodeType.blocker) {
            sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble()); continue;
          }
          if (sig.trail.any((p) => p[0] == ncol && p[1] == nrow)) {
            sig.dead = true; _spawnDeadParticles(sig.col.toDouble(), sig.row.toDouble()); continue;
          }
          sig.nextCol = ncol;
          sig.nextRow = nrow;
        }
      }

      if (!anyMoving || _activeSignals.every((s) => s.dead || s.arrived)) {
        if (_activeSignals.isNotEmpty && _activeSignals.every((s) => s.arrived)) {
          _levelComplete = true;
          _animating = false;
          int stars;
          if (_moveCount <= _level.minRotations) { stars = 3; }
          else if (_moveCount <= _level.minRotations * 2) { stars = 2; }
          else { stars = 1; }
          final prev = _starData[_currentLevel] ?? 0;
          if (stars > prev) { _starData[_currentLevel] = stars; _saveStars(); }
        } else if (_activeSignals.any((s) => s.dead)) {
          _signalDead = true;
          _animating = false;
        }
      }
    });
  }

  void _spawnDeadParticles(double x, double y) {
    for (int i = 0; i < 8; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      _particles.add(_JuiceParticle(x: x, y: y, vx: cos(a) * 1.5, vy: sin(a) * 1.5, life: 0.6, color: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onLevelSelect) return _buildLevelSelect();
    return _buildPuzzle();
  }

  Widget _buildLevelSelect() {
    return Container(
      color: const Color(0xFF080818),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 18),
          const Text('Signal Router', style: TextStyle(fontFamily: 'Avenir', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 2)),
          const SizedBox(height: 6),
          Text('Total Stars: $_totalStars / ${_totalLevelsShown * 3}', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amber.withValues(alpha: 0.8))),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                itemCount: _totalLevelsShown,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 14),
                itemBuilder: (context, index) {
                  final unlocked = index <= _unlockedUpTo;
                  final stars = _starData[index] ?? 0;
                  return GestureDetector(
                    onTap: unlocked ? () => setState(() { _currentLevel = index; _loadLevel(index); _onLevelSelect = false; }) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: unlocked ? const Color(0xFF152040) : const Color(0xFF0A0A14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: unlocked ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white10, width: 1.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${index + 1}', style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: unlocked ? Colors.white : Colors.white24)),
                        const SizedBox(height: 4),
                        if (unlocked)
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 14, color: i < stars ? Colors.amber : Colors.white24)))
                        else
                          const Icon(Icons.lock, size: 16, color: Colors.white24),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPuzzle() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Container(
        color: const Color(0xFF080818),
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (d) { if (!_animating) { final idx = _nodeAtPosition(d.localPosition, w, h); if (idx != null) _rotateNode(idx); } },
              child: CustomPaint(painter: _SignalRouterPainter(level: _level, nodes: _playNodes, signals: _activeSignals, particles: _particles, levelComplete: _levelComplete)),
            ),
          ),
          // Top bar
          Positioned(top: 8, left: 12, right: 12, child: Row(children: [
            GestureDetector(
              onTap: () => setState(() { _onLevelSelect = true; _animating = false; _ctrl.stop(); }),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.arrow_back, size: 18, color: Colors.white70)),
            ),
            const SizedBox(width: 10),
            Text('Level ${_currentLevel + 1}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            const Spacer(),
            Text('Moves: $_moveCount', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
          ])),
          // Tutorial text
          if (_level.tutorialText != null && !_animating && !_levelComplete && _moveCount == 0)
            Positioned(top: 40, left: 20, right: 20, child: Text(_level.tutorialText!, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white.withValues(alpha: 0.4)))),
          // Bottom buttons
          Positioned(bottom: 16, left: 20, right: 20, child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: _resetLevel,
              child: Container(height: 44, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24, width: 1)), alignment: Alignment.center, child: const Text('Reset', style: TextStyle(fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70))),
            )),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: GestureDetector(
              onTap: (_animating || _levelComplete) ? null : _sendSignal,
              child: Container(height: 44, decoration: BoxDecoration(color: (_animating || _levelComplete) ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF00B4D8), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(_levelComplete ? 'Solved!' : 'Send Signal', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: _levelComplete ? Colors.greenAccent : Colors.white))),
            )),
          ])),
          // Dead-end message
          if (_signalDead && !_animating)
            Positioned(bottom: 72, left: 20, right: 20, child: Center(child: Text('Signal lost! Rearrange arrows and try again.', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.redAccent.withValues(alpha: 0.8))))),
          // Level complete overlay
          if (_levelComplete)
            Positioned(bottom: 68, left: 20, right: 20, child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) {
                int stars;
                if (_moveCount <= _level.minRotations) { stars = 3; }
                else if (_moveCount <= _level.minRotations * 2) { stars = 2; }
                else { stars = 1; }
                return Icon(i < stars ? Icons.star : Icons.star_border, size: 28, color: i < stars ? Colors.amber : Colors.white24);
              })),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() { if (_currentLevel < _totalLevelsShown - 1) { _currentLevel++; _loadLevel(_currentLevel); } else { _onLevelSelect = true; } }),
                child: Container(height: 38, width: 160, decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.greenAccent, width: 1)), alignment: Alignment.center, child: Text(_currentLevel < _totalLevelsShown - 1 ? 'Next Level' : 'Back to Levels', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.greenAccent))),
              ),
            ])),
        ]),
      );
    });
  }

  int? _nodeAtPosition(Offset pos, double w, double h) {
    final cols = _level.cols;
    final rows = _level.rows;
    final cellSize = _gridCellSize(w, h, cols, rows);
    final gridW = cols * cellSize;
    final gridH = rows * cellSize;
    final ox = (w - gridW) / 2;
    final oy = (h - gridH) / 2;
    for (int i = 0; i < _playNodes.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final cx = ox + col * cellSize + cellSize / 2;
      final cy = oy + row * cellSize + cellSize / 2;
      if ((pos - Offset(cx, cy)).distance <= cellSize * 0.35 + 6) return i;
    }
    return null;
  }

  double _gridCellSize(double w, double h, int cols, int rows) {
    final cellW = (w - 40) / cols;
    final cellH = (h - 140) / rows;
    return cellW < cellH ? cellW : cellH;
  }
}

// ---------------------------------------------------------------------------
// Custom painter for the Signal Router puzzle grid
// ---------------------------------------------------------------------------

class _SignalRouterPainter extends CustomPainter {
  final _SRLevel level;
  final List<_SRNode> nodes;
  final List<_SRSignal> signals;
  final List<_JuiceParticle> particles;
  final bool levelComplete;

  _SignalRouterPainter({required this.level, required this.nodes, required this.signals, required this.particles, required this.levelComplete});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080818));
    final cols = level.cols;
    final rows = level.rows;
    final cellW = (size.width - 40) / cols;
    final cellH = (size.height - 140) / rows;
    final cellSize = cellW < cellH ? cellW : cellH;
    final gridW = cols * cellSize;
    final gridH = rows * cellSize;
    final ox = (size.width - gridW) / 2;
    final oy = (size.height - gridH) / 2;
    final nodeRadius = cellSize * 0.35;

    // Faint grid
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 0.5;
    for (int c = 0; c <= cols; c++) { final x = ox + c * cellSize; canvas.drawLine(Offset(x, oy), Offset(x, oy + gridH), gridPaint); }
    for (int r = 0; r <= rows; r++) { final y = oy + r * cellSize; canvas.drawLine(Offset(ox, y), Offset(ox + gridW, y), gridPaint); }

    // Nodes
    for (int i = 0; i < nodes.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final cx = ox + col * cellSize + cellSize / 2;
      final cy = oy + row * cellSize + cellSize / 2;
      final center = Offset(cx, cy);
      final node = nodes[i];

      if (node.type == _SRNodeType.blocker) {
        canvas.drawCircle(center, nodeRadius, Paint()..color = const Color(0xFF1A1A2A));
        canvas.drawCircle(center, nodeRadius, Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 1.5);
        final xPaint = Paint()..color = Colors.white24..strokeWidth = 2..strokeCap = StrokeCap.round;
        final xr = nodeRadius * 0.4;
        canvas.drawLine(Offset(cx - xr, cy - xr), Offset(cx + xr, cy + xr), xPaint);
        canvas.drawLine(Offset(cx + xr, cy - xr), Offset(cx - xr, cy + xr), xPaint);
        continue;
      }

      Color nodeColor;
      Color glowColor;
      switch (node.type) {
        case _SRNodeType.source: nodeColor = const Color(0xFF00E676); glowColor = Colors.greenAccent; break;
        case _SRNodeType.target: nodeColor = const Color(0xFFFF1744); glowColor = Colors.redAccent; break;
        default: nodeColor = const Color(0xFF4FC3F7); glowColor = Colors.cyanAccent;
      }

      canvas.drawCircle(center, nodeRadius + 6, Paint()..color = glowColor.withValues(alpha: 0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(center, nodeRadius, Paint()..color = nodeColor.withValues(alpha: node.locked ? 0.25 : 0.5));
      canvas.drawCircle(center, nodeRadius, Paint()..color = nodeColor.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 2);

      _drawArrow(canvas, center, node.dir, nodeRadius * 0.55, nodeColor.withValues(alpha: node.locked ? 0.4 : 0.9));

      if (node.type == _SRNodeType.source || node.type == _SRNodeType.target) {
        final label = node.type == _SRNodeType.source ? 'S' : 'T';
        final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(fontFamily: 'Avenir', fontSize: nodeRadius * 0.6, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.85))), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      }

      if (node.locked && node.type == _SRNodeType.normal) {
        final ls = nodeRadius * 0.3;
        final lp = Paint()..color = Colors.white30..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + nodeRadius * 0.28), width: ls, height: ls * 0.8), const Radius.circular(1)), lp);
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + nodeRadius * 0.28 - ls * 0.4), width: ls * 0.7, height: ls * 0.7), pi, pi, false, lp);
      }
    }

    // Signal trails
    for (final sig in signals) {
      if (sig.trail.length < 2) continue;
      final tp = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      if (sig.arrived) { tp.color = Colors.greenAccent.withValues(alpha: 0.6); }
      else if (sig.dead) { tp.color = Colors.redAccent.withValues(alpha: 0.5); }
      else { tp.color = Colors.yellowAccent.withValues(alpha: 0.4); }
      final path = ui.Path();
      for (int i = 0; i < sig.trail.length; i++) {
        final tx = ox + sig.trail[i][0] * cellSize + cellSize / 2;
        final ty = oy + sig.trail[i][1] * cellSize + cellSize / 2;
        if (i == 0) { path.moveTo(tx, ty); } else { path.lineTo(tx, ty); }
      }
      if (!sig.dead && !sig.arrived && sig.t > 0) {
        final fx = ox + sig.col * cellSize + cellSize / 2;
        final fy = oy + sig.row * cellSize + cellSize / 2;
        final tx = ox + sig.nextCol * cellSize + cellSize / 2;
        final ty = oy + sig.nextRow * cellSize + cellSize / 2;
        path.lineTo(fx + (tx - fx) * sig.t, fy + (ty - fy) * sig.t);
      }
      canvas.drawPath(path, tp);
    }

    // Signal dots
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
      canvas.drawCircle(Offset(sx, sy), 10, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.15));
      canvas.drawCircle(Offset(sx, sy), 6, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(sx, sy), 3, Paint()..color = Colors.white);
    }

    // Particles
    for (final p in particles) {
      if (p.life <= 0) continue;
      final px = ox + p.x * cellSize + cellSize / 2;
      final py = oy + p.y * cellSize + cellSize / 2;
      canvas.drawCircle(Offset(px, py), 3, Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)));
    }
  }

  void _drawArrow(Canvas canvas, Offset center, _GateDir dir, double length, Color color) {
    final paint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    double angle;
    switch (dir) { case _GateDir.up: angle = -pi / 2; break; case _GateDir.right: angle = 0; break; case _GateDir.down: angle = pi / 2; break; case _GateDir.left: angle = pi; }
    final tipX = center.dx + cos(angle) * length;
    final tipY = center.dy + sin(angle) * length;
    final tailX = center.dx - cos(angle) * length * 0.4;
    final tailY = center.dy - sin(angle) * length * 0.4;
    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY), paint);
    final hl = length * 0.4;
    canvas.drawLine(Offset(tipX, tipY), Offset(tipX + cos(angle + pi * 0.8) * hl, tipY + sin(angle + pi * 0.8) * hl), paint);
    canvas.drawLine(Offset(tipX, tipY), Offset(tipX + cos(angle - pi * 0.8) * hl, tipY + sin(angle - pi * 0.8) * hl), paint);
  }

  @override
  bool shouldRepaint(covariant _SignalRouterPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RealityMergeGame — "Reality Merge"
// Match colored bubble universes by frequency. Merge matching = grow & score.
// ═══════════════════════════════════════════════════════════════════════════════

class _BubbleUniverse {
  double x, y, vx, vy, radius;
  int colorIdx;
  Color color;
  int merges; // merge count — at 3, triggers resonance
  double pulsePhase;
  double popAnim;
  _BubbleUniverse({
    required this.x, required this.y, required this.vx, required this.vy,
    required this.radius, required this.colorIdx, required this.color,
  }) : merges = 0, pulsePhase = 0, popAnim = 0;
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

  final List<_BubbleUniverse> _bubbles = [];
  int? _dragIndex;
  int _score = 0;
  int _lives = 5;
  int _combo = 0;
  double _comboTimer = 0;
  double _spawnTimer = 0;
  double _elapsed = 0;
  double _lastTime = 0;
  Size _size = Size.zero;
  bool _gameOver = false;
  bool _started = false;
  int _resonanceCount = 0;
  double _resonanceFlash = 0;
  static const int _maxBubbles = 18;

  final List<_JuiceParticle> _particles = [];

  static const _bColors = [
    Color(0xFFE53935), Color(0xFF1E88E5),
    Color(0xFF43A047), Color(0xFFFDD835),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _initGame() {
    _score = 0; _lives = 5; _combo = 0; _comboTimer = 0;
    _spawnTimer = 0; _elapsed = 0; _resonanceCount = 0;
    _gameOver = false; _started = true; _dragIndex = null;
    _bubbles.clear(); _particles.clear(); _resonanceFlash = 0;
    // Immediate action — start with bubbles
    for (int i = 0; i < 6; i++) _spawnBubble();
  }

  void _spawnBubble() {
    if (_size == Size.zero) return;
    final ci = _rng.nextInt(4);
    final side = _rng.nextInt(4);
    double sx, sy;
    switch (side) {
      case 0: sx = _rng.nextDouble() * _size.width; sy = -35; break;
      case 1: sx = _size.width + 35; sy = _rng.nextDouble() * _size.height; break;
      case 2: sx = _rng.nextDouble() * _size.width; sy = _size.height + 35; break;
      default: sx = -35; sy = _rng.nextDouble() * _size.height;
    }
    final cx = _size.width / 2 + (_rng.nextDouble() - 0.5) * 80;
    final cy = _size.height / 2 + (_rng.nextDouble() - 0.5) * 80;
    final dx = cx - sx; final dy = cy - sy;
    final dist = sqrt(dx * dx + dy * dy).clamp(1.0, 9999.0);
    final spd = 20 + _rng.nextDouble() * 25;
    _bubbles.add(_BubbleUniverse(
      x: sx, y: sy, vx: dx / dist * spd, vy: dy / dist * spd,
      radius: 22 + _rng.nextDouble() * 8, colorIdx: ci, color: _bColors[ci],
    )..pulsePhase = _rng.nextDouble() * pi * 2);
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || !_started) return;

    setState(() {
      _elapsed += dt;

      // Overflow check
      if (_bubbles.where((b) => b.popAnim == 0).length >= _maxBubbles) {
        _gameOver = true; return;
      }

      // Rapid spawn ramp: 0.55s → 0.2s over time
      _spawnTimer -= dt;
      final rate = max(0.2, 0.55 - _elapsed * 0.003);
      if (_spawnTimer <= 0 && _bubbles.length < _maxBubbles) {
        _spawnTimer = rate + _rng.nextDouble() * 0.15;
        _spawnBubble();
        // Occasionally double-spawn at higher paces
        if (_elapsed > 30 && _rng.nextDouble() < 0.3) _spawnBubble();
      }

      // Move & pulse bubbles
      for (int i = 0; i < _bubbles.length; i++) {
        final b = _bubbles[i];
        b.pulsePhase += dt * (2.0 + b.merges * 0.5);
        if (i == _dragIndex) continue;
        b.x += b.vx * dt; b.y += b.vy * dt;
        b.vx *= (1 - 0.4 * dt); b.vy *= (1 - 0.4 * dt);
        // Speed up drift over time
        final drift = 5.0 + _elapsed * 0.08;
        b.vx += (_rng.nextDouble() - 0.5) * drift * dt;
        b.vy += (_rng.nextDouble() - 0.5) * drift * dt;
        // Bounce
        if (b.x < b.radius) { b.x = b.radius; b.vx = b.vx.abs(); }
        if (b.x > _size.width - b.radius) { b.x = _size.width - b.radius; b.vx = -b.vx.abs(); }
        if (b.y < b.radius + 50) { b.y = b.radius + 50; b.vy = b.vy.abs(); }
        if (b.y > _size.height - b.radius) { b.y = _size.height - b.radius; b.vy = -b.vy.abs(); }
      }

      // Soft repulsion
      for (int i = 0; i < _bubbles.length; i++) {
        for (int j = i + 1; j < _bubbles.length; j++) {
          if (i == _dragIndex || j == _dragIndex) continue;
          final a = _bubbles[i]; final b = _bubbles[j];
          final dx = b.x - a.x; final dy = b.y - a.y;
          final dist = sqrt(dx * dx + dy * dy);
          final minD = a.radius + b.radius;
          if (dist < minD && dist > 0.1) {
            final nx = dx / dist; final ny = dy / dist;
            final push = (minD - dist) * 1.8;
            a.vx -= nx * push; a.vy -= ny * push;
            b.vx += nx * push; b.vy += ny * push;
          }
        }
      }

      // Pop animations
      _bubbles.removeWhere((b) => b.popAnim > 0.4);
      for (final b in _bubbles) { if (b.popAnim > 0) b.popAnim += dt; }

      // Combo decay
      if (_comboTimer > 0) {
        _comboTimer -= dt;
        if (_comboTimer <= 0) _combo = 0;
      }

      // Resonance flash decay
      if (_resonanceFlash > 0) _resonanceFlash = (_resonanceFlash - dt * 2).clamp(0.0, 1.0);

      // Particles
      for (final p in _particles) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _tryMerge(int dragIdx) {
    if (dragIdx >= _bubbles.length) return;
    final dragged = _bubbles[dragIdx];
    for (int i = 0; i < _bubbles.length; i++) {
      if (i == dragIdx) continue;
      final b = _bubbles[i];
      if (b.popAnim > 0) continue;
      final dx = dragged.x - b.x; final dy = dragged.y - b.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < dragged.radius + b.radius + 8) {
        if (dragged.colorIdx == b.colorIdx) {
          // ---- Match! Merge ----
          _combo++; _comboTimer = 1.5;
          final pts = (1 + _combo ~/ 2) * (1 + b.merges);
          _score += pts;
          b.merges += dragged.merges + 1;
          b.radius = (b.radius + 6).clamp(22, 55);
          // Particles
          for (int j = 0; j < 10; j++) {
            final a = _rng.nextDouble() * 2 * pi;
            _particles.add(_JuiceParticle(
              x: (dragged.x + b.x) / 2, y: (dragged.y + b.y) / 2,
              vx: cos(a) * 90, vy: sin(a) * 90,
              life: 0.5, color: dragged.color,
            ));
          }
          _bubbles.removeAt(dragIdx);
          // Resonance check — 3+ merges triggers chain clear
          if (b.merges >= 3) {
            _triggerResonance(b.colorIdx, b.x, b.y);
          }
          return;
        } else {
          // ---- Mismatch ----
          _lives--; _combo = 0; _comboTimer = 0;
          dragged.radius = (dragged.radius - 5).clamp(14, 55);
          b.radius = (b.radius - 5).clamp(14, 55);
          if (dist > 0.1) {
            dragged.vx = dx / dist * 90; dragged.vy = dy / dist * 90;
            b.vx = -dx / dist * 90; b.vy = -dy / dist * 90;
          }
          for (int j = 0; j < 6; j++) {
            final a = _rng.nextDouble() * 2 * pi;
            _particles.add(_JuiceParticle(
              x: (dragged.x + b.x) / 2, y: (dragged.y + b.y) / 2,
              vx: cos(a) * 60, vy: sin(a) * 60,
              life: 0.4, color: Colors.grey,
            ));
          }
          if (_lives <= 0) _gameOver = true;
          return;
        }
      }
    }
  }

  void _triggerResonance(int colorIdx, double cx, double cy) {
    _resonanceCount++;
    _resonanceFlash = 1.0;
    int cleared = 0;
    // Pop all same-color bubbles
    for (final b in _bubbles) {
      if (b.colorIdx == colorIdx && b.popAnim == 0) {
        b.popAnim = 0.001;
        cleared++;
        for (int j = 0; j < 6; j++) {
          final a = _rng.nextDouble() * 2 * pi;
          _particles.add(_JuiceParticle(
            x: b.x, y: b.y, vx: cos(a) * 100, vy: sin(a) * 100,
            life: 0.6, color: b.color,
          ));
        }
      }
    }
    final bonus = cleared * 5;
    _score += bonus;
    // Shockwave particles from center
    for (int j = 0; j < 20; j++) {
      final a = _rng.nextDouble() * 2 * pi;
      _particles.add(_JuiceParticle(
        x: cx, y: cy, vx: cos(a) * 200, vy: sin(a) * 200,
        life: 0.8, color: _bColors[colorIdx], radius: 3,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanStart: (d) {
          if (_gameOver) { _initGame(); return; }
          if (!_started) { _initGame(); return; }
          for (int i = _bubbles.length - 1; i >= 0; i--) {
            final b = _bubbles[i];
            if (b.popAnim > 0) continue;
            if ((Offset(b.x, b.y) - d.localPosition).distance < b.radius + 12) {
              _dragIndex = i; return;
            }
          }
        },
        onPanUpdate: (d) {
          if (_dragIndex != null && _dragIndex! < _bubbles.length) {
            _bubbles[_dragIndex!].x = d.localPosition.dx;
            _bubbles[_dragIndex!].y = d.localPosition.dy;
            _bubbles[_dragIndex!].vx = 0;
            _bubbles[_dragIndex!].vy = 0;
          }
        },
        onPanEnd: (d) {
          if (_dragIndex != null && _dragIndex! < _bubbles.length) _tryMerge(_dragIndex!);
          _dragIndex = null;
        },
        onTapDown: (d) {
          if (_gameOver || !_started) { _initGame(); }
        },
        child: Container(
          color: const Color(0xFF0A0A1A),
          child: CustomPaint(
            painter: _RealityMergePainter(
              bubbles: _bubbles, particles: _particles,
              dragIndex: _dragIndex, combo: _combo, comboTimer: _comboTimer,
              resonanceFlash: _resonanceFlash,
            ),
            child: Stack(children: [
              if (!_started)
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Reality Merge', style: TextStyle(fontFamily: 'Avenir', fontSize: 26, fontWeight: FontWeight.w300, color: Colors.white54)),
                  const SizedBox(height: 10),
                  Text('Drag matching colors together', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.24))),
                  Text('Grow a bubble to 3 merges for chain clear', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.24))),
                  const SizedBox(height: 30),
                  Text('Tap to start', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.24))),
                ])),
              if (_started && !_gameOver) ...[
                Positioned(top: 8, left: 12, right: 12, child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      ...List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(Icons.favorite, size: 14, color: i < _lives ? const Color(0xFFFF5252) : Colors.white12),
                      )),
                    ]),
                    Text('${_bubbles.where((b) => b.popAnim == 0).length}/$_maxBubbles', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: _bubbles.length >= _maxBubbles - 3 ? Colors.redAccent : Colors.white38)),
                  ],
                )),
                if (_combo > 1) Positioned(top: 30, left: 0, right: 0, child: Center(
                  child: Text('x$_combo', style: const TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                )),
              ],
              if (_gameOver) Positioned.fill(child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_lives <= 0 ? 'Too Many Mismatches!' : 'Reality Overflow!', style: const TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 12),
                  Text('$_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 42, fontWeight: FontWeight.w300, color: Colors.white70)),
                  if (_resonanceCount > 0) Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('$_resonanceCount resonance${_resonanceCount == 1 ? '' : 's'} triggered', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.38))),
                  ),
                  const SizedBox(height: 20),
                  Text('Tap to restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white.withValues(alpha: 0.24))),
                ])),
              )),
            ]),
          ),
        ),
      );
    });
  }
}

class _RealityMergePainter extends CustomPainter {
  final List<_BubbleUniverse> bubbles;
  final List<_JuiceParticle> particles;
  final int? dragIndex;
  final int combo;
  final double comboTimer;
  final double resonanceFlash;

  _RealityMergePainter({required this.bubbles, required this.particles, required this.dragIndex, required this.combo, required this.comboTimer, required this.resonanceFlash});

  @override
  void paint(Canvas canvas, Size size) {
    // Resonance flash
    if (resonanceFlash > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: resonanceFlash * 0.08));
    }

    for (int i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      if (b.popAnim > 0) {
        // Popping animation — expanding ring
        final t = (b.popAnim / 0.4).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(b.x, b.y), b.radius * (1 + t * 2), Paint()
          ..color = b.color.withValues(alpha: (1 - t) * 0.3)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
        continue;
      }
      final pos = Offset(b.x, b.y);
      final isDragged = i == dragIndex;
      final pulse = sin(b.pulsePhase) * 0.08 + 1.0;

      // Outer glow — bigger for more merges
      final glowR = b.radius + 6 + b.merges * 4.0;
      canvas.drawCircle(pos, glowR * pulse, Paint()..color = b.color.withValues(alpha: isDragged ? 0.18 : 0.06 + b.merges * 0.03));

      // Merge rings — show progress toward resonance
      for (int m = 0; m < b.merges && m < 3; m++) {
        final ringR = b.radius + 3.0 + m * 5.0;
        canvas.drawCircle(pos, ringR * pulse, Paint()
          ..color = b.color.withValues(alpha: 0.25 + m * 0.1)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      // Body
      canvas.drawCircle(pos, b.radius, Paint()..color = b.color.withValues(alpha: isDragged ? 0.55 : 0.30));
      canvas.drawCircle(pos, b.radius, Paint()
        ..color = b.color.withValues(alpha: isDragged ? 0.8 : 0.5)
        ..style = PaintingStyle.stroke..strokeWidth = 2);

      // Highlight
      canvas.drawCircle(
        Offset(pos.dx - b.radius * 0.2, pos.dy - b.radius * 0.2),
        b.radius * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.18));

      // Merge count dots (small dots below bubble)
      if (b.merges > 0) {
        for (int m = 0; m < min(b.merges, 3); m++) {
          final dx2 = (m - (min(b.merges, 3) - 1) / 2.0) * 7.0;
          canvas.drawCircle(
            Offset(pos.dx + dx2, pos.dy + b.radius + 8),
            2.5,
            Paint()..color = b.color.withValues(alpha: 0.7),
          );
        }
      }
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(Offset(p.x, p.y), p.radius,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)));
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
// Zoom out through scales of the universe, tapping correct elements.
// ═══════════════════════════════════════════════════════════════════════════════

class _ScaleLevel {
  final String name;
  final String targetLabel;
  final Color color;
  final List<String> decoys;
  _ScaleLevel(this.name, this.targetLabel, this.color, this.decoys);
}

class EverythingGame extends StatefulWidget {
  const EverythingGame({Key? key}) : super(key: key);
  @override
  State<EverythingGame> createState() => _EverythingGameState();
}

class _EverythingGameState extends State<EverythingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  static final _levels = [
    _ScaleLevel('Quark', 'Up Quark', const Color(0xFFE53935), ['Down', 'Charm', 'Strange']),
    _ScaleLevel('Atom', 'Carbon', const Color(0xFF42A5F5), ['Helium', 'Neon', 'Iron']),
    _ScaleLevel('Molecule', 'DNA', const Color(0xFF66BB6A), ['H2O', 'CO2', 'NaCl']),
    _ScaleLevel('Cell', 'Neuron', const Color(0xFFAB47BC), ['Red Blood', 'Muscle', 'Skin']),
    _ScaleLevel('Organism', 'Human', const Color(0xFFFF7043), ['Tree', 'Whale', 'Ant']),
    _ScaleLevel('Planet', 'Earth', const Color(0xFF26C6DA), ['Mars', 'Venus', 'Jupiter']),
    _ScaleLevel('Galaxy', 'Milky Way', const Color(0xFFFFCA28), ['Andromeda', 'Triangulum', 'Sombrero']),
    _ScaleLevel('Universe', 'Everything', const Color(0xFFECEFF1), ['Nothing', 'Something', 'Anything']),
  ];

  int _currentLevel = 0;
  double _zoomAnim = 0; // 0 = showing, 1 = zooming
  bool _zooming = false;
  bool _complete = false;
  bool _wrongChoice = false;
  double _wrongTimer = 0;
  double _lastTime = 0;

  // Element positions (shuffled each level)
  List<Offset> _elementPositions = [];
  List<String> _elementLabels = [];
  int _correctIndex = 0;

  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _setupLevel();
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

  void _setupLevel() {
    if (_currentLevel >= _levels.length) {
      _complete = true;
      return;
    }
    final level = _levels[_currentLevel];
    _elementLabels = [level.targetLabel, ...level.decoys]..shuffle(_rng);
    _correctIndex = _elementLabels.indexOf(level.targetLabel);
    _elementPositions = List.generate(_elementLabels.length, (i) {
      final angle = i / _elementLabels.length * 2 * pi - pi / 2;
      return Offset(0.5 + cos(angle) * 0.25, 0.5 + sin(angle) * 0.25);
    });
    _zooming = false;
    _zoomAnim = 0;
    _wrongChoice = false;
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      if (_zooming) {
        _zoomAnim += dt * 1.5;
        if (_zoomAnim >= 1.0) {
          _zoomAnim = 0;
          _zooming = false;
          _currentLevel++;
          _setupLevel();
        }
      }

      if (_wrongChoice) {
        _wrongTimer -= dt;
        if (_wrongTimer <= 0) {
          _wrongChoice = false;
          if (_currentLevel > 0) {
            _currentLevel--;
            _setupLevel();
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

  void _onTapElement(int index) {
    if (_zooming || _wrongChoice || _complete) return;
    if (index == _correctIndex) {
      // Correct! Start zoom
      _zooming = true;
      _zoomAnim = 0;
      for (int i = 0; i < 15; i++) {
        final a = _rng.nextDouble() * 2 * pi;
        _particles.add(_JuiceParticle(
          x: _elementPositions[index].dx,
          y: _elementPositions[index].dy,
          vx: cos(a) * 0.3, vy: sin(a) * 0.3,
          life: 0.7, color: _levels[_currentLevel].color,
        ));
      }
    } else {
      // Wrong — zoom reset one level
      _wrongChoice = true;
      _wrongTimer = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onTapDown: (d) {
          if (_complete || _zooming || _wrongChoice) return;
          final pos = Offset(d.localPosition.dx / w, d.localPosition.dy / h);
          for (int i = 0; i < _elementPositions.length; i++) {
            if ((pos - _elementPositions[i]).distance < 0.08) {
              _onTapElement(i);
              return;
            }
          }
        },
        child: Container(
          color: const Color(0xFF050510),
          child: CustomPaint(
            painter: _EverythingPainter(
              levels: _levels,
              currentLevel: _currentLevel,
              elementPositions: _elementPositions,
              elementLabels: _elementLabels,
              correctIndex: _correctIndex,
              zoomAnim: _zoomAnim,
              zooming: _zooming,
              wrongChoice: _wrongChoice,
              complete: _complete,
              particles: _particles,
            ),
            child: Stack(
              children: [
                // Scale label
                if (!_complete)
                  Positioned(
                    top: 8, left: 0, right: 0,
                    child: Center(
                      child: Text(
                        _currentLevel < _levels.length ? 'Scale: ${_levels[_currentLevel].name}' : '',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold,
                          color: _currentLevel < _levels.length ? _levels[_currentLevel].color.withValues(alpha: 0.7) : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 30, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      '${_currentLevel}/${_levels.length} scales',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white30),
                    ),
                  ),
                ),
                if (_wrongChoice)
                  Center(
                    child: const Text(
                      'Wrong! Zooming back...',
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ),
                if (_complete)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('You have seen', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
                        const SizedBox(height: 8),
                        const Text('Everything', style: TextStyle(fontFamily: 'Avenir', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(() { _currentLevel = 0; _complete = false; _setupLevel(); }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                            child: const Text('See it again', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_complete && !_zooming && !_wrongChoice && _currentLevel == 0)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(
                      child: Text(
                        'Tap the correct element to zoom out',
                        style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white24),
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
}

class _EverythingPainter extends CustomPainter {
  final List<_ScaleLevel> levels;
  final int currentLevel;
  final List<Offset> elementPositions;
  final List<String> elementLabels;
  final int correctIndex;
  final double zoomAnim;
  final bool zooming, wrongChoice, complete;
  final List<_JuiceParticle> particles;

  _EverythingPainter({
    required this.levels, required this.currentLevel,
    required this.elementPositions, required this.elementLabels,
    required this.correctIndex, required this.zoomAnim,
    required this.zooming, required this.wrongChoice,
    required this.complete, required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF050510));

    if (complete) return;
    if (currentLevel >= levels.length) return;

    final level = levels[currentLevel];
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Zoom animation: scale effect
    double scale = 1.0;
    double alpha = 1.0;
    if (zooming) {
      scale = 1.0 + zoomAnim * 3;
      alpha = 1.0 - zoomAnim;
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    // Central object representation
    final centerR = 30.0;
    canvas.drawCircle(Offset(cx, cy), centerR + 10, Paint()..color = level.color.withValues(alpha: 0.08 * alpha));
    canvas.drawCircle(Offset(cx, cy), centerR, Paint()..color = level.color.withValues(alpha: 0.2 * alpha));
    // Scale name at center
    final centerTp = TextPainter(
      text: TextSpan(text: level.name, style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: level.color.withValues(alpha: 0.6 * alpha))),
      textDirection: TextDirection.ltr,
    )..layout();
    centerTp.paint(canvas, Offset(cx - centerTp.width / 2, cy - centerTp.height / 2));

    // Element options around the center
    for (int i = 0; i < elementPositions.length; i++) {
      final pos = Offset(elementPositions[i].dx * size.width, elementPositions[i].dy * size.height);
      // Connecting line
      canvas.drawLine(Offset(cx, cy), pos, Paint()..color = Colors.white.withValues(alpha: 0.05 * alpha)..strokeWidth = 1);
      // Node
      canvas.drawCircle(pos, 28, Paint()..color = level.color.withValues(alpha: 0.1 * alpha));
      canvas.drawCircle(pos, 22, Paint()
        ..color = level.color.withValues(alpha: 0.25 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: elementLabels[i],
          style: TextStyle(fontFamily: 'Avenir', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.8 * alpha)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    canvas.restore();

    // Progress bar at bottom
    final barY = size.height - 50;
    final barW = size.width * 0.6;
    final barX = (size.width - barW) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
    final progress = currentLevel / levels.length;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * progress, 6), const Radius.circular(3)),
      Paint()..color = level.color.withValues(alpha: 0.5),
    );

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), 3,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EverythingPainter old) => true;
}
