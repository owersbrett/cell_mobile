import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';
import '../../../../games/fx.dart';
import '../../../../games/potato.dart';
import '../../../../theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Farm Panic — frantic two-zone farm arcade (potato / Hot Potato Games)
//
// CONTRACT: FarmPanicGame(session: session). The MiniGameHost owns the clock,
// countdown, score HUD and results; this widget only simulates the field,
// reports points via session.addScore, and gates all play on session.isRunning.
//
// RENDERING: the whole field is one continuous Ticker → one CustomPainter
// (the "harvest lesson"). No per-entity widgets, no blur-heavy glow stacks,
// capped particle/entity counts. The score, timer and results are host chrome.
// ---------------------------------------------------------------------------

// ---- feel constants --------------------------------------------------------

// Underground water channels
const int _kChannelCount = 4;
const double _kFlowDecayBase = 0.13;
const double _kFlowDecayScale = 0.26;
const double _kSwipeFlowGain = 0.62;
const double _kSwipeHitRadius = 34.0;
const double _kChannelH = 16.0; // visual trough thickness
// A freshly-watered field stays satisfied for a short, randomized "hold" window
// (1..4s — similar across fields so they don't all come due in lockstep) before
// it starts draining and demands irrigation again.
const double _kHoldMin = 1.0;
const double _kHoldMax = 4.0;
const double _kHoldRefillAt = 0.85; // flow at/above which a field re-earns its window
// ...but only after it has genuinely lapsed (dropped this low) since its last
// window — otherwise a perpetually-topped field would never drain.
const double _kHoldLapseAt = 0.45;

// Escalating weather/pest events — punctuated stress that ramps over the round.
// Each event telegraphs a warning, then the effect lands. They start a few
// seconds in and recur on a SHRINKING interval (rare+mild early, frequent+harsh
// late) so the panic genuinely builds with the clock.
const double _kEventFirstAt = 11.0; // no events before this (let the player settle)
const double _kEventWarn = 2.0; // telegraph lead time before the effect lands
const double _kEventHold = 2.0; // banner lingers this long after it lands
const double _kEventIntervalEarly = 17.0;
const double _kEventIntervalLate = 6.5;

// Crops
const double _kPotatoGrowRate = 5.5;
const int _kPotatoCount = 6;

// Above-ground — bugs (SWIPE to swat)
const double _kBugSpawnBase = 2.8;
const double _kBugSpawnMin = 0.5;
const double _kBugSpeed = 50.0;
const double _kBugSpeedScale = 1.8;
const double _kBugHitRadius = 38.0;
const double _kBugSwipeDx = 7.0;
const int _kBugPoints = 15;
const double _kBugDamageThresh = 0.93;
const int _kBugDamageScore = -8;
const int _kBugMaxAlive = 11;

// Weeds (TAP to yank)
const double _kWeedSpawnBase = 7.0;
const double _kWeedSpawnMin = 3.2;
const int _kWeedDamage = -12;
const int _kWeedPoints = 20;
const double _kWeedRadius = 26.0;
const double _kWeedLifeMax = 12.0;
const int _kWeedMaxAlive = 6;

// Water-burst flood power-up (SWIPE)
const double _kWaterBurstSpawnBase = 12.0;
const double _kWaterBurstFlowBoost = 0.4;
const int _kWaterBurstPoints = 30;

// Ripe potato harvest (TAP)
const int _kHarvestPoints = 60;
const double _kHarvestTapRadius = 26.0;

// Cash tokens (TAP) — tokens pay CASH (which banks to score), not score direct
const double _kTokenRadius = 20.0;
const double _kTokenBubbleRate = 6.5;
const double _kTokenBubbleAccel = 0.07;
const int _kTokenMaxAlive = 5;

// ---- cash economy ----------------------------------------------------------
// Cash is a held pool, separate from score. It SLOWLY auto-banks into score
// (hold to bank) — so unspent cash is worth points, but you can SPEND it on a
// relief upgrade before it banks. That is the core decision: relief now vs.
// points later. scoreUnit is "dollars", so banked cash IS the score.
const int _kTokenCash = 10;
const int _kRichTokenCash = 20;
const double _kRichTokenChance = 0.22;
const int _kHarvestCash = 5;
const int _kSwatCash = 1;
const int _kWeedCash = 2;
const int _kBurstCash = 3;
const double _kCashBankRate = 3.0; // cash/sec that auto-deposits to score
const int _kCashScoreWorth = 2; // score earned per banked cash

// ---- shop / upgrades -------------------------------------------------------
const double _kShopBarH = 62.0;
const int _kCostPesticide = 18;
const int _kCostWind = 16;
const int _kCostIrrigation = 24;
const int _kCostAutoCollect = 30;
const double _kPestDuration = 6.0; // bug-spawn suppression
const double _kWindDuration = 3.2; // sweep visual + spawn slow
const double _kWindSlowMult = 1.9; // spawn interval ×mult while windy
const double _kIrrigDuration = 8.0; // auto-water channels
const double _kAutoDuration = 8.0; // farmhand auto-harvest
const double _kAutoInterval = 0.7; // secs between auto-harvests

// ---- scoring / misc --------------------------------------------------------
const int _kComboMultMax = 5;
const double _kShakeDecay = 9.0;
const double _kPopupLifetime = 0.85;

// Hint / discoverability
const double _kHintShowDuration = 2.6;
const double _kMidHintCooldown = 16.0;
const double _kCircStallThresh = 0.22;
const double _kNoSwipeHintTime = 8.0;

// ---- palette (brand-aligned, warm earthy farm) -----------------------------
const Color _kSkyTop = Color(0xFF11210F);
const Color _kSkyMid = Color(0xFF1C3115);
const Color _kSkyHorizon = Color(0xFF3A3410);
const Color _kSoilTop = Color(0xFF4A2A0E);
const Color _kSoilBot = Color(0xFF2A1708);
const Color _kSoilRidge = Color(0xFF6B431E);
const Color _kTrough = Color(0xFF24160A);
const Color _kWater = Color(0xFF34B6F0);
const Color _kWaterDeep = Color(0xFF1E7CC4);
const Color _kPotatoGold = Potatuhs.gold;
const Color _kPotatoDark = Color(0xFF8A5A1E);
const Color _kLeaf = Color(0xFF5BA84F);
const Color _kLeafDark = Color(0xFF2E6B2C);
const Color _kBugColor = Color(0xFFFF5722);
const Color _kWeedColor = Color(0xFF9CCC65);
const Color _kTokenColor = Potatuhs.sienna;
const Color _kWaterBurst = Color(0xFF29B6F6);
const Color _kDanger = Color(0xFFE53935);
const Color _kHintBg = Color(0xCC0D1A2A);
const Color _kHarvestReady = Potatuhs.orange;

// ---- upgrade kinds ---------------------------------------------------------
enum _Upgrade { pesticide, wind, irrigation, autoCollect }

class _ShopItem {
  final _Upgrade kind;
  final String label;
  final String glyph;
  final int cost;
  final Color color;
  Rect rect = Rect.zero; // laid out each frame from canvas size
  double buyFlash = 0; // pops to 1 on purchase, decays
  _ShopItem(this.kind, this.label, this.glyph, this.cost, this.color);
}

// ---- data classes ----------------------------------------------------------

class _Channel {
  final double yFrac;
  double flow;
  double phase = 0; // chevron scroll, advances with flow
  double handle = 0.5; // 0..1 draggable-current position (rides the water edge)
  double handleSeed;
  double hold; // seconds left in the "satisfied" window before draining resumes
  double holdSpan; // the window to reset to once the field is re-watered to full
  bool lapsed = false; // has it dropped low enough since its last window to re-earn one?
  _Channel(this.yFrac, this.flow, this.handleSeed, this.hold, this.holdSpan);
}

enum _EventKind { drought, pestilence }

class _FarmEvent {
  final _EventKind kind;
  final double warn; // telegraph lead time before the effect lands
  double age = 0;
  bool fired = false; // has the effect been applied (warning → active)
  _FarmEvent(this.kind, this.warn);
}

class _Potato {
  double x; // 0..1 across field
  double growth; // 0..1
  bool ripeFlash = false;
  double ripeFlashAge = 0;
  double sway;
  _Potato(this.x, this.growth, this.sway);
  bool get ripe => growth >= 1.0;
}

class _Bug {
  double x, y;
  bool dead = false;
  double deathAge = 0;
  double dx;
  int tier; // 0=small, 1=fast, 2=armored
  int hitsLeft;
  _Bug({required this.x, required this.y, required this.dx, this.tier = 0})
      : hitsLeft = tier == 2 ? 2 : 1;
}

class _Weed {
  double x, y;
  double age = 0;
  bool pulled = false;
  double pullAge = 0;
  double seed;
  _Weed({required this.x, required this.y, required this.seed});
}

class _Token {
  double x, y;
  bool banked = false;
  double age = 0;
  int value;
  _Token({required this.x, required this.y, required this.value});
}

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
  _Popup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.scale = 1.0,
  }) : age = 0;
}

enum _Phase { preGame, playing }

enum _HintKind { channelSwipe, harvestTap, weedTap }

class _Hint {
  _HintKind kind;
  double age = 0;
  _Hint(this.kind);
}

// ---- next-action directive --------------------------------------------------
// One "do this now" cue: the single most-urgent demand, surfaced as a banner +
// an on-target affordance. Crucially, the on-target cue is affordance-aware —
// SWIPE targets get directional arrows, TAP targets get a pulsing ring — so the
// directive reinforces (never fights) the new clearer affordances.
enum _ActionKind { swipeChannel, swatBug, pullWeed, harvest, grabToken, flood }

bool _isSwipeAction(_ActionKind k) =>
    k == _ActionKind.swipeChannel ||
    k == _ActionKind.flood ||
    k == _ActionKind.swatBug;

class _Directive {
  final _ActionKind kind;
  final String verb;
  final Color color;
  final double urgency; // 0..1
  final Offset? target;
  final double? targetRadius;
  final double? countdown; // 0..1 fail-clock remaining
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

  _Phase _phase = _Phase.preGame;
  double _elapsed = 0;
  double _lastTime = 0;
  Size _size = Size.zero;

  int get _score => widget.session.score;
  int _combo = 1;

  // Round length owns difficulty pacing — read from the host spec so the curve
  // adapts whether the round is 30s or 60s (no hardcoded duration here).
  double get _round {
    final d = widget.session.spec.durationSeconds.toDouble();
    return d > 1 ? d : 60.0;
  }

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

  // FX
  final List<FxParticle> _particles = [];
  final List<_Popup> _popups = [];
  double _shakeIntensity = 0;

  // Weather/pest events
  _FarmEvent? _event;
  _EventKind? _lastEventKind;
  double _eventTimer = _kEventFirstAt;
  double _eventFlash = 0; // 0..1 full-field flash decaying after an event lands

  // Gesture
  int? _activeChannel;
  double _lastSwipeTime = -999;

  // Hints
  _Hint? _activeHint;
  double _lastHintTime = -999;

  // Directive
  _Directive? _directive;
  _ActionKind? _lastDirectiveKind;
  double _directivePop = 0;
  double _swipeGuideAge = 0;
  bool _swipeGuideDone = false;

  // Score flash
  int _prevScore = 0;
  double _scoreFlash = 0;

  // ---- cash + shop ----------------------------------------------------------
  double _cash = 0;
  double _bankAccum = 0; // fractional banked-score carry
  double _bankPulse = 0; // HUD "depositing" shimmer when banking

  final List<_ShopItem> _shop = [
    _ShopItem(_Upgrade.pesticide, 'PEST', '🐞', _kCostPesticide,
        const Color(0xFF8BC34A)),
    _ShopItem(_Upgrade.wind, 'WIND', '🌬', _kCostWind, _kWaterBurst),
    _ShopItem(_Upgrade.irrigation, 'WATER', '💧', _kCostIrrigation, _kWater),
    _ShopItem(_Upgrade.autoCollect, 'HAND', '🧺', _kCostAutoCollect,
        Potatuhs.gold),
  ];

  // Upgrade timers (seconds remaining)
  double _pestTimer = 0;
  double _windTimer = 0;
  double _windSweep = 0; // 0..1 gust position across field
  double _irrigTimer = 0;
  double _autoTimer = 0;
  double _autoCd = 0;

  // Derived layout
  double get _groundY => _size.height * 0.50;
  double get _playBottom => _size.height - _kShopBarH;
  double get _soilZoneH => (_playBottom - _groundY).clamp(1.0, double.infinity);

