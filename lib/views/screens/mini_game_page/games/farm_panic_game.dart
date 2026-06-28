import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';
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

const double _kGameDuration = 30.0;

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

// Failure clocks (for urgency / countdown rings). These mirror the existing
// fail thresholds so the on-screen countdown is honest.
const double _kWeedLifeMax = 12.0; // weed damages crop after this many secs

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

enum _Phase { preGame, playing }

// ---- hint state ------------------------------------------------------------

enum _HintKind { channelSwipe, harvestTap, weedTap }

class _Hint {
  _HintKind kind;
  double age = 0;
  _Hint(this.kind);
}

// ---- next-action directive --------------------------------------------------
//
// Every frame we score each demand source by how close it is to costing the
// player points, pick the single most-urgent one, and surface it as (a) a
// big colour-coded banner telling the player what to do, and (b) a spotlight +
// countdown ring drawn on that exact target. The player should never wonder
// "what now?".

enum _ActionKind { swipeChannel, swatBug, pullWeed, harvest, grabToken, flood }

class _Directive {
  final _ActionKind kind;
  final String verb; // e.g. "SWIPE!"
  final Color color;
  final double urgency; // 0..1, 1 = about to fail / highest value
  final Offset? target; // world-space point to spotlight (null = no target)
  final double? targetRadius; // spotlight radius
  final double? countdown; // 0..1 of a failure clock remaining (null = none)
  const _Directive({
    required this.kind,
    required this.verb,
    required this.color,
    required this.urgency,
    this.target,
    this.targetRadius,
    this.countdown,
  });
}

// ---- widget ----------------------------------------------------------------

class FarmPanicGame extends StatefulWidget {
  final MiniGameSession session;
  const FarmPanicGame({super.key, required this.session});
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

  int get _score => widget.session.score;
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

  // Next-action directive (recomputed each tick)
  _Directive? _directive;
  // Smoothed "verb pop" — kicks to 1.0 when the directed action changes so the
  // banner punches the player's attention, then decays.
  _ActionKind? _lastDirectiveKind;
  double _directivePop = 0;
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
    _startGame();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- game setup -----------------------------------------------------------

  void _startGame() {
    _prevScore = 0;
    _combo = 1;
    _elapsed = 0;
    _shakeIntensity = 0;
    _activeChannel = null;
    _lastSwipeTime = -999;
    _lastHintTime = -999;
    _activeHint = null;
    _directive = null;
    _lastDirectiveKind = null;
    _directivePop = 0;
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
    if (!widget.session.isRunning) return;

    setState(() {
      _elapsed += dt;

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
      _computeDirective(dt);
    });
  }

  // ---- next-action directive ------------------------------------------------
  //
  // Build the single most-important "do this now" cue. We rank every live
  // demand source by an urgency in 0..1, where 1 means "you are about to lose
  // points / miss the biggest reward", and surface the winner.

