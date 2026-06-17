import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../games/fx.dart';
import '../../../../theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Farm Panic — frantic two-zone 60s arcade game (potato / Hot Potato Games)
//
// CONTRACT: const FarmPanicGame() — no params, no external score callbacks.
// Self-contained in whatever Expanded slot MiniGamePage hands it, identical
// interface to the old version.
// ---------------------------------------------------------------------------

// ---- FEEL CONSTANTS --------------------------------------------------------

const double _kGameDuration = 60.0;

// Underground zone
const int _kChannelCount = 4;
const double _kFlowDecayBase = 0.14;
const double _kFlowDecayScale = 0.28;
const double _kSwipeFlowGain = 0.65;
const double _kSwipeHitRadius = 32.0;
const double _kPotatoGrowRate = 5.5;
const double _kTokenBubbleRate = 6.5;
const double _kTokenBubbleAccel = 0.07;
const double _kTokenRadius = 22.0;

// Above-ground — bugs
const double _kBugSpawnBase = 2.8;
const double _kBugSpawnMin = 0.42;
const double _kBugSpeed = 52.0;
const double _kBugSpeedScale = 1.8;
const double _kBugHitRadius = 36.0;
const double _kBugSwipeDx = 8.0;
const int _kBugPoints = 15;
const double _kBugDamageThresh = 0.93;
const int _kBugDamageScore = -8;

// Weeds (new pest type — tap to yank, not swipe)
const double _kWeedSpawnBase = 7.0;
const double _kWeedSpawnMin = 3.2;
const int _kWeedDamage = -12;
const int _kWeedPoints = 20;
const double _kWeedRadius = 26.0;

// Water burst power-up (underground flood — swipe fast for bonus)
const double _kWaterBurstSpawnBase = 12.0;
const double _kWaterBurstFlowBoost = 0.4; // extra flow given to all channels
const int _kWaterBurstPoints = 30;

// Ripe potato — tap the above-ground plant to harvest
const int _kHarvestPoints = 60;
const double _kHarvestTapRadius = 24.0;

// Tokens
const int _kTokenPoints = 30;

// Scoring
const int _kComboMultMax = 5;

// Misc
const double _kShakeDecay = 9.0;
const double _kPopupLifetime = 0.85;

// Hint / discoverability
const double _kHintShowDuration = 2.5; // how long each hint banner shows
const double _kMidHintCooldown = 18.0; // don't re-show hint more often than this
const double _kCircStallThresh = 0.22; // avg flow below this triggers hint
const double _kNoSwipeHintTime = 8.0; // secs without underground swipe → hint

// ---- palette (brand-aligned) -----------------------------------------------

const Color _kSkyTop = Color(0xFF0C1510);
const Color _kSkyBot = Color(0xFF152214);
const Color _kSoilTop = Color(0xFF3B2007);
const Color _kSoilBot = Color(0xFF5D3A1A);
const Color _kRootPipe = Color(0xFF7B5E3A);
const Color _kRootFlow = Color(0xFF42A5F5);
const Color _kPotatoGold = Potatuhs.gold;
const Color _kPotatoDark = Color(0xFF9B6A20);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kBugColor = Color(0xFFFF5722);
const Color _kWeedColor = Color(0xFF8BC34A);
const Color _kTokenColor = Potatuhs.sienna;
const Color _kWaterBurst = Color(0xFF29B6F6);
const Color _kDanger = Color(0xFFE53935);
const Color _kHintBg = Color(0xCC0D1A2A);
const Color _kHarvestReady = Potatuhs.orange;

// ---- data classes ----------------------------------------------------------

class _Channel {
  final double yFrac;
  double flow = 0.0;
  bool swipeActive = false;
  _Channel(this.yFrac);
}

class _Potato {
  double x;
  double growth; // 0..1
  bool ripeFlash = false;
  double ripeFlashAge = 0;
  _Potato(this.x, this.growth);
  bool get ripe => growth >= 1.0;
}

class _Bug {
  double x, y;
  bool dead = false;
  double deathAge = 0;
  double dx = 0;
  int tier; // 0=small, 1=fast, 2=armored (armored needs 2 hits)
  int hitsLeft;
  _Bug({required this.x, required this.y, required this.dx, this.tier = 0})
      : hitsLeft = tier == 2 ? 2 : 1;
}

class _Weed {
  double x;
  double y; // in above-ground zone
  double age = 0;
  bool pulled = false;
  double pullAge = 0;
  _Weed({required this.x, required this.y});
}

class _Token {
  double x, y;
  bool banked = false;
  double age = 0;
  _Token({required this.x, required this.y});
}

// Water burst: appears underground, player swipes it for a channel flood boost
class _WaterBurst {
  double x, y;
  double age = 0;
  bool collected = false;
  double collectAge = 0;
  _WaterBurst({required this.x, required this.y});
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  double scale;
  _Popup(
      {required this.x,
      required this.y,
      required this.text,
      required this.color,
      this.scale = 1.0})
      : age = 0;
}

// ---- phase -----------------------------------------------------------------

enum _Phase { preGame, playing, gameOver }

// ---- hint state ------------------------------------------------------------

enum _HintKind { channelSwipe, harvestTap, weedTap }

class _Hint {
  _HintKind kind;
  double age = 0;
  _Hint(this.kind);
}

// ---- widget ----------------------------------------------------------------

class FarmPanicGame extends StatefulWidget {
  const FarmPanicGame({Key? key}) : super(key: key);
  @override
  State<FarmPanicGame> createState() => _FarmPanicGameState();
}

