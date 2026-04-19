import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
// 1. FinancialTradingGame — "Potato Futures"
// ═══════════════════════════════════════════════════════════════════════════════

class FinancialTradingGame extends StatefulWidget {
  const FinancialTradingGame({Key? key}) : super(key: key);
  @override
  State<FinancialTradingGame> createState() => _FinancialTradingGameState();
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

  // Limit orders
  double? _limitBuyPrice;
  double? _limitSellPrice;

  // News headlines
  String _headline = '';
  double _headlineTimer = 0;
  double _eventImpact = 0;

  final List<String> _bullishNews = [
    'Drought in Idaho!',
    'Potato blight reported!',
    'Export demand surges!',
    'Supply chain disrupted!',
    'French fry shortage!',
  ];
  final List<String> _bearishNews = [
    'Record harvest incoming!',
    'New GMO potato approved!',
    'Demand drops sharply!',
    'Warehouses overflowing!',
    'Sweet potatoes trending!',
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
        return;
      }

      // News events
      _headlineTimer -= dt;
      if (_headlineTimer <= 0 && _rng.nextDouble() < 0.01) {
        if (_rng.nextBool()) {
          _headline = _bullishNews[_rng.nextInt(_bullishNews.length)];
          _eventImpact = 3 + _rng.nextDouble() * 5;
        } else {
          _headline = _bearishNews[_rng.nextInt(_bearishNews.length)];
          _eventImpact = -(3 + _rng.nextDouble() * 5);
        }
        _headlineTimer = 3;
      }

      // Price physics: random walk + momentum + mean reversion + events
      final noise = (_rng.nextDouble() - 0.5) * 2;
      final meanReversion = (50 - _price) * 0.005;
      _momentum = _momentum * 0.95 + noise * 0.3 + _eventImpact * 0.1;
      _eventImpact *= 0.95;
      _price += _momentum + meanReversion;
      _price = _price.clamp(5.0, 200.0);
      _priceHistory.add(_price);
      if (_priceHistory.length > 120) _priceHistory.removeAt(0);

      // Check limit orders
      if (_limitBuyPrice != null && _price <= _limitBuyPrice! && _cash >= _price) {
        _cash -= _price;
        _inventory++;
        _spawnParticles(_rng.nextDouble() * 200, 200, Colors.green, 5);
        _limitBuyPrice = null;
      }
      if (_limitSellPrice != null && _price >= _limitSellPrice! && _inventory > 0) {
        _cash += _price;
        _inventory--;
        _spawnParticles(_rng.nextDouble() * 200, 200, Colors.red, 5);
        _limitSellPrice = null;
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

  double get _netWorth => _cash + _inventory * _price;
  double get _pnl => _netWorth - _startNetWorth;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = constraints.maxHeight * 0.35;
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            Column(
              children: [
                // Timer + headline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_timeLeft.toInt()}s',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 18,
                          color: _timeLeft < 10 ? Colors.redAccent : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_headlineTimer > 0)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _headline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Avenir', fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _eventImpact > 0 ? Colors.orangeAccent : Colors.lightBlueAccent,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        'P&L: ${_pnl >= 0 ? "+" : ""}\$${_pnl.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold,
                          color: _pnl >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price chart with tap for limit orders
                GestureDetector(
                  onTapDown: (details) {
                    if (_gameOver) return;
                    final fraction = 1 - (details.localPosition.dy / chartHeight);
                    final minP = _priceHistory.reduce(min) - 5;
                    final maxP = _priceHistory.reduce(max) + 5;
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
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Current price
                Text(
                  '\$${_price.toStringAsFixed(1)} / potato',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Inventory + cash
                Text(
                  'Cash: \$${_cash.toStringAsFixed(0)}   Potatoes: $_inventory',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54),
                ),
                if (_limitBuyPrice != null || _limitSellPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_limitBuyPrice != null ? "Limit BUY @ \$${_limitBuyPrice!.toStringAsFixed(1)}" : ""}'
                      '${_limitBuyPrice != null && _limitSellPrice != null ? "  |  " : ""}'
                      '${_limitSellPrice != null ? "Limit SELL @ \$${_limitSellPrice!.toStringAsFixed(1)}" : ""}',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.amberAccent),
                    ),
                  ),
                const SizedBox(height: 12),

                // Buy/Sell buttons
                if (!_gameOver)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tradeButton('BUY', Colors.green, _cash >= _price ? () {
                        setState(() {
                          _cash -= _price;
                          _inventory++;
                          _spawnParticles(constraints.maxWidth * 0.3, constraints.maxHeight * 0.7, Colors.green, 8);
                        });
                      } : null),
                      const SizedBox(width: 24),
                      _tradeButton('SELL', Colors.red, _inventory > 0 ? () {
                        setState(() {
                          _cash += _price;
                          _inventory--;
                          _spawnParticles(constraints.maxWidth * 0.7, constraints.maxHeight * 0.7, Colors.red, 8);
                        });
                      } : null),
                    ],
                  ),

                const SizedBox(height: 16),

                // Net worth
                Text(
                  'Net Worth: \$${_netWorth.toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE19816)),
                ),