  double _bugSpeed(double t) =>
      _kBugSpeed * (1 + (_kBugSpeedScale - 1) * (t / _round));
  double _bugInterval(double t) =>
      (_kBugSpawnBase - (_kBugSpawnBase - _kBugSpawnMin) * (t / _round))
          .clamp(_kBugSpawnMin, _kBugSpawnBase);
  double _weedInterval(double t) =>
      (_kWeedSpawnBase - (_kWeedSpawnBase - _kWeedSpawnMin) * (t / _round))
          .clamp(_kWeedSpawnMin, _kWeedSpawnBase);
  double _flowDecay(double t) => _kFlowDecayBase + _kFlowDecayScale * (t / _round);
  // A satisfied window: 1..4s, similar across fields but individually random.
  double _freshHold() => _kHoldMin + _rng.nextDouble() * (_kHoldMax - _kHoldMin);
  double _tokenInterval(double t) =>
      (_kTokenBubbleRate - _kTokenBubbleAccel * t).clamp(2.0, _kTokenBubbleRate);

  double get _avgFlow {
    if (_channels.isEmpty) return 0;
    return _channels.fold(0.0, (s, c) => s + c.flow) / _channels.length;
  }

  // ---- lifecycle ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    _startGame();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ---- ATTRACT autopilot ----------------------------------------------------
  /// One hands-free move per host tick (~250ms). Reads the game's OWN entity
  /// lists and calls the SAME resolve handlers the gestures use — no randomness,
  /// no synthetic gestures, no coordinate hunting beyond feeding an entity its
  /// own position. Each call fires the single most valuable/urgent action:
  ///   1. Swat the bug nearest the crop line (a breach steals a whole potato).
  ///   2. Harvest a ripe gold potato (biggest per-action reward).
  ///   3. Collect banked cash before it drifts off-screen.
  ///   4. Grab a flood power-up (waters every field at once).
  ///   5. Yank the oldest weed before it damages the row.
  /// It also drives IRRIGATION directly (no synthetic swipe): a critically dry
  /// channel is watered right after bugs (keeping crops growing is the engine),
  /// and any moderately dry channel is topped up when nothing else is pressing.
  /// If nothing is actionable and cash is banked, it spends on a shop upgrade —
  /// preferring WATER when the fields are drying so crops keep ripening.
  /// Deterministic throughout: ties resolve to the first candidate found.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.playing || _size == Size.zero) return;

    // 1) Most urgent bug = the one furthest down (largest y → closest breach).
    _Bug? urgentBug;
    for (final b in _bugs) {
      if (b.dead) continue;
      if (urgentBug == null || b.y > urgentBug.y) urgentBug = b;
    }
    if (urgentBug != null) {
      _tryKillBug(Offset(urgentBug.x, urgentBug.y));
      return;
    }

    // 1b) CRITICAL irrigation — a field near the growth cliff. Below ~0.25 flow
    // growth halves; below 0.10 potatoes actually shrink (see _updatePotatoes),
    // so a bone-dry channel stalls the whole harvest engine. Drive the driest
    // channel directly (the manual upgrade already auto-waters when active).
    if (_irrigTimer <= 0) {
      final dry = _driestChannel();
      if (dry != null && _channels[dry].flow < 0.28) {
        _autoIrrigate(dry);
        return;
      }
    }

    // 2) A ripe potato ready to harvest.
    final ripe = _firstRipe();
    if (ripe != null) {
      _harvestPotato(ripe);
      return;
    }

    // 3) Banked cash token drifting upward.
    for (final t in _tokens) {
      if (t.banked) continue;
      _tryBankToken(Offset(t.x, t.y));
      return;
    }

    // 4) Flood power-up — one grab waters every channel.
    for (final wb in _waterBursts) {
      if (wb.collected) continue;
      _tryCollectWaterBurst(Offset(wb.x, wb.y));
      return;
    }

    // 5) Oldest un-pulled weed (closest to timing out into crop damage).
    _Weed? weed;
    for (final w in _weeds) {
      if (w.pulled) continue;
      if (weed == null || w.age > weed.age) weed = w;
    }
    if (weed != null) {
      _tryPullWeed(Offset(weed.x, weed.y));
      return;
    }

    // 6) Idle top-up irrigation — nothing pressing, so keep the driest channel
    // comfortably above the growth taper instead of waiting for it to hit the
    // cliff. Same direct-drive path as the critical case.
    if (_irrigTimer <= 0) {
      final dry = _driestChannel();
      if (dry != null && _channels[dry].flow < 0.6) {
        _autoIrrigate(dry);
        return;
      }
    }

