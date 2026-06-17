import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Farm Panic — frantic two-zone 60s arcade game (potato / Hot Potato Games)
//
// CONTRACT: const FarmPanicGame() — no params, no external score callbacks.
// Self-contained in whatever Expanded slot MiniGamePage hands it, identical
// interface to the old version.
// ---------------------------------------------------------------------------

// ---- FEEL CONSTANTS (first-pass; tune these for playability) --------------

const double _kGameDuration     = 60.0;  // total seconds per run

// Underground zone — circulation / root channels
const int    _kChannelCount     = 4;     // number of root/pipe channels
const double _kFlowDecayBase    = 0.18;  // flow drains this much per second at t=0
const double _kFlowDecayScale   = 0.22;  // extra drain added linearly over 60s
const double _kSwipeFlowGain    = 0.55;  // how much a full channel-swipe adds
const double _kSwipeHitRadius   = 28.0;  // px finger-to-channel hit radius
const double _kPotatoGrowRate   = 4.0;   // score pts/s per fully-circulating channel
const double _kTokenBubbleRate  = 8.0;   // seconds between power-up token spawns (base)
const double _kTokenBubbleAccel = 0.06;  // shorten interval per second elapsed (faster late)
const double _kTokenRadius      = 18.0;  // px — tap target size for surface tokens

// Above-ground zone — bugs
const double _kBugSpawnBase     = 3.5;   // seconds between bug spawns at start
const double _kBugSpawnMin      = 0.55;  // minimum spawn interval at max escalation
const double _kBugSpeed         = 55.0;  // px/s descend speed at start
const double _kBugSpeedScale    = 1.6;   // speed multiplier at end of game
const double _kBugHitRadius     = 32.0;  // px swipe-kill radius
const double _kBugSwipeDx       = 12.0;  // min horizontal swipe delta to count as blow
const int    _kBugPoints        = 10;    // pts per bug cleared
const double _kBugDamageThresh  = 0.92;  // fractional Y at which bug damages crop
const int    _kBugDamageScore   = -5;    // score impact when bug reaches crop line

// Power-up tokens (bubbled from underground circulation)
const int    _kTokenPoints      = 25;    // pts for banking a token

// Scoring
const int    _kComboMultMax     = 4;     // max combo multiplier from chained actions

// Misc visuals
const double _kShakeDecay       = 8.0;   // shake-intensity decay per second
const double _kPopupLifetime    = 0.9;   // popup float duration in seconds

// ---- palette ---------------------------------------------------------------

const Color _kBg           = Color(0xFF0D0A06);
const Color _kSkyTop       = Color(0xFF0E1A10);
const Color _kSkyBot       = Color(0xFF1A2A1A);
const Color _kSoilTop      = Color(0xFF3B2007);
const Color _kSoilBot      = Color(0xFF5D3A1A);
const Color _kRootPipe     = Color(0xFF7B5E3A);
const Color _kRootFlow     = Color(0xFF42A5F5);
const Color _kPotatoGold   = Color(0xFFD4A056);
const Color _kPotatoDark   = Color(0xFFC08840);
const Color _kGreen        = Color(0xFF66BB6A);
const Color _kBugColor     = Color(0xFFFF5722);
const Color _kTokenColor   = Color(0xFFFFD54F);
const Color _kDanger       = Color(0xFFE53935);

// ---- data classes ----------------------------------------------------------

class _Channel {
  final double yFrac;   // normalised Y position in underground zone (0=top,1=bottom)
  double flow = 0.0;    // 0.0 - 1.0
  bool swipeActive = false;
  _Channel(this.yFrac);
}

class _Potato {
  double x;       // normalised 0-1 horizontal
  double growth;  // 0-1
  _Potato(this.x, this.growth);
}

class _Bug {
  double x;       // px
  double y;       // px  (descends toward ground line)
  bool dead = false;
  double deathAge = 0;
  double dx = 0;  // sideways drift
  _Bug({required this.x, required this.y, required this.dx});
}

class _Token {
  double x;
  double y;     // starts near ground line and rises
  bool banked = false;
  double age = 0;
  _Token({required this.x, required this.y});
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup({required this.x, required this.y, required this.text,
      required this.color}) : age = 0;
}

// ---- phase -----------------------------------------------------------------

