import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Molecule Builder — drag atoms together to fulfill molecule orders
// ---------------------------------------------------------------------------

// ---- constants ------------------------------------------------------------

const Color _kBgColor = Color(0xFF050510);

const Map<String, Color> _kAtomColors = {
  'H': Color(0xFFE0E0E0),
  'O': Color(0xFFE53935),
  'C': Color(0xFF424242),
  'N': Color(0xFF1E88E5),
};

const Map<String, double> _kAtomRadii = {
  'H': 14.0,
  'O': 18.0,
  'C': 20.0,
  'N': 17.0,
};

// Weighted spawn distribution: H 40%, O 25%, C 20%, N 15%
const List<String> _kSpawnPool = [
  'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', // 8 / 20 = 40%
  'O', 'O', 'O', 'O', 'O',                   // 5 / 20 = 25%
  'C', 'C', 'C', 'C',                         // 4 / 20 = 20%
  'N', 'N', 'N',                               // 3 / 20 = 15%
];

// ---- recipe data ----------------------------------------------------------

class _Recipe {
  final String key;        // sorted atom letters joined by ','
  final String formula;    // display formula (e.g. 'H₂O')
  final int points;
  final double orderTime;  // seconds for order countdown
  final List<String> atoms;

  const _Recipe({
    required this.key,
    required this.formula,
    required this.points,
    required this.orderTime,
    required this.atoms,
  });
}

const List<_Recipe> _kRecipes = [
  _Recipe(key: 'H,H',             formula: 'H\u2082',     points: 10, orderTime: 20, atoms: ['H', 'H']),
  _Recipe(key: 'H,H,O',           formula: 'H\u2082O',    points: 25, orderTime: 30, atoms: ['H', 'H', 'O']),
  _Recipe(key: 'C,O,O',           formula: 'CO\u2082',    points: 25, orderTime: 30, atoms: ['C', 'O', 'O']),
  _Recipe(key: 'H,H,H,N',         formula: 'NH\u2083',    points: 40, orderTime: 35, atoms: ['H', 'H', 'H', 'N']),
  _Recipe(key: 'C,H,H,H,H',      formula: 'CH\u2084',    points: 50, orderTime: 40, atoms: ['C', 'H', 'H', 'H', 'H']),
  _Recipe(key: 'C,C,H,H,H,H,H,H', formula: 'C\u2082H\u2086', points: 80, orderTime: 50, atoms: ['C', 'C', 'H', 'H', 'H', 'H', 'H', 'H']),
];

final Map<String, _Recipe> _kRecipeMap = {
  for (final r in _kRecipes) r.key: r,
};

// ---- data classes ---------------------------------------------------------

class _Atom {
  String type;
  double x, y;
  double vx, vy;
  double radius;
  Color color;
  double nudgeTimer; // seconds until next Brownian nudge

  _Atom({
    required this.type,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  })  : radius = _kAtomRadii[type] ?? 16.0,
        color = _kAtomColors[type] ?? Colors.white,
        nudgeTimer = 0.0;
}

class _Order {
  _Recipe recipe;
  double timeLeft;
  double totalTime;
  bool fulfilled;
  bool expired;
  double flashAge; // for green/red flash animation

  _Order({required this.recipe})
      : timeLeft = recipe.orderTime,
        totalTime = recipe.orderTime,
        fulfilled = false,
        expired = false,
        flashAge = 0.0;
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
  }) : age = 0.0;
}

class _RepulsionBurst {
  double x, y, age;
  _RepulsionBurst({required this.x, required this.y}) : age = 0.0;
}

// ---- widget ---------------------------------------------------------------

class MoleculeBuilderGame extends StatefulWidget {
  MoleculeBuilderGame({Key? key}) : super(key: key);
  @override
  State<MoleculeBuilderGame> createState() => _MoleculeBuilderGameState();
}