                if (_gameOver) ...[
                  const SizedBox(height: 12),
                  Text(
                    _pnl >= 0 ? 'Nice trades!' : 'Better luck next time!',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: _pnl >= 0 ? Colors.greenAccent : Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
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
          ],
        ),
      );
    });
  }

  Widget _tradeButton(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold, color: onTap != null ? color : Colors.grey),
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
  _TradingChartPainter(this.data, this.limitBuy, this.limitSell, this.currentPrice);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min) - 5;
    final maxV = data.reduce(max) + 5;
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
  }

  @override
  bool shouldRepaint(covariant _TradingChartPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. GlobalFeedGame — "Feed the World"
// ═══════════════════════════════════════════════════════════════════════════════

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
  bool _won = false;
  int _citiesFed = 0;

  // Producers: name, x%, y%
  final List<_MapNode> _producers = [
    _MapNode('Idaho', 0.15, 0.30, Colors.amber),
    _MapNode('Peru', 0.22, 0.65, Colors.amber),
    _MapNode('China', 0.72, 0.35, Colors.amber),
    _MapNode('India', 0.65, 0.45, Colors.amber),
    _MapNode('Europe', 0.47, 0.25, Colors.amber),
  ];

  // Cities: name, x%, y%, fed?
  late List<_CityNode> _cities;

  // Routes drawn
  final List<_SupplyRoute> _routes = [];

  // Drag state
  int? _dragSourceIdx;
  Offset? _dragCurrent;

  // Particles
  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _cities = [
      _CityNode('NYC', 0.20, 0.32, false),
      _CityNode('Lagos', 0.44, 0.55, false),
      _CityNode('Tokyo', 0.82, 0.33, false),
      _CityNode('Delhi', 0.67, 0.40, false),
      _CityNode('SP', 0.28, 0.68, false),
    ];
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
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _gameOver = true;
        return;
      }

      // Spawn new hungry cities periodically
      if (_rng.nextDouble() < 0.003 && _cities.length < 12) {
        final names = ['London', 'Cairo', 'Seoul', 'Sydney', 'Berlin', 'Rio', 'Moscow'];
        _cities.add(_CityNode(
          names[_rng.nextInt(names.length)],
          0.1 + _rng.nextDouble() * 0.8,
          0.15 + _rng.nextDouble() * 0.65,
          false,
        ));
      }

      // Animate route deliveries
      for (final r in _routes) {
        r.progress += dt * 0.5;
        if (r.progress >= 1.0 && !r.delivered) {
          r.delivered = true;
          if (!_cities[r.cityIdx].fed) {
            _cities[r.cityIdx].fed = true;
            _citiesFed++;
            final c = _cities[r.cityIdx];
            _spawnP(c.x * 400, c.y * 400, Colors.greenAccent, 10);
          }
        }
      }

      // Check win
      if (_cities.every((c) => c.fed)) {
        _won = true;
        _gameOver = true;
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

  void _spawnP(double x, double y, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: x, y: y,
        vx: (_rng.nextDouble() - 0.5) * 80,
        vy: (_rng.nextDouble() - 0.5) * 80,
        life: 0.6, color: c,
      ));
    }
  }

  void _restart() {
    setState(() {
      _timeLeft = 60;
      _transportPoints = 100;
      _gameOver = false;
      _won = false;
      _citiesFed = 0;
      _routes.clear();
      _particles.clear();
      _cities = [
        _CityNode('NYC', 0.20, 0.32, false),
        _CityNode('Lagos', 0.44, 0.55, false),
        _CityNode('Tokyo', 0.82, 0.33, false),
        _CityNode('Delhi', 0.67, 0.40, false),
        _CityNode('SP', 0.28, 0.68, false),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onPanStart: (details) {
          if (_gameOver) return;
          // Check if starting on a producer
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
            // Check if ended on a city
            for (int i = 0; i < _cities.length; i++) {
              if (_cities[i].fed) continue;
              final cx = _cities[i].x * w;
              final cy = _cities[i].y * h;
              if ((_dragCurrent! - Offset(cx, cy)).distance < 30) {
                final prod = _producers[_dragSourceIdx!];
                final dx = prod.x - _cities[i].x;
                final dy = prod.y - _cities[i].y;
                final dist = sqrt(dx * dx + dy * dy);
                final cost = (dist * 50).round();
                if (_transportPoints >= cost) {
                  setState(() {
                    _transportPoints -= cost;
                    _routes.add(_SupplyRoute(_dragSourceIdx!, i, 0, false));
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
              _producers, _cities, _routes, _dragSourceIdx, _dragCurrent, _particles,
            ),
            child: Stack(
              children: [
                // HUD
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_timeLeft.toInt()}s', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: _timeLeft < 10 ? Colors.redAccent : Colors.white70)),
                      Text('Transport: $_transportPoints', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                      Text('Fed: $_citiesFed/${_cities.length}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.greenAccent)),
                    ],
                  ),
                ),
                // Instructions / end
                Positioned(
                  bottom: 20, left: 0, right: 0,
                  child: Center(
                    child: _gameOver
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _won ? 'World Fed!' : 'Time Up! Fed $_citiesFed/${_cities.length}',
                                style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: _won ? Colors.greenAccent : Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _restart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                                  child: const Text('Restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                                ),
                              ),
                            ],
                          )
                        : const Text('Drag from producers to hungry cities', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white30)),
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

class _MapNode {
  final String name;
  final double x, y;
  final Color color;
  _MapNode(this.name, this.x, this.y, this.color);
}

class _CityNode {
  final String name;
  final double x, y;
  bool fed;
  _CityNode(this.name, this.x, this.y, this.fed);
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

  _WorldMapPainter(this.producers, this.cities, this.routes, this.dragSource, this.dragCurrent, this.particles);

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

    // North America
    _drawEllipse(canvas, size, 0.17, 0.28, 0.12, 0.14, continentPaint, outlinePaint);
    // South America
    _drawEllipse(canvas, size, 0.24, 0.62, 0.07, 0.16, continentPaint, outlinePaint);
    // Europe
    _drawEllipse(canvas, size, 0.48, 0.25, 0.08, 0.08, continentPaint, outlinePaint);
    // Africa
    _drawEllipse(canvas, size, 0.48, 0.52, 0.08, 0.15, continentPaint, outlinePaint);
    // Asia
    _drawEllipse(canvas, size, 0.70, 0.30, 0.16, 0.14, continentPaint, outlinePaint);
    // Australia
    _drawEllipse(canvas, size, 0.82, 0.65, 0.06, 0.06, continentPaint, outlinePaint);

    // Routes
    for (final r in routes) {
      final p = producers[r.producerIdx];
      final c = cities[r.cityIdx];
      final from = Offset(p.x * size.width, p.y * size.height);
      final to = Offset(c.x * size.width, c.y * size.height);
      final routePaint = Paint()
        ..color = (r.delivered ? Colors.greenAccent : Colors.amberAccent).withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, routePaint);

      // Moving dot along route
      if (!r.delivered) {
        final dotPos = Offset.lerp(from, to, r.progress.clamp(0.0, 1.0))!;
        canvas.drawCircle(dotPos, 4, Paint()..color = Colors.amberAccent);
      }
    }

    // Drag line
    if (dragSource != null && dragCurrent != null) {
      final p = producers[dragSource!];
      canvas.drawLine(
        Offset(p.x * size.width, p.y * size.height),
        dragCurrent!,
        Paint()..color = Colors.white38..strokeWidth = 1.5..style = PaintingStyle.stroke,
      );
    }

    // Producers (glow)
    for (final p in producers) {
      final pos = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(pos, 18, Paint()..color = Colors.amber.withValues(alpha: 0.15));
      canvas.drawCircle(pos, 10, Paint()..color = Colors.amber.withValues(alpha: 0.4));
      canvas.drawCircle(pos, 5, Paint()..color = Colors.amber);
      _drawLabel(canvas, p.name, pos.dx, pos.dy - 16, Colors.amberAccent, 10);
    }

    // Cities
    for (final c in cities) {
      final pos = Offset(c.x * size.width, c.y * size.height);
      if (c.fed) {
        canvas.drawCircle(pos, 8, Paint()..color = Colors.greenAccent.withValues(alpha: 0.4));
        canvas.drawCircle(pos, 4, Paint()..color = Colors.greenAccent);
      } else {
        // Flash red
        final alpha = 0.3 + 0.7 * ((DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
        canvas.drawCircle(pos, 12, Paint()..color = Colors.redAccent.withValues(alpha: alpha * 0.2));
        canvas.drawCircle(pos, 6, Paint()..color = Colors.redAccent.withValues(alpha: alpha));
      }
      _drawLabel(canvas, c.name, pos.dx, pos.dy + 12, c.fed ? Colors.greenAccent : Colors.redAccent, 10);
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x, p.y), 3,
          Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _drawEllipse(Canvas canvas, Size size, double cx, double cy, double rx, double ry, Paint fill, Paint outline) {
    final rect = Rect.fromCenter(center: Offset(cx * size.width, cy * size.height), width: rx * 2 * size.width, height: ry * 2 * size.height);
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, outline);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'Avenir', fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. PlanetCatchGame — "Gravity Well"
// ═══════════════════════════════════════════════════════════════════════════════

class PlanetCatchGame extends StatefulWidget {
  const PlanetCatchGame({Key? key}) : super(key: key);
  @override
  State<PlanetCatchGame> createState() => _PlanetCatchGameState();
}

class _PlanetCatchGameState extends State<PlanetCatchGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  double _px = 0.5, _py = 0.5; // player planet position (fraction)
  double _planetRadius = 16;
  int _score = 0;
  int _health = 3;
  bool _gameOver = false;

  final List<_Asteroid> _asteroids = [];
  final List<_OrbitObject> _orbiting = [];
  final List<_JuiceParticle> _particles = [];

  Offset? _dragTarget;

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
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      // Move player toward drag target
      if (_dragTarget != null) {
        final dx = _dragTarget!.dx - _px;
        final dy = _dragTarget!.dy - _py;
        _px += dx * 5 * dt;
        _py += dy * 5 * dt;
        _px = _px.clamp(0.05, 0.95);
        _py = _py.clamp(0.05, 0.95);
      }

      // Spawn asteroids
      if (_rng.nextDouble() < 0.04) {
        final side = _rng.nextInt(4);
        double ax, ay, avx, avy;
        final isDangerous = _rng.nextDouble() < 0.2;
        switch (side) {
          case 0: ax = -0.05; ay = _rng.nextDouble(); avx = 0.15 + _rng.nextDouble() * 0.1; avy = (_rng.nextDouble() - 0.5) * 0.1; break;
          case 1: ax = 1.05; ay = _rng.nextDouble(); avx = -(0.15 + _rng.nextDouble() * 0.1); avy = (_rng.nextDouble() - 0.5) * 0.1; break;
          case 2: ax = _rng.nextDouble(); ay = -0.05; avx = (_rng.nextDouble() - 0.5) * 0.1; avy = 0.15 + _rng.nextDouble() * 0.1; break;
          default: ax = _rng.nextDouble(); ay = 1.05; avx = (_rng.nextDouble() - 0.5) * 0.1; avy = -(0.15 + _rng.nextDouble() * 0.1); break;
        }
        _asteroids.add(_Asteroid(ax, ay, avx, avy, isDangerous));
      }

      // Update asteroids — gravity pull
      for (final a in _asteroids) {
        final dx = _px - a.x;
        final dy = _py - a.y;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.05, 2.0);
        final force = 0.002 / (dist * dist);
        a.vx += dx / dist * force;
        a.vy += dy / dist * force;
        a.x += a.vx * dt * 3;
        a.y += a.vy * dt * 3;

        // Capture check
        final captureDist = (_planetRadius / 400) + 0.03;
        if (dist < captureDist) {
          if (a.dangerous) {
            _health--;
            _spawnP(a.x, a.y, Colors.redAccent, 15);
            a.captured = true;
            if (_health <= 0) _gameOver = true;
          } else {
            _score++;
            _orbiting.add(_OrbitObject(_rng.nextDouble() * 2 * pi, 0.03 + _orbiting.length * 0.008, _getStarColor()));
            a.captured = true;
            _spawnP(a.x, a.y, Colors.cyanAccent, 8);
            // Level up
            if (_score % 5 == 0) {
              _planetRadius += 2;
            }
          }
        }
      }
      _asteroids.removeWhere((a) => a.captured || a.x < -0.2 || a.x > 1.2 || a.y < -0.2 || a.y > 1.2);

      // Update orbiting objects
      for (final o in _orbiting) {
        o.angle += 2 * dt;
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

  Color _getStarColor() {
    final colors = [Colors.cyanAccent, Colors.amberAccent, Colors.white, Colors.lightBlueAccent, Colors.purpleAccent];
    return colors[_rng.nextInt(colors.length)];
  }

  void _spawnP(double fx, double fy, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: fx, y: fy,
        vx: (_rng.nextDouble() - 0.5) * 0.5,
        vy: (_rng.nextDouble() - 0.5) * 0.5,
        life: 0.5, color: c,
      ));
    }
  }

  void _restart() {
    setState(() {
      _px = 0.5; _py = 0.5;
      _planetRadius = 16;
      _score = 0; _health = 3;
      _gameOver = false;
      _asteroids.clear();
      _orbiting.clear();
      _particles.clear();
      _dragTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return GestureDetector(
        onPanStart: (d) { if (!_gameOver) _dragTarget = Offset(d.localPosition.dx / w, d.localPosition.dy / h); },
        onPanUpdate: (d) { if (!_gameOver) setState(() => _dragTarget = Offset(d.localPosition.dx / w, d.localPosition.dy / h)); },
        onPanEnd: (_) {},
        onTapDown: (d) { if (!_gameOver) setState(() => _dragTarget = Offset(d.localPosition.dx / w, d.localPosition.dy / h)); },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _GravityWellPainter(
              _px, _py, _planetRadius, _asteroids, _orbiting, _particles, _health, _score,
            ),
            child: Stack(
              children: [
                // HUD
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.circle, size: 14, color: i < _health ? Colors.greenAccent : Colors.grey.withValues(alpha: 0.3)),
                        )),
                      ),
                      Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                ),
                if (_gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Game Over! Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _restart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                            child: const Text('Restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_gameOver && _score == 0)
                  Positioned(
                    bottom: 30, left: 0, right: 0,
                    child: const Center(
                      child: Text('Drag to move. Capture objects with gravity.', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white24)),
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

class _Asteroid {
  double x, y, vx, vy;
  bool dangerous;
  bool captured;
  _Asteroid(this.x, this.y, this.vx, this.vy, this.dangerous) : captured = false;
}

class _OrbitObject {
  double angle, orbitRadius;
  Color color;
  _OrbitObject(this.angle, this.orbitRadius, this.color);
}

class _GravityWellPainter extends CustomPainter {
  final double px, py, planetRadius;
  final List<_Asteroid> asteroids;
  final List<_OrbitObject> orbiting;
  final List<_JuiceParticle> particles;
  final int health, score;

  _GravityWellPainter(this.px, this.py, this.planetRadius, this.asteroids, this.orbiting, this.particles, this.health, this.score);

  @override
  void paint(Canvas canvas, Size size) {
    // Background stars
    final starRng = Random(42);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(starRng.nextDouble() * size.width, starRng.nextDouble() * size.height),
        0.5 + starRng.nextDouble() * 1.0,
        starPaint,
      );
    }

    final cx = px * size.width;
    final cy = py * size.height;

    // Gravity field rings
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy), planetRadius + i * 25,
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.03 * i)..style = PaintingStyle.stroke..strokeWidth = 0.5,
      );
    }

    // Player planet
    canvas.drawCircle(Offset(cx, cy), planetRadius + 4, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(cx, cy), planetRadius, Paint()..color = const Color(0xFF2196F3));
    canvas.drawCircle(Offset(cx, cy), planetRadius * 0.6, Paint()..color = const Color(0xFF42A5F5).withValues(alpha: 0.5));

    // Orbiting objects
    for (final o in orbiting) {
      final ox = cx + cos(o.angle) * (planetRadius + 8 + o.orbitRadius * size.width * 0.5);
      final oy = cy + sin(o.angle) * (planetRadius + 8 + o.orbitRadius * size.width * 0.5);
      canvas.drawCircle(Offset(ox, oy), 3, Paint()..color = o.color);
    }

    // Asteroids
    for (final a in asteroids) {
      final ax = a.x * size.width;
      final ay = a.y * size.height;
      if (a.dangerous) {
        canvas.drawCircle(Offset(ax, ay), 7, Paint()..color = Colors.redAccent.withValues(alpha: 0.4));
        canvas.drawCircle(Offset(ax, ay), 5, Paint()..color = Colors.redAccent);
      } else {
        canvas.drawCircle(Offset(ax, ay), 5, Paint()..color = Colors.white.withValues(alpha: 0.6));
        canvas.drawCircle(Offset(ax, ay), 3, Paint()..color = Colors.amberAccent);
      }
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        final px2 = p.x * size.width;
        final py2 = p.y * size.height;
        canvas.drawCircle(Offset(px2, py2), 2.5, Paint()..color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GravityWellPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. SolarSortGame — "Planet Lineup"
// ═══════════════════════════════════════════════════════════════════════════════

class SolarSortGame extends StatefulWidget {
  const SolarSortGame({Key? key}) : super(key: key);
  @override
  State<SolarSortGame> createState() => _SolarSortGameState();
}

class _SolarSortGameState extends State<SolarSortGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  static const _planetNames = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune'];
  static const _planetColors = [Color(0xFFB0B0B0), Color(0xFFE8A84C), Color(0xFF4488CC), Color(0xFFCC5533), Color(0xFFCC9966), Color(0xFFDDCC88), Color(0xFF88CCDD), Color(0xFF4466AA)];
  static const _planetFacts = [
    'Smallest planet, closest to the Sun!',
    'Hottest planet — hotter than Mercury!',
    'Only planet with liquid water on the surface!',
    'Home to the tallest mountain in the solar system!',
    'So big, 1,300 Earths could fit inside!',
    'Its rings are made mostly of ice!',
    'It rotates on its side!',
    'Winds reach 1,200 mph!',
  ];

  late List<int> _shuffledOrder; // indices into _planetNames
  final Map<int, Offset> _positions = {};
  final Set<int> _placed = {};
  int? _dragging;
  Offset _dragOffset = Offset.zero;
  double _timeLeft = 45;
  bool _gameOver = false;
  bool _won = false;
  int _round = 1;
  String _factText = '';
  double _factTimer = 0;

  final List<_JuiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _shufflePositions();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _shufflePositions() {
    _shuffledOrder = List.generate(8, (i) => i)..shuffle(_rng);
    _positions.clear();
    _placed.clear();
    // Random initial positions
    for (int i = 0; i < 8; i++) {
      _positions[_shuffledOrder[i]] = Offset(
        0.1 + _rng.nextDouble() * 0.8,
        0.2 + _rng.nextDouble() * 0.5,
      );
    }
  }

  void _tick() {
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      _timeLeft -= dt;
      if (_factTimer > 0) _factTimer -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _gameOver = true;
      }

      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _restart() {
    setState(() {
      _shufflePositions();
      _timeLeft = _round > 1 ? 30 : 45;
      _gameOver = false;
      _won = false;
      _factText = '';
      _factTimer = 0;
      _particles.clear();
    });
  }

  void _speedRound() {
    setState(() {
      _round++;
      _shufflePositions();
      _timeLeft = 25;
      _gameOver = false;
      _won = false;
      _factText = '';
      _factTimer = 0;
      _particles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final slotY = h * 0.82;
      final sunX = 30.0;

      return GestureDetector(
        onPanStart: (d) {
          if (_gameOver) return;
          for (int i = 0; i < 8; i++) {
            if (_placed.contains(i)) continue;
            final pos = _positions[i]!;
            final px = pos.dx * w;
            final py = pos.dy * h;
            if ((d.localPosition - Offset(px, py)).distance < 30) {
              _dragging = i;
              _dragOffset = Offset(px - d.localPosition.dx, py - d.localPosition.dy);
              break;
            }
          }
        },
        onPanUpdate: (d) {
          if (_dragging != null) {
            setState(() {
              _positions[_dragging!] = Offset(
                (d.localPosition.dx + _dragOffset.dx) / w,
                (d.localPosition.dy + _dragOffset.dy) / h,
              );
            });
          }
        },
        onPanEnd: (d) {
          if (_dragging != null) {
            // Check if dropped near correct slot
            final slotX = sunX + 20 + (_dragging! + 0.5) * ((w - sunX - 20) / 8);
            final pos = _positions[_dragging!]!;
            final dx = pos.dx * w - slotX;
            final dy = pos.dy * h - slotY;
            if (sqrt(dx * dx + dy * dy) < 35) {
              setState(() {
                _placed.add(_dragging!);
                _positions[_dragging!] = Offset(slotX / w, slotY / h);
                _factText = _planetFacts[_dragging!];
                _factTimer = 2.5;
                // Particles
                for (int i = 0; i < 12; i++) {
                  _particles.add(_JuiceParticle(
                    x: slotX, y: slotY,
                    vx: (_rng.nextDouble() - 0.5) * 100,
                    vy: (_rng.nextDouble() - 0.5) * 100 - 30,
                    life: 0.7,
                    color: _planetColors[_dragging!],
                  ));
                }
                if (_placed.length == 8) {
                  _won = true;
                  _gameOver = true;
                }
              });
            }
            _dragging = null;
          }
        },
        child: Container(
          color: const Color(0xFF050515),
          child: Stack(
            children: [
              // Stars background
              CustomPaint(painter: _StarfieldPainter(60)),

              // Orbit line
              Positioned(
                left: sunX, top: slotY - 1,
                child: Container(width: w - sunX, height: 2, color: Colors.white.withValues(alpha: 0.08)),
              ),

              // Sun
              Positioned(
                left: 8, top: slotY - 18,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                    boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                ),
              ),

              // Slot markers
              ...List.generate(8, (i) {
                final slotX = sunX + 20 + (i + 0.5) * ((w - sunX - 20) / 8);
                return Positioned(
                  left: slotX - 3, top: slotY - 3,
                  child: Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _placed.contains(i) ? _planetColors[i].withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                );
              }),

              // Planets
              ...List.generate(8, (idx) {
                final i = _shuffledOrder[idx];
                final pos = _positions[i]!;
                final isPlaced = _placed.contains(i);
                final size = 22.0 + (i == 4 || i == 5 ? 10 : 0); // Jupiter/Saturn bigger
                return Positioned(
                  left: pos.dx * w - size / 2,
                  top: pos.dy * h - size / 2,
                  child: Container(
                    width: size, height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _planetColors[i],
                      boxShadow: isPlaced
                          ? [BoxShadow(color: _planetColors[i].withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _planetNames[i][0],
                        style: TextStyle(fontFamily: 'Avenir', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                );
              }),

              // Particles
              ..._particles.where((p) => p.life > 0).map((p) => Positioned(
                left: p.x - 2, top: p.y - 2,
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                  ),
                ),
              )),

              // HUD
              Positioned(
                top: 8, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Round $_round', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
                    Text('${_timeLeft.toInt()}s', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: _timeLeft < 10 ? Colors.redAccent : Colors.white70)),
                    Text('${_placed.length}/8', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                  ],
                ),
              ),

              // Fact display
              if (_factTimer > 0)
                Positioned(
                  bottom: 80, left: 24, right: 24,
                  child: Center(
                    child: Text(
                      _factText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent.withValues(alpha: _factTimer.clamp(0.0, 1.0))),
                    ),
                  ),
                ),

              // End state
              if (_gameOver)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _won ? 'Sorted! Round $_round complete!' : 'Time up! ${_placed.length}/8 placed',
                        style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: _won ? Colors.greenAccent : Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _restart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                              child: const Text('Restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
                            ),
                          ),
                          if (_won) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _speedRound,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.amber.withValues(alpha: 0.2), border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5))),
                                child: const Text('Speed Round!', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.amberAccent)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

              if (!_gameOver && _placed.isEmpty)
                Positioned(
                  bottom: 20, left: 0, right: 0,
                  child: const Center(child: Text('Drag planets to their correct position from the Sun', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white24))),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _StarfieldPainter extends CustomPainter {
  final int count;
  _StarfieldPainter(this.count);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.4 + rng.nextDouble() * 1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.15 + rng.nextDouble() * 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. GalaxyCollectorGame — "Star Catcher"
// ═══════════════════════════════════════════════════════════════════════════════

class GalaxyCollectorGame extends StatefulWidget {
  const GalaxyCollectorGame({Key? key}) : super(key: key);
  @override
  State<GalaxyCollectorGame> createState() => _GalaxyCollectorGameState();
}

class _GalaxyCollectorGameState extends State<GalaxyCollectorGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  double _cx = 0.5, _cy = 0.5; // collector position
  int _score = 0;
  int _galaxyStars = 0;
  double _galaxyAngle = 0;

  final List<_FieldStar> _stars = [];
  final List<_BlackHole> _blackHoles = [];
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
      _galaxyAngle += dt * 0.5;

      // Spawn stars
      if (_rng.nextDouble() < 0.06) {
        final colors = [Colors.white, Colors.yellowAccent, Colors.cyanAccent, Colors.pinkAccent, Colors.orangeAccent];
        final points = [1, 2, 3, 5, 2];
        final ci = _rng.nextInt(colors.length);
        _stars.add(_FieldStar(
          _rng.nextDouble(), _rng.nextDouble(),
          2 + _rng.nextDouble() * 2, // lifespan
          colors[ci], points[ci],
        ));
      }

      // Spawn black holes
      if (_rng.nextDouble() < 0.005 && _blackHoles.length < 3) {
        _blackHoles.add(_BlackHole(
          _rng.nextDouble() * 0.8 + 0.1,
          _rng.nextDouble() * 0.8 + 0.1,
          8 + _rng.nextDouble() * 5,
        ));
      }

      // Update stars
      for (final s in _stars) {
        s.life -= dt;
      }
      _stars.removeWhere((s) => s.life <= 0);

      // Black hole pull on collector
      for (final bh in _blackHoles) {
        final dx = bh.x - _cx;
        final dy = bh.y - _cy;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.05, 2.0);
        final pull = 0.0005 / (dist * dist);
        _cx += dx / dist * pull;
        _cy += dy / dist * pull;

        // Steal stars if too close
        if (dist < 0.06) {
          if (_galaxyStars > 0) {
            _galaxyStars = (_galaxyStars - 1).clamp(0, 9999);
            _spawnP(bh.x, bh.y, Colors.purpleAccent, 5);
          }
        }
        bh.life -= dt;
      }
      _blackHoles.removeWhere((bh) => bh.life <= 0);

      // Check star collection
      for (final s in _stars) {
        if (s.collected) continue;
        final dx = _cx - s.x;
        final dy = _cy - s.y;
        if (sqrt(dx * dx + dy * dy) < 0.04) {
          s.collected = true;
          _score += s.points;
          _galaxyStars++;
          _spawnP(s.x, s.y, s.color, 6);
        }
      }

      _cx = _cx.clamp(0.02, 0.98);
      _cy = _cy.clamp(0.02, 0.98);

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _spawnP(double x, double y, Color c, int n) {
    for (int i = 0; i < n; i++) {
      _particles.add(_JuiceParticle(
        x: x, y: y,
        vx: (_rng.nextDouble() - 0.5) * 0.3,
        vy: (_rng.nextDouble() - 0.5) * 0.3,
        life: 0.5, color: c,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _cx = (d.localPosition.dx / w).clamp(0.02, 0.98);
            _cy = (d.localPosition.dy / h).clamp(0.02, 0.98);
          });
        },
        onTapDown: (d) {
          setState(() {
            _cx = d.localPosition.dx / w;
            _cy = d.localPosition.dy / h;
          });
        },
        child: Container(
          color: const Color(0xFF020210),
          child: CustomPaint(
            painter: _StarCatcherPainter(
              _cx, _cy, _stars, _blackHoles, _particles, _galaxyStars, _galaxyAngle,
            ),
            child: Stack(
              children: [
                // HUD
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stars: $_galaxyStars', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.cyanAccent)),
                      Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.amberAccent)),
                    ],
                  ),
                ),
                if (_score == 0)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Drag to catch stars. Avoid black holes!', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white24))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _FieldStar {
  double x, y, life;
  Color color;
  int points;
  bool collected;
  _FieldStar(this.x, this.y, this.life, this.color, this.points) : collected = false;
}

class _BlackHole {
  double x, y, life;
  _BlackHole(this.x, this.y, this.life);
}

class _StarCatcherPainter extends CustomPainter {
  final double cx, cy;
  final List<_FieldStar> stars;
  final List<_BlackHole> blackHoles;
  final List<_JuiceParticle> particles;
  final int galaxyStars;
  final double galaxyAngle;

  _StarCatcherPainter(this.cx, this.cy, this.stars, this.blackHoles, this.particles, this.galaxyStars, this.galaxyAngle);

  @override
  void paint(Canvas canvas, Size size) {
    // Background stars
    final rng = Random(7);
    for (int i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.3 + rng.nextDouble() * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.1),
      );
    }

    // Galaxy display (top-right corner)
    final galaxyCenter = Offset(size.width - 50, 60);
    for (int i = 0; i < galaxyStars && i < 200; i++) {
      final armAngle = galaxyAngle + (i % 3) * (2 * pi / 3);
      final r = 5 + i * 0.2;
      final spiralAngle = armAngle + r * 0.15;
      final sx = galaxyCenter.dx + cos(spiralAngle) * r;
      final sy = galaxyCenter.dy + sin(spiralAngle) * r;
      canvas.drawCircle(
        Offset(sx, sy), 1.2,
        Paint()..color = HSVColor.fromAHSV(0.7, (i * 30.0) % 360, 0.5, 0.9).toColor(),
      );
    }
    if (galaxyStars > 0) {
      canvas.drawCircle(galaxyCenter, 3, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }

    // Stars in field
    for (final s in stars) {
      if (s.collected) continue;
      final alpha = (s.life).clamp(0.0, 1.0);
      final sx = s.x * size.width;
      final sy = s.y * size.height;
      canvas.drawCircle(Offset(sx, sy), 6, Paint()..color = s.color.withValues(alpha: alpha * 0.2));
      canvas.drawCircle(Offset(sx, sy), 3, Paint()..color = s.color.withValues(alpha: alpha));
    }

    // Black holes
    for (final bh in blackHoles) {
      final bx = bh.x * size.width;
      final by = bh.y * size.height;
      // Dark center with purple glow
      canvas.drawCircle(Offset(bx, by), 20, Paint()..color = Colors.purpleAccent.withValues(alpha: 0.1));
      canvas.drawCircle(Offset(bx, by), 12, Paint()..color = Colors.deepPurple.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(bx, by), 6, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(bx, by), 7, Paint()
        ..color = Colors.purpleAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }

    // Collector
    final collX = cx * size.width;
    final collY = cy * size.height;
    canvas.drawCircle(Offset(collX, collY), 14, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.1));
    canvas.drawCircle(Offset(collX, collY), 10, Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    canvas.drawCircle(Offset(collX, collY), 5, Paint()..color = Colors.cyanAccent);

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
  bool shouldRepaint(covariant _StarCatcherPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. CosmicWebGame — "Web Weaver"
// ═══════════════════════════════════════════════════════════════════════════════

class CosmicWebGame extends StatefulWidget {
  const CosmicWebGame({Key? key}) : super(key: key);
  @override
  State<CosmicWebGame> createState() => _CosmicWebGameState();
}

class _CosmicWebGameState extends State<CosmicWebGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  final List<_WebNode> _nodes = [];
  final List<_WebEdge> _edges = [];
  double _timeLeft = 60;
  bool _gameOver = false;
  bool _won = false;
  int? _dragFromNode;
  Offset? _dragPos;

  final List<_JuiceParticle> _particles = [];

  static const double _maxConnectionDist = 0.28;

  @override
  void initState() {
    super.initState();
    _spawnNodes(8);
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _spawnNodes(int count) {
    _nodes.clear();
    _edges.clear();
    for (int i = 0; i < count; i++) {
      _nodes.add(_WebNode(
        0.1 + _rng.nextDouble() * 0.8,
        0.15 + _rng.nextDouble() * 0.65,
        (_rng.nextDouble() - 0.5) * 0.01,
        (_rng.nextDouble() - 0.5) * 0.01,
      ));
    }
  }

  void _tick() {
    if (_gameOver) return;
    final dt = 1 / 60.0;
    setState(() {
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _gameOver = true;
        return;
      }

      // Drift nodes
      for (final n in _nodes) {
        n.x += n.vx * dt;
        n.y += n.vy * dt;
        // Bounce off walls
        if (n.x < 0.05 || n.x > 0.95) n.vx = -n.vx;
        if (n.y < 0.1 || n.y > 0.85) n.vy = -n.vy;
        n.x = n.x.clamp(0.05, 0.95);
        n.y = n.y.clamp(0.1, 0.85);
        n.pulse += dt * 3;
      }

      // Break connections that are too far
      _edges.removeWhere((e) {
        final a = _nodes[e.a];
        final b = _nodes[e.b];
        final dx = a.x - b.x;
        final dy = a.y - b.y;
        return sqrt(dx * dx + dy * dy) > _maxConnectionDist * 1.3;
      });

      // Check win — all nodes connected (union-find)
      if (_edges.isNotEmpty && _isFullyConnected()) {
        _won = true;
        _gameOver = true;
        for (final n in _nodes) {
          _spawnP(n.x, n.y, Colors.cyanAccent, 10);
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

  void _restart() {
    setState(() {
      _spawnNodes(8 + _rng.nextInt(4));
      _timeLeft = 60;
      _gameOver = false;
      _won = false;
      _particles.clear();
    });
  }

  int? _nodeAt(Offset localPos, double w, double h) {
    for (int i = 0; i < _nodes.length; i++) {
      final nx = _nodes[i].x * w;
      final ny = _nodes[i].y * h;
      if ((localPos - Offset(nx, ny)).distance < 25) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return GestureDetector(
        onPanStart: (d) {
          if (_gameOver) return;
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
              // Check distance
              final a = _nodes[_dragFromNode!];
              final b = _nodes[toNode];
              final dx = a.x - b.x;
              final dy = a.y - b.y;
              final dist = sqrt(dx * dx + dy * dy);
              if (dist <= _maxConnectionDist) {
                // Check if edge already exists
                final exists = _edges.any((e) =>
                    (e.a == _dragFromNode && e.b == toNode) || (e.a == toNode && e.b == _dragFromNode));
                if (!exists) {
                  setState(() {
                    _edges.add(_WebEdge(_dragFromNode!, toNode));
                    _spawnP((a.x + b.x) / 2, (a.y + b.y) / 2, Colors.cyanAccent, 5);
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
            painter: _CosmicWebPainter(_nodes, _edges, _particles, _dragFromNode, _dragPos, w, h),
            child: Stack(
              children: [
                Positioned(
                  top: 8, left: 16, right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_timeLeft.toInt()}s', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: _timeLeft < 10 ? Colors.redAccent : Colors.white70)),
                      Text('Edges: ${_edges.length}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.cyanAccent)),
                      Text('Nodes: ${_nodes.length}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
                    ],
                  ),
                ),
                if (_gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _won ? 'Web Complete!' : 'Time up! Not fully connected.',
                          style: TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: _won ? Colors.cyanAccent : Colors.redAccent),
                        ),
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
                if (!_gameOver && _edges.isEmpty)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Drag between nodes to connect them', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white24))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
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

  _CosmicWebPainter(this.nodes, this.edges, this.particles, this.dragFrom, this.dragPos, this.screenW, this.screenH);

  @override
  void paint(Canvas canvas, Size size) {
    // Background grid
    final gridPaint = Paint()..color = const Color(0x08FFFFFF)..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Edges
    for (final e in edges) {
      final a = nodes[e.a];
      final b = nodes[e.b];
      final from = Offset(a.x * size.width, a.y * size.height);
      final to = Offset(b.x * size.width, b.y * size.height);
      canvas.drawLine(from, to, Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
      // Pulse effect traveling along edge
      final pulseT = (a.pulse % 2) / 2;
      final pulsePos = Offset.lerp(from, to, pulseT)!;
      canvas.drawCircle(pulsePos, 2, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.6));
    }

    // Drag line
    if (dragFrom != null && dragPos != null) {
      final from = Offset(nodes[dragFrom!].x * size.width, nodes[dragFrom!].y * size.height);
      canvas.drawLine(from, dragPos!, Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke);
    }

    // Nodes
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final pos = Offset(n.x * size.width, n.y * size.height);
      final connected = edges.any((e) => e.a == i || e.b == i);
      final glowAlpha = 0.1 + 0.05 * sin(n.pulse);
      canvas.drawCircle(pos, 16, Paint()..color = (connected ? Colors.cyanAccent : Colors.white).withValues(alpha: glowAlpha));
      canvas.drawCircle(pos, 8, Paint()..color = connected ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.3));
      canvas.drawCircle(pos, 4, Paint()..color = connected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.5));
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