enum _Phase { preGame, playing, gameOver }

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
  int _combo = 1; // combo multiplier 1-4

  // Underground
  final List<_Channel> _channels = [];
  final List<_Potato> _potatoes = [];
  double _tokenTimer = 0;

  // Above-ground
  final List<_Bug> _bugs = [];
  double _bugTimer = 0;
  final List<_Token> _tokens = [];

  // Popups / feedback
  final List<_Popup> _popups = [];

  // Visual
  double _shakeIntensity = 0;

  // Gesture tracking
  int? _activeChannel; // channel idx being swiped

  // Derived layout (computed once per frame when size is known)
  double get _groundY => _size.height * 0.52;
  double get _soilZoneH => _size.height - _groundY;

  // Bug speed escalation
  double _bugSpeed(double t) =>
      _kBugSpeed * (1 + (_kBugSpeedScale - 1) * (t / _kGameDuration));

  // Bug spawn interval escalation
  double _bugInterval(double t) =>
      (_kBugSpawnBase - (_kBugSpawnBase - _kBugSpawnMin) * (t / _kGameDuration))
          .clamp(_kBugSpawnMin, _kBugSpawnBase);

  // Flow decay escalation
  double _flowDecay(double t) =>
      _kFlowDecayBase + _kFlowDecayScale * (t / _kGameDuration);

  // Token spawn interval (gets faster)
  double _tokenInterval(double t) =>
      (_kTokenBubbleRate - _kTokenBubbleAccel * t).clamp(2.0, _kTokenBubbleRate);

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
    _combo = 1;
    _elapsed = 0;
    _shakeIntensity = 0;
    _activeChannel = null;
    _popups.clear();
    _bugs.clear();
    _tokens.clear();

    // Build channels evenly spaced in underground zone
    _channels.clear();
    for (int i = 0; i < _kChannelCount; i++) {
      _channels.add(_Channel(0.2 + 0.6 * i / (_kChannelCount - 1))
        ..flow = 0.3 + _rng.nextDouble() * 0.3);
    }

    // Scatter a few starting potatoes
    _potatoes.clear();
    for (int i = 0; i < 6; i++) {
      _potatoes.add(_Potato(0.1 + _rng.nextDouble() * 0.8, 0.1));
    }

    _bugTimer = _kBugSpawnBase * 0.5; // first bug comes quickly
    _tokenTimer = _kTokenBubbleRate * 0.4;

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
      _updateChannels(dt);
      _updatePotatoes(dt);
      _updateBugs(dt);
      _updateTokens(dt);
      _updatePopups(dt);
      _spawnBugs(dt);
      _spawnTokens(dt);
    });
  }

  void _updateShake(double dt) {
    if (_shakeIntensity > 0) {
      _shakeIntensity *= (1 - dt * _kShakeDecay);
      if (_shakeIntensity < 0.2) _shakeIntensity = 0;
    }
  }

  void _updateChannels(double dt) {
    final decay = _flowDecay(_elapsed);
    for (final ch in _channels) {
      ch.flow = (ch.flow - decay * dt).clamp(0.0, 1.0);
    }
  }

  void _updatePotatoes(double dt) {
    // Each channel with high flow grows all potatoes slightly
    double totalFlow = 0;
    for (final ch in _channels) {
      totalFlow += ch.flow;
    }
    final avgFlow = totalFlow / _channels.length;

    if (avgFlow > 0.3) {
      final growBonus = avgFlow * _kPotatoGrowRate * dt;
      // Points for sustained circulation (potato growth)
      final pts = (growBonus * _potatoes.length * _combo).round();
      if (pts > 0) _score += pts;

      for (final p in _potatoes) {
        p.growth = (p.growth + growBonus * 0.05).clamp(0.0, 1.0);
        if (p.growth >= 1.0) {
          // Harvest! Spawn new potato and award big bonus
          p.growth = 0.1;
          p.x = 0.05 + _rng.nextDouble() * 0.9;
          final harvestPts = 50 * _combo;
          _score += harvestPts;
          _spawnPopup(
            p.x * _size.width,
            _groundY + _size.height * 0.3,
            '+$harvestPts HARVEST!',
            _kPotatoGold,
          );
          _advanceCombo();
        }
      }
    } else if (avgFlow < 0.15) {
      // Flow too low — growth stalls, existing potatoes shrink slightly
      for (final p in _potatoes) {
        p.growth = (p.growth - 0.005 * dt).clamp(0.0, 1.0);
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
        if (bug.deathAge > 0.4) _bugs.removeAt(i);
        continue;
      }
      bug.y += speed * dt;
      bug.x += bug.dx * dt;
      // Keep in bounds horizontally
      if (bug.x < 0) bug.dx = bug.dx.abs();
      if (bug.x > _size.width) bug.dx = -bug.dx.abs();

      if (bug.y >= groundLine * _kBugDamageThresh) {
        // Bug reached the crop — damage
        bug.dead = true;
        _score = max(0, _score + _kBugDamageScore);
        _combo = 1;
        _shakeIntensity = 5;
        _spawnPopup(
          bug.x,
          groundLine - 20,
          '$_kBugDamageScore',
          _kDanger,
        );
      }
    }
  }

  void _updateTokens(double dt) {
    for (int i = _tokens.length - 1; i >= 0; i--) {
      final tok = _tokens[i];
      if (tok.banked) {
        tok.age += dt;
        if (tok.age > 0.4) _tokens.removeAt(i);
        continue;
      }
      tok.age += dt;
      // Tokens rise upward from just below ground line
      tok.y -= 30.0 * dt;
      // Auto-expire if not tapped in time
      if (tok.age > 4.0) _tokens.removeAt(i);
    }
  }

  void _updatePopups(double dt) {
    for (int i = _popups.length - 1; i >= 0; i--) {
      _popups[i].age += dt;
      _popups[i].y -= 35 * dt;
      if (_popups[i].age > _kPopupLifetime) _popups.removeAt(i);
    }
  }

  void _spawnBugs(double dt) {
    _bugTimer -= dt;
    if (_bugTimer <= 0) {
      _bugTimer = _bugInterval(_elapsed) + _rng.nextDouble() * 0.5;
      _bugs.add(_Bug(
        x: 20 + _rng.nextDouble() * (_size.width - 40),
        y: -10,
        dx: (_rng.nextDouble() - 0.5) * 40,
      ));
    }
  }

  void _spawnTokens(double dt) {
    _tokenTimer -= dt;
    if (_tokenTimer <= 0) {
      _tokenTimer = _tokenInterval(_elapsed) + _rng.nextDouble() * 1.0;
      // Token appears near ground line (bubbled up from underground)
      _tokens.add(_Token(
        x: 30 + _rng.nextDouble() * (_size.width - 60),
        y: _groundY - 10,
      ));
    }
  }

  // ---- scoring helpers ------------------------------------------------------

  void _advanceCombo() {
    _combo = (_combo + 1).clamp(1, _kComboMultMax);
  }

  void _spawnPopup(double x, double y, String text, Color color) {
    _popups.add(_Popup(x: x, y: y, text: text, color: color));
  }

  // ---- gesture handling -----------------------------------------------------

  // Underground: swipe along channel → fills flow
  // Above-ground: horizontal swipe near bug → kills it; tap token → banks it

  void _onPointerDown(Offset pos) {
    if (_phase == _Phase.preGame || _phase == _Phase.gameOver) {
      _startGame();
      return;
    }
    if (_phase != _Phase.playing) return;

    // Check token taps (above-ground zone)
    if (pos.dy < _groundY) {
      _tryBankToken(pos);
    }

    // Check which underground channel finger is on
    if (pos.dy >= _groundY) {
      _activeChannel = _nearestChannel(pos);
    }
  }

  void _onPointerMove(Offset pos, Offset delta) {
    if (_phase != _Phase.playing) return;

    // Underground: if dragging in soil zone along a channel, add flow
    if (pos.dy >= _groundY && _activeChannel != null) {
      final ch = _channels[_activeChannel!];
      final chY = _channelY(_activeChannel!);
      if ((pos.dy - chY).abs() < _kSwipeHitRadius) {
        // Flow gain proportional to swipe speed
        final speed = delta.distance;
        ch.flow = (ch.flow + _kSwipeFlowGain * speed / 200.0).clamp(0.0, 1.0);
      }
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
      if (sqrt(dx * dx + dy * dy) < _kTokenRadius * 2) {
        tok.banked = true;
        final pts = _kTokenPoints * _combo;
        _score += pts;
        _spawnPopup(tok.x, tok.y, '+$pts', _kTokenColor);
        _advanceCombo();
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
        bug.dead = true;
        final pts = _kBugPoints * _combo;
        _score += pts;
        _spawnPopup(bug.x, bug.y, '+$pts', _kGreen);
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
              channels: _channels,
              potatoes: _potatoes,
              bugs: _bugs,
              tokens: _tokens,
              popups: _popups,
              shakeIntensity: _shakeIntensity,
              groundY: _groundY,
              channelYs: List.generate(
                  _channels.length, (i) => _channelY(i)),
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
  final double elapsed, gameTime, shakeIntensity, groundY;
  final int score, combo;
  final List<_Channel> channels;
  final List<_Potato> potatoes;
  final List<_Bug> bugs;
  final List<_Token> tokens;
  final List<_Popup> popups;
  final List<double> channelYs;

  _FarmPanicPainter({
    required this.phase,
    required this.elapsed,
    required this.gameTime,
    required this.score,
    required this.combo,
    required this.channels,
    required this.potatoes,
    required this.bugs,
    required this.tokens,
    required this.popups,
    required this.shakeIntensity,
    required this.groundY,
    required this.channelYs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    if (phase == _Phase.preGame) {
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
    _drawTokens(canvas, size);
    _drawPopups(canvas, size);
    _drawHUD(canvas, size);

    if (shakeIntensity > 0) canvas.restore();

    if (phase == _Phase.gameOver) {
      _drawGameOver(canvas, size);
    }
  }

  // ---- above-ground zone ----------------------------------------------------

  void _drawAboveGround(Canvas canvas, Size size) {
    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, groundY),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, groundY),
          [_kSkyTop, _kSkyBot],
        ),
    );

    // Animated sun / moon glow
    final sunX = size.width * 0.82;
    final sunY = groundY * 0.15;
    canvas.drawCircle(
      Offset(sunX, sunY),
      18,
      Paint()..color = _kPotatoGold.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      10,
      Paint()..color = _kPotatoGold.withValues(alpha: 0.5),
    );

    // Stalks/leaves above ground (one per potato, at same X)
    for (final p in potatoes) {
      final px = p.x * size.width;
      final stalkH = 20 + p.growth * 45;
      final sway = sin(elapsed * 1.4 + p.x * 8) * 3;

      // Stalk
      canvas.drawLine(
        Offset(px + sway * 0.3, groundY),
        Offset(px + sway, groundY - stalkH),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF5D4037),
            _kGreen,
            p.growth.clamp(0.0, 1.0),
          )!
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // Leaves
      if (p.growth > 0.2) {
        canvas.drawLine(
          Offset(px + sway * 0.6, groundY - stalkH * 0.55),
          Offset(px - 7 + sway, groundY - stalkH * 0.75),
          Paint()
            ..color = _kGreen.withValues(alpha: p.growth.clamp(0.2, 0.8))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
      if (p.growth > 0.5) {
        canvas.drawLine(
          Offset(px + sway * 0.4, groundY - stalkH * 0.35),
          Offset(px + 7 + sway * 0.5, groundY - stalkH * 0.5),
          Paint()
            ..color = _kGreen.withValues(alpha: p.growth.clamp(0.2, 0.8))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // "ABOVE GROUND" label when game starts (fades after 3s)
    if (elapsed < 3.0) {
      final alpha = (1.0 - elapsed / 3.0).clamp(0.0, 1.0);
      _drawText(canvas, 'SWIPE BUGS • TAP TOKENS', 11,
          Colors.white.withValues(alpha: alpha * 0.35),
          Offset(size.width / 2, groundY * 0.88));
    }
  }

  // ---- ground line ----------------------------------------------------------

  void _drawGroundLine(Canvas canvas, Size size) {
    // Animated horizon glow
    final glowAlpha = 0.2 + 0.08 * sin(elapsed * 2.5);
    final glowPaint = Paint()
      ..color = _kRootFlow.withValues(alpha: glowAlpha)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), glowPaint);
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
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

    // Draw each root/pipe channel
    for (int i = 0; i < channels.length; i++) {
      final ch = channels[i];
      final cy = channelYs[i];

      // Channel track (dim pipe)
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = _kRootPipe.withValues(alpha: 0.22)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // Flow fill (animated moving dots)
      if (ch.flow > 0.05) {
        final flowAlpha = ch.flow * 0.8;
        // Animated dashes
        final dashOffset = (elapsed * 60) % 20.0;
        for (double x = -20 + dashOffset; x < size.width; x += 20) {
          final xStart = x.clamp(0.0, size.width);
          final xEnd = (x + 10).clamp(0.0, size.width);
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

      // Flow meter indicator at left edge
      const mW = 6.0;
      const mH = 24.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(2, cy - mH / 2, mW, mH), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.06),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                2, cy - mH / 2 + mH * (1 - ch.flow), mW, mH * ch.flow),
            const Radius.circular(3)),
        Paint()
          ..color = (ch.flow > 0.4 ? _kRootFlow : _kDanger)
              .withValues(alpha: 0.7),
      );

      // Low-flow warning pulse
      if (ch.flow < 0.2) {
        final pulse = 0.3 + 0.2 * sin(elapsed * 12 + i);
        canvas.drawLine(
          Offset(0, cy),
          Offset(size.width, cy),
          Paint()
            ..color = _kDanger.withValues(alpha: pulse * 0.25)
            ..strokeWidth = 4,
        );
      }
    }

    // Underground potatoes
    for (final p in potatoes) {
      final px = p.x * size.width;
      final py = groundY + (size.height - groundY) * 0.28;
      final r = 6.0 + p.growth * 10;
      // Glow
      if (p.growth > 0.4) {
        canvas.drawCircle(
          Offset(px, py),
          r + 4,
          Paint()
            ..color = _kPotatoGold.withValues(alpha: p.growth * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: r * 1.6, height: r),
        Paint()..color = _kPotatoGold.withValues(alpha: 0.4 + p.growth * 0.5),
      );
      // Spud eye
      canvas.drawCircle(
        Offset(px - r * 0.25, py - 1),
        r * 0.15,
        Paint()..color = _kPotatoDark.withValues(alpha: 0.5),
      );
    }

    // "UNDERGROUND" hint
    if (elapsed < 3.0) {
      final alpha = (1.0 - elapsed / 3.0).clamp(0.0, 1.0);
      _drawText(canvas, 'SWIPE CHANNELS TO CIRCULATE', 10,
          Colors.white.withValues(alpha: alpha * 0.35),
          Offset(size.width / 2, groundY + (size.height - groundY) * 0.1));
    }
  }

  // ---- bugs -----------------------------------------------------------------

  void _drawBugs(Canvas canvas, Size size) {
    for (final bug in bugs) {
      if (bug.dead) {
        // Death burst
        final t = bug.deathAge / 0.4;
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3 + elapsed;
          final r = t * 18;
          canvas.drawCircle(
            Offset(bug.x + cos(a) * r, bug.y + sin(a) * r),
            2.5 * (1 - t),
            Paint()..color = _kBugColor.withValues(alpha: (1 - t) * 0.8),
          );
        }
        continue;
      }
      // Body
      final wobble = sin(elapsed * 18 + bug.x * 0.03) * 1.5;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bug.x, bug.y + wobble), width: 14, height: 10),
        Paint()..color = _kBugColor.withValues(alpha: 0.85),
      );
      // Legs
      for (int leg = 0; leg < 3; leg++) {
        final lx = bug.x + (leg - 1) * 4.0;
        canvas.drawLine(
          Offset(lx, bug.y + 4 + wobble),
          Offset(lx - 4 + leg * 4.0, bug.y + 10 + wobble),
          Paint()
            ..color = _kBugColor.withValues(alpha: 0.5)
            ..strokeWidth = 1,
        );
      }
      // Eyes
      canvas.drawCircle(
          Offset(bug.x - 3, bug.y - 2 + wobble), 2, Paint()..color = Colors.red);
      canvas.drawCircle(
          Offset(bug.x + 3, bug.y - 2 + wobble), 2, Paint()..color = Colors.red);
    }
  }

  // ---- tokens ---------------------------------------------------------------

  void _drawTokens(Canvas canvas, Size size) {
    for (final tok in tokens) {
      if (tok.banked) {
        // Bank burst
        final t = tok.age / 0.4;
        for (int i = 0; i < 8; i++) {
          final a = i * pi / 4;
          final r = t * 22;
          canvas.drawCircle(
            Offset(tok.x + cos(a) * r, tok.y + sin(a) * r),
            2.5 * (1 - t),
            Paint()..color = _kTokenColor.withValues(alpha: (1 - t) * 0.9),
          );
        }
        continue;
      }
      final expireFrac = tok.age / 4.0;
      final pulse = 0.7 + 0.3 * sin(elapsed * 9 + tok.x);
      // Glow
      canvas.drawCircle(
        Offset(tok.x, tok.y),
        _kTokenRadius + 5,
        Paint()
          ..color = _kTokenColor.withValues(alpha: 0.15 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Coin
      canvas.drawCircle(
        Offset(tok.x, tok.y),
        _kTokenRadius,
        Paint()
          ..color = _kTokenColor.withValues(alpha: (1 - expireFrac * 0.7) * 0.9),
      );
      // $ symbol
      _drawText(canvas, '\$', 14, const Color(0xFF5D3A00),
          Offset(tok.x, tok.y));
    }
  }

  // ---- popups ---------------------------------------------------------------

  void _drawPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = (1 - p.age / _kPopupLifetime).clamp(0.0, 1.0);
      _drawText(canvas, p.text, 14, p.color.withValues(alpha: alpha),
          Offset(p.x, p.y));
    }
  }

  // ---- HUD ------------------------------------------------------------------

  void _drawHUD(Canvas canvas, Size size) {
    const barH = 4.0;
    final barY = 8.0;
    final barX = 12.0;
    final barW = size.width - 24;

    // Time bar background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    // Time bar fill
    final timeLeft = ((gameTime - elapsed) / gameTime).clamp(0.0, 1.0);
    final timerColor = timeLeft > 0.4
        ? _kGreen
        : timeLeft > 0.15
            ? const Color(0xFFFF9800)
            : _kDanger;
    final pulseAlpha =
        timeLeft < 0.2 ? 0.5 + 0.3 * sin(elapsed * 14) : 0.65;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * timeLeft, barH),
          const Radius.circular(2)),
      Paint()..color = timerColor.withValues(alpha: pulseAlpha),
    );

    // Score
    _drawText(canvas, '\$$score', 16, _kPotatoGold.withValues(alpha: 0.85),
        Offset(size.width / 2, 22),
        bold: true);

    // Combo
    if (combo > 1) {
      final comboAlpha = 0.6 + 0.3 * sin(elapsed * 8);
      _drawText(canvas, 'x$combo', 13,
          _kTokenColor.withValues(alpha: comboAlpha),
          Offset(size.width * 0.75, 22));
    }
  }

  // ---- screens --------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    // Background hint of zones
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.52),
      Paint()..color = _kSkyBot.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.48),
      Paint()..color = _kSoilTop.withValues(alpha: 0.5),
    );

    // Potato icon
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.3),
        width: 58,
        height: 44,
      ),
      Paint()..color = _kPotatoGold.withValues(alpha: 0.65),
    );
    canvas.drawCircle(
      Offset(size.width / 2 - 9, size.height * 0.3 - 5),
      3.5,
      Paint()..color = _kPotatoDark.withValues(alpha: 0.45),
    );

    _drawTextCentered(canvas, size, 'FARM PANIC', 30,
        Colors.white.withValues(alpha: 0.7), -18);
    _drawTextCentered(canvas, size, '60 seconds. Two zones. Juggle both.', 12,
        Colors.white.withValues(alpha: 0.3), 12);
    _drawTextCentered(canvas, size, 'UNDERGROUND: swipe channels to grow spuds', 11,
        Colors.white.withValues(alpha: 0.22), 32);
    _drawTextCentered(canvas, size, 'ABOVE: swipe bugs away • tap \$ tokens', 11,
        Colors.white.withValues(alpha: 0.22), 50);
    _drawTextCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.25), 78);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.78),
    );

    _drawTextCentered(canvas, size, 'FARM OVER', 30,
        Colors.white.withValues(alpha: 0.5), -55);
    _drawTextCentered(canvas, size, '$score', 56,
        _kPotatoGold.withValues(alpha: 0.8), -8);
    _drawTextCentered(canvas, size, 'points', 14,
        Colors.white.withValues(alpha: 0.3), 32);
    _drawTextCentered(canvas, size, 'Tap to restart', 14,
        Colors.white.withValues(alpha: 0.22), 60);
  }

  // ---- text helpers ---------------------------------------------------------

  void _drawText(Canvas canvas, String text, double sz, Color color,
      Offset center, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: sz,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawTextCentered(Canvas canvas, Size size, String text, double sz,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: sz,
          fontWeight: FontWeight.w600,
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
  bool shouldRepaint(covariant _FarmPanicPainter old) => true;
}