    // 7) Idle: bank surplus cash into an upgrade. Prefer irrigation when the
    // fields are drying (keeps crops growing → future harvests); otherwise take
    // the first affordable item.
    if (_irrigTimer <= 0 && _avgFlow < 0.4) {
      for (final item in _shop) {
        if (item.kind == _Upgrade.irrigation && _cash >= item.cost) {
          _buy(item);
          return;
        }
      }
    }
    for (final item in _shop) {
      if (_cash >= item.cost) {
        _buy(item);
        return;
      }
    }
  }

  /// Index of the channel with the least water, or null if there are none.
  /// Deterministic: ties resolve to the lowest index.
  int? _driestChannel() {
    if (_channels.isEmpty) return null;
    int worst = 0;
    for (int i = 1; i < _channels.length; i++) {
      if (_channels[i].flow < _channels[worst].flow) worst = i;
    }
    return worst;
  }

  /// Autopilot irrigation: drive a channel the way a decisive player swipe would
  /// (see _onPointerMove), but via the game's own state instead of a synthetic
  /// pixel gesture. Raising [ch.flow] is the lowest-level effect a swipe has;
  /// we also re-seat the handle on the water's edge and stamp the swipe time so
  /// the low-flow teaching hint doesn't nag.
  void _autoIrrigate(int idx) {
    final ch = _channels[idx];
    ch.flow = (ch.flow + _kSwipeFlowGain).clamp(0.0, 1.0);
    ch.handle = 0.12 + 0.88 * ch.flow;
    _lastSwipeTime = _elapsed;
    if (!_swipeGuideDone) _swipeGuideDone = true;
  }

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
    _cash = 0;
    _bankAccum = 0;
    _bankPulse = 0;
    _pestTimer = 0;
    _windTimer = 0;
    _windSweep = 0;
    _irrigTimer = 0;
    _autoTimer = 0;
    _autoCd = 0;
    for (final s in _shop) {
      s.buyFlash = 0;
    }
    _popups.clear();
    _bugs.clear();
    _weeds.clear();
    _tokens.clear();
    _waterBursts.clear();
    _particles.clear();

    _channels.clear();
    for (int i = 0; i < _kChannelCount; i++) {
      final flow0 = 0.35 + _rng.nextDouble() * 0.25;
      final span = _freshHold();
      final ch = _Channel(
        0.16 + 0.78 * i / (_kChannelCount - 1),
        flow0,
        _rng.nextDouble() * pi * 2,
        // Stagger the first demand so fields don't all come due at once.
        span * (0.3 + _rng.nextDouble() * 0.7),
        span,
      );
      ch.handle = 0.12 + 0.88 * flow0; // start the grip on the water's edge
      _channels.add(ch);
    }

    _potatoes.clear();
    for (int i = 0; i < _kPotatoCount; i++) {
      _potatoes.add(_Potato(
        (i + 0.5) / _kPotatoCount + (_rng.nextDouble() - 0.5) * 0.06,
        0.06 + _rng.nextDouble() * 0.08,
        _rng.nextDouble() * pi * 2,
      ));
    }

    _bugTimer = _kBugSpawnBase * 0.5;
    _weedTimer = _kWeedSpawnBase * 0.6;
    _tokenTimer = _kTokenBubbleRate * 0.25;
    _waterBurstTimer = _kWaterBurstSpawnBase * 0.5;

    _event = null;
    _lastEventKind = null;
    _eventTimer = _kEventFirstAt;
    _eventFlash = 0;

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
      _updateUpgrades(dt);
      _updateCash(dt);
      _updateSwipeGuide(dt);
      _updateHints(dt);
      _updateEvents(dt);
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

  // ---- upgrades -------------------------------------------------------------

  void _updateUpgrades(double dt) {
    for (final s in _shop) {
      if (s.buyFlash > 0) s.buyFlash = (s.buyFlash - dt * 2.2).clamp(0.0, 1.0);
    }
    if (_pestTimer > 0) _pestTimer = (_pestTimer - dt).clamp(0.0, _kPestDuration);
    if (_windTimer > 0) {
      _windTimer = (_windTimer - dt).clamp(0.0, _kWindDuration);
      _windSweep = (1.0 - _windTimer / _kWindDuration).clamp(0.0, 1.0);
      // Gust keeps clearing weeds/loose bugs as it crosses the field.
      final gx = _windSweep * _size.width;
      for (final w in _weeds) {
        if (!w.pulled && w.x < gx) {
          w.pulled = true;
          w.pullAge = 0;
        }
      }
      for (final b in _bugs) {
        if (!b.dead && b.x < gx && b.y < _groundY * 0.72) {
          b.dead = true;
          b.deathAge = 0;
        }
      }
    }
    if (_irrigTimer > 0) {
      _irrigTimer = (_irrigTimer - dt).clamp(0.0, _kIrrigDuration);
    }
    if (_autoTimer > 0) {
      _autoTimer = (_autoTimer - dt).clamp(0.0, _kAutoDuration);
      _autoCd -= dt;
      if (_autoCd <= 0) {
        final ripe = _firstRipe();
        if (ripe != null) {
          _harvestPotato(ripe, fromAuto: true);
          _autoCd = _kAutoInterval;
        } else {
          _autoCd = 0.2;
        }
      }
    }
  }

  _Potato? _firstRipe() {
    _Potato? best;
    for (final p in _potatoes) {
      if (!p.ripe) continue;
      if (best == null || p.ripeFlashAge > best.ripeFlashAge) best = p;
    }
    return best;
  }

  void _buy(_ShopItem item) {
    if (_cash < item.cost) return;
    _cash -= item.cost;
    item.buyFlash = 1.0;
    _shakeIntensity = max(_shakeIntensity, 3.0);
    final cx = item.rect.center.dx;
    switch (item.kind) {
      case _Upgrade.pesticide:
        _pestTimer = _kPestDuration;
        for (final b in _bugs) {
          if (!b.dead) {
            b.dead = true;
            b.deathAge = 0;
          }
        }
        _spawnParticles(
            Offset(_size.width * 0.5, _groundY * 0.45), const Color(0xFF7CB342),
            count: 18);
        _spawnPopup(_size.width * 0.5, _groundY * 0.4, 'BUGS CLEARED',
            const Color(0xFF8BC34A),
            scale: 1.2);
        break;
      case _Upgrade.wind:
        _windTimer = _kWindDuration;
        _windSweep = 0;
        _spawnParticles(Offset(0, _groundY * 0.5), Colors.white,
            count: 16, speed: 200);
        _spawnPopup(_size.width * 0.5, _groundY * 0.4, 'GUST!', _kWaterBurst,
            scale: 1.2);
        break;
      case _Upgrade.irrigation:
        _irrigTimer = _kIrrigDuration;
        _spawnPopup(_size.width * 0.5, _groundY + 24, 'IRRIGATION ON', _kWater,
            scale: 1.1);
        break;
      case _Upgrade.autoCollect:
        _autoTimer = _kAutoDuration;
        _autoCd = 0;
        _spawnPopup(_size.width * 0.5, _groundY * 0.4, 'FARMHAND HIRED',
            Potatuhs.gold,
            scale: 1.1);
        break;
    }
    _spawnParticles(Offset(cx, _playBottom), item.color, count: 10);
  }

  // ---- cash banking ---------------------------------------------------------

  void _updateCash(double dt) {
    if (_cash > 0) {
      final bank = min(_cash, _kCashBankRate * dt);
      _cash -= bank;
      _bankAccum += bank * _kCashScoreWorth;
      final whole = _bankAccum.floor();
      if (whole > 0) {
        widget.session.addScore(whole);
        _bankAccum -= whole;
      }
      _bankPulse = (0.5 + 0.5 * sin(_elapsed * 6)).toDouble();
    } else {
      _bankPulse = 0;
    }
  }

  // ---- directive ------------------------------------------------------------

  void _computeDirective(double dt) {
    _Directive? best;
    void consider(_Directive d) {
      if (best == null || d.urgency > best!.urgency) best = d;
    }

    final w = _size.width;

    // 1) Failing channel circulation.
    int worstCh = -1;
    double worstFlow = 1.0;
    for (int i = 0; i < _channels.length; i++) {
      if (_channels[i].flow < worstFlow) {
        worstFlow = _channels[i].flow;
        worstCh = i;
      }
    }
    if (worstCh >= 0 && worstFlow < 0.45 && _irrigTimer <= 0) {
      final u = (1.0 - worstFlow / 0.45).clamp(0.0, 1.0) * 0.82;
      consider(_Directive(
        kind: _ActionKind.swipeChannel,
        verb: 'SWIPE TO FLOW',
        color: _kWater,
        urgency: u,
        target: Offset(w * 0.5, _channelY(worstCh)),
        targetRadius: 40,
        countdown: worstFlow.clamp(0.0, 1.0),
      ));
    }

    // 2) Weed about to damage crop.
    _Weed? oldestWeed;
    for (final weed in _weeds) {
      if (weed.pulled) continue;
      if (oldestWeed == null || weed.age > oldestWeed.age) oldestWeed = weed;
    }
    if (oldestWeed != null) {
      final frac = (oldestWeed.age / _kWeedLifeMax).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.pullWeed,
        verb: 'TAP TO YANK',
        color: _kWeedColor,
        urgency: (0.45 + 0.5 * frac).clamp(0.0, 1.0),
        target: Offset(oldestWeed.x, oldestWeed.y),
        targetRadius: 28,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 3) Bug nearing the ground line.
    _Bug? nearestBug;
    for (final bug in _bugs) {
      if (bug.dead) continue;
      if (nearestBug == null || bug.y > nearestBug.y) nearestBug = bug;
    }
    if (nearestBug != null) {
      final breach = _groundY * _kBugDamageThresh;
      final frac = (nearestBug.y / breach).clamp(0.0, 1.0);
      consider(_Directive(
        kind: _ActionKind.swatBug,
        verb: 'SWIPE THE BUG',
        color: _kBugColor,
        urgency: (0.4 + 0.55 * frac).clamp(0.0, 1.0),
        target: Offset(nearestBug.x, nearestBug.y),
        targetRadius: 30,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 4) Ripe potato ready to harvest (big reward).
    _Potato? bestRipe = _firstRipe();
    if (bestRipe != null) {
      final u = (0.5 + 0.3 * (bestRipe.ripeFlashAge / 5.0)).clamp(0.0, 0.86);
      final px = bestRipe.x * w;
      final tipY = _groundY - _stalkHeight(bestRipe) - 6;
      consider(_Directive(
        kind: _ActionKind.harvest,
        verb: 'TAP TO HARVEST',
        color: _kHarvestReady,
        urgency: u,
        target: Offset(px, tipY),
        targetRadius: 26,
        countdown: null,
      ));
    }

    // 5) Water burst flood power-up.
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
        verb: 'SWIPE THE FLOOD',
        color: _kWaterBurst,
        urgency: (0.5 + 0.25 * frac).clamp(0.0, 0.78),
        target: Offset(wb.x, wb.y),
        targetRadius: 30,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    // 6) Cash token grab.
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
        verb: 'TAP THE CASH',
        color: _kTokenColor,
        urgency: (0.32 + 0.2 * frac).clamp(0.0, 0.6),
        target: Offset(tok.x, tok.y),
        targetRadius: 24,
        countdown: (1.0 - frac).clamp(0.0, 1.0),
      ));
    }

    best ??= _Directive(
      kind: _ActionKind.swipeChannel,
      verb: 'SWIPE TO FLOW',
      color: _kWater,
      urgency: 0.2,
      target: _channels.isNotEmpty ? Offset(w * 0.5, _channelY(0)) : null,
      targetRadius: 40,
      countdown: null,
    );

    if (best!.kind != _lastDirectiveKind) {
      _directivePop = 1.0;
      _lastDirectiveKind = best!.kind;
    } else {
      _directivePop = (_directivePop - dt * 3.2).clamp(0.0, 1.0);
    }
    _directive = best;
  }

  // ---- per-frame updates ----------------------------------------------------

  void _updateShake(double dt) {
    if (_shakeIntensity > 0) {
      _shakeIntensity *= (1 - dt * _kShakeDecay);
      if (_shakeIntensity < 0.2) _shakeIntensity = 0;
    }
  }

  void _updateSwipeGuide(double dt) {
    if (_swipeGuideDone) return;
    _swipeGuideAge += dt;
    if (_swipeGuideAge > 3.5) _swipeGuideDone = true;
  }

  void _updateHints(double dt) {
    if (_activeHint != null) {
      _activeHint!.age += dt;
      if (_activeHint!.age > _kHintShowDuration) _activeHint = null;
      return;
    }
    if (_elapsed - _lastHintTime < _kMidHintCooldown) return;
    if (_elapsed < 5.0) return;

    final noSwipe = (_elapsed - _lastSwipeTime) > _kNoSwipeHintTime;
    final lowFlow = _avgFlow < _kCircStallThresh;
    if (_irrigTimer <= 0 && (noSwipe || (lowFlow && _elapsed > 10))) {
      _showHint(_HintKind.channelSwipe);
      return;
    }
    if (_potatoes.any((p) => p.ripe && p.ripeFlashAge > 4.0) &&
        _autoTimer <= 0) {
      _showHint(_HintKind.harvestTap);
      return;
    }
    if (_weeds.where((w) => !w.pulled).length >= 2 && _score < 80) {
      _showHint(_HintKind.weedTap);
    }
  }

  void _showHint(_HintKind kind) {
    _activeHint = _Hint(kind);
    _lastHintTime = _elapsed;
  }

  // ---- weather/pest events --------------------------------------------------

  void _updateEvents(double dt) {
    if (_eventFlash > 0) _eventFlash = (_eventFlash - dt * 1.6).clamp(0.0, 1.0);

    final ev = _event;
    if (ev != null) {
      ev.age += dt;
      if (!ev.fired && ev.age >= ev.warn) {
        ev.fired = true;
        _fireEvent(ev.kind);
      }
      if (ev.fired && ev.age >= ev.warn + _kEventHold) {
        _event = null;
        _eventTimer = _nextEventInterval();
      }
      return;
    }

    if (_elapsed < _kEventFirstAt) return;
    _eventTimer -= dt;
    if (_eventTimer <= 0) _event = _FarmEvent(_pickEvent(), _kEventWarn);
  }

  // Interval shrinks as the round runs: rare early, relentless late.
  double _nextEventInterval() {
    final t = (_elapsed / _round).clamp(0.0, 1.0);
    final base =
        _kEventIntervalEarly + (_kEventIntervalLate - _kEventIntervalEarly) * t;
    return base * (0.8 + _rng.nextDouble() * 0.4);
  }

  // Vary the entropy — avoid the same event twice running when we can.
  _EventKind _pickEvent() {
    var pick = _rng.nextBool() ? _EventKind.drought : _EventKind.pestilence;
    if (pick == _lastEventKind && _rng.nextBool()) {
      pick = pick == _EventKind.drought
          ? _EventKind.pestilence
          : _EventKind.drought;
    }
    _lastEventKind = pick;
    return pick;
  }

  void _fireEvent(_EventKind kind) {
    _eventFlash = 1.0;
    _shakeIntensity = max(_shakeIntensity, 9);
    final t = (_elapsed / _round).clamp(0.0, 1.0);
    final cx = _size.width / 2;
    final cy = _groundY + _soilZoneH * 0.5;
    switch (kind) {
      case _EventKind.drought:
        // Every channel instantly runs dry — scramble to re-irrigate. (Active
        // irrigation auto-refills over the next seconds, softening the blow.)
        for (final ch in _channels) {
          ch.flow = 0.0;
          ch.hold = 0.0;
          ch.lapsed = true;
        }
        _spawnPopup(cx, cy, 'DROUGHT!', _kDanger, scale: 1.6);
        for (int i = 0; i < 5; i++) {
          _spawnParticles(Offset(_size.width * (i + 0.5) / 5, _groundY + 14),
              const Color(0xFFC9A24B), count: 6, speed: 80);
        }
        break;
      case _EventKind.pestilence:
        // A swarm descends all at once — bigger the later it strikes. Pesticide
        // (the PEST upgrade) shields the field, so the warning is a buy cue.
        if (_pestTimer > 0) {
          _spawnPopup(cx, cy, 'SWARM REPELLED!', _kHarvestReady, scale: 1.3);
          break;
        }
        final swarm = (5 + 6 * t).round();
        for (int i = 0; i < swarm; i++) {
          final tier = (t > 0.6 && _rng.nextDouble() < 0.3) ? 1 : 0;
          _bugs.add(_Bug(
            x: 16 + _rng.nextDouble() * (_size.width - 32),
            y: -12 - _rng.nextDouble() * 70, // staggered entry from above
            dx: (_rng.nextDouble() - 0.5) * 60,
            tier: tier,
          ));
        }
        _spawnPopup(cx, cy, 'PEST SWARM!', _kDanger, scale: 1.5);
        break;
    }
  }

  void _updateChannels(double dt) {
    final decay = _flowDecay(_elapsed);
    for (int i = 0; i < _channels.length; i++) {
      final ch = _channels[i];
      if (_irrigTimer > 0) {
        ch.flow = (ch.flow + 0.7 * dt).clamp(0.0, 1.0); // auto-water
        ch.hold = ch.holdSpan; // the upgrade keeps every field satisfied
      } else if (ch.hold > 0) {
        ch.hold -= dt; // satisfied window — the field holds its water, no drain
      } else {
        ch.flow = (ch.flow - decay * dt).clamp(0.0, 1.0); // demand is back
      }
      // Once a field drops low it has "lapsed" and may re-earn a window.
      if (ch.flow < _kHoldLapseAt) ch.lapsed = true;
      // Re-watering a lapsed field (near) full grants a fresh, random window.
      // The lapse gate is what stops a topped-off field from holding forever.
      if (ch.flow >= _kHoldRefillAt && ch.hold <= 0 && ch.lapsed) {
        ch.holdSpan = _freshHold();
        ch.hold = ch.holdSpan;
        ch.lapsed = false;
      }
      // The grip rides the water's leading edge: it slides back as the field
      // drains, and forward as it fills. While the player is dragging this
      // channel, their finger owns the grip (see _onPointerMove); on release it
      // re-binds to the level here.
      if (_activeChannel != i) {
        final target = 0.12 + 0.88 * ch.flow;
        ch.handle += (target - ch.handle) * (1 - exp(-6 * dt));
      }
      ch.phase += (35 + 150 * ch.flow) * dt; // visual flow speed ∝ flow
    }
  }

  void _updatePotatoes(double dt) {
    final avg = _irrigTimer > 0 ? max(_avgFlow, 0.9) : _avgFlow;
    // Growth tracks how watered the fields are: a GENTLE taper as they drain
    // through the watered range, then an ABRUPT collapse (and slight shrink)
    // once they run nearly dry.
    double mul;
    if (avg >= 0.25) {
      mul = 0.5 + 0.5 * ((avg - 0.25) / 0.75); // 0.25→half … 1.0→full
    } else if (avg >= 0.10) {
      mul = 0.5 * ((avg - 0.10) / 0.15); // 0.25→half knees down to 0.10→0
    } else {
      mul = -0.18; // bone dry: potatoes back off
    }
    final rate = _kPotatoGrowRate * mul * 0.06 * dt;
    for (final p in _potatoes) {
      if (p.ripe) {
        if (p.ripeFlash) p.ripeFlashAge += dt;
        continue;
      }
      p.growth = (p.growth + rate).clamp(0.0, 1.0);
      if (rate > 0 && p.growth >= 1.0) {
        p.ripeFlash = true;
        p.ripeFlashAge = 0;
        _spawnParticles(
            Offset(p.x * _size.width, _groundY - 18), _kPotatoGold,
            count: 12);
        _spawnPopup(
            p.x * _size.width, _groundY - 30, 'READY!', _kHarvestReady,
            scale: 1.15);
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
      final spd = bug.tier == 1 ? speed * 1.55 : speed;
      bug.y += spd * dt;
      bug.x += bug.dx * dt;
      if (bug.x < 0) bug.dx = bug.dx.abs();
      if (bug.x > _size.width) bug.dx = -bug.dx.abs();
      if (bug.y >= groundLine * _kBugDamageThresh) {
        bug.dead = true;
        _combo = 1;
        _shakeIntensity = 6;
        // The bug reaches the row and STEALS the nearest crop outright (100%):
        // whatever that potato had grown is gone. Swat bugs or lose the harvest.
        _Potato? target;
        double best = double.infinity;
        for (final p in _potatoes) {
          final d = (p.x * _size.width - bug.x).abs();
          if (d < best) {
            best = d;
            target = p;
          }
        }
        if (target != null && target.growth > 0.02) {
          final wasRipe = target.ripe;
          final tx = target.x * _size.width;
          target.growth = 0.0;
          target.ripeFlash = false;
          target.ripeFlashAge = 0;
          _spawnPopup(tx, groundLine - 24, wasRipe ? 'STOLEN!' : 'EATEN!',
              _kDanger, scale: 1.2);
          _spawnParticles(
              Offset(tx, groundLine - 14), _kPotatoDark, count: 14, speed: 130);
        }
        widget.session.addScore(_kBugDamageScore);
        _spawnPopup(bug.x, groundLine - 40, '$_kBugDamageScore', _kDanger);
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
      if (w.age > _kWeedLifeMax) {
        w.pulled = true;
        widget.session.addScore(_kWeedDamage);
        _combo = 1;
        _shakeIntensity = 4;
        _spawnPopup(w.x, w.y - 20, '$_kWeedDamage', _kDanger);
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
      tok.y -= 26.0 * dt;
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
    if (_particles.length > 140) {
      _particles.removeRange(0, _particles.length - 140);
    }
  }

  void _updatePopups(double dt) {
    for (int i = _popups.length - 1; i >= 0; i--) {
      _popups[i].age += dt;
      _popups[i].y -= 38 * dt;
      if (_popups[i].age > _kPopupLifetime) _popups.removeAt(i);
    }
    if (_popups.length > 10) _popups.removeRange(0, _popups.length - 10);
  }

  // ---- spawning -------------------------------------------------------------

  void _spawnBugs(double dt) {
    _bugTimer -= dt;
    if (_bugTimer > 0) return;
    final slow = _windTimer > 0 ? _kWindSlowMult : 1.0;
    _bugTimer = (_bugInterval(_elapsed) + _rng.nextDouble() * 0.4) * slow;
    if (_pestTimer > 0) return; // suppressed
    if (_bugs.where((b) => !b.dead).length >= _kBugMaxAlive) return;
    int tier = 0;
    final f = _elapsed / _round;
    if (f > 0.45 && _rng.nextDouble() < 0.35) tier = 1;
    if (f > 0.70 && _rng.nextDouble() < 0.2) tier = 2;
    _bugs.add(_Bug(
      x: 20 + _rng.nextDouble() * (_size.width - 40),
      y: -12,
      dx: (_rng.nextDouble() - 0.5) * 50,
      tier: tier,
    ));
  }

  void _spawnWeeds(double dt) {
    _weedTimer -= dt;
    if (_weedTimer > 0) return;
    final slow = _windTimer > 0 ? _kWindSlowMult : 1.0;
    _weedTimer = (_weedInterval(_elapsed) + _rng.nextDouble() * 1.0) * slow;
    if (_weeds.where((w) => !w.pulled).length >= _kWeedMaxAlive) return;
    _weeds.add(_Weed(
      x: 24.0 + _rng.nextDouble() * (_size.width - 48),
      y: _groundY - 16 - _rng.nextDouble() * 26,
      seed: _rng.nextDouble() * pi * 2,
    ));
  }

  void _spawnTokens(double dt) {
    _tokenTimer -= dt;
    if (_tokenTimer > 0) return;
    _tokenTimer = _tokenInterval(_elapsed) + _rng.nextDouble() * 0.8;
    if (_tokens.where((t) => !t.banked).length >= _kTokenMaxAlive) return;
    final rich = _rng.nextDouble() < _kRichTokenChance;
    _tokens.add(_Token(
      x: 30 + _rng.nextDouble() * (_size.width - 60),
      y: _groundY - 10,
      value: rich ? _kRichTokenCash : _kTokenCash,
    ));
  }

  void _spawnWaterBursts(double dt) {
    _waterBurstTimer -= dt;
    if (_waterBurstTimer > 0) return;
    _waterBurstTimer = _kWaterBurstSpawnBase * (0.8 + _rng.nextDouble() * 0.4);
    final chIdx = _rng.nextInt(_kChannelCount);
    _waterBursts.add(_WaterBurst(
      x: _size.width * (0.2 + _rng.nextDouble() * 0.6),
      y: _channelY(chIdx),
    ));
  }

  void _checkScoreFlash(double dt) {
    if (_score > _prevScore) {
      _scoreFlash = 1.0;
      _prevScore = _score;
    }
    _scoreFlash = (_scoreFlash - dt * 4).clamp(0.0, 1.0);
  }

  // ---- fx helpers -----------------------------------------------------------

  void _spawnParticles(Offset at, Color color,
      {int count = 12, double speed = 130}) {
    _particles.addAll(FxBurst.spawn(at, color, count: count, speed: speed));
  }

  void _spawnPopup(double x, double y, String text, Color color,
      {double scale = 1.0}) {
    _popups.add(_Popup(x: x, y: y, text: text, color: color, scale: scale));
  }

  void _advanceCombo() => _combo = (_combo + 1).clamp(1, _kComboMultMax);

  double _stalkHeight(_Potato p) => 22 + p.growth.clamp(0.0, 1.0) * 48;

  // ---- gestures -------------------------------------------------------------

  void _onPointerDown(Offset pos) {
    if (!widget.session.isRunning) return;

    // Shop bar owns the bottom strip.
    if (pos.dy >= _playBottom) {
      for (final item in _shop) {
        if (item.rect.contains(pos)) {
          _buy(item);
          return;
        }
      }
      return;
    }

    if (pos.dy < _groundY) {
      _tryBankToken(pos);
      _tryPullWeed(pos);
      _tryHarvestPotato(pos);
    } else {
      _activeChannel = _nearestChannel(pos);
      final ch = _channels[_activeChannel!];
      ch.handle = (pos.dx / _size.width).clamp(0.0, 1.0);
      _tryCollectWaterBurst(pos);
    }
  }

  void _onPointerMove(Offset pos, Offset delta) {
    if (_phase != _Phase.playing) return;
    if (pos.dy >= _playBottom) return;

    if (pos.dy >= _groundY && _activeChannel != null) {
      final ch = _channels[_activeChannel!];
      final chY = _channelY(_activeChannel!);
      if ((pos.dy - chY).abs() < _kSwipeHitRadius) {
        final speed = delta.distance;
        ch.flow = (ch.flow + _kSwipeFlowGain * speed / 200.0).clamp(0.0, 1.0);
        ch.handle = (pos.dx / _size.width).clamp(0.0, 1.0);
        _lastSwipeTime = _elapsed;
        if (!_swipeGuideDone) _swipeGuideDone = true;
      }
      _tryCollectWaterBurst(pos);
    }

    if (pos.dy < _groundY && delta.dx.abs() > _kBugSwipeDx) {
      _tryKillBug(pos);
    }
  }

  void _onPointerUp(Offset pos) => _activeChannel = null;

  void _tryBankToken(Offset pos) {
    for (int i = _tokens.length - 1; i >= 0; i--) {
      final tok = _tokens[i];
      if (tok.banked) continue;
      final dx = tok.x - pos.dx;
      final dy = tok.y - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kTokenRadius * 2.2) {
        tok.banked = true;
        _cash += tok.value;
        _spawnPopup(tok.x, tok.y, '+\$${tok.value}', _kTokenColor, scale: 1.1);
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
        _cash += _kWeedCash;
        _spawnPopup(w.x, w.y - 10, '+$pts', _kWeedColor, scale: 1.1);
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
      final tipY = _groundY - _stalkHeight(p);
      final dx = px - pos.dx;
      final dy = tipY - pos.dy;
      if (sqrt(dx * dx + dy * dy) < _kHarvestTapRadius * 2.5) {
        _harvestPotato(p);
        break;
      }
    }
  }

  void _harvestPotato(_Potato p, {bool fromAuto = false}) {
    final px = p.x * _size.width;
    final tipY = _groundY - _stalkHeight(p);
    final pts = _kHarvestPoints * (fromAuto ? 1 : _combo);
    widget.session.addScore(pts);
    _cash += _kHarvestCash;
    _spawnPopup(px, tipY - 10, fromAuto ? '+$pts' : '+$pts!', _kPotatoGold,
        scale: fromAuto ? 1.0 : 1.4);
    _spawnParticles(Offset(px, tipY), _kPotatoGold, count: 16, speed: 150);
    if (!fromAuto) _advanceCombo();
    p.growth = 0.06 + _rng.nextDouble() * 0.06;
    p.ripeFlash = false;
    p.ripeFlashAge = 0;
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
          _cash += _kSwatCash;
          _spawnPopup(bug.x, bug.y, '+$pts', _kLeaf);
          _spawnParticles(Offset(bug.x, bug.y), _kBugColor, count: 10);
          _advanceCombo();
        } else {
          _spawnPopup(bug.x, bug.y, 'HIT!', _kLeaf, scale: 0.9);
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
      if (sqrt(dx * dx + dy * dy) < 38) {
        wb.collected = true;
        for (final ch in _channels) {
          ch.flow = (ch.flow + _kWaterBurstFlowBoost).clamp(0.0, 1.0);
        }
        final pts = _kWaterBurstPoints * _combo;
        widget.session.addScore(pts);
        _cash += _kBurstCash;
        _spawnPopup(wb.x, wb.y, '+$pts FLOOD', _kWaterBurst, scale: 1.2);
        _spawnParticles(Offset(wb.x, wb.y), _kWaterBurst, count: 16, speed: 140);
        _advanceCombo();
        break;
      }
    }
  }

  int _nearestChannel(Offset pos) {
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _channels.length; i++) {
      final dist = (pos.dy - _channelY(i)).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  double _channelY(int idx) {
    if (_size == Size.zero) return 0;
    return _groundY + _channels[idx].yFrac * _soilZoneH;
  }

  void _layoutShop(Size size) {
    const pad = 8.0;
    const gap = 6.0;
    final n = _shop.length;
    final top = size.height - _kShopBarH + 6;
    final h = _kShopBarH - 12;
    final bw = (size.width - pad * 2 - gap * (n - 1)) / n;
    for (int i = 0; i < n; i++) {
      _shop[i].rect = Rect.fromLTWH(pad + i * (bw + gap), top, bw, h);
    }
  }

  double _upgradeTimer(_Upgrade u) {
    switch (u) {
      case _Upgrade.pesticide:
        return _pestTimer / _kPestDuration;
      case _Upgrade.wind:
        return _windTimer / _kWindDuration;
      case _Upgrade.irrigation:
        return _irrigTimer / _kIrrigDuration;
      case _Upgrade.autoCollect:
        return _autoTimer / _kAutoDuration;
    }
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      _layoutShop(_size);
      return Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        onPointerMove: (e) => _onPointerMove(e.localPosition, e.localDelta),
        onPointerUp: (e) => _onPointerUp(e.localPosition),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _FarmPanicPainter(
                elapsed: _elapsed,
                round: _round,
                score: _score,
                combo: _combo,
                cash: _cash.round(),
                bankPulse: _bankPulse,
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
                playBottom: _playBottom,
                soilZoneH: _soilZoneH,
                channelYs:
                    List.generate(_channels.length, (i) => _channelY(i)),
                stalkHeights:
                    List.generate(_potatoes.length, (i) => _stalkHeight(_potatoes[i])),
                activeHint: _activeHint,
                swipeGuideAge: _swipeGuideAge,
                swipeGuideDone: _swipeGuideDone,
                directive: _directive,
                directivePop: _directivePop,
                shop: _shop,
                shopTimers: {
                  for (final s in _shop) s.kind: _upgradeTimer(s.kind)
                },
                windTimer: _windTimer,
                windSweep: _windSweep,
                irrigActive: _irrigTimer > 0,
                event: _event,
                eventFlash: _eventFlash,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );
    });
  }
}

// ===========================================================================
// Painter — the whole field in one pass.
// ===========================================================================

class _FarmPanicPainter extends CustomPainter {
  final double elapsed, round, shakeIntensity, groundY, playBottom, soilZoneH;
  final double scoreFlash, bankPulse;
  final int score, combo, cash;
  final List<_Channel> channels;
  final List<_Potato> potatoes;
  final List<_Bug> bugs;
  final List<_Weed> weeds;
  final List<_Token> tokens;
  final List<_WaterBurst> waterBursts;
  final List<FxParticle> particles;
  final List<_Popup> popups;
  final List<double> channelYs;
  final List<double> stalkHeights;
  final _Hint? activeHint;
  final double swipeGuideAge;
  final bool swipeGuideDone;
  final _Directive? directive;
  final double directivePop;
  final List<_ShopItem> shop;
  final Map<_Upgrade, double> shopTimers;
  final double windTimer, windSweep;
  final bool irrigActive;
  final _FarmEvent? event;
  final double eventFlash;

  _FarmPanicPainter({
    required this.elapsed,
    required this.round,
    required this.score,
    required this.combo,
    required this.cash,
    required this.bankPulse,
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
    required this.playBottom,
    required this.soilZoneH,
    required this.channelYs,
    required this.stalkHeights,
    required this.activeHint,
    required this.swipeGuideAge,
    required this.swipeGuideDone,
    required this.directive,
    required this.directivePop,
    required this.shop,
    required this.shopTimers,
    required this.windTimer,
    required this.windSweep,
    required this.irrigActive,
    required this.event,
    required this.eventFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (shakeIntensity > 0) {
      canvas.save();
      canvas.translate(
        sin(elapsed * 47) * shakeIntensity,
        cos(elapsed * 37) * shakeIntensity,
      );
    }

    _drawSky(canvas, size);
    _drawSoil(canvas, size);
    _drawGroundRidge(canvas, size);
    for (int i = 0; i < channels.length; i++) {
      _drawChannel(canvas, size, i);
    }
    _drawUndergroundTubers(canvas, size);
    for (int i = 0; i < potatoes.length; i++) {
      _drawPlant(canvas, size, i);
    }
    _drawBugs(canvas, size);
    _drawWeeds(canvas, size);
    _drawTokens(canvas, size);
    _drawWaterBursts(canvas, size);
    if (windTimer > 0) _drawWind(canvas, size);
    FxBurst.paint(canvas, particles);
    _drawTargetCue(canvas, size); // affordance-aware (swipe arrows / tap ring)
    _drawPopups(canvas, size);
    _drawVignette(canvas, size);
    _drawCashHud(canvas, size);
    _drawComboBadge(canvas, size);
    _drawDirectiveBanner(canvas, size);
    _drawSwipeGuide(canvas, size);
    _drawHintBanner(canvas, size);
    _drawEventBanner(canvas, size);
    _drawShop(canvas, size);

    if (shakeIntensity > 0) canvas.restore();
  }

  // ---- weather/pest event banner --------------------------------------------

  void _drawEventBanner(Canvas canvas, Size size) {
    // Full-field red flash the instant an event lands.
    if (eventFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kDanger.withValues(alpha: 0.22 * eventFlash));
    }
    final ev = event;
    if (ev == null) return;

    final warning = !ev.fired;
    final drought = ev.kind == _EventKind.drought;
    final label = drought
        ? (warning ? 'DROUGHT WARNING' : 'DROUGHT')
        : (warning ? 'PEST SWARM INCOMING' : 'PEST SWARM');
    final accent = drought ? const Color(0xFFE8A53A) : _kDanger;
    final pulse = 0.5 + 0.5 * sin(elapsed * (warning ? 9 : 5));

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bw = tp.width + 56;
    final bh = tp.height + 16;
    final cx = size.width / 2;
    final top = groundY * 0.34;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, top), width: bw, height: bh),
      const Radius.circular(10),
    );
    // glow → backing → pulsing border
    canvas.drawRRect(
      rect,
      Paint()
        ..color = accent.withValues(alpha: 0.30 + 0.25 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawRRect(
        rect, Paint()..color = Colors.black.withValues(alpha: 0.58));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + 1.6 * pulse
        ..color = accent.withValues(alpha: 0.6 + 0.4 * pulse),
    );

    // warning triangles flanking the label
    void triangle(double tx) {
      final s = 6.0;
      canvas.drawPath(
        Path()
          ..moveTo(tx, top - s)
          ..lineTo(tx + s, top + s)
          ..lineTo(tx - s, top + s)
          ..close(),
        Paint()..color = accent.withValues(alpha: 0.85 + 0.15 * pulse),
      );
    }

    triangle(cx - tp.width / 2 - 16);
    triangle(cx + tp.width / 2 + 16);
    tp.paint(canvas, Offset(cx - tp.width / 2, top - tp.height / 2));

    // countdown bar under the warning so the brace can be timed
    if (warning) {
      final frac = ((ev.warn - ev.age) / ev.warn).clamp(0.0, 1.0);
      final barW = bw - 16;
      final by = top + bh / 2 + 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - barW / 2, by, barW * frac, 3),
            const Radius.circular(2)),
        Paint()..color = accent.withValues(alpha: 0.85),
      );
    }
  }

  // ---- helpers --------------------------------------------------------------

  void _glyph(Canvas canvas, String s, Offset center, double size,
      {double alpha = 1.0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: Colors.white.withValues(alpha: alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// A row of chevrons sliding from left→right along a horizontal span — the
  /// universal "this flows / swipe this way" read. Used for water channels and
  /// the directive's swipe cue.
  void _flowChevrons(Canvas canvas, double x0, double x1, double y,
      double scrollPx, Color color, double alpha,
      {double sz = 7, double gap = 22, double stroke = 2.6}) {
    if (alpha <= 0 || x1 <= x0) return;
    final off = scrollPx % gap;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
    for (double x = x0 - gap + off; x < x1 + gap; x += gap) {
      final cx = x.clamp(x0, x1);
      if (cx <= x0 || cx >= x1) continue;
      canvas.drawPath(
        Path()
          ..moveTo(cx - sz, y - sz * 0.72)
          ..lineTo(cx, y)
          ..lineTo(cx - sz, y + sz * 0.72),
        paint,
      );
    }
  }

  // ---- sky ------------------------------------------------------------------

  void _drawSky(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, groundY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, groundY),
          [_kSkyTop, _kSkyMid, _kSkyHorizon],
          [0.0, 0.62, 1.0],
        ),
    );

    // Warm low sun + bloom.
    final sunX = size.width * 0.82;
    final sunY = groundY * 0.20;
    final bloomR = (groundY * 0.95).clamp(8.0, size.height);
    canvas.drawCircle(
      Offset(sunX, sunY),
      bloomR,
      Paint()
        ..shader = RadialGradient(colors: [
          Potatuhs.gold.withValues(alpha: 0.18),
          Potatuhs.orange.withValues(alpha: 0.05),
          const Color(0x00000000),
        ], stops: const [
          0.0,
          0.45,
          1.0,
        ]).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: bloomR)),
    );
    GameFx.orb(canvas, Offset(sunX, sunY), 12, Potatuhs.gold,
        glow: 0.6, specular: true);

    // Drifting motes / pollen.
    final mote = Paint();
    for (int i = 0; i < 14; i++) {
      final seed = i * 1.618;
      final x = (size.width * ((seed * 0.513) % 1.0) + elapsed * (3 + i % 4)) %
          size.width;
      final y = groundY * ((seed * 0.271) % 0.85);
      final tw = 0.15 + 0.2 * (0.5 + 0.5 * sin(elapsed * 0.8 + seed));
      mote.color = Potatuhs.gold.withValues(alpha: tw * 0.18);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.3, mote);
    }

    // Rolling hills for depth.
    final hill = Path()..moveTo(0, groundY);
    final hillTop = groundY - (groundY * 0.12).clamp(6.0, 44.0);
    for (double x = 0; x <= size.width; x += size.width / 6) {
      hill.lineTo(x, hillTop + sin(x * 0.012) * 7);
    }
    hill.lineTo(size.width, groundY);
    hill.close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF12200F).withValues(alpha: 0.6));
  }

  // ---- soil -----------------------------------------------------------------

  void _drawSoil(Canvas canvas, Size size) {
    final soilH = size.height - groundY;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, soilH),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, groundY),
          Offset(0, size.height),
          [_kSoilTop, _kSoilBot],
        ),
    );
    // Horizontal strata bands.
    for (int b = 1; b <= 3; b++) {
      final y = groundY + soilH * (b / 4.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = 2,
      );
    }
    // Pebbles.
    final peb = Paint();
    for (int i = 0; i < 26; i++) {
      final seed = i * 2.37;
      final mx = size.width * ((seed * 0.618) % 1.0);
      final my = groundY + soilH * ((seed * 0.314) % 0.95);
      final dark = i.isEven;
      peb.color = (dark ? Colors.black : _kSoilRidge)
          .withValues(alpha: dark ? 0.10 : 0.16);
      canvas.drawCircle(Offset(mx, my), 1.4 + (i % 4) * 0.5, peb);
    }
  }

  void _drawGroundRidge(Canvas canvas, Size size) {
    // A textured soil lip at the surface — furrow rows + warm highlight.
    canvas.drawRect(
      Rect.fromLTWH(0, groundY - 4, size.width, 8),
      Paint()..color = _kSoilRidge.withValues(alpha: 0.55),
    );
    canvas.drawLine(
      Offset(0, groundY - 4),
      Offset(size.width, groundY - 4),
      Paint()
        ..color = Potatuhs.sienna.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
    final furrow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, groundY + 1), Offset(x + 7, groundY + 1), furrow);
    }
  }

  // ---- water channels (THE swipe affordance) --------------------------------

  void _drawChannel(Canvas canvas, Size size, int i) {
    final ch = channels[i];
    final cy = channelYs[i];
    final flow = ch.flow;
    final low = flow < 0.30 && !irrigActive;

    // Trough — a recessed soil capsule.
    final trough = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(size.width / 2, cy),
          width: size.width - 8,
          height: _kChannelH),
      const Radius.circular(_kChannelH / 2),
    );
    canvas.drawRRect(trough, Paint()..color = _kTrough);
    canvas.drawRRect(
      trough,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withValues(alpha: 0.4),
    );

    // Water body — coverage by flow (the "level"). Brighter & wider with flow.
    final innerL = 6.0;
    final innerR = size.width - 6.0;
    final span = innerR - innerL;
    final coverage = innerL + span * (0.12 + 0.88 * flow);
    final waterRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(innerL, cy - _kChannelH / 2 + 3, coverage,
          cy + _kChannelH / 2 - 3),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      waterRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cy - _kChannelH / 2),
          Offset(0, cy + _kChannelH / 2),
          [
            Color.lerp(_kWaterDeep, _kWater, 0.7)!.withValues(alpha: 0.35 + 0.5 * flow),
            _kWaterDeep.withValues(alpha: 0.30 + 0.45 * flow),
          ],
        ),
    );

    // Flowing chevrons — the unmistakable "water is moving →" read. Density and
    // brightness scale with flow; they slide along at ch.phase.
    _flowChevrons(canvas, innerL + 4, coverage - 4, cy, ch.phase,
        Colors.white, (0.25 + 0.6 * flow).clamp(0.0, 0.85),
        sz: 6, gap: 20, stroke: 2.4);

    // Direction arrowheads pinned at both ends so the channel always reads as
    // a left→right current even at rest.
    final endA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _kWater.withValues(alpha: 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(innerR - 9, cy - 4)
        ..lineTo(innerR - 3, cy)
        ..lineTo(innerR - 9, cy + 4),
      endA,
    );

    // Draggable "current handle" — a paddle bead you push sideways. Bobs gently;
    // clearly a grab-and-drag control, not a tap dot.
    final hx = innerL + span * ch.handle;
    final bob = sin(elapsed * 3 + ch.handleSeed) * 2.0;
    final hy = cy + bob;
    final handleColor = low ? _kDanger : _kWater;
    // grip body
    final grip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(hx, hy), width: 16, height: _kChannelH + 6),
      const Radius.circular(7),
    );
    canvas.drawRRect(grip,
        Paint()..color = Color.lerp(handleColor, Colors.white, 0.15)!.withValues(alpha: 0.92));
    canvas.drawRRect(
        grip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: 0.7));
    // grip ribs
    for (int r = -1; r <= 1; r++) {
      canvas.drawLine(
        Offset(hx + r * 3.5, hy - 5),
        Offset(hx + r * 3.5, hy + 5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.30)
          ..strokeWidth = 1.4,
      );
    }
    // side "‹ ›" drag arrows on the handle
    final dragA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: low ? 0.95 : 0.6);
    final ax = 13.0 + (low ? 2.0 + 1.5 * sin(elapsed * 9) : 0.0);
    canvas.drawPath(
      Path()
        ..moveTo(hx - ax + 4, hy - 4)
        ..lineTo(hx - ax, hy)
        ..lineTo(hx - ax + 4, hy + 4),
      dragA,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hx + ax - 4, hy - 4)
        ..lineTo(hx + ax, hy)
        ..lineTo(hx + ax - 4, hy + 4),
      dragA,
    );

    // Low-flow teaching: a ghost hand demonstrating the swipe + a label.
    if (low) {
      final cycle = (elapsed * 0.8) % 1.0;
      final ghx = innerL + span * (0.22 + 0.56 * cycle);
      canvas.drawCircle(
          Offset(ghx, cy), 9, Paint()..color = Colors.white.withValues(alpha: 0.5));
      _flowChevrons(canvas, innerL + 6, innerR - 6, cy, elapsed * 90,
          _kDanger, 0.4 + 0.3 * sin(elapsed * 8),
          sz: 7, gap: 26, stroke: 2.6);
    }
  }

  // ---- underground tubers ---------------------------------------------------

  void _drawUndergroundTubers(Canvas canvas, Size size) {
    final soilH = size.height - groundY;
    for (final p in potatoes) {
      final px = p.x * size.width;
      final py = groundY + soilH * 0.22;
      final r = 4.0 + p.growth * 10;
      final col = Color.lerp(_kPotatoDark, _kPotatoGold, p.growth)!;
      // root threads to the nearest channel
      canvas.drawLine(
        Offset(px, py + r),
        Offset(px, py + r + 14),
        Paint()
          ..color = _kLeafDark.withValues(alpha: 0.35)
          ..strokeWidth = 1.2,
      );
      PotatoArt.paint(
        canvas,
        center: Offset(px, py),
        rx: r * 1.05,
        ry: r * 0.82,
        seed: p.sway,
        color: col,
        glow: p.ripe ? 0.6 : p.growth * 0.4,
        eyes: p.growth > 0.4,
        eyeColor: const Color(0xFF5A3A12).withValues(alpha: 0.55),
      );
    }
  }

  // ---- potato plants (above ground, readable ripeness) ----------------------

  void _drawPlant(Canvas canvas, Size size, int idx) {
    final p = potatoes[idx];
    final px = p.x * size.width;
    final g = p.growth.clamp(0.0, 1.0);
    final stalkH = stalkHeights[idx];
    final sway = sin(elapsed * 1.4 + p.sway) * (2.5 + g * 2);
    final baseX = px;
    final topX = px + sway;
    final topY = groundY - stalkH;

    // little soil mound at the base
    canvas.drawOval(
      Rect.fromCenter(center: Offset(baseX, groundY - 1), width: 18 + g * 8, height: 7),
      Paint()..color = _kSoilRidge.withValues(alpha: 0.5),
    );

    // main stem (greens as it matures)
    final stemColor = Color.lerp(const Color(0xFF6E4A2A), _kLeaf, g)!;
    canvas.drawLine(
      Offset(baseX, groundY),
      Offset(topX, topY + 6),
      Paint()
        ..color = stemColor
        ..strokeWidth = 2.6 + g * 1.4
        ..strokeCap = StrokeCap.round,
    );

    // leaves — count grows with maturity, fan out around the stem
    final leaves = (2 + (g * 5)).round();
    for (int i = 0; i < leaves; i++) {
      final f = (i + 1) / (leaves + 1);
      final ly = groundY - stalkH * f;
      final side = i.isEven ? 1.0 : -1.0;
      final lx = px + sway * f;
      final leafLen = (8 + g * 9) * (0.7 + 0.4 * f);
      final c = Color.lerp(_kLeafDark, _kLeaf, (g * 0.6 + f * 0.4).clamp(0.0, 1.0))!;
      final tipX = lx + side * leafLen;
      final tipY = ly - leafLen * 0.5;
      final path = Path()
        ..moveTo(lx, ly)
        ..quadraticBezierTo(lx + side * leafLen * 0.5, ly - leafLen * 0.1, tipX, tipY)
        ..quadraticBezierTo(
            lx + side * leafLen * 0.45, ly - leafLen * 0.05, lx, ly + 1.5);
      canvas.drawPath(path, Paint()..color = c);
      canvas.drawLine(Offset(lx, ly), Offset(tipX, tipY),
          Paint()..color = c.withValues(alpha: 0.5)..strokeWidth = 0.8);
    }

    // flowering near ripeness (potato blossoms)
    if (g > 0.75 && !p.ripe) {
      final bloom = ((g - 0.75) / 0.25).clamp(0.0, 1.0);
      for (int b = 0; b < 3; b++) {
        final a = b * 2.1 + elapsed * 0.5;
        final fx = topX + cos(a) * 7;
        final fy = topY + 4 + sin(a) * 4;
        canvas.drawCircle(Offset(fx, fy), 2.4 * bloom,
            Paint()..color = const Color(0xFFE6D6F2).withValues(alpha: 0.85 * bloom));
        canvas.drawCircle(Offset(fx, fy), 0.9 * bloom,
            Paint()..color = Potatuhs.gold.withValues(alpha: bloom));
      }
    }

    // growth ring above the plant — shows progress to ripe at a glance
    if (!p.ripe) {
      final ringC = Offset(topX, topY - 8);
      const rr = 7.0;
      canvas.drawArc(Rect.fromCircle(center: ringC, radius: rr), -pi / 2, 2 * pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withValues(alpha: 0.14));
      canvas.drawArc(Rect.fromCircle(center: ringC, radius: rr), -pi / 2,
          2 * pi * g, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = (g < 0.5
                    ? const Color(0xFFFFB300)
                    : Color.lerp(const Color(0xFFFFEE58), _kLeaf, g))!
                .withValues(alpha: 0.85));
    }

    // RIPE: a glowing golden tuber pops up at the tip — pulsing, tappable.
    if (p.ripe) {
      final pulse = 0.5 + 0.5 * sin(elapsed * 7 + p.sway);
      final tipX = topX;
      final tipY = topY;
      // pop offset so it "lifts" out of the foliage
      final lift = 3 + pulse * 3;
      final tc = Offset(tipX, tipY - lift);
      // glow
      canvas.drawCircle(tc, 16 + pulse * 5,
          Paint()
            ..color = _kHarvestReady.withValues(alpha: 0.22 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      // tap ring (affordance: this is a TAP target)
      canvas.drawCircle(tc, 15 + pulse * 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = _kHarvestReady.withValues(alpha: 0.55 + 0.35 * pulse));
      // tuber body — a lumpy golden potato (wider than tall, irregular outline)
      PotatoArt.paint(
        canvas,
        center: tc,
        rx: 12.0,
        ry: 9.0,
        seed: p.sway,
        color: _kPotatoGold,
      );
    }
  }

  // ---- bugs (swipe affordance: motion smear) --------------------------------

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
            Paint()..color = _kBugColor.withValues(alpha: (1 - t).clamp(0.0, 1.0) * 0.8),
          );
        }
        continue;
      }
      final wobble = sin(elapsed * 18 + bug.x * 0.03) * 1.5;
      final bodyColor = bug.tier == 2
          ? const Color(0xFF7E8C94)
          : bug.tier == 1
              ? const Color(0xFFFF9800)
              : _kBugColor;
      final bodyW = 14.0 + bug.tier * 3.0;
      final bodyH = 10.0 + bug.tier * 2.0;

      // directional motion smear — signals "swipe me"
      final dir = bug.dx.sign;
      for (int s = 1; s <= 2; s++) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(bug.x - dir * s * 5, bug.y + wobble),
              width: bodyW - s * 2,
              height: bodyH - s * 1.5),
          Paint()..color = bodyColor.withValues(alpha: 0.12 / s),
        );
      }

      // body
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
              center: Offset(bug.x, bug.y + wobble), width: bodyW, height: bodyH)),
      );
      // legs
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
      // eyes
      canvas.drawCircle(Offset(bug.x - 3, bug.y - 2 + wobble), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));
      canvas.drawCircle(Offset(bug.x + 3, bug.y - 2 + wobble), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));
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

  // ---- weeds (tap affordance: pulsing ring) ---------------------------------

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
            Paint()..color = _kWeedColor.withValues(alpha: (1 - t) * 0.8),
          );
        }
        continue;
      }
      final lifeFrac = (w.age / _kWeedLifeMax).clamp(0.0, 1.0);
      final sway = sin(elapsed * 2.1 + w.seed) * 2.5;
      final pulse = 0.5 + 0.5 * sin(elapsed * 5 + w.seed);

      // tap ring (dashed) — clearly says "tap me"
      final ringCol = lifeFrac > 0.6
          ? Color.lerp(_kWeedColor, _kDanger, (lifeFrac - 0.6) / 0.4)!
          : _kWeedColor;
      _dashedRing(canvas, Offset(w.x, w.y - 6), 18 + pulse * 2, ringCol,
          0.4 + 0.4 * pulse);

      // spiky weed
      canvas.drawLine(
        Offset(w.x + sway * 0.3, w.y + 10),
        Offset(w.x + sway, w.y - 22),
        Paint()
          ..color = _kWeedColor.withValues(alpha: 0.85)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      for (int j = -1; j <= 1; j += 2) {
        for (int k = 1; k <= 2; k++) {
          canvas.drawLine(
            Offset(w.x + sway * 0.5, w.y - 4 - k * 6),
            Offset(w.x + j * (8 + k * 3) + sway, w.y - 10 - k * 7),
            Paint()
              ..color = Color.lerp(_kWeedColor, _kLeafDark, 0.2)!.withValues(alpha: 0.8)
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  void _dashedRing(Canvas canvas, Offset c, double r, Color color, double alpha) {
    const segs = 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
    final rot = elapsed * 1.2;
    for (int i = 0; i < segs; i++) {
      if (i.isOdd) continue;
      final a0 = rot + i / segs * 2 * pi;
      final a1 = a0 + (2 * pi / segs) * 0.6;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, a1 - a0, false, paint);
    }
  }

  // ---- cash tokens ----------------------------------------------------------

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
      final pulse = 0.5 + 0.5 * sin(elapsed * 5 + tok.x);
      // tap ring
      _dashedRing(canvas, Offset(tok.x, tok.y), _kTokenRadius + 3 + pulse * 2,
          _kTokenColor, 0.5 * (1 - expireFrac * 0.5));
      // gold coin
      GameFx.orb(canvas, Offset(tok.x, tok.y), _kTokenRadius * 0.8, _kTokenColor,
          glow: 0.7 * (1 - expireFrac * 0.5));
      _glyph(canvas, '\$', Offset(tok.x, tok.y), 15);
    }
  }

  // ---- water bursts (swipe affordance) --------------------------------------

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
      GameFx.orb(canvas, Offset(wb.x, wb.y), 15, _kWaterBurst, glow: 0.9 * pulse);
      // radiating swipe chevrons left + right
      _flowChevrons(canvas, wb.x + 14, wb.x + 40, wb.y, elapsed * 120,
          Colors.white, 0.6 * pulse, sz: 6, gap: 12, stroke: 2.2);
      canvas.save();
      canvas.translate(wb.x * 2, 0);
      canvas.scale(-1, 1);
      _flowChevrons(canvas, wb.x + 14, wb.x + 40, wb.y, elapsed * 120,
          Colors.white, 0.6 * pulse, sz: 6, gap: 12, stroke: 2.2);
      canvas.restore();
    }
  }

  // ---- wind sweep -----------------------------------------------------------

  void _drawWind(Canvas canvas, Size size) {
    final gx = windSweep * size.width;
    final bandW = size.width * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(gx - bandW, 0, bandW, groundY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(gx - bandW, 0),
          Offset(gx, 0),
          [_kWaterBurst.withValues(alpha: 0.0), _kWaterBurst.withValues(alpha: 0.22)],
        ),
    );
    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final y = groundY * (0.15 + 0.7 * (i / 5));
      final x = gx - (i % 3) * 18.0;
      canvas.drawLine(Offset(x - 22, y), Offset(x, y), streak);
    }
  }

  // ---- affordance-aware target cue ------------------------------------------
  // SWIPE targets → directional arrows/track. TAP targets → pulsing ring.
  // This makes the directive REINFORCE the affordances instead of always
  // drawing a click-style bullseye (the old water-channel complaint).

  void _drawTargetCue(Canvas canvas, Size size) {
    final d = directive;
    if (d == null || d.target == null || d.targetRadius == null) return;
    final c = d.target!;
    if (!c.dx.isFinite || !c.dy.isFinite) return;
    final swipe = _isSwipeAction(d.kind);
    final alpha = (0.4 + 0.5 * d.urgency).clamp(0.0, 0.95);

    if (swipe) {
      // A horizontal swipe track centered on the target — big sliding arrows.
      final half = (d.targetRadius! + 26).clamp(30.0, size.width * 0.35);
      final x0 = (c.dx - half).clamp(6.0, size.width - 12);
      final x1 = (c.dx + half).clamp(12.0, size.width - 6);
      // track glow line
      canvas.drawLine(
        Offset(x0, c.dy),
        Offset(x1, c.dy),
        Paint()
          ..color = d.color.withValues(alpha: alpha * 0.25)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
      _flowChevrons(canvas, x0, x1, c.dy, elapsed * 150, d.color, alpha,
          sz: 9, gap: 18, stroke: 3.0);
    } else {
      // TAP cue — a pulsing focus ring + down chevron.
      final pulse = 0.5 + 0.5 * sin(elapsed * (6 + 6 * d.urgency));
      final ringR = d.targetRadius! + 6 + pulse * (4 + 6 * d.urgency);
      canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 + 1.5 * d.urgency
          ..color = d.color.withValues(alpha: alpha),
      );
      final cd = d.countdown;
      if (cd != null && cd.isFinite) {
        final frac = cd.clamp(0.0, 1.0);
        final rect = Rect.fromCircle(center: c, radius: ringR + 6);
        canvas.drawArc(rect, -pi / 2, 2 * pi, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = Colors.white.withValues(alpha: 0.10));
        canvas.drawArc(rect, -pi / 2, 2 * pi * frac, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round
              ..color = Color.lerp(_kDanger, d.color, frac)!.withValues(alpha: 0.9));
      }
      final chevY = c.dy - ringR - 12;
      if (chevY > 4) {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 7, chevY - 5)
            ..lineTo(c.dx, chevY + 3)
            ..lineTo(c.dx + 7, chevY - 5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = d.color.withValues(alpha: (0.6 + 0.35 * pulse) * alpha),
        );
      }
    }
  }

  // ---- popups ---------------------------------------------------------------

  void _drawPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = (1 - p.age / _kPopupLifetime).clamp(0.0, 1.0);
      final sz = (14.0 * p.scale).clamp(10.0, 22.0);
      GameFx.text(canvas, p.text, Offset(p.x, p.y), sz,
          p.color.withValues(alpha: alpha),
          glow: 0.5 * alpha);
    }
  }

  // ---- vignette -------------------------------------------------------------

  void _drawVignette(Canvas canvas, Size size) {
    final r = size.longestSide * 0.75;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: const [Color(0x00000000), Color(0x00000000), Color(0x55000000)],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2), radius: r)),
    );
  }

  // ---- cash HUD -------------------------------------------------------------

  void _drawCashHud(Canvas canvas, Size size) {
    // Game-owned currency chip (host owns score/timer up top). Top-left.
    final pad = const Offset(12, 12);
    final w = 96.0;
    final h = 30.0;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad.dx, pad.dy, w, h), const Radius.circular(15));
    canvas.drawRRect(rect, Paint()..color = const Color(0xCC120D08));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Potatuhs.gold.withValues(alpha: 0.45 + 0.3 * bankPulse),
    );
    // coin
    final coinC = Offset(pad.dx + 16, pad.dy + h / 2);
    GameFx.orb(canvas, coinC, 8, Potatuhs.gold, glow: 0.4);
    _glyph(canvas, '\$', coinC, 10, alpha: 0.95);
    // amount
    GameFx.text(canvas, '$cash', Offset(pad.dx + 56, pad.dy + h / 2), 15,
        Potatuhs.textPrimary,
        weight: FontWeight.w900);
    // banking indicator
    if (bankPulse > 0.05) {
      GameFx.text(canvas, '▲', Offset(pad.dx + w - 11, pad.dy + h / 2), 9,
          _kLeaf.withValues(alpha: 0.5 + 0.5 * bankPulse));
    }
  }

  void _drawComboBadge(Canvas canvas, Size size) {
    if (combo <= 1) return;
    final a = 0.65 + 0.3 * sin(elapsed * 8);
    final center = Offset(size.width - 34, 27);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 44, height: 22),
          const Radius.circular(11)),
      Paint()..color = Potatuhs.orange.withValues(alpha: 0.22 * a),
    );
    GameFx.text(canvas, 'x$combo', center, 13,
        Potatuhs.gold.withValues(alpha: a),
        glow: 0.5 * a);
  }

  // ---- directive banner -----------------------------------------------------

  void _drawDirectiveBanner(Canvas canvas, Size size) {
    final d = directive;
    if (d == null) return;
    final cx = size.width / 2;
    final cy = (size.height * 0.085).clamp(30.0, 84.0);
    final beat = 0.5 + 0.5 * sin(elapsed * (5 + 5 * d.urgency));
    final scale = 1.0 + 0.12 * directivePop + 0.04 * beat * d.urgency;

    final tp = TextPainter(
      text: TextSpan(
        text: d.verb,
        style: TextStyle(
          fontFamily: Potatuhs.displayFont,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillHi = (size.width - 24).clamp(40.0, double.infinity);
    final pillLo = pillHi < 130.0 ? pillHi : 130.0;
    final pillW = (tp.width + 52).clamp(pillLo, pillHi);
    const pillH = 32.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final pillRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: pillW, height: pillH),
        const Radius.circular(16));
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
    canvas.drawRRect(
      pillRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 + 1.2 * d.urgency
        ..color = d.color.withValues(alpha: 0.55 + 0.4 * beat),
    );
    // leading affordance glyph: ↔ for swipe, ◎ for tap
    final isSw = _isSwipeAction(d.kind);
    GameFx.text(canvas, isSw ? '↔' : '◎', Offset(cx - pillW / 2 + 18, cy), 14,
        d.color, glow: 0.6 * beat);
    tp.paint(canvas, Offset(cx - tp.width / 2 + 10, cy - tp.height / 2));
    canvas.restore();
  }

  // ---- intro swipe guide ----------------------------------------------------

  void _drawSwipeGuide(Canvas canvas, Size size) {
    if (swipeGuideDone || swipeGuideAge < 0.3) return;
    final alpha =
        (swipeGuideAge < 1.0 ? swipeGuideAge : (3.5 - swipeGuideAge) / 2.5)
            .clamp(0.0, 1.0);
    if (alpha <= 0) return;
    final ch0Y = channelYs.isNotEmpty ? channelYs[0] : size.height * 0.65;
    final cycle = (swipeGuideAge % 1.5) / 1.5;
    final swipeX = size.width * 0.25 + cycle * size.width * 0.5;
    _flowChevrons(canvas, size.width * 0.2, size.width * 0.8, ch0Y,
        swipeGuideAge * 140, _kWater, alpha * 0.6, sz: 8, gap: 20, stroke: 2.8);
    canvas.drawCircle(Offset(swipeX, ch0Y), 10,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.85));
    GameFx.text(canvas, 'SWIPE TO MAKE WATER FLOW',
        Offset(size.width / 2, ch0Y - 24), 10,
        Colors.white.withValues(alpha: alpha * 0.8));
  }

  // ---- mid-game hint --------------------------------------------------------

  void _drawHintBanner(Canvas canvas, Size size) {
    if (activeHint == null) return;
    final hint = activeHint!;
    final t = hint.age / _kHintShowDuration;
    final fadeIn = (hint.age / 0.3).clamp(0.0, 1.0);
    final fadeOut = t > 0.6 ? (1.0 - (t - 0.6) / 0.4).clamp(0.0, 1.0) : 1.0;
    final alpha = fadeIn * fadeOut;
    if (alpha <= 0) return;

    String line1, line2;
    switch (hint.kind) {
      case _HintKind.channelSwipe:
        line1 = 'SWIPE THE UNDERGROUND CHANNELS';
        line2 = 'Drag the current sideways — keep water flowing!';
        break;
      case _HintKind.harvestTap:
        line1 = 'TAP THE GLOWING GOLD POTATO';
        line2 = 'Harvest ripe potatoes for big points!';
        break;
      case _HintKind.weedTap:
        line1 = 'TAP THE WEEDS TO YANK THEM';
        line2 = 'They damage your crop if ignored!';
        break;
    }

    const bannerH = 50.0;
    final bannerY = size.height * 0.42 - bannerH / 2;
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(16, bannerY, size.width - 32, bannerH),
        const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = _kHintBg.withValues(alpha: alpha * 0.92));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kWater.withValues(alpha: alpha * 0.4),
    );
    GameFx.text(canvas, line1, Offset(size.width / 2, bannerY + 16), 11,
        Colors.white.withValues(alpha: alpha * 0.95));
    GameFx.text(canvas, line2, Offset(size.width / 2, bannerY + 34), 9,
        Potatuhs.textSecondary.withValues(alpha: alpha * 0.7));
  }

  // ---- shop bar -------------------------------------------------------------

  void _drawShop(Canvas canvas, Size size) {
    // backing strip
    canvas.drawRect(
      Rect.fromLTWH(0, playBottom, size.width, _kShopBarH),
      Paint()..color = const Color(0xE6100B07),
    );
    canvas.drawLine(
      Offset(0, playBottom),
      Offset(size.width, playBottom),
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.25)
        ..strokeWidth = 1.4,
    );

    for (final item in shop) {
      final rect = item.rect;
      if (rect == Rect.zero) continue;
      final affordable = cash >= item.cost;
      final active = (shopTimers[item.kind] ?? 0) > 0.001;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(11));

      // body
      canvas.drawRRect(
        rr,
        Paint()
          ..color = affordable
              ? Color.lerp(const Color(0xFF1B140C), item.color, 0.16)!
              : const Color(0xFF181410),
      );
      // active fill (remaining duration) sweeps up from the bottom
      if (active) {
        final frac = (shopTimers[item.kind] ?? 0).clamp(0.0, 1.0);
        final fh = rect.height * frac;
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.bottom - fh, rect.width, fh),
          Paint()..color = item.color.withValues(alpha: 0.22),
        );
        canvas.restore();
      }
      // buy flash
      if (item.buyFlash > 0) {
        canvas.drawRRect(rr,
            Paint()..color = Colors.white.withValues(alpha: 0.5 * item.buyFlash));
      }
      // border
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = affordable ? 1.8 : 1.0
          ..color = affordable
              ? item.color.withValues(
                  alpha: 0.7 + 0.3 * (active ? (0.5 + 0.5 * sin(elapsed * 6)) : 1.0))
              : Colors.white.withValues(alpha: 0.10),
      );

      final cx = rect.center.dx;
      final iconY = rect.top + rect.height * 0.34;
      _glyph(canvas, item.glyph, Offset(cx, iconY), 18,
          alpha: affordable ? 1.0 : 0.4);
      // label
      GameFx.text(canvas, item.label, Offset(cx, rect.top + rect.height * 0.66),
          9,
          (affordable ? Potatuhs.textPrimary : Potatuhs.textFaint),
          weight: FontWeight.w800);
      // cost
      GameFx.text(canvas, '\$${item.cost}',
          Offset(cx, rect.bottom - 9), 10,
          affordable ? Potatuhs.gold : Potatuhs.textFaint.withValues(alpha: 0.6),
          weight: FontWeight.w900);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmPanicPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn statically with the SAME
