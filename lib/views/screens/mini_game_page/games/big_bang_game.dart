import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// GAME: Big Bang — Build matter from energy. Chain targets, avoid antimatter.
// ---------------------------------------------------------------------------

// ---- Element thresholds ---------------------------------------------------

class _Element {
  final String symbol;
  final String name;
  final int threshold;
  final Color color;
  const _Element(this.symbol, this.name, this.threshold, this.color);
}

const List<_Element> _kElements = [
  _Element('H',  'Hydrogen', 10,  Color(0xFFE0E8FF)),
  _Element('He', 'Helium',   25,  Color(0xFFB3E5FC)),
  _Element('Li', 'Lithium',  44,  Color(0xFFCCE5FF)),
  _Element('C',  'Carbon',   68,  Color(0xFF80DEEA)),
  _Element('N',  'Nitrogen', 96,  Color(0xFF80CBC4)),
  _Element('O',  'Oxygen',   130, Color(0xFF81C784)),
  _Element('Ne', 'Neon',     170, Color(0xFFA5D6A7)),
  _Element('Si', 'Silicon',  215, Color(0xFFFFF176)),
  _Element('Fe', 'Iron',     270, Color(0xFFFFCC80)), // final win
];

// ---- Enums ----------------------------------------------------------------

enum _TargetType { normal, time, antimatter, chain }

enum _GamePhase { idle, playing, gameOver, win }

// ---- Data classes ---------------------------------------------------------

class _BangTarget {
  double x, y, vx, vy;
  double radius;
  _TargetType type;
  double lifeTimer; // time before exploding
  double maxLife;
  bool isChainActive; // lit up as next in chain
  int chainId;
  int chainIndex;
  double pulsePhase;

  _BangTarget({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.type,
    required this.lifeTimer,
    this.isChainActive = false,
    this.chainId = -1,
    this.chainIndex = -1,
    double? pulsePhase,
  })  : maxLife = lifeTimer,
        pulsePhase = pulsePhase ?? 0.0;
}

class _BangPopup {
  double x, y, age;
  String text;
  Color color;
  double size;
  _BangPopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.size = 22,
  }) : age = 0;
}

class _Shockwave {
  double x, y, radius, age, maxAge;
  _Shockwave({required this.x, required this.y})
      : radius = 0,
        age = 0,
        maxAge = 0.7;
}

class _DustParticle {
  double x, y, radius, opacity;
  _DustParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}

class _ResonanceWave {
  double x, y, radius, age, maxAge;
  Color color;
  _ResonanceWave({
    required this.x,
    required this.y,
    required this.color,
  })  : radius = 0,
        age = 0,
        maxAge = 0.9;
}

class _CelebrationParticle {
  double x, y, vx, vy, age, maxAge, radius;
  Color color;
  _CelebrationParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
  })  : age = 0,
        maxAge = 1.2;
}

class _ElementUnlock {
  final _Element element;
  double age;
  _ElementUnlock(this.element) : age = 0;
}

// ---- State ----------------------------------------------------------------

class BigBangGame extends StatefulWidget {
  BigBangGame({Key? key}) : super(key: key);
  @override
  State<BigBangGame> createState() => _BigBangGameState();
}

