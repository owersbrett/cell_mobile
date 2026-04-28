import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ===========================================================================
// SYSTEM LINK — Manage a potato plant's organ systems.
//
// Route resources between four organ system nodes while squishing pests
// that crawl in from the edges. Keep every system alive as long as possible.
// ===========================================================================

// ---- constants -------------------------------------------------------------

const Color _kBg = Color(0xFF1A0E0A);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kBrown = Color(0xFF8D6E63);
const Color _kTan = Color(0xFFD4A056);
const Color _kWaterBlue = Color(0xFF42A5F5);
const Color _kSugarYellow = Color(0xFFFDD835);
const Color _kNutrientPurple = Color(0xFFCE93D8);
const Color _kPestRed = Color(0xFFFF5722);

// ---- enums -----------------------------------------------------------------

enum _OrganType { root, shoot, vascular, reproductive }

enum _ResourceType { water, sugar, nutrient }

enum _PestKind { aphid, beetle }

// ---- data classes ----------------------------------------------------------

class _OrganNode {
  final _OrganType type;
  final String label;
  final Color color;
  final String icon; // text glyph
  double x, y;
  double health;
  double maxHealth;
  _ResourceType? needs; // current resource need (null = satisfied for now)
  double needTimer; // time until need becomes urgent
  double needUrgency; // 0..1 how urgent the need is
  double damageFlash; // flash timer when damaged
  double healFlash; // flash timer when healed
  double pulsePhase;

  _OrganNode({
    required this.type,
    required this.label,
    required this.color,
    required this.icon,
    this.x = 0,
    this.y = 0,
    this.health = 100,
    this.maxHealth = 100,
    this.needs,
    this.needTimer = 0,
    this.needUrgency = 0,
    this.damageFlash = 0,
    this.healFlash = 0,
    this.pulsePhase = 0,
  });
}

class _Resource {
  _ResourceType type;
  double x, y;
  double age;
  bool grabbed; // being dragged by player
  double bobPhase;

  _Resource({
    required this.type,
    required this.x,
    required this.y,
    this.age = 0,
    this.grabbed = false,
    this.bobPhase = 0,
  });

  Color get color {
    switch (type) {
      case _ResourceType.water:
        return _kWaterBlue;
      case _ResourceType.sugar:
        return _kSugarYellow;
      case _ResourceType.nutrient:
        return _kNutrientPurple;
    }
  }

  String get symbol {
    switch (type) {
      case _ResourceType.water:
        return 'W';
      case _ResourceType.sugar:
        return 'S';
      case _ResourceType.nutrient:
        return 'N';
    }
  }

  String get name {
    switch (type) {
      case _ResourceType.water:
        return 'Water';
      case _ResourceType.sugar:
        return 'Sugar';
      case _ResourceType.nutrient:
        return 'Nutrient';
    }
  }
}

class _Pest {
  _PestKind kind;
  double x, y;
  double vx, vy;
  _OrganType target;
  double health;
  bool dead;
  double deathAge;
  double size;
  double wobblePhase;

  _Pest({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.target,
    this.health = 1.0,
    this.dead = false,
    this.deathAge = 0,
    this.size = 14,
    this.wobblePhase = 0,
  });

  Color get color => _kPestRed;
}

class _FlowParticle {
  double x, y;
  double progress; // 0..1 along the connection path
  Color color;
  int fromIndex, toIndex;
  double speed;

  _FlowParticle({
    required this.x,
    required this.y,
    required this.progress,
    required this.color,
    required this.fromIndex,
    required this.toIndex,
    this.speed = 0.6,
  });
}

class _FxDot {
  double x, y, vx, vy, life, size;
  Color color;
  _FxDot({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 3,
  });
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup(this.x, this.y, this.text, this.color) : age = 0;
}

// Delivery animation: resource flying from source to target node
class _Delivery {
  double fromX, fromY, toX, toY;
  double progress; // 0..1
  Color color;
  _ResourceType type;
  _Delivery({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.progress = 0,
    required this.color,
    required this.type,
  });
}

// ---- connections between nodes (fixed topology) ----------------------------

class _Connection {
  final int a, b;
  const _Connection(this.a, this.b);
}

// Diamond: root(0)-vascular(2), root(0)-reproductive(3),
//          shoot(1)-vascular(2), shoot(1)-reproductive(3),
//          vascular(2)-root(0), vascular(2)-shoot(1)
// Basically a fully connected diamond but we show the 4 edges of the diamond
// plus the 2 diagonals = vascular connections.
const _kConnections = <_Connection>[
  _Connection(0, 2), // root  ↔ vascular
  _Connection(0, 3), // root  ↔ reproductive
  _Connection(1, 2), // shoot ↔ vascular
  _Connection(1, 3), // shoot ↔ reproductive
  _Connection(2, 3), // vascular ↔ reproductive (cross)
  _Connection(0, 1), // root  ↔ shoot (vertical through middle)
];

// ---- widget ----------------------------------------------------------------

class OrganSystemGame extends StatefulWidget {
  const OrganSystemGame({Key? key}) : super(key: key);
  @override
  State<OrganSystemGame> createState() => _OrganSystemGameState();
}