// components the live game uses (the channel trough + handle, the golden ripe
// tuber, a bug, a weed, a storm, a shop chip). No elapsed/ticker: fixed phases.
// ═══════════════════════════════════════════════════════════════════════════

void _fpBackdrop(Canvas canvas, Size size, double groundY) {
  final w = size.width, h = size.height;
  // sky
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, groundY),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, groundY),
        const [_kSkyTop, _kSkyMid, _kSkyHorizon],
        const [0.0, 0.6, 1.0],
      ),
  );
  // soil
  canvas.drawRect(
    Rect.fromLTWH(0, groundY, w, h - groundY),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, groundY),
        Offset(0, h),
        const [_kSoilTop, _kSoilBot],
      ),
  );
  // ground ridge line
  canvas.drawLine(Offset(0, groundY), Offset(w, groundY),
      Paint()..color = _kSoilRidge.withValues(alpha: 0.6)..strokeWidth = 2);
}

void _fpChevrons(
    Canvas canvas, double x0, double x1, double y, Color color, double alpha) {
  if (x1 <= x0 + 12) return;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
  const gap = 20.0, sz = 6.0;
  for (double x = x0 + 10; x < x1 - 4; x += gap) {
    canvas.drawPath(
      Path()
        ..moveTo(x - sz, y - sz * 0.7)
        ..lineTo(x, y)
        ..lineTo(x - sz, y + sz * 0.7),
      p,
    );
  }
}