class _FarmPanicGameState extends State<FarmPanicGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // ---- state ----------------------------------------------------------------
  _Phase _phase = _Phase.preGame;
  double _elapsed = 0;
  double _lastTime = 0;
  Size _size = Size.zero;

  int _score = 0;
  int _combo = 1;

  // Underground
  final List<_Channel> _channels = [];
  final List<_Potato> _potatoes = [];
  double _tokenTimer = 0;
  double _waterBurstTimer = 0;
  final List<_WaterBurst> _waterBursts = [];

  // Above-ground
  final List<_Bug> _bugs = [];
  double _bugTimer = 0;
  double _weedTimer = 0;
  final List<_Weed> _weeds = [];
  final List<_Token> _tokens = [];

  // Particles / popups
  final List<FxParticle> _particles = [];
  final List<_Popup> _popups = [];

  // Visual
  double _shakeIntensity = 0;

  // Gesture
  int? _activeChannel;
  double _lastSwipeTime = -999; // tracks last underground swipe for hint logic

  // Hint system
  _Hint? _activeHint;
  double _lastHintTime = -999;
  // Swipe guide animation (shown at game start)
  double _swipeGuideAge = 0;
  bool _swipeGuideDone = false;

  // Score flash for milestone pops
  int _prevScore = 0;
  double _scoreFlash = 0;

  // Derived layout
  double get _groundY => _size.height * 0.52;
  double get _soilZoneH => _size.height - _groundY;

  // Bug speed escalation
  double _bugSpeed(double t) =>
      _kBugSpeed * (1 + (_kBugSpeedScale - 1) * (t / _kGameDuration));

  // Bug spawn interval escalation
  double _bugInterval(double t) =>
      (_kBugSpawnBase - (_kBugSpawnBase - _kBugSpawnMin) * (t / _kGameDuration))
          .clamp(_kBugSpawnMin, _kBugSpawnBase);

  // Weed spawn escalation
  double _weedInterval(double t) =>
      (_kWeedSpawnBase -
              (_kWeedSpawnBase - _kWeedSpawnMin) * (t / _kGameDuration))
          .clamp(_kWeedSpawnMin, _kWeedSpawnBase);

  // Flow decay escalation
  double _flowDecay(double t) =>
      _kFlowDecayBase + _kFlowDecayScale * (t / _kGameDuration);

  // Token spawn interval
  double _tokenInterval(double t) =>
      (_kTokenBubbleRate - _kTokenBubbleAccel * t).clamp(2.0, _kTokenBubbleRate);

  // Average channel flow
  double get _avgFlow {
    if (_channels.isEmpty) return 0;
    return _channels.fold(0.0, (s, c) => s + c.flow) / _channels.length;
  }

  // ---- lifecycle ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
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

  // ---- game setup -----------------------------------------------------------

  void _startGame() {
    _score = 0;
    _prevScore = 0;
    _combo = 1;
    _elapsed = 0;
    _shakeIntensity = 0;
    _activeChannel = null;
    _lastSwipeTime = -999;
    _lastHintTime = -999;
    _activeHint = null;
    _swipeGuideAge = 0;
    _swipeGuideDone = false;
    _scoreFlash = 0;
    _popups.clear();
    _bugs.clear();
    _weeds.clear();
    _tokens.clear();
    _waterBursts.clear();
    _particles.clear();

    _channels.clear();
    for (int i = 0; i < _kChannelCount; i++) {
      _channels.add(_Channel(0.2 + 0.6 * i / (_kChannelCount - 1))
        ..flow = 0.35 + _rng.nextDouble() * 0.25);
    }

    _potatoes.clear();
    for (int i = 0; i < 6; i++) {
      _potatoes.add(_Potato(0.1 + _rng.nextDouble() * 0.8, 0.08));
    }

    _bugTimer = _kBugSpawnBase * 0.4;
    _weedTimer = _kWeedSpawnBase * 0.6;
    _tokenTimer = _kTokenBubbleRate * 0.3;
    _waterBurstTimer = _kWaterBurstSpawnBase * 0.5;

    _phase = _Phase.playing;
  }

  // ---- game loop ------------------------------------------------------------

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05).toDouble();
    _lastTime = now;
    if (_size == Size.zero) return;

    setState(() {
      if (_phase != _Phase.playing) return;

      _elapsed += dt;
      if (_elapsed >= _kGameDuration) {
        _phase = _Phase.gameOver;
        return;
      }

      _updateShake(dt);
      _updateSwipeGuide(dt);
      _updateHints(dt);
      _updateChannels(dt);
      _updatePotatoes(dt);
      _updateBugs(dt);
      _updateWeeds(dt);
      _updateTokens(dt);
      _updateWaterBursts(dt);
      _updateParticles(dt);
      _updatePopups(dt);
      _spawnBugs(dt);
      _spawnWeeds(dt);
      _spawnTokens(dt);
      _spawnWaterBursts(dt);
      _checkScoreFlash(dt);
    });
  }

  void _updateShake(double dt) {
    if (_shakeIntensity > 0) {
      _shakeIntensity *= (1 - dt * _kShakeDecay);
      if (_shakeIntensity < 0.2) _shakeIntensity = 0;
    }
  }

  void _updateSwipeGuide(double dt) {
    if (_swipeGuideDone) return;
    _swipeGuideAge += dt;
    // Show for 3s, then check if player has swiped — guide dismisses after first swipe
    if (_swipeGuideAge > 3.5) _swipeGuideDone = true;
  }

  void _updateHints(double dt) {
    // Tick active hint
    if (_activeHint != null) {
      _activeHint!.age += dt;
      if (_activeHint!.age > _kHintShowDuration) _activeHint = null;
      return; // one hint at a time
    }

    // Cooldown check
    if (_elapsed - _lastHintTime < _kMidHintCooldown) return;
    // Only hint after the initial swipe guide is done and game is mid-way
    if (_elapsed < 5.0) return;

    // Trigger 1: player hasn't swiped underground in a while → channel swipe hint
    final noSwipe = (_elapsed - _lastSwipeTime) > _kNoSwipeHintTime;
    final lowFlow = _avgFlow < _kCircStallThresh;
    if (noSwipe || (lowFlow && _elapsed > 10)) {
      _showHint(_HintKind.channelSwipe);
      return;
    }

    // Trigger 2: one or more ripe potatoes that player hasn't harvested in >4s
    final hasRipe = _potatoes.any((p) => p.ripe && p.ripeFlashAge > 4.0);
    if (hasRipe) {
      _showHint(_HintKind.harvestTap);
      return;
    }

    // Trigger 3: player scoring low and weeds piling up
    if (_weeds.where((w) => !w.pulled).length >= 2 && _score < 80) {
      _showHint(_HintKind.weedTap);
    }
  }

  void _showHint(_HintKind kind) {
    _activeHint = _Hint(kind);
    _lastHintTime = _elapsed;
  }

  void _updateChannels(double dt) {
    final decay = _flowDecay(_elapsed);
    for (final ch in _channels) {
      ch.flow = (ch.flow - decay * dt).clamp(0.0, 1.0);
    }
  }

  void _updatePotatoes(double dt) {
    final avg = _avgFlow;

    if (avg > 0.25) {
      final growBonus = avg * _kPotatoGrowRate * dt;
      // Drip score proportional to growth (makes the circulation feel productive)
      final dripPts = (growBonus * _potatoes.where((p) => !p.ripe).length * _combo * 2).round();
      if (dripPts > 0) _score += dripPts;

      for (final p in _potatoes) {
        if (p.ripe) {
          // Keep ripe flash timer ticking
          if (p.ripeFlash) p.ripeFlashAge += dt;
          continue;
        }
        p.growth = (p.growth + growBonus * 0.06).clamp(0.0, 1.0);
        if (p.growth >= 1.0) {
          // Potato just ripened
          p.ripeFlash = true;
          p.ripeFlashAge = 0;
          _spawnParticles(
              Offset(p.x * _size.width, _groundY - 20), _kPotatoGold,
              count: 14);
          _spawnPopup(p.x * _size.width, _groundY - 30, 'READY! TAP',
              _kHarvestReady,
              scale: 1.2);
        }
      }
    } else if (avg < 0.12) {
      for (final p in _potatoes) {
        if (!p.ripe) {
          p.growth = (p.growth - 0.004 * dt).clamp(0.0, 1.0);
        }
      }
    }
  }

  void _updateBugs(double dt) {
    final speed = _bugSpeed(_elapsed);
    final groundLine = _groundY;

    for (int i = _bugs.length - 1; i >= 0; i--) {
      final bug = _bugs[i];
      if (bug.dead) {
        bug.deathAge += dt;
        if (bug.deathAge > 0.5) _bugs.removeAt(i);
        continue;
      }
      // Fast bugs (tier 1) move faster
      final spd = bug.tier == 1 ? speed * 1.55 : speed;
      bug.y += spd * dt;
      bug.x += bug.dx * dt;
      if (bug.x < 0) bug.dx = bug.dx.abs();
      if (bug.x > _size.width) bug.dx = -bug.dx.abs();

      if (bug.y >= groundLine * _kBugDamageThresh) {
        bug.dead = true;
        _score = max(0, _score + _kBugDamageScore);
        _combo = 1;
        _shakeIntensity = 6;
        _spawnPopup(bug.x, groundLine - 20, '$_kBugDamageScore', _kDanger);
        _spawnParticles(Offset(bug.x, bug.y), _kDanger, count: 8);
      }
    }
  }

  void _updateWeeds(double dt) {
    for (int i = _weeds.length - 1; i >= 0; i--) {
      final w = _weeds[i];
      if (w.pulled) {
        w.pullAge += dt;
        if (w.pullAge > 0.45) _weeds.removeAt(i);
        continue;
      }
      w.age += dt;
      // Weed damages if it lingers too long (12s)
      if (w.age > 12.0) {
        w.pulled = true; // kill without points
        _score = max(0, _score + _kWeedDamage);
        _combo = 1;
        _shakeIntensity = 4;
        _spawnPopup(w.x, w.y - 20, '$_kWeedDamage WEED DAMAGE', _kDanger);
      }
    }
  }

  void _updateTokens(double dt) {
    for (int i = _tokens.length - 1; i >= 0; i--) {
      final tok = _tokens[i];
      if (tok.banked) {
        tok.age += dt;
        if (tok.age > 0.45) _tokens.removeAt(i);
        continue;
      }
      tok.age += dt;
      tok.y -= 28.0 * dt;
      if (tok.age > 4.5) _tokens.removeAt(i);
    }
  }

  void _updateWaterBursts(double dt) {
    for (int i = _waterBursts.length - 1; i >= 0; i--) {
      final wb = _waterBursts[i];
      if (wb.collected) {
        wb.collectAge += dt;
        if (wb.collectAge > 0.5) _waterBursts.removeAt(i);
        continue;
      }
      wb.age += dt;
      if (wb.age > 5.5) _waterBursts.removeAt(i);
    }
  }

  void _updateParticles(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
  }

  void _updatePopups(double dt) {
    for (int i = _popups.length - 1; i >= 0; i--) {
      _popups[i].age += dt;
      _popups[i].y -= 38 * dt;
      if (_popups[i].age > _kPopupLifetime) _popups.removeAt(i);
    }
  }

  void _spawnBugs(double dt) {
    _bugTimer -= dt;
    if (_bugTimer <= 0) {
      _bugTimer = _bugInterval(_elapsed) + _rng.nextDouble() * 0.4;
      // Escalate bug tier over time
      int tier = 0;
      if (_elapsed > 30 && _rng.nextDouble() < 0.35) tier = 1; // fast
      if (_elapsed > 45 && _rng.nextDouble() < 0.2) tier = 2; // armored
      _bugs.add(_Bug(
        x: 20 + _rng.nextDouble() * (_size.width - 40),
        y: -12,
        dx: (_rng.nextDouble() - 0.5) * 50,
        tier: tier,
      ));
    }
  }

  void _spawnWeeds(double dt) {
    _weedTimer -= dt;
    if (_weedTimer <= 0) {
      _weedTimer = _weedInterval(_elapsed) + _rng.nextDouble() * 1.0;
      final weedX = 24.0 + _rng.nextDouble() * (_size.width - 48);
      // Weeds appear near the ground line (just above it)
      _weeds.add(_Weed(
        x: weedX,
        y: _groundY - 18 - _rng.nextDouble() * 30,
      ));
    }
  }

  void _spawnTokens(double dt) {
    _tokenTimer -= dt;
    if (_tokenTimer <= 0) {
      _tokenTimer = _tokenInterval(_elapsed) + _rng.nextDouble() * 0.8;
      _tokens.add(_Token(
        x: 30 + _rng.nextDouble() * (_size.width - 60),
        y: _groundY - 10,
      ));
    }
  }

  void _spawnWaterBursts(double dt) {
    _waterBurstTimer -= dt;
    if (_waterBurstTimer <= 0) {
      _waterBurstTimer = _kWaterBurstSpawnBase * (0.8 + _rng.nextDouble() * 0.4);
      // Pick a random channel Y to spawn near
      final chIdx = _rng.nextInt(_kChannelCount);
      final cy = _channelY(chIdx);
      _waterBursts.add(_WaterBurst(
        x: _size.width * (0.2 + _rng.nextDouble() * 0.6),
        y: cy,
      ));
    }
  }

  void _checkScoreFlash(double dt) {
    if (_score > _prevScore) {
      _scoreFlash = 1.0;
      _prevScore = _score;
    }
    _scoreFlash = (_scoreFlash - dt * 4).clamp(0.0, 1.0);
  }

  // ---- particles / popups ---------------------------------------------------

  void _spawnParticles(Offset at, Color color,
      {int count = 12, double speed = 130}) {
    _particles.addAll(FxBurst.spawn(at, color, count: count, speed: speed));
  }

  void _spawnPopup(double x, double y, String text, Color color,
      {double scale = 1.0}) {
    _popups.add(_Popup(x: x, y: y, text: text, color: color, scale: scale));
  }

  // ---- combo ----------------------------------------------------------------

  void _advanceCombo() {
    _combo = (_combo + 1).clamp(1, _kComboMultMax);
  }

  // ---- gesture handling -----------------------------------------------------

  void _onPointerDown(Offset pos) {
    if (_phase == _Phase.preGame || _phase == _Phase.gameOver) {
      _startGame();
      return;
    }
    if (_phase != _Phase.playing) return;

    if (pos.dy < _groundY) {
      // Above-ground: try token tap, weed tap, ripe potato harvest tap
      _tryBankToken(pos);
      _tryPullWeed(pos);
      _tryHarvestPotato(pos);
    }

    if (pos.dy >= _groundY) {
      _activeChannel = _nearestChannel(pos);
    }
  }

  void _onPointerMove(Offset pos, Offset delta) {
    if (_phase != _Phase.playing) return;

    // Underground swipe — fill channels + collect water bursts
    if (pos.dy >= _groundY && _activeChannel != null) {
      final ch = _channels[_activeChannel!];
      final chY = _channelY(_activeChannel!);
      if ((pos.dy - chY).abs() < _kSwipeHitRadius) {
        final speed = delta.distance;
        ch.flow = (ch.flow + _kSwipeFlowGain * speed / 200.0).clamp(0.0, 1.0);
        _lastSwipeTime = _elapsed;
        // Dismiss the swipe guide on first use
        if (!_swipeGuideDone) _swipeGuideDone = true;
      }
      // Collect water burst if swiping near it
      _tryCollectWaterBurst(pos);
    }

    // Above-ground: horizontal swipe near a bug → blow it away
    if (pos.dy < _groundY && delta.dx.abs() > _kBugSwipeDx) {
      _tryKillBug(pos);
    }
  }

  void _onPointerUp(Offset pos) {
    _activeChannel = null;
  }

  void _tryBankToken(Offset pos) {
    for (int i = _tokens.length - 1; i >= 0; i--) {
      final tok = _tokens[i];
      if (tok.banked) continue;
      final dx = tok.x - pos.dx;
      final dy = tok.y - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kTokenRadius * 2.2) {
        tok.banked = true;
        final pts = _kTokenPoints * _combo;
        _score += pts;
        _spawnPopup(tok.x, tok.y, '+$pts', _kTokenColor, scale: 1.1);
        _spawnParticles(Offset(tok.x, tok.y), _kTokenColor, count: 10);
        _advanceCombo();
        break;
      }
    }
  }

  void _tryPullWeed(Offset pos) {
    for (int i = _weeds.length - 1; i >= 0; i--) {
      final w = _weeds[i];
      if (w.pulled) continue;
      final dx = w.x - pos.dx;
      final dy = w.y - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kWeedRadius * 2) {
        w.pulled = true;
        final pts = _kWeedPoints * _combo;
        _score += pts;
        _spawnPopup(w.x, w.y - 10, '+$pts YANKED', _kWeedColor, scale: 1.1);
        _spawnParticles(Offset(w.x, w.y), _kWeedColor, count: 8);
        _advanceCombo();
        break;
      }
    }
  }

  void _tryHarvestPotato(Offset pos) {
    for (final p in _potatoes) {
      if (!p.ripe) continue;
      final px = p.x * _size.width;
      // Tap target is the stalk tip above ground
      final stalkH = 20.0 + 45.0;
      final tipX = px;
      final tipY = _groundY - stalkH;
      final dx = tipX - pos.dx;
      final dy = tipY - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kHarvestTapRadius * 2.5) {
        // Harvest!
        final pts = _kHarvestPoints * _combo;
        _score += pts;
        _spawnPopup(px, tipY - 10, '+$pts HARVESTED!', _kPotatoGold, scale: 1.4);
        _spawnParticles(Offset(px, tipY), _kPotatoGold,
            count: 18, speed: 150);
        _advanceCombo();
        // Reset potato
        p.growth = 0.08;
        p.ripeFlash = false;
        p.ripeFlashAge = 0;
        p.x = 0.05 + _rng.nextDouble() * 0.9;
        break;
      }
    }
  }

  void _tryKillBug(Offset pos) {
    for (int i = _bugs.length - 1; i >= 0; i--) {
      final bug = _bugs[i];
      if (bug.dead) continue;
      final dx = bug.x - pos.dx;
      final dy = bug.y - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kBugHitRadius) {
        bug.hitsLeft--;
        if (bug.hitsLeft <= 0) {
          bug.dead = true;
          final pts = _kBugPoints * (bug.tier + 1) * _combo;
          _score += pts;
          _spawnPopup(bug.x, bug.y, '+$pts', _kGreen);
          _spawnParticles(Offset(bug.x, bug.y), _kBugColor, count: 10);
          _advanceCombo();
        } else {
          // Armored bug — flash but stays alive
          _spawnPopup(bug.x, bug.y, 'HIT!', _kGreen, scale: 0.9);
          _spawnParticles(Offset(bug.x, bug.y), Colors.orange, count: 5);
        }
        break;
      }
    }
  }

  void _tryCollectWaterBurst(Offset pos) {
    for (int i = _waterBursts.length - 1; i >= 0; i--) {
      final wb = _waterBursts[i];
      if (wb.collected) continue;
      final dx = wb.x - pos.dx;
      final dy = wb.y - pos.dy;
      if (sqrt(dx * dx + dy * dy) < 36) {
        wb.collected = true;
        // Flood all channels with bonus flow
        for (final ch in _channels) {
          ch.flow = (ch.flow + _kWaterBurstFlowBoost).clamp(0.0, 1.0);
        }
        final pts = _kWaterBurstPoints * _combo;
        _score += pts;
        _spawnPopup(wb.x, wb.y, '+$pts FLOOD!', _kWaterBurst, scale: 1.2);
        _spawnParticles(Offset(wb.x, wb.y), _kWaterBurst,
            count: 16, speed: 140);
        _advanceCombo();
        break;
      }
    }
  }

  int _nearestChannel(Offset pos) {
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _channels.length; i++) {
      final cy = _channelY(i);
      final dist = (pos.dy - cy).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  double _channelY(int idx) {
    if (_size == Size.zero) return 0;
    final ch = _channels[idx];
    return _groundY + ch.yFrac * _soilZoneH * 0.85;
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        onPointerMove: (e) =>
            _onPointerMove(e.localPosition, e.localDelta),
        onPointerUp: (e) => _onPointerUp(e.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _FarmPanicPainter(
              phase: _phase,
              elapsed: _elapsed,
              gameTime: _kGameDuration,
              score: _score,
              combo: _combo,
              scoreFlash: _scoreFlash,
              channels: _channels,
              potatoes: _potatoes,
              bugs: _bugs,
              weeds: _weeds,
              tokens: _tokens,
              waterBursts: _waterBursts,
              particles: _particles,
              popups: _popups,
              shakeIntensity: _shakeIntensity,
              groundY: _groundY,
              channelYs:
                  List.generate(_channels.length, (i) => _channelY(i)),
              activeHint: _activeHint,
              swipeGuideAge: _swipeGuideAge,
              swipeGuideDone: _swipeGuideDone,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter ---------------------------------------------------------------

class _FarmPanicPainter extends CustomPainter {
  final _Phase phase;
  final double elapsed, gameTime, shakeIntensity, groundY, scoreFlash;
  final int score, combo;
  final List<_Channel> channels;
  final List<_Potato> potatoes;
  final List<_Bug> bugs;
  final List<_Weed> weeds;
  final List<_Token> tokens;
  final List<_WaterBurst> waterBursts;
  final List<FxParticle> particles;
  final List<_Popup> popups;
  final List<double> channelYs;
  final _Hint? activeHint;
  final double swipeGuideAge;
  final bool swipeGuideDone;

  _FarmPanicPainter({
    required this.phase,
    required this.elapsed,
    required this.gameTime,
    required this.score,
    required this.combo,
    required this.scoreFlash,
    required this.channels,
    required this.potatoes,
    required this.bugs,
    required this.weeds,
    required this.tokens,
    required this.waterBursts,
    required this.particles,
    required this.popups,
    required this.shakeIntensity,
    required this.groundY,
    required this.channelYs,
    required this.activeHint,
    required this.swipeGuideAge,
    required this.swipeGuideDone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == _Phase.preGame) {
      // Atmospheric bg even on pre-game
      GameFx.atmosphere(canvas, size, Potatuhs.sienna, elapsed, motes: 24);
      _drawPreGame(canvas, size);
      return;
    }

    // Shake transform
    if (shakeIntensity > 0) {
      canvas.save();
      canvas.translate(
        sin(elapsed * 47) * shakeIntensity,
        cos(elapsed * 37) * shakeIntensity,
      );
    }

    _drawAboveGround(canvas, size);
    _drawGroundLine(canvas, size);
    _drawUnderground(canvas, size);
    _drawBugs(canvas, size);
    _drawWeeds(canvas, size);
    _drawTokens(canvas, size);
    _drawWaterBursts(canvas, size);
    FxBurst.paint(canvas, particles);
    _drawPopups(canvas, size);
    _drawHUD(canvas, size);
    _drawSwipeGuide(canvas, size);
    _drawHintBanner(canvas, size);

    if (shakeIntensity > 0) canvas.restore();

    if (phase == _Phase.gameOver) {
      _drawGameOver(canvas, size);
    }
  }

  // ---- above-ground zone ----------------------------------------------------

  void _drawAboveGround(Canvas canvas, Size size) {
    // Sky gradient with a hint of sienna (Potatuhs brand)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, groundY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, groundY),
          [_kSkyTop, _kSkyBot, const Color(0xFF1B2A1C)],
          [0.0, 0.65, 1.0],
        ),
    );

    // Slow drifting motes in sky
    final motePaint = Paint();
    for (int i = 0; i < 18; i++) {
      final seed = i * 1.618;
      final x =
          (size.width * ((seed * 0.513) % 1.0) + elapsed * (3 + i % 4)) %
              size.width;
      final y = groundY * ((seed * 0.271) % 0.9);
      final tw = 0.15 + 0.2 * (0.5 + 0.5 * sin(elapsed * 0.8 + seed));
      motePaint.color = Colors.white.withValues(alpha: tw * 0.18);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.3, motePaint);
    }

    // Sun orb
    final sunX = size.width * 0.82;
    final sunY = groundY * 0.14;
    GameFx.orb(canvas, Offset(sunX, sunY), 11, Potatuhs.gold,
        glow: 0.7, specular: true);

    // Stalks / leaves above ground
    for (final p in potatoes) {
      _drawStalk(canvas, size, p);
    }

    // Zone label (fades quickly)
    if (elapsed < 2.5) {
      final alpha = (1.0 - elapsed / 2.5).clamp(0.0, 1.0);
      GameFx.text(
        canvas,
        'SWIPE BUGS • TAP WEEDS • HARVEST PLANTS',
        Offset(size.width / 2, groundY * 0.87),
        10,
        Colors.white.withValues(alpha: alpha * 0.45),
      );
    }
  }

  void _drawStalk(Canvas canvas, Size size, _Potato p) {
    final px = p.x * size.width;
    final growClamped = p.growth.clamp(0.0, 1.0);
    final stalkH = 20 + growClamped * 45;
    final sway = sin(elapsed * 1.4 + p.x * 8) * 3;

    final stalkColor = Color.lerp(
        const Color(0xFF5D4037), _kGreen, growClamped)!;

    canvas.drawLine(
      Offset(px + sway * 0.3, groundY),
      Offset(px + sway, groundY - stalkH),
      Paint()
        ..color = stalkColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    if (growClamped > 0.2) {
      canvas.drawLine(
        Offset(px + sway * 0.6, groundY - stalkH * 0.55),
        Offset(px - 7 + sway, groundY - stalkH * 0.75),
        Paint()
          ..color = _kGreen.withValues(alpha: growClamped.clamp(0.2, 0.85))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (growClamped > 0.5) {
      canvas.drawLine(
        Offset(px + sway * 0.4, groundY - stalkH * 0.35),
        Offset(px + 7 + sway * 0.5, groundY - stalkH * 0.5),
        Paint()
          ..color = _kGreen.withValues(alpha: growClamped.clamp(0.2, 0.85))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Ripe potato glow at stalk tip — pulsing, tapable
    if (p.ripe) {
      final pulse = 0.5 + 0.5 * sin(elapsed * 8 + p.x * 5);
      final tipX = px + sway;
      final tipY = groundY - stalkH;
      // Outer glow
      canvas.drawCircle(
        Offset(tipX, tipY),
        16 + pulse * 6,
        Paint()
          ..color = _kHarvestReady.withValues(alpha: 0.25 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      GameFx.orb(canvas, Offset(tipX, tipY), 12 + pulse * 3, _kHarvestReady,
          glow: 0.8 * pulse);
      // "TAP" hint on the orb
      GameFx.text(
        canvas,
        'TAP',
        Offset(tipX, tipY),
        7,
        Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  // ---- ground line ----------------------------------------------------------

  void _drawGroundLine(Canvas canvas, Size size) {
    final glowAlpha = 0.22 + 0.1 * sin(elapsed * 2.5);
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = _kRootFlow.withValues(alpha: glowAlpha)
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = 1,
    );
  }

  // ---- underground zone -----------------------------------------------------

  void _drawUnderground(Canvas canvas, Size size) {
    final soilH = size.height - groundY;

    // Soil gradient
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, soilH),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, groundY),
          Offset(0, size.height),
          [_kSoilTop, _kSoilBot],
        ),
    );

    // Subtle soil texture motes
    final soilPaint = Paint();
    for (int i = 0; i < 22; i++) {
      final seed = i * 2.37;
      final mx = size.width * ((seed * 0.618) % 1.0);
      final my = groundY + soilH * ((seed * 0.314) % 0.95);
      soilPaint.color =
          Colors.black.withValues(alpha: 0.08 + 0.05 * sin(seed));
      canvas.drawCircle(Offset(mx, my), 1.5 + (i % 4) * 0.5, soilPaint);
    }

    // Draw channels
    for (int i = 0; i < channels.length; i++) {
      _drawChannel(canvas, size, i);
    }

    // Underground potato orbs
    for (final p in potatoes) {
      final px = p.x * size.width;
      final py = groundY + soilH * 0.30;
      final r = 5.0 + p.growth * 11;
      final baseColor = Color.lerp(_kPotatoDark, _kPotatoGold, p.growth)!;
      GameFx.orb(canvas, Offset(px, py), r, baseColor,
          glow: p.growth * 0.8, specular: true);
    }

    // Zone label (fades fast)
    if (elapsed < 2.5) {
      final alpha = (1.0 - elapsed / 2.5).clamp(0.0, 1.0);
      GameFx.text(
        canvas,
        'SWIPE CHANNELS ↔ TO CIRCULATE',
        Offset(size.width / 2, groundY + soilH * 0.08),
        10,
        Colors.white.withValues(alpha: alpha * 0.45),
      );
    }
  }

  void _drawChannel(Canvas canvas, Size size, int i) {
    final ch = channels[i];
    final cy = channelYs[i];

    // Pipe track
    canvas.drawLine(
      Offset(0, cy),
      Offset(size.width, cy),
      Paint()
        ..color = _kRootPipe.withValues(alpha: 0.25)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Animated flow dashes
    if (ch.flow > 0.05) {
      final flowAlpha = ch.flow * 0.85;
      final dashOffset = (elapsed * 65) % 22.0;
      for (double x = -22 + dashOffset; x < size.width; x += 22) {
        final xStart = x.clamp(0.0, size.width);
        final xEnd = (x + 11).clamp(0.0, size.width);
        if (xEnd > xStart) {
          canvas.drawLine(
            Offset(xStart, cy),
            Offset(xEnd, cy),
            Paint()
              ..color = _kRootFlow.withValues(alpha: flowAlpha)
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Flow meter at left edge
    const mW = 6.0;
    const mH = 26.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, cy - mH / 2, mW, mH), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, cy - mH / 2 + mH * (1 - ch.flow), mW, mH * ch.flow),
          const Radius.circular(3)),
      Paint()
        ..color = (ch.flow > 0.35 ? _kRootFlow : _kDanger)
            .withValues(alpha: 0.75),
    );

    // Low-flow warning pulse on pipe
    if (ch.flow < 0.18) {
      final pulse = 0.3 + 0.22 * sin(elapsed * 13 + i);
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = _kDanger.withValues(alpha: pulse * 0.3)
          ..strokeWidth = 5,
      );
    }
  }

  // ---- bugs -----------------------------------------------------------------

  void _drawBugs(Canvas canvas, Size size) {
    for (final bug in bugs) {
      if (bug.dead) {
        final t = bug.deathAge / 0.5;
        for (int i = 0; i < 8; i++) {
          final a = i * pi / 4 + elapsed;
          final r = t * 22;
          canvas.drawCircle(
            Offset(bug.x + cos(a) * r, bug.y + sin(a) * r),
            2.5 * (1 - t).clamp(0.0, 1.0),
            Paint()
              ..color = _kBugColor.withValues(alpha: (1 - t).clamp(0.0, 1.0) * 0.8),
          );
        }
        continue;
      }
      final wobble = sin(elapsed * 18 + bug.x * 0.03) * 1.5;
      // Tier-based appearance
      final bodyColor = bug.tier == 2
          ? const Color(0xFF607D8B) // armored = steely
          : bug.tier == 1
              ? const Color(0xFFFF9800) // fast = orange
              : _kBugColor;
      final bodyW = 14.0 + bug.tier * 3.0;
      final bodyH = 10.0 + bug.tier * 2.0;

      // Bug body as layered orb-ish oval
      canvas.drawCircle(
        Offset(bug.x, bug.y + wobble),
        bodyW * 0.55,
        Paint()
          ..color = bodyColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bug.x, bug.y + wobble), width: bodyW, height: bodyH),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              Color.lerp(bodyColor, Colors.white, 0.35)!,
              bodyColor,
              Color.lerp(bodyColor, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCenter(
              center: Offset(bug.x, bug.y + wobble),
              width: bodyW,
              height: bodyH)),
      );

      // Legs
      for (int leg = 0; leg < 3; leg++) {
        final lx = bug.x + (leg - 1) * 4.0;
        canvas.drawLine(
          Offset(lx, bug.y + 4 + wobble),
          Offset(lx - 4 + leg * 4.0, bug.y + 10 + wobble),
          Paint()
            ..color = bodyColor.withValues(alpha: 0.5)
            ..strokeWidth = 1.2,
        );
      }
      // Antennae
      canvas.drawLine(
        Offset(bug.x - 3, bug.y - 4 + wobble),
        Offset(bug.x - 7, bug.y - 10 + wobble),
        Paint()
          ..color = bodyColor.withValues(alpha: 0.5)
          ..strokeWidth = 0.8,
      );
      canvas.drawLine(
        Offset(bug.x + 3, bug.y - 4 + wobble),
        Offset(bug.x + 7, bug.y - 10 + wobble),
        Paint()
          ..color = bodyColor.withValues(alpha: 0.5)
          ..strokeWidth = 0.8,
      );
      // Eyes
      canvas.drawCircle(
          Offset(bug.x - 3, bug.y - 2 + wobble), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));
      canvas.drawCircle(
          Offset(bug.x + 3, bug.y - 2 + wobble), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));

      // Armor ring for tier 2
      if (bug.tier == 2) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(bug.x, bug.y + wobble),
              width: bodyW + 4,
              height: bodyH + 4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.3),
        );
      }
    }
  }

  // ---- weeds ----------------------------------------------------------------

  void _drawWeeds(Canvas canvas, Size size) {
    for (final w in weeds) {
      if (w.pulled) {
        final t = (w.pullAge / 0.45).clamp(0.0, 1.0);
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3 + elapsed;
          final r = t * 16;
          canvas.drawCircle(
            Offset(w.x + cos(a) * r, w.y + sin(a) * r),
            2.0 * (1 - t),
            Paint()
              ..color = _kWeedColor.withValues(alpha: (1 - t) * 0.8),
          );
        }
        continue;
      }

      final lifeFrac = (w.age / 12.0).clamp(0.0, 1.0);
      final urgency = lifeFrac > 0.6
          ? (0.5 + 0.5 * sin(elapsed * 12 + w.x))
          : 1.0;
      final weedSway = sin(elapsed * 2.1 + w.x * 3) * 2.5;

      // Weed glow
      canvas.drawCircle(
        Offset(w.x, w.y),
        18,
        Paint()
          ..color = _kWeedColor.withValues(alpha: 0.12 * urgency)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Weed stem
      canvas.drawLine(
        Offset(w.x + weedSway * 0.3, w.y + 10),
        Offset(w.x + weedSway, w.y - 22),
        Paint()
          ..color = _kWeedColor.withValues(alpha: 0.8)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // Spiky leaves
      for (int j = -1; j <= 1; j += 2) {
        canvas.drawLine(
          Offset(w.x + weedSway * 0.5, w.y - 8),
          Offset(w.x + j * 11 + weedSway, w.y - 16),
          Paint()
            ..color = _kWeedColor.withValues(alpha: 0.75)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }

      // Danger indicator when close to expiring
      if (lifeFrac > 0.6) {
        final dangerAlpha = 0.3 * urgency;
        canvas.drawCircle(
          Offset(w.x, w.y),
          22,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _kDanger.withValues(alpha: dangerAlpha),
        );
      }
    }
  }

  // ---- tokens ---------------------------------------------------------------

  void _drawTokens(Canvas canvas, Size size) {
    for (final tok in tokens) {
      if (tok.banked) {
        final t = (tok.age / 0.45).clamp(0.0, 1.0);
        for (int i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final r = t * 24;
          canvas.drawCircle(
            Offset(tok.x + cos(a) * r, tok.y + sin(a) * r),
            2.5 * (1 - t),
            Paint()..color = _kTokenColor.withValues(alpha: (1 - t) * 0.9),
          );
        }
        continue;
      }
      final expireFrac = tok.age / 4.5;
      GameFx.orb(
        canvas,
        Offset(tok.x, tok.y),
        _kTokenRadius,
        _kTokenColor,
        glow: 0.8 * (1 - expireFrac * 0.6),
      );
      // Coin label
      GameFx.text(
        canvas,
        '\$',
        Offset(tok.x, tok.y),
        13,
        Colors.white.withValues(alpha: 0.9),
        weight: FontWeight.w900,
      );
    }
  }

  // ---- water bursts ---------------------------------------------------------

  void _drawWaterBursts(Canvas canvas, Size size) {
    for (final wb in waterBursts) {
      if (wb.collected) {
        final t = (wb.collectAge / 0.5).clamp(0.0, 1.0);
        for (int i = 0; i < 10; i++) {
          final a = i * pi / 5 + elapsed;
          final r = t * 30;
          canvas.drawCircle(
            Offset(wb.x + cos(a) * r, wb.y + sin(a) * r),
            2.0 * (1 - t),
            Paint()..color = _kWaterBurst.withValues(alpha: (1 - t) * 0.85),
          );
        }
        continue;
      }
      final pulse = 0.6 + 0.4 * sin(elapsed * 7 + wb.x);
      GameFx.orb(canvas, Offset(wb.x, wb.y), 16, _kWaterBurst,
          glow: 0.9 * pulse);
      // Swipe arrow hint on the burst
      GameFx.text(
        canvas,
        '↔',
        Offset(wb.x, wb.y + 20),
        9,
        Colors.white.withValues(alpha: 0.6),
      );
    }
  }

  // ---- popups ---------------------------------------------------------------

  void _drawPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = (1 - p.age / _kPopupLifetime).clamp(0.0, 1.0);
      final sz = (14.0 * p.scale).clamp(10.0, 22.0);
      GameFx.text(
        canvas,
        p.text,
        Offset(p.x, p.y),
        sz,
        p.color.withValues(alpha: alpha),
        glow: 0.55 * alpha,
      );
    }
  }

  // ---- HUD ------------------------------------------------------------------

  void _drawHUD(Canvas canvas, Size size) {
    const barH = 5.0;
    const barY = 9.0;
    const barX = 12.0;
    final barW = size.width - 24;

    // Time bar bg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(2.5)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    final timeLeft = ((gameTime - elapsed) / gameTime).clamp(0.0, 1.0);
    final timerColor = timeLeft > 0.4
        ? _kGreen
        : timeLeft > 0.15
            ? Potatuhs.sienna
            : _kDanger;
    final pulseAlpha =
        timeLeft < 0.2 ? 0.55 + 0.3 * sin(elapsed * 14) : 0.7;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * timeLeft, barH),
          const Radius.circular(2.5)),
      Paint()
        ..color = timerColor.withValues(alpha: pulseAlpha)
        ..maskFilter = timeLeft < 0.2
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null,
    );

    // Score — juicy gold, flashes on increment
    final scoreGlow = 0.4 + scoreFlash * 0.6;
    final scoreSz = 17.0 + scoreFlash * 4;
    GameFx.text(
      canvas,
      '\$$score',
      Offset(size.width / 2, 24),
      scoreSz,
      _kPotatoGold.withValues(alpha: 0.9 + scoreFlash * 0.1),
      display: true,
      glow: scoreGlow,
    );

    // Combo badge
    if (combo > 1) {
      final comboAlpha = 0.65 + 0.3 * sin(elapsed * 8);
      // Mini badge bg
      final badgeCenter = Offset(size.width * 0.78, 24);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: badgeCenter, width: 40, height: 20),
            const Radius.circular(10)),
        Paint()
          ..color = Potatuhs.orange.withValues(alpha: 0.2 * comboAlpha),
      );
      GameFx.text(
        canvas,
        'x$combo',
        badgeCenter,
        13,
        Potatuhs.gold.withValues(alpha: comboAlpha),
        glow: 0.5 * comboAlpha,
      );
    }

    // Low-flow warning label
    double totalFlow = 0;
    for (final ch in channels) totalFlow += ch.flow;
    final avg = channels.isEmpty ? 0.0 : totalFlow / channels.length;
    if (avg < 0.15 && elapsed > 5) {
      final urgency = 0.5 + 0.5 * sin(elapsed * 10);
      GameFx.text(
        canvas,
        '⚠ CIRCULATION LOW',
        Offset(size.width / 2, barY + barH + 16),
        10,
        _kDanger.withValues(alpha: urgency * 0.85),
      );
    }
  }

  // ---- swipe guide (initial onboarding animation) ---------------------------

  void _drawSwipeGuide(Canvas canvas, Size size) {
    if (swipeGuideDone || swipeGuideAge < 0.3) return;

    // Show an animated hand/arrow swiping along the first channel
    final alpha =
        (swipeGuideAge < 1.0 ? swipeGuideAge : (3.5 - swipeGuideAge) / 2.5)
            .clamp(0.0, 1.0);
    if (alpha <= 0) return;

    // Channel 0 Y
    final ch0Y = channels.isNotEmpty ? channelYs[0] : size.height * 0.65;

    // Animated swipe progress: 0→1 over 1.5s cycle
    final cycle = (swipeGuideAge % 1.5) / 1.5;
    final swipeX = size.width * 0.25 + cycle * size.width * 0.5;

    // Swipe line
    canvas.drawLine(
      Offset(size.width * 0.25, ch0Y),
      Offset(swipeX, ch0Y),
      Paint()
        ..color = _kWaterBurst.withValues(alpha: alpha * 0.6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Finger dot
    GameFx.orb(canvas, Offset(swipeX, ch0Y), 10,
        Colors.white.withValues(alpha: alpha * 0.85),
        glow: 0.5 * alpha);

    // Arrow label above the swipe
    GameFx.text(
      canvas,
      '← SWIPE CHANNELS →',
      Offset(size.width / 2, ch0Y - 22),
      10,
      Colors.white.withValues(alpha: alpha * 0.75),
    );
  }

  // ---- mid-game hint banner -------------------------------------------------

  void _drawHintBanner(Canvas canvas, Size size) {
    if (activeHint == null) return;
    final hint = activeHint!;
    final t = hint.age / _kHintShowDuration;
    // Fade in over 0.3s, fade out in last 0.4s
    final fadeIn = (hint.age / 0.3).clamp(0.0, 1.0);
    final fadeOut = t > 0.6 ? (1.0 - (t - 0.6) / 0.4).clamp(0.0, 1.0) : 1.0;
    final alpha = fadeIn * fadeOut;
    if (alpha <= 0) return;

    String line1, line2;
    switch (hint.kind) {
      case _HintKind.channelSwipe:
        line1 = '← SWIPE THE UNDERGROUND CHANNELS →';
        line2 = 'Keep circulation flowing to grow potatoes!';
        break;
      case _HintKind.harvestTap:
        line1 = '🥔 TAP THE GLOWING PLANT TIP';
        line2 = 'Harvest ripe potatoes for big points!';
        break;
      case _HintKind.weedTap:
        line1 = '🌿 TAP THE WEEDS TO PULL THEM';
        line2 = 'They damage your crop if ignored!';
        break;
    }

    final bannerH = 50.0;
    final bannerY = size.height * 0.44 - bannerH / 2;

    // Banner bg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(16, bannerY, size.width - 32, bannerH),
          const Radius.circular(10)),
      Paint()..color = _kHintBg.withValues(alpha: alpha * 0.92),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(16, bannerY, size.width - 32, bannerH),
          const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kWaterBurst.withValues(alpha: alpha * 0.4),
    );

    GameFx.text(
      canvas,
      line1,
      Offset(size.width / 2, bannerY + 16),
      11,
      Colors.white.withValues(alpha: alpha * 0.95),
      display: false,
    );
    GameFx.text(
      canvas,
      line2,
      Offset(size.width / 2, bannerY + 34),
      9,
      Potatuhs.textSecondary.withValues(alpha: alpha * 0.7),
    );
  }

  // ---- screens --------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    // Zone preview
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.52),
      Paint()..color = _kSkyBot.withValues(alpha: 0.45),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.48),
      Paint()..color = _kSoilTop.withValues(alpha: 0.45),
    );

    // Potato orb as hero icon
    GameFx.orb(
      canvas,
      Offset(size.width / 2, size.height * 0.28),
      32,
      _kPotatoGold,
      glow: 1.0,
    );

    GameFx.text(canvas, 'FARM PANIC', Offset(size.width / 2, size.height * 0.45),
        28, Colors.white.withValues(alpha: 0.85),
        display: true, glow: 0.4);

    GameFx.text(canvas, '60s • Two Zones • Juggle Both',
        Offset(size.width / 2, size.height * 0.52), 11,
        Potatuhs.textSecondary.withValues(alpha: 0.6));

    GameFx.text(canvas, 'UNDERGROUND: swipe channels to circulate',
        Offset(size.width / 2, size.height * 0.575), 10,
        Colors.white.withValues(alpha: 0.35));

    GameFx.text(canvas, 'ABOVE: swipe bugs • tap weeds • harvest ripe plants',
        Offset(size.width / 2, size.height * 0.615), 10,
        Colors.white.withValues(alpha: 0.35));

    GameFx.text(canvas, 'Tap to Start',
        Offset(size.width / 2, size.height * 0.68), 14,
        Colors.white.withValues(alpha: 0.3));
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.82),
    );

    GameFx.text(canvas, 'FARM OVER',
        Offset(size.width / 2, size.height / 2 - 60), 28,
        Colors.white.withValues(alpha: 0.55),
        display: true);

    // Big score
    GameFx.text(canvas, '$score',
        Offset(size.width / 2, size.height / 2 - 8), 54,
        _kPotatoGold.withValues(alpha: 0.9),
        display: true, glow: 0.6);

    GameFx.text(canvas, 'points',
        Offset(size.width / 2, size.height / 2 + 32), 14,
        Colors.white.withValues(alpha: 0.35));

    GameFx.text(canvas, 'Tap to restart',
        Offset(size.width / 2, size.height / 2 + 60), 13,
        Colors.white.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant _FarmPanicPainter old) => true;
}