  void _computeDirective(double dt) {
    _Directive? best;
    void consider(_Directive d) {
      if (best == null || d.urgency > best!.urgency) best = d;
    }

    final w = _size.width;

    // 1) Failing channel (circulation about to stall). Most-empty channel.
    int worstCh = -1;
    double worstFlow = 1.0;
    for (int i = 0; i < _channels.length; i++) {
      if (_channels[i].flow < worstFlow) {
        worstFlow = _channels[i].flow;
        worstCh = i;
      }
    }
    if (worstCh >= 0 && worstFlow < 0.45) {
      // urgency rises as flow approaches 0
      final u = (1.0 - worstFlow / 0.45).clamp(0.0, 1.0) * 0.82;
      consider(_Directive(
        kind: _ActionKind.swipeChannel,
        verb: 'SWIPE!',
        color: _kRootFlow,
        urgency: u,
        target: Offset(w * 0.5, _channelY(worstCh)),
        targetRadius: 40,
        countdown: worstFlow.clamp(0.0, 1.0), // ring drains as flow drains
      ));
    }

    // 2) Weed about to damage crop. Oldest unpulled weed.
    _Weed? oldestWeed;
    for (final weed in _weeds) {
      if (weed.pulled) continue;
      if (oldestWeed == null || weed.age > oldestWeed.age) oldestWeed = weed;
    }
    if (oldestWeed != null) {
      final frac = (oldestWeed.age / _kWeedLifeMax).clamp(0.0, 1.0);
      // grows from a baseline so weeds always read as a real task
      final u = (0.45 + 0.5 * frac).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.pullWeed,
        verb: 'YANK WEED!',
        color: _kWeedColor,
        urgency: u,
        target: Offset(oldestWeed.x, oldestWeed.y),
        targetRadius: 30,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 3) Bug about to break through the ground line. Lowest (closest) live bug.
    _Bug? nearestBug;
    for (final bug in _bugs) {
      if (bug.dead) continue;
      if (nearestBug == null || bug.y > nearestBug.y) nearestBug = bug;
    }
    if (nearestBug != null) {
      final breach = _groundY * _kBugDamageThresh;
      final frac = (nearestBug.y / breach).clamp(0.0, 1.0);
      final u = (0.4 + 0.55 * frac).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.swatBug,
        verb: 'SWIPE BUG!',
        color: _kBugColor,
        urgency: u,
        target: Offset(nearestBug.x, nearestBug.y),
        targetRadius: 30,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 4) Ripe potato ready to harvest (big reward, not a failure). Pick the one
    //    that has been ripe longest.
    _Potato? bestRipe;
    for (final p in _potatoes) {
      if (!p.ripe) continue;
      if (bestRipe == null || p.ripeFlashAge > bestRipe.ripeFlashAge) {
        bestRipe = p;
      }
    }
    if (bestRipe != null) {
      // reward urgency ramps the longer it sits unharvested
      final u = (0.5 + 0.3 * (bestRipe.ripeFlashAge / 5.0)).clamp(0.0, 0.86);
      final px = bestRipe.x * w;
      final tipY = _groundY - (20.0 + 45.0);
      consider(_Directive(
        kind: _ActionKind.harvest,
        verb: 'HARVEST!',
        color: _kHarvestReady,
        urgency: u,
        target: Offset(px, tipY),
        targetRadius: 26,
        countdown: null,
      ));
    }

    // 5) Water burst (rare flood power-up) — strong nudge while it's live.
    _WaterBurst? wb;
    for (final b in _waterBursts) {
      if (b.collected) continue;
      wb = b;
      break;
    }
    if (wb != null) {
      final frac = (wb.age / 5.5).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.flood,
        verb: 'FLOOD! SWIPE',
        color: _kWaterBurst,
        urgency: (0.5 + 0.25 * frac).clamp(0.0, 0.78),
        target: Offset(wb.x, wb.y),
        targetRadius: 30,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 6) Floating cash token — low-priority grab.
    _Token? tok;
    for (final t in _tokens) {
      if (t.banked) continue;
      tok = t;
      break;
    }
    if (tok != null) {
      final frac = (tok.age / 4.5).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.grabToken,
        verb: 'GRAB \$!',
        color: _kTokenColor,
        urgency: (0.32 + 0.2 * frac).clamp(0.0, 0.6),
        target: Offset(tok.x, tok.y),
        targetRadius: 26,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // Fallback so the banner is never empty early-game: nudge swiping.
    best ??= _Directive(
      kind: _ActionKind.swipeChannel,
      verb: 'SWIPE TO GROW!',
      color: _kRootFlow,
      urgency: 0.2,
      target: _channels.isNotEmpty ? Offset(w * 0.5, _channelY(0)) : null,
      targetRadius: 40,
      countdown: null,
    );

    // Pop the banner when the directed action changes.
    if (best!.kind != _lastDirectiveKind) {
      _directivePop = 1.0;
      _lastDirectiveKind = best!.kind;
    } else {
      _directivePop = (_directivePop - dt * 3.2).clamp(0.0, 1.0);
    }

    _directive = best;
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
      if (dripPts > 0) widget.session.addScore(dripPts);

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
        widget.session.addScore(_kBugDamageScore);
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
        widget.session.addScore(_kWeedDamage);
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
      // Escalate bug tier over time (compressed for the 30s round)
      int tier = 0;
      if (_elapsed > 15 && _rng.nextDouble() < 0.35) tier = 1; // fast
      if (_elapsed > 22 && _rng.nextDouble() < 0.2) tier = 2; // armored
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
    if (!widget.session.isRunning) return;

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
        widget.session.addScore(pts);
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
        widget.session.addScore(pts);
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
        widget.session.addScore(pts);
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
          widget.session.addScore(pts);
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
        widget.session.addScore(pts);
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
              directive: _directive,
              directivePop: _directivePop,
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
  final _Directive? directive;
  final double directivePop;

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
    required this.directive,
    required this.directivePop,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
    _drawSpotlight(canvas, size); // ← spotlight the most-urgent target
    _drawPopups(canvas, size);
    _drawVignette(canvas, size);
    _drawHUD(canvas, size);
    _drawDirectiveBanner(canvas, size); // ← "DO THIS NOW" banner
    _drawSwipeGuide(canvas, size);
    _drawHintBanner(canvas, size);

    if (shakeIntensity > 0) canvas.restore();
  }

  // ---- vignette (frames the action, adds depth) -----------------------------

  void _drawVignette(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final r = size.longestSide * 0.75;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            Colors.black.withValues(alpha: 0.34),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2), radius: r)),
    );
  }

  // ---- spotlight on the single most-urgent target ---------------------------

  void _drawSpotlight(Canvas canvas, Size size) {
    final d = directive;
    if (d == null || d.target == null || d.targetRadius == null) return;
    final c = d.target!;
    if (!c.dx.isFinite || !c.dy.isFinite) return;
    final baseR = d.targetRadius!;
    // The more urgent, the tighter / faster / brighter the pulse.
    final pulse = 0.5 + 0.5 * sin(elapsed * (6 + 6 * d.urgency));
    final ringR = baseR + 6 + pulse * (4 + 6 * d.urgency);
    final alpha = (0.35 + 0.5 * d.urgency).clamp(0.0, 0.95);

    // Soft glow halo so the eye snaps to it.
    canvas.drawCircle(
      c,
      ringR + 4,
      Paint()
        ..color = d.color.withValues(alpha: alpha * 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Pulsing focus ring.
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + 1.5 * d.urgency
        ..color = d.color.withValues(alpha: alpha),
    );

    // Countdown arc — drains as the target approaches failure.
    final cd = d.countdown;
    if (cd != null && cd.isFinite) {
      final frac = cd.clamp(0.0, 1.0);
      final arcR = ringR + 7;
      final rect = Rect.fromCircle(center: c, radius: arcR);
      // track
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: 0.10),
      );
      // remaining (turns red as it empties)
      final cdColor = Color.lerp(_kDanger, d.color, frac)!;
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..color = cdColor.withValues(alpha: 0.9),
      );
    }

    // Down-pointing chevron above the target so it reads as "here".
    final chevY = c.dy - ringR - 14;
    if (chevY > 4) {
      final chevAlpha = (0.55 + 0.4 * pulse) * alpha;
      final path = Path()
        ..moveTo(c.dx - 7, chevY - 5)
        ..lineTo(c.dx, chevY + 3)
        ..lineTo(c.dx + 7, chevY - 5);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = d.color.withValues(alpha: chevAlpha.clamp(0.0, 1.0)),
      );
    }
  }

  // ---- the big "DO THIS NOW" directive banner -------------------------------

  void _drawDirectiveBanner(Canvas canvas, Size size) {
    final d = directive;
    if (d == null || size.width <= 0) return;

    // Position: a pill near the top, clear of the host's score/timer chrome
    // (host owns the very top — we sit just below it, centered).
    final cx = size.width / 2;
    final cy = (size.height * 0.085).clamp(34.0, 84.0);

    // Urgency drives colour intensity + a heartbeat pulse.
    final beat = 0.5 + 0.5 * sin(elapsed * (5 + 5 * d.urgency));
    final pop = directivePop;
    final scale = 1.0 + 0.12 * pop + 0.04 * beat * d.urgency;

    final verb = d.verb;
    final tp = TextPainter(
      text: TextSpan(
        text: verb,
        style: TextStyle(
          fontFamily: Potatuhs.displayFont,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Guard the clamp: on a tiny viewport `size.width - 24` can fall below the
    // 120 floor, and num.clamp throws if hi < lo (black-screen bug class).
    final pillHi = (size.width - 24).clamp(40.0, double.infinity);
    final pillLo = pillHi < 120.0 ? pillHi : 120.0;
    final pillW = (tp.width + 44).clamp(pillLo, pillHi);
    final pillH = 34.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final pillRect = Rect.fromCenter(
        center: Offset(cx, cy), width: pillW, height: pillH);
    final pillRRect =
        RRect.fromRectAndRadius(pillRect, const Radius.circular(17));

    // Glow halo behind the pill (stronger with urgency).
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..color = d.color.withValues(alpha: (0.25 + 0.4 * d.urgency) * (0.6 + 0.4 * beat))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Pill body.
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, cy - pillH / 2),
          Offset(cx, cy + pillH / 2),
          [
            Color.lerp(const Color(0xFF0D1A12), d.color, 0.30)!,
            Color.lerp(const Color(0xFF0A0F0B), d.color, 0.12)!,
          ],
        ),
    );
    // Bright urgency rim.
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 + 1.2 * d.urgency
        ..color = d.color.withValues(alpha: 0.55 + 0.4 * beat),
    );

    // A small leading "dot" marker in the action colour.
    final dotX = cx - pillW / 2 + 16;
    GameFx.orb(canvas, Offset(dotX, cy), 5, d.color, glow: 0.8 + 0.6 * beat);

    // Verb text.
    tp.paint(canvas, Offset(cx - tp.width / 2 + 8, cy - tp.height / 2));

    canvas.restore();
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

    // Warm sun bloom behind the sky — gives the flat gradient depth.
    if (groundY > 0) {
      final sunX = size.width * 0.82;
      final sunY = groundY * 0.14;
      final bloomR =
          (groundY * 0.9).clamp(8.0, size.height.clamp(8.0, double.infinity));
      canvas.drawCircle(
        Offset(sunX, sunY),
        bloomR,
        Paint()
          ..shader = RadialGradient(colors: [
            Potatuhs.gold.withValues(alpha: 0.16),
            Potatuhs.orange.withValues(alpha: 0.04),
            const Color(0x00000000),
          ], stops: const [
            0.0,
            0.45,
            1.0,
          ]).createShader(Rect.fromCircle(
              center: Offset(sunX, sunY), radius: bloomR)),
      );
      // Sun orb
      GameFx.orb(canvas, Offset(sunX, sunY), 11, Potatuhs.gold,
          glow: 0.7, specular: true);
      // Subtle distant hills silhouette for depth.
      final hillPath = Path()..moveTo(0, groundY);
      final hillTop = groundY - (groundY * 0.10).clamp(6.0, 40.0);
      hillPath.lineTo(0, groundY - 4);
      for (double x = 0; x <= size.width; x += size.width / 6) {
        final hy = hillTop + sin(x * 0.012) * 6;
        hillPath.lineTo(x, hy);
      }
      hillPath.lineTo(size.width, groundY);
      hillPath.close();
      canvas.drawPath(
        hillPath,
        Paint()..color = const Color(0xFF0E1A10).withValues(alpha: 0.5),
      );
    }

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
    const barY = 9.0;
    const barH = 5.0;

    // Combo badge (game-specific HUD — kept)
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

  @override
  bool shouldRepaint(covariant _FarmPanicPainter old) => true;
}