void _fpDashedRing(
    Canvas canvas, Offset c, double r, Color color, double alpha) {
  const segs = 12;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
  for (int i = 0; i < segs; i++) {
    if (i.isOdd) continue;
    final a0 = i / segs * 2 * pi;
    final a1 = a0 + (2 * pi / segs) * 0.6;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, a1 - a0, false, paint);
  }
}

/// One irrigation channel: recessed trough, blue water body sized by [flow], a
/// draggable current handle with ‹ › side arrows (red when the field is
/// starving). Mirrors the live `_drawChannel`.
void _fpDrawChannel(
    Canvas canvas, Size size, double cy, double flow, bool low) {
  final w = size.width;
  const chH = 18.0;
  final trough = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(w / 2, cy), width: w - 16, height: chH),
    const Radius.circular(chH / 2),
  );
  canvas.drawRRect(trough, Paint()..color = _kTrough);
  canvas.drawRRect(
    trough,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.black.withValues(alpha: 0.4),
  );

  const innerL = 10.0;
  final innerR = w - 10.0;
  final span = innerR - innerL;
  final coverage = innerL + span * (0.12 + 0.88 * flow);
  final waterRect = RRect.fromRectAndRadius(
    Rect.fromLTRB(innerL, cy - chH / 2 + 3, coverage, cy + chH / 2 - 3),
    const Radius.circular(5),
  );
  canvas.drawRRect(
    waterRect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, cy - chH / 2),
        Offset(0, cy + chH / 2),
        [
          Color.lerp(_kWaterDeep, _kWater, 0.7)!
              .withValues(alpha: 0.35 + 0.5 * flow),
          _kWaterDeep.withValues(alpha: 0.30 + 0.45 * flow),
        ],
      ),
  );
  _fpChevrons(canvas, innerL + 4, coverage - 4, cy,
      low ? _kDanger : Colors.white, low ? 0.55 : 0.65);

  // draggable current handle
  final hx = innerL + span * (low ? 0.30 : 0.5);
  final handleColor = low ? _kDanger : _kWater;
  final grip = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(hx, cy), width: 16, height: chH + 6),
    const Radius.circular(7),
  );
  canvas.drawRRect(
      grip,
      Paint()
        ..color =
            Color.lerp(handleColor, Colors.white, 0.15)!.withValues(alpha: 0.92));
  canvas.drawRRect(
      grip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.7));
  for (int r = -1; r <= 1; r++) {
    canvas.drawLine(
      Offset(hx + r * 3.5, cy - 5),
      Offset(hx + r * 3.5, cy + 5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..strokeWidth = 1.4,
    );
  }
  final dragA = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Colors.white.withValues(alpha: low ? 0.95 : 0.72);
  const ax = 14.0;
  canvas.drawPath(
    Path()
      ..moveTo(hx - ax + 4, cy - 4)
      ..lineTo(hx - ax, cy)
      ..lineTo(hx - ax + 4, cy + 4),
    dragA,
  );
  canvas.drawPath(
    Path()
      ..moveTo(hx + ax - 4, cy - 4)
      ..lineTo(hx + ax, cy)
      ..lineTo(hx + ax - 4, cy + 4),
    dragA,
  );
}