class _BigBangGameState extends State<BigBangGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _timeRemaining = 22.0;
  double _elapsed = 0.0;
  int _score = 0;
  int _matterProgress = 0;
  _GamePhase _phase = _GamePhase.idle;

  // Targets
  final List<_BangTarget> _targets = [];
  double _spawnTimer = 0.0;

  // Player
  bool _holding = false;
  Offset _holdPos = Offset.zero;
  double _playerRadius = 0.0;
  static const double _growRate = 95.0;

  // Chain system
  int _nextChainId = 0;
  double _chainTimer = 0.0; // countdown to finish chain
  int? _activeChainId;
  int _chainCombo = 0; // how many in current chain are complete
  double _lastHitTime = 0.0; // for resonance detection
  double _secondLastHitTime = 0.0;
  Offset _lastHitPos = Offset.zero;
  Offset _secondLastHitPos = Offset.zero;

  // Effects
  final List<_BangPopup> _popups = [];
  final List<_Shockwave> _shockwaves = [];
  final List<_DustParticle> _dust = [];
  final List<_ResonanceWave> _resonanceWaves = [];
  final List<_CelebrationParticle> _celebParticles = [];
  final List<_ElementUnlock> _unlockQueue = [];

  double _flashAlpha = 0.0;
  Color _flashColor = Colors.white;
  double _screenShake = 0.0;
  double _totalTime = 0.0; // wall-clock seconds from game start

  // Element tracking
  int _currentElementIndex = -1;

  Size _screenSize = Size.zero;
  double _lastTime = 0.0;

  // Anti-spam: track last antimatter hit time
  double _lastAntimatterHitTime = -10.0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double get _spawnInterval =>
      (2.0 - (_elapsed / 30.0) * 1.3).clamp(0.45, 2.0);
  double get _driftSpeed => 40.0 + 60.0 * (_elapsed / 30.0).clamp(0.0, 1.0);
  double get _targetLife =>
      (7.0 - (_elapsed / 30.0) * 3.0).clamp(3.5, 7.0);

  // ---- tick ---------------------------------------------------------------

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    if (_phase == _GamePhase.idle || _phase == _GamePhase.gameOver ||
        _phase == _GamePhase.win) return;

    setState(() {
      _totalTime += dt;
      _timeRemaining -= dt;
      _elapsed += dt;

      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _phase = _GamePhase.gameOver;
        _holding = false;
        return;
      }

      // Player grow
      if (_holding && _playerRadius < 200) {
        _playerRadius += _growRate * dt;
      }

      // Chain timer
      if (_activeChainId != null) {
        _chainTimer -= dt;
        if (_chainTimer <= 0) {
          // Chain expired — lose combo bonus
          _activeChainId = null;
          _chainCombo = 0;
          _popups.add(_BangPopup(
            x: _screenSize.width / 2,
            y: _screenSize.height / 2,
            text: 'CHAIN BROKEN',
            color: const Color(0xFFFF5252),
            size: 18,
          ));
        }
      }

      // Spawn
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _screenSize != Size.zero) {
        _spawnTarget();
        _spawnTimer = _spawnInterval;
      }

      // Move & age targets
      final List<_BangTarget> toExplode = [];
      for (final t in _targets) {
        t.x += t.vx * dt;
        t.y += t.vy * dt;
        t.pulsePhase += dt * 2.5;
        if (t.type != _TargetType.antimatter) {
          t.lifeTimer -= dt;
          if (t.lifeTimer <= 0) toExplode.add(t);
        }
      }

      // Explode expired targets
      for (final t in toExplode) {
        _targets.remove(t);
        _explodeTarget(t);
      }

      // Cull way off-screen
      _targets.removeWhere((t) {
        final m = t.radius + 120;
        return t.x < -m ||
            t.x > _screenSize.width + m ||
            t.y < -m ||
            t.y > _screenSize.height + m;
      });

      // Dust spawn
      if (_dust.length < 60 && _rng.nextDouble() < dt * 4) {
        _spawnDust();
      }

      // Effects decay
      _flashAlpha = (_flashAlpha - dt * 5).clamp(0.0, 1.0);
      _screenShake = (_screenShake - dt * 8).clamp(0.0, 1.0);

      // Shockwaves
      for (final sw in _shockwaves) {
        sw.age += dt;
        sw.radius += 300 * dt;
      }
      _shockwaves.removeWhere((sw) => sw.age >= sw.maxAge);

      // Resonance waves
      for (final rw in _resonanceWaves) {
        rw.age += dt;
        rw.radius += 220 * dt;
      }
      _resonanceWaves.removeWhere((rw) => rw.age >= rw.maxAge);

      // Celebration particles
      for (final cp in _celebParticles) {
        cp.age += dt;
        cp.x += cp.vx * dt;
        cp.y += cp.vy * dt;
        cp.vy += 120 * dt; // gravity
      }
      _celebParticles.removeWhere((cp) => cp.age >= cp.maxAge);

      // Popups
      for (final p in _popups) {
        p.age += dt;
        p.y -= 44 * dt;
      }
      _popups.removeWhere((p) => p.age > 1.5);

      // Element unlock animations
      for (final u in _unlockQueue) {
        u.age += dt;
      }
      _unlockQueue.removeWhere((u) => u.age > 2.5);

      // Check element unlocks
      _checkElementUnlocks();
    });
  }

  // ---- spawning -----------------------------------------------------------

  void _spawnTarget() {
    final sz = _screenSize;
    if (sz == Size.zero) return;

    final radius = 26.0 + _rng.nextDouble() * 50;
    final edge = _rng.nextInt(4);
    double x, y;

    switch (edge) {
      case 0:
        x = _rng.nextDouble() * sz.width;
        y = -radius - 12;
        break;
      case 1:
        x = sz.width + radius + 12;
        y = _rng.nextDouble() * sz.height;
        break;
      case 2:
        x = _rng.nextDouble() * sz.width;
        y = sz.height + radius + 12;
        break;
      default:
        x = -radius - 12;
        y = _rng.nextDouble() * sz.height;
    }

    final tx = sz.width * (0.15 + _rng.nextDouble() * 0.7);
    final ty = sz.height * (0.15 + _rng.nextDouble() * 0.7);
    final a = atan2(ty - y, tx - x);
    final spd = _driftSpeed;

    // Type distribution
    final roll = _rng.nextDouble();
    _TargetType type;
    if (roll < 0.18) {
      type = _TargetType.antimatter;
    } else if (roll < 0.30) {
      type = _TargetType.time;
    } else if (roll < 0.55) {
      type = _TargetType.chain;
    } else {
      type = _TargetType.normal;
    }

    // Chains: spawn 2-3 linked targets
    if (type == _TargetType.chain) {
      _spawnChain(x, y, radius, a, spd);
      return;
    }

    _targets.add(_BangTarget(
      x: x,
      y: y,
      vx: cos(a) * spd,
      vy: sin(a) * spd,
      radius: radius,
      type: type,
      lifeTimer: type == _TargetType.antimatter ? 9999 : _targetLife,
      pulsePhase: _rng.nextDouble() * pi * 2,
    ));
  }

  void _spawnChain(
      double startX, double startY, double r, double angle, double spd) {
    final chainId = _nextChainId++;
    final count = 2 + _rng.nextInt(2); // 2 or 3
    final sz = _screenSize;

    for (int i = 0; i < count; i++) {
      // Stagger spawn positions around the screen
      final offsetAngle = angle + (i * pi * 0.4);
      final dist = 80.0 + _rng.nextDouble() * 80;
      final cx = (startX + cos(offsetAngle) * dist).clamp(0, sz.width as num).toDouble();
      final cy = (startY + sin(offsetAngle) * dist).clamp(0, sz.height as num).toDouble();

      // Chain targets drift slowly
      final driftA = atan2(sz.height / 2 - cy, sz.width / 2 - cx);
      final chainSpd = spd * 0.55;

      _targets.add(_BangTarget(
        x: cx,
        y: cy,
        vx: cos(driftA) * chainSpd,
        vy: sin(driftA) * chainSpd,
        radius: r * (0.7 + i * 0.12),
        type: _TargetType.chain,
        lifeTimer: _targetLife * 1.4,
        isChainActive: i == 0, // first is immediately lit
        chainId: chainId,
        chainIndex: i,
        pulsePhase: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  void _spawnDust() {
    final sz = _screenSize;
    _dust.add(_DustParticle(
      x: _rng.nextDouble() * sz.width,
      y: _rng.nextDouble() * sz.height,
      radius: 1.5 + _rng.nextDouble() * 3.5,
      opacity: 0.03 + _rng.nextDouble() * 0.07,
    ));
  }

  // ---- target explode -----------------------------------------------------

  void _explodeTarget(_BangTarget t) {
    if (t.type == _TargetType.antimatter) return;

    // Time penalty
    _timeRemaining = (_timeRemaining - 1.5).clamp(0.0, 999.0);

    // Shockwave
    _shockwaves.add(_Shockwave(x: t.x, y: t.y));

    // Screen shake
    _screenShake = 0.6;
    _flashColor = const Color(0xFFFF5252);
    _flashAlpha = 0.2;

    _popups.add(_BangPopup(
      x: t.x,
      y: t.y,
      text: '-1.5s',
      color: const Color(0xFFFF5252),
      size: 16,
    ));

    // Shockwave pushes nearby targets off-screen
    final sz = _screenSize;
    for (final other in _targets) {
      final dx = other.x - t.x;
      final dy = other.y - t.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < 160 && dist > 1) {
        final pushF = (1.0 - dist / 160) * 280;
        other.vx += (dx / dist) * pushF;
        other.vy += (dy / dist) * pushF;
      }
    }

    // Clear the chain if this was a chain target
    if (t.chainId >= 0 && _activeChainId == t.chainId) {
      _activeChainId = null;
      _chainCombo = 0;
    }

    // Remove dust in radius — hitting targets clears area
    _dust.removeWhere((d) {
      final dx = d.x - t.x;
      final dy = d.y - t.y;
      return sqrt(dx * dx + dy * dy) < 90;
    });

    // Clamp time
    if (_timeRemaining <= 0) {
      _phase = _GamePhase.gameOver;
    }
  }

  // ---- input --------------------------------------------------------------

  void _beginHold(Offset pos) {
    if (_phase == _GamePhase.gameOver || _phase == _GamePhase.win) {
      _restart();
      return;
    }
    if (_phase == _GamePhase.idle) _phase = _GamePhase.playing;
    if (_holding) {
      _holdPos = pos;
      return;
    }
    _holding = true;
    _holdPos = pos;
    _playerRadius = 0;
  }

  void _endHold() {
    if (!_holding) return;
    _holding = false;
    if (_playerRadius < 8) {
      _playerRadius = 0;
      return;
    }
    _resolve();
    _playerRadius = 0;
  }

  void _resolve() {
    // Check antimatter collision first — any overlap = penalty
    for (final t in List.of(_targets)) {
      if (t.type != _TargetType.antimatter) continue;
      final dx = t.x - _holdPos.dx;
      final dy = t.y - _holdPos.dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < _playerRadius + t.radius) {
        // Hit antimatter — penalize
        final now = _totalTime;
        if (now - _lastAntimatterHitTime > 0.5) {
          _lastAntimatterHitTime = now;
          _score = (_score - 5).clamp(0, 9999);
          _timeRemaining = (_timeRemaining - 2).clamp(0, 999);
          _flashColor = const Color(0xFFAA00FF);
          _flashAlpha = 0.5;
          _screenShake = 1.0;
          _popups.add(_BangPopup(
            x: _holdPos.dx,
            y: _holdPos.dy,
            text: 'ANTIMATTER! -5',
            color: const Color(0xFFCE93D8),
            size: 17,
          ));
          // Antimatter stays — doesn't get removed
        }
        return; // cancel rest of resolve
      }
    }

    // Find best matching normal/chain/time target
    _BangTarget? best;
    double bestAcc = double.infinity;

    for (final t in _targets) {
      if (t.type == _TargetType.antimatter) continue;
      if (t.type == _TargetType.chain && !t.isChainActive) continue;

      final dx = t.x - _holdPos.dx;
      final dy = t.y - _holdPos.dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > _playerRadius + t.radius) continue;

      final acc = (_playerRadius - t.radius).abs() / t.radius;
      if (acc < bestAcc) {
        bestAcc = acc;
        best = t;
      }
    }

    if (best == null || bestAcc > 0.40) return;

    final int baseReward;
    if (bestAcc < 0.06) {
      baseReward = 5;
    } else if (bestAcc < 0.18) {
      baseReward = 2;
    } else {
      baseReward = 1;
    }

    _targets.remove(best);

    // Clear dust around hit
    _dust.removeWhere((d) {
      final dx = d.x - best!.x;
      final dy = d.y - best.y;
      return sqrt(dx * dx + dy * dy) < 100;
    });

    // Handle time target
    if (best.type == _TargetType.time) {
      final bonus = baseReward + 1;
      _timeRemaining += bonus;
      _popups.add(_BangPopup(
        x: best.x,
        y: best.y,
        text: '+${bonus}s',
        color: const Color(0xFF4FC3F7),
        size: 20,
      ));
      _flashColor = const Color(0xFF4FC3F7);
      _flashAlpha = 0.15;

      // Time targets also give matter
      _matterProgress += 1;
      _score += 1;
      _checkResonance(best.x, best.y, const Color(0xFF4FC3F7));
      return;
    }

    // Handle chain target
    if (best.type == _TargetType.chain) {
      _hitChainTarget(best, baseReward);
      return;
    }

    // Normal hit
    _score += baseReward;
    _matterProgress += baseReward;
    _popups.add(_BangPopup(
      x: best.x,
      y: best.y,
      text: '+$baseReward',
      color: baseReward == 5
          ? const Color(0xFFFFD700)
          : baseReward >= 2
              ? Colors.white
              : Colors.white60,
      size: baseReward == 5 ? 26 : 20,
    ));
    _flashColor = Colors.white;
    _flashAlpha = baseReward == 5 ? 0.25 : baseReward == 2 ? 0.12 : 0.06;

    _checkResonance(best.x, best.y, Colors.white);
  }

  void _hitChainTarget(_BangTarget best, int baseReward) {
    final chainId = best.chainId;

    // Start or continue chain
    if (_activeChainId != chainId) {
      _activeChainId = chainId;
      _chainCombo = 1;
      _chainTimer = 5.0; // 5 seconds to complete chain
    } else {
      _chainCombo++;
      _chainTimer = (_chainTimer + 1.5).clamp(0, 7.0); // refresh timer
    }

    // Light up next in chain
    _BangTarget? nextInChain;
    int lowestNext = 9999;
    for (final t in _targets) {
      if (t.chainId == chainId &&
          t.chainIndex == best.chainIndex + 1) {
        nextInChain = t;
        lowestNext = t.chainIndex;
      }
    }
    if (nextInChain != null) {
      nextInChain.isChainActive = true;
    }

    // Check if chain complete
    bool chainComplete = true;
    for (final t in _targets) {
      if (t.chainId == chainId) {
        chainComplete = false;
        break;
      }
    }

    int reward = baseReward;
    Color popupColor = const Color(0xFFFFAB40);

    if (chainComplete || nextInChain == null) {
      // Chain finished
      final bonus = _chainCombo * 4;
      reward = baseReward + bonus;
      _activeChainId = null;
      _chainCombo = 0;
      _timeRemaining += 2;
      _celebrateChain(best.x, best.y);
      _popups.add(_BangPopup(
        x: best.x,
        y: best.y - 36,
        text: 'CHAIN! +${bonus}',
        color: const Color(0xFFFFD700),
        size: 24,
      ));
      popupColor = const Color(0xFFFFD700);
    } else {
      _popups.add(_BangPopup(
        x: best.x,
        y: best.y,
        text: '+$reward ×$_chainCombo',
        color: const Color(0xFFFFAB40),
        size: 20,
      ));
    }

    _score += reward;
    _matterProgress += reward;
    _flashColor = const Color(0xFFFFAB40);
    _flashAlpha = 0.2;

    _checkResonance(best.x, best.y, const Color(0xFFFFAB40));
  }

  void _celebrateChain(double cx, double cy) {
    for (int i = 0; i < 28; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final spd = 80 + _rng.nextDouble() * 200;
      _celebParticles.add(_CelebrationParticle(
        x: cx,
        y: cy,
        vx: cos(angle) * spd,
        vy: sin(angle) * spd - 60,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFFAB40),
          const Color(0xFFFFF176),
          Colors.white,
        ][_rng.nextInt(4)],
        radius: 2 + _rng.nextDouble() * 3,
      ));
    }
  }

  void _checkResonance(double hx, double hy, Color color) {
    final now = _totalTime;
    final gap1 = now - _lastHitTime;
    final gap2 = _lastHitTime - _secondLastHitTime;

    // Resonance: two hits within 1 second of each other
    if (gap1 < 1.0 && _lastHitTime > 0) {
      // Trigger resonance wave from midpoint of last two hits
      final mx = (hx + _lastHitPos.dx) / 2;
      final my = (hy + _lastHitPos.dy) / 2;
      _resonanceWaves.add(_ResonanceWave(x: mx, y: my, color: color));

      // Auto-capture any small nearby target within wave radius
      final List<_BangTarget> autocap = [];
      for (final t in _targets) {
        if (t.type == _TargetType.antimatter) continue;
        final dx = t.x - mx;
        final dy = t.y - my;
        if (sqrt(dx * dx + dy * dy) < 90 && t.radius < 38) {
          autocap.add(t);
        }
      }
      for (final t in autocap) {
        _targets.remove(t);
        _matterProgress += 1;
        _score += 1;
        _popups.add(_BangPopup(
          x: t.x,
          y: t.y,
          text: '⚛ +1',
          color: color.withValues(alpha: 0.9),
          size: 15,
        ));
      }

      if (autocap.isNotEmpty) {
        _popups.add(_BangPopup(
          x: mx,
          y: my - 30,
          text: 'RESONANCE',
          color: color,
          size: 19,
        ));
      }
    }

    _secondLastHitTime = _lastHitTime;
    _secondLastHitPos = _lastHitPos;
    _lastHitTime = now;
    _lastHitPos = Offset(hx, hy);
  }

  // ---- element unlocks ----------------------------------------------------

  void _checkElementUnlocks() {
    final nextIdx = _currentElementIndex + 1;
    if (nextIdx >= _kElements.length) return;

    final next = _kElements[nextIdx];
    if (_matterProgress >= next.threshold) {
      _currentElementIndex = nextIdx;
      _unlockQueue.add(_ElementUnlock(next));
      _flashColor = next.color;
      _flashAlpha = 0.4;

      // Celebration burst
      final cx = _screenSize.width / 2;
      final cy = _screenSize.height / 2;
      for (int i = 0; i < 40; i++) {
        final angle = _rng.nextDouble() * pi * 2;
        final spd = 60 + _rng.nextDouble() * 280;
        _celebParticles.add(_CelebrationParticle(
          x: cx,
          y: cy,
          vx: cos(angle) * spd,
          vy: sin(angle) * spd - 80,
          color: next.color,
          radius: 2.5 + _rng.nextDouble() * 3.5,
        ));
      }

      // Iron = win condition
      if (next.symbol == 'Fe') {
        _phase = _GamePhase.win;
        _holding = false;
      }
    }
  }

  // ---- restart ------------------------------------------------------------

  void _restart() {
    setState(() {
      _timeRemaining = 22;
      _elapsed = 0;
      _totalTime = 0;
      _score = 0;
      _matterProgress = 0;
      _phase = _GamePhase.idle;
      _holding = false;
      _playerRadius = 0;
      _targets.clear();
      _popups.clear();
      _shockwaves.clear();
      _dust.clear();
      _resonanceWaves.clear();
      _celebParticles.clear();
      _unlockQueue.clear();
      _spawnTimer = 0;
      _activeChainId = null;
      _chainCombo = 0;
      _chainTimer = 0;
      _currentElementIndex = -1;
      _nextChainId = 0;
      _lastHitTime = 0;
      _secondLastHitTime = 0;
      _flashAlpha = 0;
      _screenShake = 0;
      _lastAntimatterHitTime = -10;
    });
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _screenSize = Size(box.maxWidth, box.maxHeight);
      final shake = _screenShake > 0
          ? Offset(
              (_rng.nextDouble() - 0.5) * _screenShake * 6,
              (_rng.nextDouble() - 0.5) * _screenShake * 6,
            )
          : Offset.zero;

      return GestureDetector(
        onTapDown: (d) => _beginHold(d.localPosition),
        onTapUp: (_) => _endHold(),
        onPanStart: (d) => _beginHold(d.localPosition),
        onPanUpdate: (d) => _holdPos = d.localPosition,
        onPanEnd: (_) => _endHold(),
        child: ClipRect(
          child: Transform.translate(
            offset: shake,
            child: CustomPaint(
              painter: _BigBangPainter(
                targets: _targets,
                holding: _holding,
                holdPos: _holdPos,
                playerRadius: _playerRadius,
                popups: _popups,
                timeRemaining: _timeRemaining,
                score: _score,
                matterProgress: _matterProgress,
                phase: _phase,
                flashAlpha: _flashAlpha,
                flashColor: _flashColor,
                shockwaves: _shockwaves,
                dust: _dust,
                resonanceWaves: _resonanceWaves,
                celebParticles: _celebParticles,
                unlockQueue: _unlockQueue,
                currentElementIndex: _currentElementIndex,
                activeChainId: _activeChainId,
                chainTimer: _chainTimer,
                totalTime: _totalTime,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _BigBangPainter extends CustomPainter {
  final List<_BangTarget> targets;
  final bool holding;
  final Offset holdPos;
  final double playerRadius;
  final List<_BangPopup> popups;
  final double timeRemaining;
  final int score;
  final int matterProgress;
  final _GamePhase phase;
  final double flashAlpha;
  final Color flashColor;
  final List<_Shockwave> shockwaves;
  final List<_DustParticle> dust;
  final List<_ResonanceWave> resonanceWaves;
  final List<_CelebrationParticle> celebParticles;
  final List<_ElementUnlock> unlockQueue;
  final int currentElementIndex;
  final int? activeChainId;
  final double chainTimer;
  final double totalTime;

  _BigBangPainter({
    required this.targets,
    required this.holding,
    required this.holdPos,
    required this.playerRadius,
    required this.popups,
    required this.timeRemaining,
    required this.score,
    required this.matterProgress,
    required this.phase,
    required this.flashAlpha,
    required this.flashColor,
    required this.shockwaves,
    required this.dust,
    required this.resonanceWaves,
    required this.celebParticles,
    required this.unlockQueue,
    required this.currentElementIndex,
    required this.activeChainId,
    required this.chainTimer,
    required this.totalTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Starfield (static seed)
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final sr = Random(42);
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(sr.nextDouble() * size.width, sr.nextDouble() * size.height),
        sr.nextDouble() * 1.2,
        starPaint,
      );
    }

    // Cosmic dust overlay (reduces visibility)
    for (final d in dust) {
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.radius,
        Paint()..color = Colors.white.withValues(alpha: d.opacity),
      );
    }

    // Shockwaves
    for (final sw in shockwaves) {
      final prog = sw.age / sw.maxAge;
      final a = (1.0 - prog) * 0.6;
      canvas.drawCircle(
        Offset(sw.x, sw.y),
        sw.radius,
        Paint()
          ..color = const Color(0xFFFF5252).withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - prog),
      );
    }

    // Resonance waves
    for (final rw in resonanceWaves) {
      final prog = rw.age / rw.maxAge;
      final a = (1.0 - prog) * 0.55;
      canvas.drawCircle(
        Offset(rw.x, rw.y),
        rw.radius,
        Paint()
          ..color = rw.color.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1 - prog),
      );
    }

    // Targets
    for (final t in targets) {
      _drawTarget(canvas, t);
    }

    // Player circle
    if (holding && playerRadius > 2) {
      _drawPlayerCircle(canvas, holdPos, playerRadius);
    }

    // Celebration particles
    for (final cp in celebParticles) {
      final prog = cp.age / cp.maxAge;
      final a = (1.0 - prog);
      canvas.drawCircle(
        Offset(cp.x, cp.y),
        cp.radius * (1 - prog * 0.5),
        Paint()..color = cp.color.withValues(alpha: a * 0.9),
      );
    }

    // Flash overlay
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = flashColor.withValues(alpha: flashAlpha * 0.35),
      );
    }

    // Popups
    for (final p in popups) {
      final a = (1.0 - p.age / 1.5).clamp(0.0, 1.0);
      final s = 1.0 + p.age * 0.2;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: p.size * s,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: a),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    // Element unlock announcements
    for (final u in unlockQueue) {
      _drawElementUnlock(canvas, size, u);
    }

    // HUD
    if (phase == _GamePhase.playing || phase == _GamePhase.gameOver ||
        phase == _GamePhase.win) {
      _drawHUD(canvas, size);
    }

    // Pre-game
    if (phase == _GamePhase.idle) {
      _drawIntro(canvas, size);
    }

    // Game over / win
    if (phase == _GamePhase.gameOver) {
      _drawGameOver(canvas, size);
    }
    if (phase == _GamePhase.win) {
      _drawWin(canvas, size);
    }
  }

  void _drawTarget(Canvas canvas, _BangTarget t) {
    final c = Offset(t.x, t.y);
    final pulse = sin(t.pulsePhase) * 0.5 + 0.5; // 0..1

    switch (t.type) {
      case _TargetType.antimatter:
        _drawAntimatter(canvas, c, t.radius, pulse);
        break;
      case _TargetType.time:
        _drawTimeTarget(canvas, c, t.radius, t.lifeTimer, t.maxLife, pulse);
        break;
      case _TargetType.chain:
        _drawChainTarget(canvas, c, t.radius, t.lifeTimer, t.maxLife,
            t.isChainActive, t.chainIndex, pulse);
        break;
      case _TargetType.normal:
        _drawNormalTarget(canvas, c, t.radius, t.lifeTimer, t.maxLife, pulse);
        break;
    }
  }

  void _drawNormalTarget(Canvas canvas, Offset c, double r, double life,
      double maxLife, double pulse) {
    final urgency = (1.0 - life / maxLife).clamp(0.0, 1.0);
    final baseColor = Color.lerp(Colors.white, const Color(0xFFFF5252), urgency * urgency)!;

    // Scoring bands
    canvas.drawCircle(c, r * 1.35,
        Paint()..color = baseColor.withValues(alpha: 0.03)..style = PaintingStyle.fill);
    canvas.drawCircle(c, r * 1.35,
        Paint()
          ..color = baseColor.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
    canvas.drawCircle(c, r * 1.18,
        Paint()..color = baseColor.withValues(alpha: 0.06)..style = PaintingStyle.fill);
    canvas.drawCircle(c, r * 1.18,
        Paint()
          ..color = baseColor.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
    canvas.drawCircle(c, r * 1.06,
        Paint()..color = baseColor.withValues(alpha: 0.10)..style = PaintingStyle.fill);

    // Life ring (shrinks as life drains)
    final lifeAngle = 2 * pi * (life / maxLife);
    final rect = Rect.fromCircle(center: c, radius: r + 5);
    canvas.drawArc(
      rect,
      -pi / 2,
      lifeAngle,
      false,
      Paint()
        ..color = baseColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Core ring
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = baseColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(c, r * 0.92,
        Paint()..color = baseColor.withValues(alpha: 0.03)..style = PaintingStyle.fill);
  }

  void _drawTimeTarget(Canvas canvas, Offset c, double r, double life,
      double maxLife, double pulse) {
    const baseColor = Color(0xFF4FC3F7);
    final lifeAngle = 2 * pi * (life / maxLife);

    canvas.drawCircle(c, r * 1.3,
        Paint()..color = baseColor.withValues(alpha: 0.05 + pulse * 0.04)..style = PaintingStyle.fill);
    canvas.drawCircle(c, r * 1.1,
        Paint()
          ..color = baseColor.withValues(alpha: 0.18 + pulse * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = baseColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    // Life arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 5),
      -pi / 2,
      lifeAngle,
      false,
      Paint()
        ..color = baseColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // "+t" label
    final tp = TextPainter(
      text: TextSpan(
          text: '+t',
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              color: baseColor.withValues(alpha: 0.65))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawChainTarget(Canvas canvas, Offset c, double r, double life,
      double maxLife, bool isActive, int idx, double pulse) {
    final activeColor = const Color(0xFFFFAB40);
    final dimColor = const Color(0xFF795548);
    final col = isActive ? activeColor : dimColor;
    final glow = isActive ? 0.12 + pulse * 0.12 : 0.03;

    canvas.drawCircle(c, r * 1.4,
        Paint()..color = col.withValues(alpha: glow)..style = PaintingStyle.fill);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = col.withValues(alpha: isActive ? 0.7 : 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.0 : 1.0);

    if (isActive) {
      // Pulsing inner ring
      canvas.drawCircle(
          c,
          r * (0.7 + pulse * 0.1),
          Paint()
            ..color = activeColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }

    // Life arc
    if (isActive) {
      final lifeAngle = 2 * pi * (life / maxLife);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r + 6),
        -pi / 2,
        lifeAngle,
        false,
        Paint()
          ..color = activeColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Chain index label
    final tp = TextPainter(
      text: TextSpan(
          text: '${idx + 1}',
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              color: col.withValues(alpha: isActive ? 0.8 : 0.3))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawAntimatter(
      Canvas canvas, Offset c, double r, double pulse) {
    const col = Color(0xFFCE93D8);

    // Inverted inner fill
    canvas.drawCircle(c, r,
        Paint()..color = col.withValues(alpha: 0.06 + pulse * 0.06)..style = PaintingStyle.fill);

    // Dashed ring (approximated as segmented arc)
    final dashPaint = Paint()
      ..color = col.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (int i = 0; i < 8; i++) {
      final startA = (i / 8) * 2 * pi + totalTime * 0.8;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), startA, pi / 10, false, dashPaint);
    }

    // Outer warning ring
    canvas.drawCircle(
        c,
        r * 1.25,
        Paint()
          ..color = col.withValues(alpha: 0.12 + pulse * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    // ∅ label
    final tp = TextPainter(
      text: TextSpan(
          text: '∅',
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 13,
              color: col.withValues(alpha: 0.75))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawPlayerCircle(Canvas canvas, Offset pos, double r) {
    final glowR = r * 1.3;
    canvas.drawCircle(
        pos,
        glowR,
        Paint()
          ..shader = ui.Gradient.radial(pos, glowR,
              [Colors.white.withValues(alpha: 0.07), Colors.transparent]));
    canvas.drawCircle(
        pos, r, Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    canvas.drawCircle(
        pos, 3.0, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  void _drawHUD(Canvas canvas, Size size) {
    // Timer
    final tc = timeRemaining < 5
        ? Color.lerp(
            const Color(0xFFFF5252), Colors.white, timeRemaining / 5)!
        : Colors.white70;
    _drawText(canvas,
        text: timeRemaining.toStringAsFixed(1),
        fontSize: 34,
        fontWeight: FontWeight.w300,
        color: tc,
        x: size.width / 2,
        y: 34,
        centered: true);

    // Score
    _drawText(canvas,
        text: '$score',
        fontSize: 16,
        color: Colors.white38,
        x: size.width - 20,
        y: 34,
        centered: false,
        rightAlign: true);

    // Matter progress bar
    _drawMatterBar(canvas, size);

    // Chain timer strip
    if (activeChainId != null && chainTimer > 0) {
      final pct = (chainTimer / 5.0).clamp(0.0, 1.0);
      final barW = size.width * 0.55;
      final barX = (size.width - barW) / 2;
      const barY = 76.0;
      const barH = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(2)),
        Paint()..color = Colors.white12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW * pct, barH),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFAB40).withValues(alpha: 0.8),
      );
      _drawText(canvas,
          text: 'CHAIN',
          fontSize: 9,
          color: const Color(0xFFFFAB40).withValues(alpha: 0.6),
          x: size.width / 2,
          y: barY + 6,
          centered: true);
    }
  }

  void _drawMatterBar(Canvas canvas, Size size) {
    final nextIdx = currentElementIndex + 1;
    if (nextIdx >= _kElements.length) return;

    final next = _kElements[nextIdx];
    final prev = currentElementIndex >= 0 ? _kElements[currentElementIndex] : null;

    final fromThresh = prev?.threshold ?? 0;
    final toThresh = next.threshold;
    final pct =
        ((matterProgress - fromThresh) / (toThresh - fromThresh)).clamp(0.0, 1.0);

    const barW = 160.0;
    const barH = 3.5;
    final barX = (size.width - barW) / 2;
    const barY = 58.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(2)),
      Paint()..color = Colors.white10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * pct, barH), const Radius.circular(2)),
      Paint()..color = next.color.withValues(alpha: 0.7),
    );

    // Element label
    final label = prev != null
        ? '${prev.symbol} → ${next.symbol}'
        : '→ ${next.symbol}';
    _drawText(canvas,
        text: label,
        fontSize: 9,
        color: next.color.withValues(alpha: 0.5),
        x: size.width / 2,
        y: barY + 7,
        centered: true);
  }

  void _drawElementUnlock(Canvas canvas, Size size, _ElementUnlock u) {
    final prog = (u.age / 2.5).clamp(0.0, 1.0);
    double a;
    if (prog < 0.1) {
      a = prog / 0.1;
    } else if (prog > 0.75) {
      a = (1.0 - prog) / 0.25;
    } else {
      a = 1.0;
    }
    a = a.clamp(0.0, 1.0);

    final cy = size.height * 0.38;
    final el = u.element;

    // Big symbol
    _drawText(canvas,
        text: el.symbol,
        fontSize: 64,
        fontWeight: FontWeight.w200,
        color: el.color.withValues(alpha: a * 0.9),
        x: size.width / 2,
        y: cy - 40,
        centered: true);

    // Name
    _drawText(canvas,
        text: el.name.toUpperCase(),
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: el.color.withValues(alpha: a * 0.6),
        x: size.width / 2,
        y: cy + 32,
        centered: true);

    // "CREATED" subtitle
    _drawText(canvas,
        text: 'CREATED',
        fontSize: 10,
        color: Colors.white.withValues(alpha: a * 0.35),
        x: size.width / 2,
        y: cy + 50,
        centered: true);
  }

  void _drawIntro(Canvas canvas, Size size) {
    _drawCentered(canvas, size, 'BIG BANG', 36, Colors.white38, -60);
    _drawCentered(canvas, size, 'Build matter from energy.', 15, Colors.white24, -18);
    _drawCentered(canvas, size, 'Hold to grow your circle.', 13, Colors.white24, 6);
    _drawCentered(canvas, size, 'Match targets. Chain combos.', 13, Colors.white24, 24);
    _drawCentered(canvas, size, 'Avoid the ∅ antimatter.', 13,
        const Color(0xFFCE93D8).withValues(alpha: 0.45), 42);
    _drawCentered(canvas, size, 'Reach Iron to win.', 12, Colors.white12, 62);
    _drawCentered(canvas, size, '— tap to begin —', 13, Colors.white24, 90);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    // Dim overlay
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.55));

    _drawCentered(canvas, size, 'TIME', 44, Colors.white54, -50);
    _drawCentered(canvas, size, '$score', 60, Colors.white70, 14);

    // Final element reached
    if (currentElementIndex >= 0) {
      final el = _kElements[currentElementIndex];
      _drawCentered(canvas, size, 'reached ${el.name}', 14,
          el.color.withValues(alpha: 0.6), 62);
    }

    _drawCentered(canvas, size, 'tap to restart', 13, Colors.white24, 94);
  }

  void _drawWin(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.60));

    const iron = Color(0xFFFFCC80);

    _drawCentered(canvas, size, 'IRON', 18, iron.withValues(alpha: 0.55), -80);
    _drawCentered(canvas, size, 'Fe', 72, iron.withValues(alpha: 0.85), -44);
    _drawCentered(canvas, size, 'MATTER CREATED', 12, iron.withValues(alpha: 0.45), 32);
    _drawCentered(canvas, size, '$score', 52, Colors.white70, 72);
    _drawCentered(canvas, size, 'tap to play again', 13, Colors.white24, 118);
  }

  void _drawCentered(Canvas c, Size s, String text, double fontSize,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: fontSize,
              fontWeight: FontWeight.w300,
              color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2, (s.height - tp.height) / 2 + yOff));
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required double fontSize,
    required Color color,
    required double x,
    required double y,
    FontWeight fontWeight = FontWeight.w300,
    bool centered = false,
    bool rightAlign = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = x;
    if (centered) dx = x - tp.width / 2;
    if (rightAlign) dx = x - tp.width;
    tp.paint(canvas, Offset(dx, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BigBangPainter old) => true;
}