class _OrganSystemGameState extends State<OrganSystemGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // ---- game state ----------------------------------------------------------
  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  double _comboTimer = 0; // time since last pest kill for combo decay
  int _deliveries = 0;
  int _pestsKilled = 0;
  double _elapsed = 0; // total time survived
  double _difficulty = 1.0; // ramps over time
  double _lastT = 0;

  // tutorial
  double _tutorialAge = 0;
  bool _tutorialDismissed = false;

  // nodes
  final List<_OrganNode> _nodes = [];

  // resources on screen
  final List<_Resource> _resources = [];
  double _resourceSpawnTimer = 0;

  // pests
  final List<_Pest> _pests = [];
  double _pestSpawnTimer = 0;

  // flow particles along connections
  final List<_FlowParticle> _flowParticles = [];

  // deliveries in flight
  final List<_Delivery> _activeDeliveries = [];

  // effects
  final List<_FxDot> _fx = [];
  final List<_Popup> _pops = [];

  // drag state
  int? _dragResourceIndex;
  // drag state (continued)

  // need generation
  double _needCycleTimer = 0;

  Size _sz = Size.zero;

  // ---- lifecycle -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- init game -----------------------------------------------------------

  void _initGame() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _comboTimer = 0;
    _deliveries = 0;
    _pestsKilled = 0;
    _elapsed = 0;
    _difficulty = 1.0;
    _gameOver = false;
    _started = true;
    _tutorialAge = 0;
    _tutorialDismissed = false;
    _resources.clear();
    _pests.clear();
    _flowParticles.clear();
    _activeDeliveries.clear();
    _fx.clear();
    _pops.clear();
    _dragResourceIndex = null;
    _resourceSpawnTimer = 0;
    _pestSpawnTimer = 2.5; // grace period before first pest
    _needCycleTimer = 0;

    _buildNodes();
  }

  void _buildNodes() {
    _nodes.clear();
    if (_sz == Size.zero) return;

    final cx = _sz.width / 2;
    final cy = _sz.height * 0.46;
    final spread = min(_sz.width * 0.30, _sz.height * 0.18);

    _nodes.addAll([
      _OrganNode(
        type: _OrganType.root,
        label: 'Roots',
        color: _kBrown,
        icon: 'R',
        x: cx,
        y: cy + spread,
        pulsePhase: 0,
      ),
      _OrganNode(
        type: _OrganType.shoot,
        label: 'Shoots',
        color: _kGreen,
        icon: 'S',
        x: cx,
        y: cy - spread,
        pulsePhase: 1.2,
      ),
      _OrganNode(
        type: _OrganType.vascular,
        label: 'Vascular',
        color: _kTan,
        icon: 'V',
        x: cx - spread * 1.1,
        y: cy,
        pulsePhase: 2.4,
      ),
      _OrganNode(
        type: _OrganType.reproductive,
        label: 'Reprod.',
        color: const Color(0xFFE8A0BF),
        icon: 'F',
        x: cx + spread * 1.1,
        y: cy,
        pulsePhase: 3.6,
      ),
    ]);

    // Start with initial needs
    _assignNewNeeds();
  }

  // ---- needs assignment ----------------------------------------------------

  void _assignNewNeeds() {
    final types = _ResourceType.values;
    for (final node in _nodes) {
      if (node.needs == null) {
        // Roots produce water, shoots produce sugar — they don't need what
        // they produce. Other nodes can need anything.
        final available = <_ResourceType>[];
        for (final t in types) {
          if (node.type == _OrganType.root && t == _ResourceType.water) continue;
          if (node.type == _OrganType.shoot && t == _ResourceType.sugar) continue;
          available.add(t);
        }
        if (_rng.nextDouble() < 0.6) {
          node.needs = available[_rng.nextInt(available.length)];
          node.needTimer = 0;
          node.needUrgency = 0;
        }
      }
    }
  }

  // ---- resource spawning ---------------------------------------------------

  void _spawnResource() {
    if (_resources.length >= 6) return; // cap on-screen resources

    // Water spawns near roots, sugar near shoots, nutrients at random
    final roll = _rng.nextDouble();
    _ResourceType type;
    double sx, sy;

    if (roll < 0.4) {
      type = _ResourceType.water;
      final rootNode = _nodes[0];
      sx = rootNode.x + (_rng.nextDouble() - 0.5) * 80;
      sy = rootNode.y + 30 + _rng.nextDouble() * 40;
    } else if (roll < 0.75) {
      type = _ResourceType.sugar;
      final shootNode = _nodes[1];
      sx = shootNode.x + (_rng.nextDouble() - 0.5) * 80;
      sy = shootNode.y - 30 - _rng.nextDouble() * 40;
    } else {
      type = _ResourceType.nutrient;
      // Nutrients appear near roots or vascular
      final srcNode = _nodes[_rng.nextBool() ? 0 : 2];
      sx = srcNode.x + (_rng.nextDouble() - 0.5) * 70;
      sy = srcNode.y + (_rng.nextDouble() - 0.5) * 70;
    }

    // Clamp to screen
    sx = sx.clamp(20, _sz.width - 20);
    sy = sy.clamp(60, _sz.height - 40);

    _resources.add(_Resource(
      type: type,
      x: sx,
      y: sy,
      bobPhase: _rng.nextDouble() * 2 * pi,
    ));
  }

  // ---- pest spawning -------------------------------------------------------

  void _spawnPest() {
    final kind = _rng.nextBool() ? _PestKind.aphid : _PestKind.beetle;
    final target = _OrganType.values[_rng.nextInt(4)];
    final targetNode = _nodes[target.index];

    // Spawn from a random screen edge
    double sx, sy;
    final edge = _rng.nextInt(4);
    switch (edge) {
      case 0: // top
        sx = _rng.nextDouble() * _sz.width;
        sy = -20;
        break;
      case 1: // bottom
        sx = _rng.nextDouble() * _sz.width;
        sy = _sz.height + 20;
        break;
      case 2: // left
        sx = -20;
        sy = _rng.nextDouble() * _sz.height;
        break;
      default: // right
        sx = _sz.width + 20;
        sy = _rng.nextDouble() * _sz.height;
        break;
    }

    final dx = targetNode.x - sx;
    final dy = targetNode.y - sy;
    final dist = sqrt(dx * dx + dy * dy);
    final speed = 28 + _difficulty * 8 + _rng.nextDouble() * 12;

    _pests.add(_Pest(
      kind: kind,
      x: sx,
      y: sy,
      vx: dx / dist * speed,
      vy: dy / dist * speed,
      target: target,
      size: kind == _PestKind.beetle ? 16 : 12,
      wobblePhase: _rng.nextDouble() * 2 * pi,
    ));
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (_gameOver || !_started) return;

    setState(() {
      _elapsed += dt;
      _tutorialAge += dt;
      if (_tutorialAge > 6) _tutorialDismissed = true;

      // Ramp difficulty over time
      _difficulty = 1.0 + _elapsed / 30.0; // +1 every 30 seconds

      // ---- combo decay ----
      _comboTimer += dt;
      if (_comboTimer > 3.0 && _combo > 0) {
        _combo = 0;
      }

      // ---- update node pulses & urgency ----
      for (final node in _nodes) {
        node.pulsePhase += dt * 2;
        if (node.damageFlash > 0) node.damageFlash -= dt * 3;
        if (node.healFlash > 0) node.healFlash -= dt * 3;
        if (node.needs != null) {
          node.needTimer += dt;
          // Urgency rises over 8 seconds
          node.needUrgency = (node.needTimer / 8.0).clamp(0.0, 1.0);
          // If urgency hits max, drain health
          if (node.needUrgency >= 1.0) {
            node.health -= dt * (6 + _difficulty * 2);
            node.damageFlash = 0.3;
            if (node.health <= 0) {
              node.health = 0;
              _gameOver = true;
            }
          }
        }
      }

      // ---- need cycle: assign new needs periodically ----
      _needCycleTimer += dt;
      final needInterval = max(3.0, 6.0 - _difficulty * 0.5);
      if (_needCycleTimer >= needInterval) {
        _needCycleTimer = 0;
        _assignNewNeeds();
      }

      // ---- spawn resources ----
      _resourceSpawnTimer -= dt;
      if (_resourceSpawnTimer <= 0) {
        _spawnResource();
        _resourceSpawnTimer = max(1.2, 3.0 - _difficulty * 0.2);
      }

      // ---- age resources & remove old ones ----
      for (final r in _resources) {
        r.age += dt;
        r.bobPhase += dt * 3;
      }
      _resources.removeWhere((r) => r.age > 12 && !r.grabbed);

      // ---- spawn pests ----
      _pestSpawnTimer -= dt;
      if (_pestSpawnTimer <= 0) {
        _spawnPest();
        _pestSpawnTimer = max(0.8, 3.5 - _difficulty * 0.25);
      }

      // ---- update pests ----
      for (final pest in _pests) {
        if (pest.dead) {
          pest.deathAge += dt;
          continue;
        }
        pest.wobblePhase += dt * 8;
        final targetNode = _nodes[pest.target.index];
        // Re-aim toward target
        final dx = targetNode.x - pest.x;
        final dy = targetNode.y - pest.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 24) {
          // Reached target — deal damage
          targetNode.health -= (8 + _difficulty * 3);
          targetNode.damageFlash = 0.5;
          _burst(pest.x, pest.y, _kPestRed.withValues(alpha: 0.6), 6);
          pest.dead = true;
          pest.deathAge = 0;
          if (targetNode.health <= 0) {
            targetNode.health = 0;
            _gameOver = true;
          }
        } else {
          final speed = sqrt(pest.vx * pest.vx + pest.vy * pest.vy);
          pest.vx = dx / dist * speed;
          pest.vy = dy / dist * speed;
          pest.x += pest.vx * dt;
          pest.y += pest.vy * dt;
        }
      }
      _pests.removeWhere((p) => p.dead && p.deathAge > 0.5);

      // ---- update deliveries ----
      for (final d in _activeDeliveries) {
        d.progress += dt * 2.2;
      }
      // Complete deliveries
      _activeDeliveries.removeWhere((d) {
        if (d.progress >= 1.0) {
          _burst(d.toX, d.toY, d.color, 10);
          return true;
        }
        return false;
      });

      // ---- flow particles on connections ----
      // Spawn ambient flow particles
      if (_rng.nextDouble() < dt * 3) {
        final conn = _kConnections[_rng.nextInt(_kConnections.length)];
        final from = _nodes[conn.a];
        _flowParticles.add(_FlowParticle(
          x: from.x,
          y: from.y,
          progress: 0,
          color: _kTan.withValues(alpha: 0.3),
          fromIndex: conn.a,
          toIndex: conn.b,
          speed: 0.3 + _rng.nextDouble() * 0.3,
        ));
      }
      for (final fp in _flowParticles) {
        fp.progress += dt * fp.speed;
        final from = _nodes[fp.fromIndex];
        final to = _nodes[fp.toIndex];
        fp.x = from.x + (to.x - from.x) * fp.progress;
        fp.y = from.y + (to.y - from.y) * fp.progress;
      }
      _flowParticles.removeWhere((fp) => fp.progress >= 1.0);

      // ---- particles ----
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 120 * dt;
        p.life -= dt;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // ---- popups ----
      for (final p in _pops) {
        p.age += dt;
        p.y -= 30 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.4);
    });
  }

  // ---- input ---------------------------------------------------------------

  void _onTapDown(Offset pos) {
    if (_gameOver) {
      setState(() => _initGame());
      return;
    }
    if (!_started) {
      setState(() => _initGame());
      return;
    }

    // First check: tap on pest to squish it
    bool hitPest = false;
    for (int i = _pests.length - 1; i >= 0; i--) {
      final pest = _pests[i];
      if (pest.dead) continue;
      final dx = pos.dx - pest.x;
      final dy = pos.dy - pest.y;
      if (dx * dx + dy * dy < (pest.size + 16) * (pest.size + 16)) {
        _squishPest(i, pos);
        hitPest = true;
        break;
      }
    }
    if (hitPest) return;

    // Dismiss tutorial on any tap
    if (!_tutorialDismissed) _tutorialDismissed = true;
  }

  void _onPanStart(Offset pos) {
    if (_gameOver || !_started) return;

    // First try pest squish
    for (int i = _pests.length - 1; i >= 0; i--) {
      final pest = _pests[i];
      if (pest.dead) continue;
      final dx = pos.dx - pest.x;
      final dy = pos.dy - pest.y;
      if (dx * dx + dy * dy < (pest.size + 16) * (pest.size + 16)) {
        _squishPest(i, pos);
        return;
      }
    }

    // Try to grab a resource
    double bestDist = double.infinity;
    int bestIdx = -1;
    for (int i = 0; i < _resources.length; i++) {
      final r = _resources[i];
      if (r.grabbed) continue;
      final dx = pos.dx - r.x;
      final dy = pos.dy - r.y;
      final d = sqrt(dx * dx + dy * dy);
      if (d < 44 && d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    if (bestIdx >= 0) {
      _resources[bestIdx].grabbed = true;
      _dragResourceIndex = bestIdx;
    }
  }

  void _onPanUpdate(Offset pos) {
    if (_dragResourceIndex == null) return;
    if (_dragResourceIndex! >= _resources.length) {
      _dragResourceIndex = null;
      return;
    }
    setState(() {
      _resources[_dragResourceIndex!].x = pos.dx;
      _resources[_dragResourceIndex!].y = pos.dy;
    });
  }

  void _onPanEnd() {
    if (_dragResourceIndex == null) return;
    if (_dragResourceIndex! >= _resources.length) {
      _dragResourceIndex = null;
      return;
    }

    final res = _resources[_dragResourceIndex!];
    res.grabbed = false;

    // Check if dropped on a node that needs this resource
    bool delivered = false;
    for (final node in _nodes) {
      final dx = res.x - node.x;
      final dy = res.y - node.y;
      if (dx * dx + dy * dy < 48 * 48) {
        if (node.needs == res.type) {
          // Successful delivery
          _deliverResource(res, node);
          _resources.removeAt(_dragResourceIndex!);
          delivered = true;
          break;
        } else if (node.needs != null) {
          // Wrong resource — snap back with feedback
          _pops.add(_Popup(res.x, res.y - 20, 'Wrong!', const Color(0xFFFF8A65)));
        }
      }
    }

    if (!delivered) {
      // Snap resource to original-ish position (don't remove)
    }

    _dragResourceIndex = null;
  }

  void _deliverResource(_Resource res, _OrganNode node) {
    setState(() {
      node.needs = null;
      node.needTimer = 0;
      node.needUrgency = 0;
      node.healFlash = 0.5;

      // Heal the node
      node.health = min(node.maxHealth, node.health + 12);

      // Score
      final pts = 10 + (_combo > 0 ? _combo * 2 : 0);
      _score += pts;
      _deliveries++;

      _pops.add(_Popup(node.x, node.y - 36, '+$pts', res.color));
      _burst(node.x, node.y, res.color, 14);

      // Spawn delivery particles along connections
      _spawnDeliveryParticles(node, res.color);
    });
  }

  void _spawnDeliveryParticles(_OrganNode targetNode, Color color) {
    final targetIdx = _nodes.indexOf(targetNode);
    for (final conn in _kConnections) {
      if (conn.a == targetIdx || conn.b == targetIdx) {
        final otherIdx = conn.a == targetIdx ? conn.b : conn.a;
        final from = _nodes[otherIdx];
        _flowParticles.add(_FlowParticle(
          x: from.x,
          y: from.y,
          progress: 0,
          color: color.withValues(alpha: 0.6),
          fromIndex: otherIdx,
          toIndex: targetIdx,
          speed: 0.8 + _rng.nextDouble() * 0.4,
        ));
      }
    }
  }

  void _squishPest(int index, Offset pos) {
    setState(() {
      final pest = _pests[index];
      pest.dead = true;
      pest.deathAge = 0;

      // Combo
      _combo++;
      _comboTimer = 0;
      if (_combo > _maxCombo) _maxCombo = _combo;

      // Score with multiplier
      final mult = min(_combo, 8);
      final pts = 5 * mult;
      _score += pts;
      _pestsKilled++;

      _burst(pest.x, pest.y, _kPestRed, 12);
      final comboText = _combo > 1 ? '  x$_combo' : '';
      _pops.add(_Popup(pest.x, pest.y - 16, '+$pts$comboText', _kPestRed));

      // Screen shake-like flash
    });
  }

  void _burst(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 40 + _rng.nextDouble() * 100;
      _fx.add(_FxDot(
        x: x,
        y: y,
        vx: cos(a) * spd,
        vy: sin(a) * spd - 20,
        life: 0.3 + _rng.nextDouble() * 0.4,
        color: color,
        size: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        _sz = newSz;
        if (_started && _nodes.isNotEmpty) {
          // Reposition nodes
          _buildNodes();
        }
      }
      return GestureDetector(
        onTapDown: (d) => _onTapDown(d.localPosition),
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            painter: _GamePainter(
              started: _started,
              gameOver: _gameOver,
              score: _score,
              combo: _combo,
              deliveries: _deliveries,
              pestsKilled: _pestsKilled,
              elapsed: _elapsed,
              difficulty: _difficulty,
              tutorialAge: _tutorialAge,
              tutorialDismissed: _tutorialDismissed,
              nodes: List.of(_nodes),
              resources: List.of(_resources),
              pests: List.of(_pests),
              flowParticles: List.of(_flowParticles),
              activeDeliveries: List.of(_activeDeliveries),
              fx: List.of(_fx),
              pops: List.of(_pops),
              dragResourceIndex: _dragResourceIndex,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GamePainter extends CustomPainter {
  final bool started;
  final bool gameOver;
  final int score;
  final int combo;
  final int deliveries;
  final int pestsKilled;
  final double elapsed;
  final double difficulty;
  final double tutorialAge;
  final bool tutorialDismissed;
  final List<_OrganNode> nodes;
  final List<_Resource> resources;
  final List<_Pest> pests;
  final List<_FlowParticle> flowParticles;
  final List<_Delivery> activeDeliveries;
  final List<_FxDot> fx;
  final List<_Popup> pops;
  final int? dragResourceIndex;

  _GamePainter({
    required this.started,
    required this.gameOver,
    required this.score,
    required this.combo,
    required this.deliveries,
    required this.pestsKilled,
    required this.elapsed,
    required this.difficulty,
    required this.tutorialAge,
    required this.tutorialDismissed,
    required this.nodes,
    required this.resources,
    required this.pests,
    required this.flowParticles,
    required this.activeDeliveries,
    required this.fx,
    required this.pops,
    required this.dragResourceIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // Subtle earthy gradient overlay
    final bgGrad = ui.Gradient.radial(
      Offset(size.width / 2, size.height * 0.46),
      size.height * 0.5,
      [
        const Color(0x12443322),
        const Color(0x00000000),
      ],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = bgGrad);

    if (!started && !gameOver) {
      _drawPreGame(canvas, size);
      return;
    }

    _drawConnections(canvas, size);
    _drawFlowParticles(canvas);
    _drawNodes(canvas, size);
    _drawResources(canvas, size);
    _drawPests(canvas, size);
    _drawDeliveries(canvas, size);
    _drawParticles(canvas);
    _drawPopups(canvas);
    _drawHud(canvas, size);

    if (!tutorialDismissed && tutorialAge < 6) {
      _drawTutorial(canvas, size);
    }

    if (gameOver) _drawGameOver(canvas, size);
  }

  // ---- pre-game ------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    // Title
    _paintText(canvas, 'SYSTEM LINK', 28,
        Colors.white.withValues(alpha: 0.75), FontWeight.w300,
        size.width / 2, size.height / 2 - 80, true);

    // Subtitle
    _paintText(canvas, 'Manage your potato plant\'s', 13,
        Colors.white.withValues(alpha: 0.35), FontWeight.w300,
        size.width / 2, size.height / 2 - 36, true);
    _paintText(canvas, 'organ systems to survive', 13,
        Colors.white.withValues(alpha: 0.35), FontWeight.w300,
        size.width / 2, size.height / 2 - 18, true);

    // Instructions
    _paintText(canvas, 'Drag resources to needy organs', 11,
        _kTan.withValues(alpha: 0.4), FontWeight.w400,
        size.width / 2, size.height / 2 + 16, true);
    _paintText(canvas, 'Tap pests to squish them', 11,
        _kPestRed.withValues(alpha: 0.4), FontWeight.w400,
        size.width / 2, size.height / 2 + 34, true);

    // Diamond preview
    final cx = size.width / 2;
    final cy = size.height / 2 + 80;
    final previewNodes = [
      Offset(cx, cy + 28), // root bottom
      Offset(cx, cy - 28), // shoot top
      Offset(cx - 34, cy), // vascular left
      Offset(cx + 34, cy), // reproductive right
    ];
    final previewColors = [_kBrown, _kGreen, _kTan, const Color(0xFFE8A0BF)];
    // connections
    for (final c in _kConnections) {
      canvas.drawLine(
        previewNodes[c.a],
        previewNodes[c.b],
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(previewNodes[i], 8,
          Paint()..color = previewColors[i].withValues(alpha: 0.4));
    }

    _paintText(canvas, 'Tap to start', 13,
        Colors.white.withValues(alpha: 0.22), FontWeight.w300,
        size.width / 2, size.height / 2 + 140, true);
  }

  // ---- connections ---------------------------------------------------------

  void _drawConnections(Canvas canvas, Size size) {
    for (final conn in _kConnections) {
      if (conn.a >= nodes.length || conn.b >= nodes.length) continue;
      final a = nodes[conn.a];
      final b = nodes[conn.b];

      // Main connection line
      canvas.drawLine(
        Offset(a.x, a.y),
        Offset(b.x, b.y),
        Paint()
          ..color = _kTan.withValues(alpha: 0.10)
          ..strokeWidth = 2,
      );

      // Dashed glow on top
      _drawDashedLine(canvas, a.x, a.y, b.x, b.y,
          _kTan.withValues(alpha: 0.06), 1.5);
    }
  }

  void _drawDashedLine(Canvas canvas, double x1, double y1, double x2,
      double y2, Color color, double width) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);
    const dashLen = 6.0;
    const gapLen = 4.0;
    final steps = dist / (dashLen + gapLen);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < steps; i++) {
      final t1 = i * (dashLen + gapLen) / dist;
      final t2 = (i * (dashLen + gapLen) + dashLen) / dist;
      if (t2 > 1) break;
      canvas.drawLine(
        Offset(x1 + dx * t1, y1 + dy * t1),
        Offset(x1 + dx * t2, y1 + dy * t2),
        paint,
      );
    }
  }

  // ---- flow particles ------------------------------------------------------

  void _drawFlowParticles(Canvas canvas) {
    for (final fp in flowParticles) {
      final a = (1.0 - fp.progress).clamp(0.0, 1.0) *
          (fp.progress * 4).clamp(0.0, 1.0); // fade in and out
      canvas.drawCircle(
        Offset(fp.x, fp.y),
        2.0 + a * 1.5,
        Paint()..color = fp.color.withValues(alpha: a * 0.7),
      );
    }
  }

  // ---- nodes ---------------------------------------------------------------

  void _drawNodes(Canvas canvas, Size size) {
    for (final node in nodes) {
      final nodeR = 32.0;

      // Glow behind node based on health
      final healthFrac = node.health / node.maxHealth;
      final glowR = nodeR + 12 + sin(node.pulsePhase) * 3;
      final glowColor = node.damageFlash > 0
          ? _kPestRed.withValues(alpha: 0.3 * node.damageFlash.clamp(0, 1))
          : node.healFlash > 0
              ? _kGreen.withValues(alpha: 0.3 * node.healFlash.clamp(0, 1))
              : node.color.withValues(alpha: 0.08 + healthFrac * 0.06);

      canvas.drawCircle(
        Offset(node.x, node.y),
        glowR,
        Paint()..color = glowColor,
      );

      // Node circle
      final nodeGrad = ui.Gradient.radial(
        Offset(node.x - 4, node.y - 6),
        nodeR * 2,
        [
          node.color.withValues(alpha: 0.7),
          node.color.withValues(alpha: 0.3),
        ],
      );
      canvas.drawCircle(
        Offset(node.x, node.y),
        nodeR,
        Paint()..shader = nodeGrad,
      );

      // Node border
      canvas.drawCircle(
        Offset(node.x, node.y),
        nodeR,
        Paint()
          ..color = node.color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Icon text
      _paintText(canvas, node.icon, 18,
          Colors.white.withValues(alpha: 0.85), FontWeight.bold,
          node.x, node.y - 2, true);

      // Label below
      _paintText(canvas, node.label, 10,
          node.color.withValues(alpha: 0.6), FontWeight.w500,
          node.x, node.y + nodeR + 10, true);

      // Health bar below label
      const barW = 48.0;
      const barH = 4.0;
      final barX = node.x - barW / 2;
      final barY = node.y + nodeR + 22;

      // Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW, barH),
            const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );

      // Health fill
      final hColor = healthFrac > 0.5
          ? _kGreen
          : healthFrac > 0.25
              ? _kTan
              : _kPestRed;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW * healthFrac, barH),
            const Radius.circular(2)),
        Paint()..color = hColor,
      );

      // Need indicator (floating icon above node)
      if (node.needs != null) {
        final needColor = _resourceColor(node.needs!);
        final needSymbol = _resourceSymbol(node.needs!);
        final urgency = node.needUrgency;
        final bobY = node.y - nodeR - 18 + sin(node.pulsePhase * 2) * 3;
        final bobAlpha = 0.5 + urgency * 0.5;

        // Pulsing urgency ring
        if (urgency > 0.5) {
          final pulseR = 10 + sin(node.pulsePhase * 4) * 3;
          canvas.drawCircle(
            Offset(node.x, bobY),
            pulseR,
            Paint()
              ..color = needColor.withValues(alpha: urgency * 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }

        // Need bubble
        canvas.drawCircle(
          Offset(node.x, bobY),
          9,
          Paint()..color = needColor.withValues(alpha: bobAlpha * 0.6),
        );
        _paintText(canvas, needSymbol, 9,
            Colors.white.withValues(alpha: bobAlpha), FontWeight.bold,
            node.x, bobY, true);
      }
    }
  }

  Color _resourceColor(_ResourceType type) {
    switch (type) {
      case _ResourceType.water:
        return _kWaterBlue;
      case _ResourceType.sugar:
        return _kSugarYellow;
      case _ResourceType.nutrient:
        return _kNutrientPurple;
    }
  }

  String _resourceSymbol(_ResourceType type) {
    switch (type) {
      case _ResourceType.water:
        return 'W';
      case _ResourceType.sugar:
        return 'S';
      case _ResourceType.nutrient:
        return 'N';
    }
  }

  // ---- resources -----------------------------------------------------------

  void _drawResources(Canvas canvas, Size size) {
    for (int i = 0; i < resources.length; i++) {
      final r = resources[i];
      final isGrabbed = i == dragResourceIndex;
      final bob = sin(r.bobPhase) * 3;
      final alpha = isGrabbed ? 0.9 : 0.65;
      final glow = isGrabbed ? 20.0 : 0.0;

      if (isGrabbed) {
        // Glow halo when grabbed
        canvas.drawCircle(
          Offset(r.x, r.y + bob),
          18 + glow,
          Paint()..color = r.color.withValues(alpha: 0.15),
        );
      }

      // Resource circle
      canvas.drawCircle(
        Offset(r.x, r.y + bob),
        isGrabbed ? 16 : 13,
        Paint()..color = r.color.withValues(alpha: alpha * 0.5),
      );

      // Inner bright dot
      canvas.drawCircle(
        Offset(r.x, r.y + bob),
        isGrabbed ? 10 : 8,
        Paint()..color = r.color.withValues(alpha: alpha),
      );

      // Symbol
      _paintText(canvas, r.symbol, isGrabbed ? 11 : 9,
          Colors.white.withValues(alpha: alpha), FontWeight.bold,
          r.x, r.y + bob, true);

      // Fade indicator for old resources
      if (r.age > 9 && !r.grabbed) {
        final fade = ((r.age - 9) / 3).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(r.x, r.y + bob),
          13,
          Paint()
            ..color = Colors.white.withValues(alpha: fade * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  // ---- pests ---------------------------------------------------------------

  void _drawPests(Canvas canvas, Size size) {
    for (final pest in pests) {
      if (pest.dead) {
        // Death splat animation
        final fade = (1 - pest.deathAge / 0.5).clamp(0.0, 1.0);
        final splatR = pest.size * (1.0 + pest.deathAge * 3);
        canvas.drawCircle(
          Offset(pest.x, pest.y),
          splatR,
          Paint()..color = _kPestRed.withValues(alpha: fade * 0.3),
        );
        // X mark
        _paintText(canvas, 'X', 14 + pest.deathAge * 8,
            Colors.white.withValues(alpha: fade * 0.6), FontWeight.bold,
            pest.x, pest.y, true);
        continue;
      }

      // Wobble
      final wobbleX = sin(pest.wobblePhase) * 2;
      final wobbleY = cos(pest.wobblePhase * 1.3) * 1.5;
      final px = pest.x + wobbleX;
      final py = pest.y + wobbleY;

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(px, py + pest.size * 0.7),
            width: pest.size * 1.6,
            height: pest.size * 0.5),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      // Body
      if (pest.kind == _PestKind.beetle) {
        // Beetle: oval body with dark shell
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(px, py),
              width: pest.size * 1.4,
              height: pest.size * 1.1),
          Paint()..color = const Color(0xFF8B4513), // dark brown shell
        );
        // Shell line
        canvas.drawLine(
          Offset(px, py - pest.size * 0.5),
          Offset(px, py + pest.size * 0.5),
          Paint()
            ..color = const Color(0xFF5D2906)
            ..strokeWidth = 1,
        );
        // Eyes
        canvas.drawCircle(Offset(px - 3, py - 4), 2,
            Paint()..color = _kPestRed);
        canvas.drawCircle(Offset(px + 3, py - 4), 2,
            Paint()..color = _kPestRed);
      } else {
        // Aphid: small round body, lighter
        canvas.drawCircle(
          Offset(px, py),
          pest.size * 0.7,
          Paint()..color = const Color(0xFF7CB342), // green aphid
        );
        canvas.drawCircle(
          Offset(px, py - 3),
          pest.size * 0.4,
          Paint()..color = const Color(0xFF9CCC65),
        );
        // Antennae
        canvas.drawLine(
          Offset(px - 3, py - pest.size * 0.5),
          Offset(px - 6, py - pest.size),
          Paint()
            ..color = const Color(0xFF558B2F)
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(px + 3, py - pest.size * 0.5),
          Offset(px + 6, py - pest.size),
          Paint()
            ..color = const Color(0xFF558B2F)
            ..strokeWidth = 0.8,
        );
      }

      // Danger indicator: line toward target
      if (nodes.isNotEmpty) {
        final target = nodes[pest.target.index];
        final dx = target.x - px;
        final dy = target.y - py;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 50) {
          canvas.drawLine(
            Offset(px + dx / dist * pest.size, py + dy / dist * pest.size),
            Offset(px + dx / dist * (pest.size + 8),
                py + dy / dist * (pest.size + 8)),
            Paint()
              ..color = _kPestRed.withValues(alpha: 0.25)
              ..strokeWidth = 1
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  // ---- deliveries ----------------------------------------------------------

  void _drawDeliveries(Canvas canvas, Size size) {
    for (final d in activeDeliveries) {
      final t = d.progress.clamp(0.0, 1.0);
      final x = d.fromX + (d.toX - d.fromX) * t;
      final y = d.fromY + (d.toY - d.fromY) * t;
      final a = (1 - t).clamp(0.2, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = d.color.withValues(alpha: a * 0.7),
      );
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()..color = d.color.withValues(alpha: a * 0.15),
      );
    }
  }

  // ---- particles / popups --------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final p in fx) {
      if (p.life <= 0) continue;
      final a = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * a,
        Paint()..color = p.color.withValues(alpha: a * 0.8),
      );
    }
  }

  void _drawPopups(Canvas canvas) {
    for (final p in pops) {
      final a = (1 - p.age / 1.4).clamp(0.0, 1.0);
      _paintText(canvas, p.text, 14 + p.age * 2,
          p.color.withValues(alpha: a), FontWeight.bold,
          p.x, p.y, true);
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Score (top center)
    _paintText(canvas, '$score', 22,
        Colors.white.withValues(alpha: 0.45), FontWeight.w300,
        size.width / 2, 24, true);

    // Combo (top right)
    if (combo > 1) {
      _paintText(canvas, 'x$combo', 16,
          _kPestRed.withValues(alpha: 0.8), FontWeight.bold,
          size.width - 30, 22, true);
    }

    // Time survived (top left)
    final mins = (elapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsed.toInt() % 60).toString().padLeft(2, '0');
    _paintText(canvas, '$mins:$secs', 12,
        Colors.white.withValues(alpha: 0.22), FontWeight.w400,
        24, 22, false);

    // Difficulty indicator (below time)
    final diffLabel = 'LV ${difficulty.floor()}';
    _paintText(canvas, diffLabel, 9,
        _kTan.withValues(alpha: 0.25), FontWeight.w400,
        24, 38, false);

    // Stats at bottom
    _paintText(canvas, '${deliveries}d  ${pestsKilled}k', 10,
        Colors.white.withValues(alpha: 0.15), FontWeight.w300,
        size.width / 2, size.height - 20, true);
  }

  // ---- tutorial ------------------------------------------------------------

  void _drawTutorial(Canvas canvas, Size size) {
    final fade = tutorialAge < 0.5
        ? (tutorialAge / 0.5).clamp(0.0, 1.0)
        : tutorialAge > 4.5
            ? ((6 - tutorialAge) / 1.5).clamp(0.0, 1.0)
            : 1.0;

    final alpha = fade * 0.7;

    // Semi-transparent backdrop at bottom
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, size.height - 110, size.width - 40, 74),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.6),
    );

    final textAlpha = fade * 0.85;
    _paintText(canvas, 'Drag resources to organs that need them', 12,
        Colors.white.withValues(alpha: textAlpha), FontWeight.w400,
        size.width / 2, size.height - 92, true);
    _paintText(canvas, 'Tap pests to squish them before they attack', 12,
        Colors.white.withValues(alpha: textAlpha), FontWeight.w400,
        size.width / 2, size.height - 72, true);
    _paintText(canvas, 'Keep all organ systems alive!', 11,
        _kTan.withValues(alpha: textAlpha * 0.7), FontWeight.w300,
        size.width / 2, size.height - 52, true);
  }

  // ---- game over -----------------------------------------------------------

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.82),
    );

    // Find dead organ
    String deadOrgan = '';
    for (final n in nodes) {
      if (n.health <= 0) {
        deadOrgan = n.label;
        break;
      }
    }

    _paintText(canvas, 'PLANT LOST', 32,
        Colors.white.withValues(alpha: 0.65), FontWeight.w300,
        size.width / 2, size.height / 2 - 80, true);

    if (deadOrgan.isNotEmpty) {
      _paintText(canvas, '$deadOrgan system failed', 14,
          _kPestRed.withValues(alpha: 0.5), FontWeight.w400,
          size.width / 2, size.height / 2 - 42, true);
    }

    _paintText(canvas, '$score', 52,
        Colors.white.withValues(alpha: 0.75), FontWeight.w200,
        size.width / 2, size.height / 2 + 6, true);

    final mins = (elapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsed.toInt() % 60).toString().padLeft(2, '0');
    _paintText(canvas, 'Survived $mins:$secs', 13,
        Colors.white.withValues(alpha: 0.3), FontWeight.w300,
        size.width / 2, size.height / 2 + 52, true);
    _paintText(canvas, '$deliveries deliveries  $pestsKilled pests squished', 11,
        Colors.white.withValues(alpha: 0.2), FontWeight.w300,
        size.width / 2, size.height / 2 + 72, true);

    _paintText(canvas, 'Tap to retry', 13,
        Colors.white.withValues(alpha: 0.22), FontWeight.w300,
        size.width / 2, size.height / 2 + 108, true);
  }

  // ---- helpers -------------------------------------------------------------

  void _paintText(Canvas canvas, String text, double fontSize, Color color,
      FontWeight weight, double x, double y, bool centred) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        centred
            ? Offset(x - tp.width / 2, y - tp.height / 2)
            : Offset(x, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