/// A potato plant at maturity [g]; when [ripe] a glowing golden tuber pops out
/// of the foliage with a tap ring, else a growth ring shows progress. Condensed
/// from the live `_drawPlant`.
void _fpDrawPlant(
    Canvas canvas, double baseX, double groundY, double g, bool ripe) {
  canvas.drawOval(
    Rect.fromCenter(center: Offset(baseX, groundY - 1), width: 18 + g * 8, height: 7),
    Paint()..color = _kSoilRidge.withValues(alpha: 0.5),
  );
  final stalkH = 30 + g * 34;
  final topY = groundY - stalkH;
  final topX = baseX;
  final stemColor = Color.lerp(const Color(0xFF6E4A2A), _kLeaf, g)!;
  canvas.drawLine(
    Offset(baseX, groundY),
    Offset(topX, topY + 6),
    Paint()
      ..color = stemColor
      ..strokeWidth = 2.6 + g * 1.4
      ..strokeCap = StrokeCap.round,
  );
  final leaves = (2 + g * 5).round();
  for (int i = 0; i < leaves; i++) {
    final f = (i + 1) / (leaves + 1);
    final ly = groundY - stalkH * f;
    final side = i.isEven ? 1.0 : -1.0;
    final leafLen = (8 + g * 9) * (0.7 + 0.4 * f);
    final c = Color.lerp(_kLeafDark, _kLeaf, (g * 0.6 + f * 0.4).clamp(0.0, 1.0))!;
    final tipX = baseX + side * leafLen;
    final tipY = ly - leafLen * 0.5;
    final path = Path()
      ..moveTo(baseX, ly)
      ..quadraticBezierTo(baseX + side * leafLen * 0.5, ly - leafLen * 0.1, tipX, tipY)
      ..quadraticBezierTo(baseX + side * leafLen * 0.45, ly - leafLen * 0.05, baseX, ly + 1.5);
    canvas.drawPath(path, Paint()..color = c);
  }
  if (ripe) {
    final tc = Offset(topX, topY - 6);
    canvas.drawCircle(
        tc,
        18,
        Paint()
          ..color = _kHarvestReady.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawCircle(
        tc,
        16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = _kHarvestReady.withValues(alpha: 0.8));
    PotatoArt.paint(canvas, center: tc, rx: 12.0, ry: 9.0, seed: baseX, color: _kPotatoGold);
  } else {
    final ringC = Offset(topX, topY - 8);
    const rr = 7.0;
    canvas.drawArc(Rect.fromCircle(center: ringC, radius: rr), -pi / 2, 2 * pi, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawArc(Rect.fromCircle(center: ringC, radius: rr), -pi / 2, 2 * pi * g, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = (g < 0.5 ? const Color(0xFFFFB300) : Color.lerp(const Color(0xFFFFEE58), _kLeaf, g))!
              .withValues(alpha: 0.85));
  }
}

/// A crop-eating bug with its directional motion smear (the "swipe me" tell).
void _fpDrawBug(Canvas canvas, Offset c, double dir) {
  const bodyW = 16.0, bodyH = 11.0;
  for (int s = 1; s <= 2; s++) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - dir * s * 5, c.dy), width: bodyW - s * 2, height: bodyH - s * 1.5),
      Paint()..color = _kBugColor.withValues(alpha: 0.12 / s),
    );
  }
  canvas.drawOval(
    Rect.fromCenter(center: c, width: bodyW, height: bodyH),
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Color.lerp(_kBugColor, Colors.white, 0.35)!,
          _kBugColor,
          Color.lerp(_kBugColor, Colors.black, 0.4)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCenter(center: c, width: bodyW, height: bodyH)),
  );
  for (int leg = 0; leg < 3; leg++) {
    final lx = c.dx + (leg - 1) * 4.0;
    canvas.drawLine(Offset(lx, c.dy + 4), Offset(lx - 4 + leg * 4.0, c.dy + 10),
        Paint()..color = _kBugColor.withValues(alpha: 0.5)..strokeWidth = 1.2);
  }
  canvas.drawCircle(Offset(c.dx - 3, c.dy - 2), 2, Paint()..color = Colors.red.withValues(alpha: 0.9));
  canvas.drawCircle(Offset(c.dx + 3, c.dy - 2), 2, Paint()..color = Colors.red.withValues(alpha: 0.9));
}