class _MoleculeBuilderGameState extends State<MoleculeBuilderGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Clock
  double _timeRemaining = 90.0;
  int _score = 0;
  bool _gameOver = false;
  bool _started = false;
  String _gameOverReason = '';

  // Lives
  int _lives = 5;

  // Atoms
  final List<_Atom> _atoms = [];
  int? _dragIndex;

  // Orders
  final List<_Order> _orders = [];

  // Popups
  final List<_Popup> _popups = [];

  // Repulsion bursts (red flash on failed match)
  final List<_RepulsionBurst> _bursts = [];

  // Combo
  int _combo = 0;
  double _lastFulfillTime = -10.0;
  double _comboDisplayScale = 1.0;

  // Stats
  int _moleculesBuilt = 0;
  int _ordersTotal = 0;
  int _ordersFilled = 0;

  // Spawn delay queue
  final List<double> _spawnDelays = [];

  Size _screenSize = Size.zero;
  double _lastTime = 0.0;
  double _elapsed = 0.0;

  static const int _targetAtomCount = 14;

  // ---- lifecycle ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
        vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- initialisation -----------------------------------------------------

  void _initGame() {
    _atoms.clear();
    _orders.clear();
    _popups.clear();
    _bursts.clear();
    _spawnDelays.clear();
    _timeRemaining = 90.0;
    _score = 0;
    _lives = 5;
    _combo = 0;
    _lastFulfillTime = -10.0;
    _comboDisplayScale = 1.0;
    _moleculesBuilt = 0;
    _ordersTotal = 0;
    _ordersFilled = 0;
    _dragIndex = null;
    _gameOver = false;
    _gameOverReason = '';
    _elapsed = 0.0;

    if (_screenSize != Size.zero) {
      // Spawn initial atoms
      for (int i = 0; i < _targetAtomCount; i++) {
        _spawnAtomImmediate();
      }
      // Spawn initial orders
      for (int i = 0; i < 3; i++) {
        _addNewOrder();
      }
    }
  }

  // ---- atom spawning ------------------------------------------------------

  String _pickAtomType() {
    // 30% chance to pick a type needed by active orders
    if (_orders.isNotEmpty && _rng.nextDouble() < 0.30) {
      final needed = <String>[];
      for (final order in _orders) {
        if (!order.fulfilled && !order.expired) {
          needed.addAll(order.recipe.atoms);
        }
      }
      if (needed.isNotEmpty) {
        return needed[_rng.nextInt(needed.length)];
      }
    }
    return _kSpawnPool[_rng.nextInt(_kSpawnPool.length)];
  }

  void _spawnAtomImmediate() {
    if (_screenSize == Size.zero) return;
    final type = _pickAtomType();
    final radius = _kAtomRadii[type] ?? 16.0;
    final margin = radius + 4.0;
    final x = margin + _rng.nextDouble() * (_screenSize.width - margin * 2);
    final y = 120.0 + _rng.nextDouble() * (_screenSize.height - 200.0);
    final speed = 20.0 + _rng.nextDouble() * 30.0;
    final angle = _rng.nextDouble() * 2.0 * pi;
    _atoms.add(_Atom(
      type: type,
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
    )..nudgeTimer = _rng.nextDouble() * 0.4);
  }

  void _spawnAtomFromEdge() {
    if (_screenSize == Size.zero) return;
    final type = _pickAtomType();
    final radius = _kAtomRadii[type] ?? 16.0;
    final edge = _rng.nextInt(4);
    double x, y;
    switch (edge) {
      case 0:
        x = _rng.nextDouble() * _screenSize.width;
        y = -radius;
        break;
      case 1:
        x = _screenSize.width + radius;
        y = 120.0 + _rng.nextDouble() * (_screenSize.height - 200.0);
        break;
      case 2:
        x = _rng.nextDouble() * _screenSize.width;
        y = _screenSize.height + radius;
        break;
      default:
        x = -radius;
        y = 120.0 + _rng.nextDouble() * (_screenSize.height - 200.0);
    }
    // Aim inward
    final tx = _screenSize.width * (0.2 + _rng.nextDouble() * 0.6);
    final ty = _screenSize.height * (0.25 + _rng.nextDouble() * 0.5);
    final angle = atan2(ty - y, tx - x);
    final speed = 25.0 + _rng.nextDouble() * 35.0;
    _atoms.add(_Atom(
      type: type,
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
    )..nudgeTimer = _rng.nextDouble() * 0.4);
  }

  // ---- order management ---------------------------------------------------

  _Recipe _pickRecipe() {
    final r = _rng.nextDouble();
    List<double> weights;
    if (_score < 100) {
      weights = [0.50, 0.30, 0.20, 0.0, 0.0, 0.0];
    } else if (_score < 300) {
      weights = [0.30, 0.25, 0.25, 0.20, 0.0, 0.0];
    } else if (_score < 500) {
      weights = [0.15, 0.25, 0.20, 0.25, 0.15, 0.0];
    } else {
      weights = [0.10, 0.20, 0.15, 0.20, 0.20, 0.15];
    }
    double cumulative = 0.0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (r < cumulative) return _kRecipes[i];
    }
    return _kRecipes[0];
  }

  void _addNewOrder() {
    final recipe = _pickRecipe();
    _orders.add(_Order(recipe: recipe));
    _ordersTotal++;
  }

  int get _maxOrders => _score > 500 ? 4 : 3;

  // ---- tick ---------------------------------------------------------------

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || !_started) return;

    setState(() {
      _elapsed += dt;
      _timeRemaining -= dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _gameOver = true;
        _gameOverReason = 'TIME';
        _dragIndex = null;
        return;
      }

      // Update atoms
      _updateAtoms(dt);

      // Auto-formation: check if atoms naturally drifted close enough to form a recipe
      _checkAutoFormation();

      // Update orders
      _updateOrders(dt);

      // Spawn delays
      _processSpawnDelays(dt);

      // Maintain atom count
      final deficit = _targetAtomCount - _atoms.length - _spawnDelays.length;
      if (deficit > 0) {
        for (int i = 0; i < deficit; i++) {
          _spawnDelays.add(0.3 + _rng.nextDouble() * 0.2);
        }
      }

      // Update popups
      for (final p in _popups) {
        p.age += dt;
        p.y -= 35.0 * dt;
      }
      _popups.removeWhere((p) => p.age > 1.5);

      // Update bursts
      for (final b in _bursts) {
        b.age += dt;
      }
      _bursts.removeWhere((b) => b.age > 0.3);

      // Combo display scale decay
      if (_comboDisplayScale > 1.0) {
        _comboDisplayScale = (_comboDisplayScale - dt * 4.0).clamp(1.0, 2.0);
      }
    });
  }

  void _updateAtoms(double dt) {
    for (int i = 0; i < _atoms.length; i++) {
      final a = _atoms[i];
      if (i == _dragIndex) continue; // dragged atom is controlled by finger

      // Brownian motion nudge — gentle drift
      a.nudgeTimer -= dt;
      if (a.nudgeTimer <= 0) {
        a.nudgeTimer = 0.5 + _rng.nextDouble() * 0.3;
        final nudgeStrength = 8.0 + _rng.nextDouble() * 10.0;
        final angle = _rng.nextDouble() * 2.0 * pi;
        a.vx += cos(angle) * nudgeStrength;
        a.vy += sin(angle) * nudgeStrength;
      }

      // Damping
      a.vx *= (1.0 - 1.5 * dt);
      a.vy *= (1.0 - 1.5 * dt);

      // Clamp velocity
      final speed = sqrt(a.vx * a.vx + a.vy * a.vy);
      if (speed > 60.0) {
        a.vx = a.vx / speed * 60.0;
        a.vy = a.vy / speed * 60.0;
      }

      // Move
      a.x += a.vx * dt;
      a.y += a.vy * dt;

      // Bounce off edges
      if (a.x - a.radius < 0) {
        a.x = a.radius;
        a.vx = a.vx.abs();
      } else if (a.x + a.radius > _screenSize.width) {
        a.x = _screenSize.width - a.radius;
        a.vx = -a.vx.abs();
      }
      if (a.y - a.radius < 90) {
        a.y = 90 + a.radius;
        a.vy = a.vy.abs();
      } else if (a.y + a.radius > _screenSize.height - 60) {
        a.y = _screenSize.height - 60 - a.radius;
        a.vy = -a.vy.abs();
      }
    }

    // Soft-body repulsion between atoms
    for (int i = 0; i < _atoms.length; i++) {
      for (int j = i + 1; j < _atoms.length; j++) {
        if (i == _dragIndex || j == _dragIndex) continue;
        final a = _atoms[i];
        final b = _atoms[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final dist = sqrt(dx * dx + dy * dy);
        final minDist = a.radius + b.radius + 2.0;
        if (dist < minDist && dist > 0.01) {
          final overlap = minDist - dist;
          final nx = dx / dist;
          final ny = dy / dist;
          final push = overlap * 2.0;
          a.vx -= nx * push;
          a.vy -= ny * push;
          b.vx += nx * push;
          b.vy += ny * push;
        }
      }
    }
  }

  void _updateOrders(double dt) {
    for (final order in _orders) {
      if (order.fulfilled || order.expired) {
        order.flashAge += dt;
        continue;
      }
      order.timeLeft -= dt;
      if (order.timeLeft <= 0) {
        order.expired = true;
        order.flashAge = 0.0;
        _lives--;
        if (_lives <= 0) {
          _gameOver = true;
          _gameOverReason = 'NO LIVES';
          _dragIndex = null;
          return;
        }
      }
    }

    // Remove fulfilled/expired orders that have finished their flash animation
    _orders.removeWhere(
        (o) => (o.fulfilled || o.expired) && o.flashAge > 0.5);

    // Refill orders
    while (_orders.where((o) => !o.fulfilled && !o.expired).length < _maxOrders) {
      _addNewOrder();
    }
  }

  void _processSpawnDelays(double dt) {
    for (int i = _spawnDelays.length - 1; i >= 0; i--) {
      _spawnDelays[i] -= dt;
      if (_spawnDelays[i] <= 0) {
        _spawnDelays.removeAt(i);
        _spawnAtomFromEdge();
      }
    }
  }

  // ---- molecule matching --------------------------------------------------

  void _tryBuildMolecule(int droppedIndex) {
    if (droppedIndex < 0 || droppedIndex >= _atoms.length) return;
    final dropped = _atoms[droppedIndex];

    // Find all atoms within bonding distance of the dropped atom
    final List<int> neighbors = [];
    for (int i = 0; i < _atoms.length; i++) {
      if (i == droppedIndex) continue;
      final a = _atoms[i];
      final dx = a.x - dropped.x;
      final dy = a.y - dropped.y;
      final dist = sqrt(dx * dx + dy * dy);
      final bondDist = (a.radius + dropped.radius) * 2.5;
      if (dist < bondDist) {
        neighbors.add(i);
      }
    }

    if (neighbors.isEmpty) return;

    // Build full cluster: dropped + all neighbors
    final List<int> cluster = [droppedIndex, ...neighbors];

    // Try all subsets that include the dropped atom, find largest recipe match
    // that is in the order queue (preferred) or any recipe match
    int bestSize = 0;
    String bestKey = '';
    List<int> bestIndices = [];
    bool bestIsOrder = false;

    // Generate subsets of neighbors (2^n where n = neighbors.length, max ~7)
    final int nCount = neighbors.length;
    final int subsetCount = 1 << nCount; // 2^n

    for (int mask = 0; mask < subsetCount; mask++) {
      final List<int> subset = [droppedIndex];
      for (int b = 0; b < nCount; b++) {
        if ((mask >> b) & 1 == 1) {
          subset.add(neighbors[b]);
        }
      }
      if (subset.length < 2) continue; // need at least 2 atoms

      // Sort atom types and build key
      final List<String> types = [];
      for (final idx in subset) {
        types.add(_atoms[idx].type);
      }
      types.sort();
      final key = types.join(',');

      final recipe = _kRecipeMap[key];
      if (recipe == null) continue;

      // Check if this recipe is in the active order queue
      bool isOrder = false;
      for (final order in _orders) {
        if (!order.fulfilled && !order.expired && order.recipe.key == key) {
          isOrder = true;
          break;
        }
      }

      // Prefer order matches; among equal preference, pick largest
      if (isOrder && !bestIsOrder) {
        bestSize = subset.length;
        bestKey = key;
        bestIndices = List.of(subset);
        bestIsOrder = true;
      } else if (isOrder == bestIsOrder && subset.length > bestSize) {
        bestSize = subset.length;
        bestKey = key;
        bestIndices = List.of(subset);
        bestIsOrder = isOrder;
      }
    }

    if (bestKey.isEmpty) {
      // No recipe match — repulsion burst
      _applyRepulsionBurst(dropped.x, dropped.y, cluster);
      return;
    }

    final recipe = _kRecipeMap[bestKey]!;

    // Calculate center of consumed atoms for popup
    double cx = 0, cy = 0;
    for (final idx in bestIndices) {
      cx += _atoms[idx].x;
      cy += _atoms[idx].y;
    }
    cx /= bestIndices.length;
    cy /= bestIndices.length;

    if (bestIsOrder) {
      // Fulfill the order
      _Order? targetOrder;
      for (final order in _orders) {
        if (!order.fulfilled && !order.expired && order.recipe.key == bestKey) {
          targetOrder = order;
          break;
        }
      }
      if (targetOrder != null) {
        targetOrder.fulfilled = true;
        targetOrder.flashAge = 0.0;
        _ordersFilled++;
      }

      // Combo check
      final now = _elapsed;
      if (now - _lastFulfillTime < 3.0) {
        _combo++;
        _comboDisplayScale = 1.6;
      } else {
        _combo = 0;
      }
      _lastFulfillTime = now;

      final double multiplier = 1.0 + _combo * 0.25;
      final int points = (recipe.points * multiplier).round();
      _score += points;
      _moleculesBuilt++;

      _popups.add(_Popup(
        x: cx,
        y: cy,
        text: '${recipe.formula} +$points',
        color: const Color(0xFF4CAF50),
      ));
    } else {
      // Bonus — recipe valid but not in order queue
      _score += 5;
      _moleculesBuilt++;

      _popups.add(_Popup(
        x: cx,
        y: cy,
        text: '${recipe.formula} bonus +5',
        color: const Color(0xFFFFB74D),
      ));
    }

    // Remove consumed atoms (sort indices descending to avoid shifting)
    bestIndices.sort((a, b) => b.compareTo(a));
    for (final idx in bestIndices) {
      _atoms.removeAt(idx);
    }
    // Fix drag index (should be null after drop, but be safe)
    _dragIndex = null;
  }

  void _applyRepulsionBurst(double cx, double cy, List<int> cluster) {
    _bursts.add(_RepulsionBurst(x: cx, y: cy));
    for (final idx in cluster) {
      if (idx < _atoms.length) {
        final a = _atoms[idx];
        final dx = a.x - cx;
        final dy = a.y - cy;
        final dist = sqrt(dx * dx + dy * dy).clamp(1.0, 1000.0);
        a.vx += (dx / dist) * 150.0;
        a.vy += (dy / dist) * 150.0;
      }
    }
  }

  // ---- auto-formation: atoms close enough form molecules on their own -----

  void _checkAutoFormation() {
    // For each atom, find its cluster of touching neighbors and check recipes.
    // Only auto-form if ALL atoms in the cluster are within tight proximity
    // (tighter than manual bonding — 1.1x sum of radii).
    // Skip if player is currently dragging.
    if (_dragIndex != null) return;

    final used = <int>{};
    for (int i = 0; i < _atoms.length; i++) {
      if (used.contains(i)) continue;
      // BFS from atom i to find tight cluster
      final cluster = <int>[i];
      final queue = <int>[i];
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        final ac = _atoms[cur];
        for (int j = 0; j < _atoms.length; j++) {
          if (cluster.contains(j) || used.contains(j)) continue;
          final aj = _atoms[j];
          final dx = aj.x - ac.x;
          final dy = aj.y - ac.y;
          final dist = sqrt(dx * dx + dy * dy);
          // Proximity threshold for auto-formation
          if (dist < (ac.radius + aj.radius) * 1.4) {
            cluster.add(j);
            queue.add(j);
          }
        }
        if (cluster.length > 8) break; // cap search
      }
      if (cluster.length < 2) continue;

      // Check if cluster matches a recipe (try full cluster first, then subsets)
      final types = cluster.map((idx) => _atoms[idx].type).toList()..sort();
      final key = types.join(',');
      final recipe = _kRecipeMap[key];
      if (recipe == null) continue;

      // Check if it matches an active order
      bool isOrder = false;
      _Order? targetOrder;
      for (final order in _orders) {
        if (!order.fulfilled && !order.expired && order.recipe.key == key) {
          isOrder = true;
          targetOrder = order;
          break;
        }
      }

      // Calculate center
      double cx = 0, cy = 0;
      for (final idx in cluster) {
        cx += _atoms[idx].x;
        cy += _atoms[idx].y;
      }
      cx /= cluster.length;
      cy /= cluster.length;

      // Score it
      if (isOrder && targetOrder != null) {
        targetOrder.fulfilled = true;
        targetOrder.flashAge = 0.0;
        _ordersFilled++;
        final now = _elapsed;
        if (now - _lastFulfillTime < 3.0) {
          _combo++;
          _comboDisplayScale = 1.6;
        } else {
          _combo = 0;
        }
        _lastFulfillTime = now;
        final double multiplier = 1.0 + _combo * 0.25;
        final int points = (recipe.points * multiplier).round();
        _score += points;
        _moleculesBuilt++;
        _popups.add(_Popup(x: cx, y: cy, text: '${recipe.formula} +$points', color: const Color(0xFF4CAF50)));
      } else {
        _score += 5;
        _moleculesBuilt++;
        _popups.add(_Popup(x: cx, y: cy, text: '${recipe.formula} bonus +5', color: const Color(0xFFFFB74D)));
      }

      // Remove consumed atoms
      for (final idx in cluster) {
        used.add(idx);
      }
      final sorted = cluster.toList()..sort((a, b) => b.compareTo(a));
      for (final idx in sorted) {
        _atoms.removeAt(idx);
      }
      // Indices shifted — break and let next tick catch more
      break;
    }
  }

  // ---- nearby atoms for visual hint ---------------------------------------

  List<int> _getNearbyAtoms(int dragIdx) {
    if (dragIdx < 0 || dragIdx >= _atoms.length) return [];
    final dropped = _atoms[dragIdx];
    final List<int> result = [];
    for (int i = 0; i < _atoms.length; i++) {
      if (i == dragIdx) continue;
      final a = _atoms[i];
      final dx = a.x - dropped.x;
      final dy = a.y - dropped.y;
      final dist = sqrt(dx * dx + dy * dy);
      final bondDist = (a.radius + dropped.radius) * 2.5;
      if (dist < bondDist) {
        result.add(i);
      }
    }
    return result;
  }

  // ---- input --------------------------------------------------------------

  void _onPanStart(Offset pos) {
    if (_gameOver) {
      _initGame();
      _started = true;
      return;
    }
    if (!_started) {
      _initGame();
      _started = true;
      return;
    }

    // Find closest atom to tap
    double bestDist = double.infinity;
    int bestIdx = -1;
    for (int i = 0; i < _atoms.length; i++) {
      final a = _atoms[i];
      final dx = a.x - pos.dx;
      final dy = a.y - pos.dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < a.radius + 20.0 && dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    if (bestIdx >= 0) {
      _dragIndex = bestIdx;
    }
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex != null && _dragIndex! < _atoms.length) {
      final dragged = _atoms[_dragIndex!];
      dragged.x = pos.dx;
      dragged.y = pos.dy;

      // Magnetic attraction: gently pull nearby atoms toward the dragged atom
      final magnetRange = (dragged.radius + 20) * 3.5;
      for (int i = 0; i < _atoms.length; i++) {
        if (i == _dragIndex) continue;
        final a = _atoms[i];
        final dx = dragged.x - a.x;
        final dy = dragged.y - a.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < magnetRange && dist > 0.01) {
          final strength = 40.0 * (1.0 - dist / magnetRange);
          a.vx += (dx / dist) * strength;
          a.vy += (dy / dist) * strength;
        }
      }
    }
  }

  void _onPanEnd() {
    if (_dragIndex != null) {
      final idx = _dragIndex!;
      _dragIndex = null;
      if (idx < _atoms.length) {
        _tryBuildMolecule(idx);
      }
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _screenSize = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        onTapDown: (d) {
          if (_gameOver || !_started) {
            _onPanStart(d.localPosition);
          }
        },
        child: ClipRect(
          child: CustomPaint(
            painter: _MoleculeBuilderPainter(
              atoms: _atoms,
              orders: _orders,
              popups: _popups,
              bursts: _bursts,
              dragIndex: _dragIndex,
              nearbyAtoms:
                  _dragIndex != null ? _getNearbyAtoms(_dragIndex!) : [],
              timeRemaining: _timeRemaining,
              score: _score,
              lives: _lives,
              combo: _combo,
              comboScale: _comboDisplayScale,
              gameOver: _gameOver,
              gameOverReason: _gameOverReason,
              started: _started,
              moleculesBuilt: _moleculesBuilt,
              ordersTotal: _ordersTotal,
              ordersFilled: _ordersFilled,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _MoleculeBuilderPainter extends CustomPainter {
  final List<_Atom> atoms;
  final List<_Order> orders;
  final List<_Popup> popups;
  final List<_RepulsionBurst> bursts;
  final int? dragIndex;
  final List<int> nearbyAtoms;
  final double timeRemaining;
  final int score;
  final int lives;
  final int combo;
  final double comboScale;
  final bool gameOver;
  final String gameOverReason;
  final bool started;
  final int moleculesBuilt;
  final int ordersTotal;
  final int ordersFilled;

  _MoleculeBuilderPainter({
    required this.atoms,
    required this.orders,
    required this.popups,
    required this.bursts,
    required this.dragIndex,
    required this.nearbyAtoms,
    required this.timeRemaining,
    required this.score,
    required this.lives,
    required this.combo,
    required this.comboScale,
    required this.gameOver,
    required this.gameOverReason,
    required this.started,
    required this.moleculesBuilt,
    required this.ordersTotal,
    required this.ordersFilled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBgColor);

    // Red flash for repulsion bursts
    for (final b in bursts) {
      final a = (1.0 - b.age / 0.3).clamp(0.0, 1.0) * 0.12;
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFFFF1744).withValues(alpha: a));
    }

    if (!started && !gameOver) {
      _drawPreGame(canvas, size);
      return;
    }

    // Draw bond hint lines from dragged atom to nearby atoms
    if (dragIndex != null && dragIndex! < atoms.length) {
      final dragged = atoms[dragIndex!];
      for (final ni in nearbyAtoms) {
        if (ni < atoms.length) {
          final neighbor = atoms[ni];
          _drawBondLine(canvas, dragged, neighbor);
        }
      }
    }

    // Draw atoms
    for (int i = 0; i < atoms.length; i++) {
      _drawAtom(canvas, atoms[i], i == dragIndex);
    }

    // Draw order cards
    _drawOrderCards(canvas, size);

    // Draw HUD
    _drawHud(canvas, size);

    // Draw popups
    for (final p in popups) {
      final alpha = (1.0 - p.age / 1.5).clamp(0.0, 1.0);
      final scale = 1.0 + p.age * 0.15;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    // Game over overlay
    if (gameOver) {
      _drawGameOver(canvas, size);
    }
  }

  void _drawAtom(Canvas canvas, _Atom atom, bool isDragged) {
    final center = Offset(atom.x, atom.y);

    // Outer glow
    final glowRadius = isDragged ? atom.radius + 8.0 : atom.radius + 3.0;
    final glowAlpha = isDragged ? 0.25 : 0.15;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(center, glowRadius, [
          atom.color.withValues(alpha: glowAlpha),
          atom.color.withValues(alpha: 0.0),
        ]),
    );

    // Fill
    final fillAlpha = isDragged ? 0.95 : 0.85;
    canvas.drawCircle(
      center,
      atom.radius,
      Paint()..color = atom.color.withValues(alpha: fillAlpha),
    );

    // Subtle inner highlight
    canvas.drawCircle(
      Offset(atom.x - atom.radius * 0.25, atom.y - atom.radius * 0.25),
      atom.radius * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(atom.x - atom.radius * 0.25, atom.y - atom.radius * 0.25),
          atom.radius * 0.5,
          [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
    );

    // Border
    canvas.drawCircle(
      center,
      atom.radius,
      Paint()
        ..color = atom.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Element letter
    final tp = TextPainter(
      text: TextSpan(
        text: atom.type,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: atom.radius * 0.9,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(atom.x - tp.width / 2, atom.y - tp.height / 2));
  }

  void _drawBondLine(Canvas canvas, _Atom from, _Atom to) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.1) return;
    final nx = dx / dist;
    final ny = dy / dist;

    const dashLen = 4.0;
    const gapLen = 4.0;
    double d = from.radius;
    final end = dist - to.radius;
    while (d < end) {
      final x1 = from.x + nx * d;
      final y1 = from.y + ny * d;
      final d2 = (d + dashLen).clamp(0.0, end);
      final x2 = from.x + nx * d2;
      final y2 = from.y + ny * d2;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      d += dashLen + gapLen;
    }
  }

  void _drawOrderCards(Canvas canvas, Size size) {
    final activeOrders =
        orders.where((o) => !o.fulfilled || o.flashAge < 0.5).toList();
    if (activeOrders.isEmpty) return;

    final cardW = 80.0;
    final cardH = 68.0;
    final gap = 8.0;
    final totalW =
        activeOrders.length * cardW + (activeOrders.length - 1) * gap;
    double startX = (size.width - totalW) / 2;
    final topY = 12.0;

    for (final order in activeOrders) {
      final rect =
          RRect.fromRectAndRadius(Rect.fromLTWH(startX, topY, cardW, cardH), const Radius.circular(8));

      // Flash effect
      Color cardBg = const Color(0xFF1A1A2E);
      if (order.fulfilled && order.flashAge < 0.5) {
        final flashA = (1.0 - order.flashAge / 0.5).clamp(0.0, 1.0) * 0.4;
        cardBg = Color.lerp(
            cardBg, const Color(0xFF4CAF50), flashA)!;
      } else if (order.expired && order.flashAge < 0.5) {
        final flashA = (1.0 - order.flashAge / 0.5).clamp(0.0, 1.0) * 0.4;
        cardBg = Color.lerp(
            cardBg, const Color(0xFFFF1744), flashA)!;
      }

      // Card background
      canvas.drawRRect(
          rect, Paint()..color = cardBg);

      // Card border
      canvas.drawRRect(
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Formula text
      final formulaTp = TextPainter(
        text: TextSpan(
          text: order.recipe.formula,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      formulaTp.paint(
          canvas,
          Offset(startX + (cardW - formulaTp.width) / 2, topY + 6));

      // Atom dots
      final atomDots = order.recipe.atoms;
      final dotSize = 5.0;
      final dotGap = 3.0;
      final dotsW =
          atomDots.length * dotSize * 2 + (atomDots.length - 1) * dotGap;
      double dotX = startX + (cardW - dotsW) / 2;
      final dotY = topY + 28.0;
      for (final atomType in atomDots) {
        final dotColor = _kAtomColors[atomType] ?? Colors.white;
        canvas.drawCircle(
          Offset(dotX + dotSize, dotY + dotSize),
          dotSize,
          Paint()..color = dotColor.withValues(alpha: 0.8),
        );
        dotX += dotSize * 2 + dotGap;
      }

      // Timer bar (only for active orders)
      if (!order.fulfilled && !order.expired) {
        final barY = topY + cardH - 10.0;
        final barW = cardW - 12.0;
        final barH = 4.0;
        final barX = startX + 6.0;
        final progress =
            (order.timeLeft / order.totalTime).clamp(0.0, 1.0);

        // Bar background
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: 0.08),
        );

        // Bar fill
        Color barColor;
        if (progress > 0.5) {
          barColor = const Color(0xFF4CAF50);
        } else if (progress > 0.25) {
          barColor = const Color(0xFFFFEB3B);
        } else {
          barColor = const Color(0xFFFF5252);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, barY, barW * progress, barH),
              const Radius.circular(2)),
          Paint()..color = barColor.withValues(alpha: 0.8),
        );
      }

      startX += cardW + gap;
    }
  }

  void _drawHud(Canvas canvas, Size size) {
    // Lives — top-left
    for (int i = 0; i < 5; i++) {
      final cx = 20.0 + i * 18.0;
      final cy = 24.0;
      if (i < lives) {
        canvas.drawCircle(
            Offset(cx, cy), 5.0, Paint()..color = const Color(0xFF4CAF50));
      } else {
        canvas.drawCircle(
          Offset(cx, cy),
          5.0,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Time — top-right
    final timeTp = TextPainter(
      text: TextSpan(
        text: '${timeRemaining.toInt()}s',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timeTp.paint(canvas, Offset(size.width - timeTp.width - 16, 16));

    // Score — bottom-center
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 22,
          fontWeight: FontWeight.w300,
          color: Colors.white.withValues(alpha: 0.38),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(
        canvas,
        Offset(
            (size.width - scoreTp.width) / 2, size.height - 48));

    // Combo — bottom-right
    if (combo > 0) {
      final comboTp = TextPainter(
        text: TextSpan(
          text: 'x${combo + 1}',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18 * comboScale,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFB74D),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      comboTp.paint(
          canvas,
          Offset(size.width - comboTp.width - 20, size.height - 48));
    }
  }

  void _drawPreGame(Canvas canvas, Size size) {
    _drawCentered(canvas, size, 'Molecule Builder', 28,
        Colors.white.withValues(alpha: 0.54), -50);
    _drawCentered(canvas, size, 'Drag an atom near others to combine them.', 14,
        Colors.white.withValues(alpha: 0.24), -10);
    _drawCentered(canvas, size, 'Match the formulas at the top!', 14,
        Colors.white.withValues(alpha: 0.24), 10);
    _drawCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.24), 40);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    // Overlay
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.8));

    // Title
    _drawCentered(canvas, size, gameOverReason, 38,
        Colors.white.withValues(alpha: 0.54), -60);

    // Score
    _drawCentered(canvas, size, '$score', 52,
        Colors.white.withValues(alpha: 0.70), 0);

    // Stats
    final pct =
        ordersTotal > 0 ? (ordersFilled * 100 / ordersTotal).round() : 0;
    _drawCentered(
        canvas,
        size,
        '$moleculesBuilt molecules built \u00B7 $pct% orders filled',
        14,
        Colors.white.withValues(alpha: 0.38),
        50);

    // Restart hint
    _drawCentered(canvas, size, 'Tap to restart', 14,
        Colors.white.withValues(alpha: 0.24), 80);
  }

  void _drawCentered(Canvas canvas, Size size, String text, double fontSize,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2,
            (size.height - tp.height) / 2 + yOff));
  }

  @override
  bool shouldRepaint(covariant _MoleculeBuilderPainter old) => true;
}