/// A weed with its dashed tap-ring (the "tap me" tell).
void _fpDrawWeed(Canvas canvas, Offset base, double urgency) {
  final ringCol = urgency > 0.5 ? _kDanger : _kWeedColor;
  _fpDashedRing(canvas, Offset(base.dx, base.dy - 12), 18, ringCol, 0.7);
  canvas.drawLine(
    Offset(base.dx, base.dy + 6),
    Offset(base.dx, base.dy - 24),
    Paint()
      ..color = _kWeedColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round,
  );
  for (int j = -1; j <= 1; j += 2) {
    for (int k = 1; k <= 2; k++) {
      canvas.drawLine(
        Offset(base.dx, base.dy - 6 - k * 6),
        Offset(base.dx + j * (8 + k * 3), base.dy - 12 - k * 7),
        Paint()
          ..color = Color.lerp(_kWeedColor, _kLeafDark, 0.2)!.withValues(alpha: 0.8)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

// ── Frame 1 — the irrigation verb ────────────────────────────────────────────
void _fpLegendIrrigate(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 12 || h < 12) return;
  final groundY = h * 0.20;
  _fpBackdrop(canvas, size, groundY);
  _fpDrawChannel(canvas, size, h * 0.44, 0.92, false);
  _fpDrawChannel(canvas, size, h * 0.74, 0.20, true);
  GameFx.text(canvas, 'DRAG →', Offset(w * 0.5, h * 0.44 - 24), 11,
      _kWater, weight: FontWeight.w900);
  GameFx.text(canvas, 'STARVING', Offset(w * 0.5, h * 0.74 + 26), 10,
      _kDanger, weight: FontWeight.w900);
}

// ── Frame 2 — grow potatoes to score ─────────────────────────────────────────
void _fpLegendGrow(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 12 || h < 12) return;
  final groundY = h * 0.78;
  _fpBackdrop(canvas, size, groundY);
  _fpDrawChannel(canvas, size, h * 0.90, 0.85, false);
  _fpDrawPlant(canvas, w * 0.24, groundY, 0.30, false);
  _fpDrawPlant(canvas, w * 0.50, groundY, 0.68, false);
  _fpDrawPlant(canvas, w * 0.78, groundY, 1.0, true);
  GameFx.text(canvas, 'TAP', Offset(w * 0.78, h * 0.14), 11,
      _kHarvestReady, weight: FontWeight.w900);
}

// ── Frame 3 — the dangers ────────────────────────────────────────────────────
void _fpLegendDanger(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 12 || h < 12) return;
  final groundY = h * 0.66;
  _fpBackdrop(canvas, size, groundY);
  _fpDrawBug(canvas, Offset(w * 0.30, h * 0.30), 1.0);
  GameFx.text(canvas, 'SWIPE', Offset(w * 0.30, h * 0.30 - 22), 10,
      _kBugColor, weight: FontWeight.w900);
  _fpDrawWeed(canvas, Offset(w * 0.72, groundY - 2), 0.7);
  GameFx.text(canvas, 'TAP', Offset(w * 0.72, h * 0.24), 10,
      _kWeedColor, weight: FontWeight.w900);
  _fpDrawChannel(canvas, size, h * 0.84, 0.14, true);
  GameFx.text(canvas, 'DROUGHT', Offset(w * 0.5, h * 0.84 + 26), 10,
      _kDanger, weight: FontWeight.w900);
}

// ── Frame 4 — escalation + the relief shop ───────────────────────────────────
void _fpLegendEscalate(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 12 || h < 12) return;
  final groundY = h * 0.62;
  _fpBackdrop(canvas, size, groundY);
  // storm cloud + rain streaks — escalating weather
  final cloudC = Offset(w * 0.5, h * 0.24);
  for (final o in const [Offset(-22, 0), Offset(0, -6), Offset(22, 0), Offset(10, 4), Offset(-10, 4)]) {
    canvas.drawCircle(cloudC + o, 15, Paint()..color = const Color(0xFF3A4A55).withValues(alpha: 0.92));
  }
  for (int i = 0; i < 7; i++) {
    final rx = w * (0.28 + i * 0.072);
    canvas.drawLine(Offset(rx, h * 0.34), Offset(rx - 5, h * 0.46),
        Paint()..color = _kWater.withValues(alpha: 0.65)..strokeWidth = 2..strokeCap = StrokeCap.round);
  }
  GameFx.text(canvas, 'STORM!', Offset(w * 0.5, h * 0.055), 13,
      _kDanger, weight: FontWeight.w900);
  // a shop relief chip
  final chip = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.80), width: w * 0.44, height: h * 0.22),
    const Radius.circular(12),
  );
  canvas.drawRRect(chip, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.85));
  canvas.drawRRect(
      chip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _kWater.withValues(alpha: 0.8));
  GameFx.text(canvas, '💧', Offset(w * 0.5, h * 0.755), 18, Colors.white);
  GameFx.text(canvas, 'WATER', Offset(w * 0.5, h * 0.815), 9,
      Potatuhs.textPrimary, weight: FontWeight.w800);
  GameFx.text(canvas, '\$24', Offset(w * 0.5, h * 0.86), 10,
      Potatuhs.gold, weight: FontWeight.w900);
}

/// The visual manual for Farm Panic — wired into the registry spec.
final List<LegendFrame> farmPanicLegendFrames = [
  const LegendFrame(
      caption: 'Drag the water handles to keep every channel flowing',
      paint: _fpLegendIrrigate),
  const LegendFrame(
      caption: 'Watered crops grow — tap the ripe golden potato to harvest',
      paint: _fpLegendGrow),
  const LegendFrame(
      caption: 'Swipe bugs, tap weeds — a dry channel starves your crops',
      paint: _fpLegendDanger),
  const LegendFrame(
      caption: 'Storms & pests ramp up — spend banked cash on relief',
      paint: _fpLegendEscalate),
];
