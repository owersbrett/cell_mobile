import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/organism/organism_facts.dart';

// ---------------------------------------------------------------------------
// Helper: tiny particle for visual feedback across multiple games
// ---------------------------------------------------------------------------
class _FxParticle {
  double x, y, vx, vy, life;
  Color color;
  double size;
  _FxParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 4,
  });
}

// ---------------------------------------------------------------------------
// _PotatoPatch — state for one cell in the 4×4 harvest grid
// ---------------------------------------------------------------------------
class _PotatoPatch {
  double progress; // 0..1 — grow progress toward ripe
  double growSpeed; // progress units per second (base, before difficulty mult)
  bool harvested = false;
  bool rotten = false;
  bool isGolden;
  double rotTimer = 0; // seconds spent fully ripe before harvest
  _PotatoPatch({
    this.progress = 0,
    this.growSpeed = 0.08,
    this.isGolden = false,
  });
}

// ---------------------------------------------------------------------------
// _ScorePop — floating score label that rises and fades
// ---------------------------------------------------------------------------
class _ScorePop {
  double x, y;
  double vy = -90; // pixels per second (upward = negative)
  double life = 1.0; // 0..1, fades out
  final String label;
  final Color color;
  // Laid out ONCE at spawn. Re-shaping text every frame in the painter (the old
  // behaviour) cost ~9ms per pop per frame on web; a frenzy of pops drove the
  // paint phase to ~180ms/frame → blank frames → "black screen". Cache it.
  final TextPainter tp;
  _ScorePop({
    required this.x,
    required this.y,
    required this.label,
    required this.color,
  }) : tp = (TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout());
}

// Coin geometry — top-level so both the painter and the game state agree on the
// hit radius. Kept tight: coins are tap targets, not decoration.
const double _kCoinRadius = 15.0;
const double _kCoinHitPad = 7.0; // forgiveness around the visual disc on tap

// ---------------------------------------------------------------------------
// _BonusCoin — an ephemeral coin that pops in the field margin and decays fast.
// Replaces the old swaying fact cards: it lives ENTIRELY on the ticker-driven
// canvas (no widget, no Positioned, no per-frame text layout), so it can't cause
// the relayout/rebuild jitter the fact-card widgets did. The "+N" glyph is laid
// out ONCE at spawn (same discipline as _ScorePop).
// ---------------------------------------------------------------------------
class _BonusCoin {
  double x, y;
  double life; // seconds remaining; fades out over the last _coinFadeTime
  final int value;
  final TextPainter tp;
  _BonusCoin({
    required this.x,
    required this.y,
    required this.life,
    required this.value,
  }) : tp = (TextPainter(
          text: TextSpan(
            text: '+$value',
            style: const TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout());
}

/// Draws all Harvest FX particles + score pops + bonus coins in ONE paint pass.
/// Replaces the dozens of per-particle Positioned/Opacity widgets that stalled
/// the web GPU (each Opacity = an offscreen saveLayer) and blacked the screen on
/// bursts — and now also the swaying fact-card widgets, whose Positioned motion
/// re-ran text layout every rebuild at a choppy 15fps.
class _HarvestFxPainter extends CustomPainter {
  final List<_FxParticle> fx;
  final List<_ScorePop> pops;
  final List<_BonusCoin> coins;
  final double coinFade; // seconds over which a coin fades as its life expires
  _HarvestFxPainter({
    required this.fx,
    required this.pops,
    required this.coins,
    required this.coinFade,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Skip any non-finite frame entirely — a single NaN/Infinity reaching the
    // canvas can make Skia drop the whole frame (black screen).
    if (!size.width.isFinite || !size.height.isFinite) return;
    for (final p in fx) {
      // Defend against NaN/Infinity in alpha (clamp passes NaN through) and in
      // coordinates — either would poison the draw call and can blank the layer.
      final double a = p.life.isFinite ? p.life.clamp(0.0, 1.0) : 0.0;
      if (a <= 0) continue;
      if (!p.x.isFinite || !p.y.isFinite || !p.size.isFinite) continue;
      canvas.drawCircle(
        Offset(p.x, p.y),
        (p.size / 2) * a,
        Paint()..color = p.color.withValues(alpha: a),
      );
    }
    for (final pop in pops) {
      final double a = pop.life.isFinite ? pop.life.clamp(0.0, 1.0) : 0.0;
      if (a <= 0) continue;
      if (!pop.x.isFinite || !pop.y.isFinite) continue;
      // Draw the pre-laid-out glyph — NO per-frame text shaping. Fade is applied
      // as group opacity via a tiny saveLayer only while actually fading (the
      // pops are capped in number, so this is a handful of small layers at most).
      final tp = pop.tp;
      final off = Offset(pop.x - 24, pop.y);
      if (a >= 0.98) {
        tp.paint(canvas, off);
      } else {
        final rect = off & tp.size;
        canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, a));
        tp.paint(canvas, off);
        canvas.restore();
      }
    }
    // Bonus coins — a gold disc with a rim + shine and the cached "+N" glyph.
    // Fades over its final `coinFade` seconds. Capped in number by the spawner,
    // so this is a handful of cheap draws.
    for (final coin in coins) {
      if (!coin.x.isFinite || !coin.y.isFinite || !coin.life.isFinite) continue;
      final double a =
          (coin.life >= coinFade ? 1.0 : coin.life / coinFade).clamp(0.0, 1.0);
      if (a <= 0) continue;
      final c = Offset(coin.x, coin.y);
      canvas.drawCircle(
          c, _kCoinRadius, Paint()..color = const Color(0xFFFFC107).withValues(alpha: a));
      canvas.drawCircle(
          c,
          _kCoinRadius,
          Paint()
            ..color = const Color(0xFFFFA000).withValues(alpha: a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      canvas.drawCircle(
          c.translate(-_kCoinRadius * 0.3, -_kCoinRadius * 0.3),
          _kCoinRadius * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * a));
      final tp = coin.tp;
      final off = c - Offset(tp.width / 2, tp.height / 2);
      if (a >= 0.98) {
        tp.paint(canvas, off);
      } else {
        final rect = off & tp.size;
        canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, a));
        tp.paint(canvas, off);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_HarvestFxPainter oldDelegate) => true;
}

/// Draws the whole 4×4 Harvest grid (patch fills, borders, ripe glow, icon +
/// progress/rot bars) in ONE paint pass. Replaces 16 gradient+shadow Container
/// widgets that were rebuilt every frame from the game loop and stalled the web
/// GPU to black. Procedural/canvas, per the project's rendering rule.
class _HarvestGridPainter extends CustomPainter {
  final List<List<_PotatoPatch>> grid;
  final int rows, cols;
  final double patchSize, spacing, rotWindow, rotWarn;
  final bool waterActive;
  final double anim; // seconds elapsed — drives the ripe pulse
  _HarvestGridPainter({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.patchSize,
    required this.spacing,
    required this.rotWindow,
    required this.rotWarn,
    required this.waterActive,
    required this.anim,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // A zero-size layout (collapsed viewport mid-resize) or any non-finite
    // metric must not reach the draw calls — skip the frame cleanly instead of
    // letting a degenerate rect/NaN poison the layer and black the screen.
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        !patchSize.isFinite ||
        patchSize <= 0) {
      return;
    }
    final step = patchSize + spacing;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = grid[r][c];
        final rect = Rect.fromLTWH(c * step, r * step, patchSize, patchSize);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
        final isRipe =
            p.progress >= 0.9 && !p.harvested && !p.rotten;
        // No MaskFilter.blur glow — blur is a per-frame web-rasterizer stall.
        // Ripe is signalled by the fill color + the bright border below.
        canvas.drawRRect(rrect, Paint()..color = _color(p));
        final b = _border(p);
        canvas.drawRRect(
            rrect,
            Paint()
              ..color = b.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = b.width);
        _content(canvas, p, rect, isRipe);
      }
    }
  }

  Color _color(_PotatoPatch p) {
    if (p.rotten) return const Color(0xFF3E2723);
    if (p.harvested) return const Color(0xFF1C2A30);
    Color base;
    if (p.progress < 0.5) {
      base = const Color(0xFF5D4037);
    } else if (p.progress < 0.9) {
      base = const Color(0xFF7B5E3B);
    } else {
      final rotFrac = (p.rotTimer / rotWindow).clamp(0.0, 1.0);
      base =
          Color.lerp(const Color(0xFF4CAF50), const Color(0xFFEF5350), rotFrac)!;
    }
    if (waterActive && !p.harvested && !p.rotten) {
      base = Color.lerp(base, const Color(0xFF42A5F5), 0.22)!;
    }
    return base;
  }

  ({Color color, double width}) _border(_PotatoPatch p) {
    if (p.harvested || p.rotten) return (color: Colors.white10, width: 1.0);
    if (p.isGolden) {
      return (color: const Color(0xFFFFD700).withValues(alpha: 0.7), width: 2.0);
    }
    if (p.progress >= 1.0 && p.rotTimer > rotWarn) {
      final urgency =
          ((p.rotTimer - rotWarn) / (rotWindow - rotWarn)).clamp(0.0, 1.0);
      return (
        color:
            Color.lerp(const Color(0xFFEF9A9A), const Color(0xFFEF5350), urgency)!,
        width: 2.0
      );
    }
    if (p.progress >= 0.9) {
      return (color: const Color(0xFF4CAF50).withValues(alpha: 0.55), width: 1.5);
    }
    return (color: Colors.white12, width: 1.0);
  }

  void _content(Canvas canvas, _PotatoPatch p, Rect rect, bool isRipe) {
    final center = rect.center;
    // Plain canvas shapes — no TextPainter/icon glyphs (re-shaping text for 16
    // cells every frame was a per-frame web cost).
    if (p.rotten) {
      final s = patchSize * 0.16;
      final mark = Paint()
        ..color = Colors.white24
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center.translate(-s, -s), center.translate(s, s), mark);
      canvas.drawLine(center.translate(s, -s), center.translate(-s, s), mark);
      return;
    }
    if (p.harvested) {
      final s = patchSize * 0.16;
      final tick = Paint()
        ..color = Colors.white24
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - s, center.dy)
          ..lineTo(center.dx - s * 0.2, center.dy + s * 0.7)
          ..lineTo(center.dx + s, center.dy - s * 0.6),
        tick,
      );
      return;
    }
    // Growing/ripe: an actual potato (egg-shaped tuber) that swells as it
    // matures — earthy brown while growing, greening when ripe, gold if golden.
    final tuberColor = p.isGolden
        ? const Color(0xFFFFD700)
        : isRipe
            ? const Color(0xFF81C784)
            : Color.lerp(const Color(0xFF6D4C41), const Color(0xFFA1887F),
                p.progress)!; // earthy, lightening as it grows
    final cx = center.dx;
    final cy = rect.top + patchSize * 0.34;
    final grow = 0.45 + 0.55 * p.progress; // size factor by progress
    final pulse = isRipe ? (1.0 + 0.05 * sin(anim * 4)) : 1.0; // ripe "breathes"
    final w = patchSize * 0.36 * grow * pulse;
    final h = patchSize * 0.27 * grow * pulse;
    final body = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    canvas.drawOval(body, Paint()..color = tuberColor);
    // top-left highlight for a little 3D
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - w * 0.12, cy - h * 0.16),
            width: w * 0.5,
            height: h * 0.4),
        Paint()..color = Colors.white.withValues(alpha: 0.18));
    // potato "eyes" once it's grown a bit
    if (p.progress > 0.3) {
      final eye = Paint()..color = Colors.black.withValues(alpha: 0.22);
      canvas.drawCircle(Offset(cx - w * 0.16, cy + h * 0.02), w * 0.045, eye);
      canvas.drawCircle(Offset(cx + w * 0.13, cy - h * 0.12), w * 0.038, eye);
    }

    Color barColor;
    if (p.progress < 0.5) {
      barColor = const Color(0xFFFF8F00);
    } else if (p.progress < 0.9) {
      barColor = const Color(0xFFFFEE58);
    } else if (p.rotTimer > rotWarn) {
      barColor = const Color(0xFFEF5350);
    } else {
      barColor = const Color(0xFF66BB6A);
    }
    _bar(canvas, rect, 0.60, 0.62, 0.07, p.progress, barColor);

    if (isRipe) {
      final rotFrac = 1.0 - (p.rotTimer / rotWindow).clamp(0.0, 1.0);
      _bar(canvas, rect, 0.72, 0.62, 0.045, rotFrac,
          Color.lerp(const Color(0xFFEF5350), const Color(0xFF4CAF50), rotFrac)!);
    }
  }


  void _bar(Canvas canvas, Rect cell, double yFrac, double wFrac, double hFrac,
      double fill, Color fg) {
    final w = patchSize * wFrac;
    final h = patchSize * hFrac;
    final left = cell.left + (patchSize - w) / 2;
    final top = cell.top + patchSize * yFrac;
    final radius = Radius.circular(h / 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), radius),
        Paint()..color = Colors.white10);
    final f = fill.clamp(0.0, 1.0);
    if (f > 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w * f, h), radius),
          Paint()..color = fg);
    }
  }

  @override
  bool shouldRepaint(_HarvestGridPainter oldDelegate) => true;
}

class OrganismHarvestGame extends StatefulWidget {
  final MiniGameSession session;
  const OrganismHarvestGame({Key? key, required this.session})
      : super(key: key);
  @override
  State<OrganismHarvestGame> createState() => _OrganismHarvestGameState();
}

class _OrganismHarvestGameState extends State<OrganismHarvestGame>
    with SingleTickerProviderStateMixin {
  // ── Difficulty / timing knobs ────────────────────────────────────────────
  // (Run length is owned by the host clock; the game no longer tracks its own
  // duration/time-remaining.)

  /// Base grow-speed range for a fresh patch at the start of the game.
  static const double _baseGrowMin = 0.055;
  static const double _baseGrowMax = 0.095;

  /// How much the grow-speed multiplier increases per second elapsed.
  /// Ramps from 1.0 at t=0 up to [_difficultyPlateau] at t=[_plateauTime].
  static const double _difficultyRampRate = 0.018; // ×/s

  /// Grow-speed multiplier is capped here — difficulty plateaus, never goes
  /// unplayable.
  static const double _difficultyPlateau = 1.65;

  // Difficulty plateaus at ~37s — ( (_difficultyPlateau-1) / _difficultyRampRate )

  /// Seconds a ripe potato can sit before it rots.
  static const double _rotWindow = 4.5;

  /// Seconds before rot at which we show the urgent red border.
  static const double _rotWarnThreshold = 2.5;

  /// Chance a new patch is a golden potato.
  static const double _goldenChance = 0.10;

  /// Milliseconds before a harvested patch re-sprouts.
  static const int _replantDelayMs = 550;

  /// Helper cooldown in seconds between auto-saves.
  static const double _helperCooldownMax = 7.0;

  /// Water boost multiplier on grow speed (cosmetic — player waters to rush
  /// a patch to ripe faster, then harvests before it rots).
  static const double _waterSpeedMult = 2.2;

  /// Seconds a water boost lasts.
  static const double _waterDuration = 5.0;

  /// Seconds within which two harvests count as a combo continuation.
  static const double _comboWindow = 1.8;

  // ── Bonus-coin tunable consts ─────────────────────────────────────────────
  /// Max coins alive at once (the field margin would get noisy beyond this).
  static const int _coinMaxActive = 4;

  /// Lifetime range of a coin — short, so the player must react fast.
  static const double _coinLifeMin = 1.2;
  static const double _coinLifeMax = 1.8;

  /// Seconds over which a coin fades as its life runs out.
  static const double _coinFadeTime = 0.45;

  /// Spawn interval (seconds) at combo 0 (slow) → at [_coinComboPeak] (fast).
  /// "Doing well" (a hot combo) makes coins rain faster → more speed pressure.
  static const double _coinSpawnSlow = 2.2;
  static const double _coinSpawnFast = 0.7;
  static const double _coinComboPeak = 6;

  /// Coin payout: a normal coin, and the rarer "rich" coin.
  static const int _coinValue = 2;
  static const double _coinRichChance = 0.22;
  static const int _coinRichValue = 4;

  /// Keep a coin this far clear of the core grid rect when spawning.
  static const double _coinBandGap = 8.0;

  /// Height of the fixed fact banner reserved below the grid.
  static const double _bannerHeight = 34.0;

  // ── Runtime state ─────────────────────────────────────────────────────────
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;
  double _elapsed = 0; // total seconds played (for difficulty curve)
  bool _gameOver = false;

  static const int _rows = 4;
  static const int _cols = 4;
  final List<List<_PotatoPatch>> _grid = [];

  // Visual feedback
  final List<_FxParticle> _fx = [];
  final List<_ScorePop> _pops = [];

  // Combo
  int _combo = 0;
  double _comboTimer = 0; // counts down; reset on each harvest

  // Coins and helper system
  int _coins = 0;
  bool _helperHired = false;
  int _helperUsesLeft = 0;
  double _helperCooldown = 0;

  // Water powerup
  bool _waterActive = false;
  double _waterTimer = 0;

  // Education: a single fact shown in a fixed, non-moving banner. Refreshed on
  // ripe harvests. Replaces the swaying fact cards — the facts still land, but
  // the delivery no longer animates in the widget tree.
  int _lastFactIndex = -1; // prevents an immediate repeat
  String _currentFact = '';

  // Bonus coins (ephemeral canvas targets in the field margin).
  final List<_BonusCoin> _bonusCoins = [];
  double _coinSpawnTimer = 0;

  // Layout geometry cached from build() so the out-of-build spawn + tap
  // hit-testing have real coordinates to work with. The core 4×4 grid is
  // centered inside its region; coins live in the surrounding band.
  double _geomW = 0;
  double _gridLeft = 0, _gridTop = 0, _gridW = 0, _gridH = 0;
  double _stepCache = 0, _patchSizeCache = 0;
  double _gridRegionTop = 0, _gridRegionBottom = 0;
  bool _geomReady = false;

  // Instructions overlay — shown until player dismisses or harvests twice
  bool _showInstructions = true;
  int _instructionDismissHarvests = 0; // auto-dismiss after 2 harvests

  @override
  void initState() {
    super.initState();
    _initGrid();
    _currentFact = kOrganismFacts[_nextFactIndex()];
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
  }

  void _initGrid() {
    _grid.clear();
    for (int r = 0; r < _rows; r++) {
      _grid.add(List.generate(_cols, (_) => _newPatch()));
    }
  }

  /// Grow speed for a fresh patch, scaled by current difficulty.
  double _currentDiffMult() {
    final ramp = _elapsed * _difficultyRampRate;
    return 1.0 + ramp.clamp(0.0, _difficultyPlateau - 1.0);
  }

  _PotatoPatch _newPatch() {
    final base = _baseGrowMin + _rng.nextDouble() * (_baseGrowMax - _baseGrowMin);
    return _PotatoPatch(
      progress: _rng.nextDouble() * 0.15,
      growSpeed: base * _currentDiffMult(),
      isGolden: _rng.nextDouble() < _goldenChance,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _uiAccum = 0; // throttles widget-tree rebuilds; canvas repaints via ticker

  void _update() {
    // The host (MiniGameHost) owns the countdown, results and wind-down. We
    // only advance simulation while the session is in its playing phase.
    if (!widget.session.isRunning) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = (_lastTime == 0 ? 0.016 : (t - _lastTime)).clamp(0.0, 0.05);
    _lastTime = t;

    // Mutate game state every frame WITHOUT setState — the canvas (grid + FX)
    // repaints at 60fps off the ticker (CustomPaint repaint: _ticker), so we no
    // longer rebuild the whole widget tree 60×/sec. The HUD/cards/badges refresh
    // at ~15fps via the throttled setState at the end.
    {
      _elapsed += dt;

      // ── Combo decay ─────────────────────────────────────────────────────
      if (_combo > 0) {
        _comboTimer -= dt;
        if (_comboTimer <= 0) {
          _combo = 0;
          _comboTimer = 0;
        }
      }

      // ── Water timer ─────────────────────────────────────────────────────
      if (_waterActive) {
        _waterTimer -= dt;
        if (_waterTimer <= 0) {
          _waterActive = false;
          _waterTimer = 0;
        }
      }

      // ── Bonus coins: decay + scaled spawn ───────────────────────────────
      for (final coin in _bonusCoins) {
        coin.life -= dt;
      }
      _bonusCoins.removeWhere((c) => c.life <= 0);
      if (_geomReady) {
        _coinSpawnTimer -= dt;
        if (_coinSpawnTimer <= 0 && _bonusCoins.length < _coinMaxActive) {
          _spawnBonusCoin();
          // Hotter combo → shorter interval → coins rain faster when you're
          // doing well, which is exactly when we want to demand more speed.
          final t = (_combo / _coinComboPeak).clamp(0.0, 1.0);
          final base = _coinSpawnSlow + (_coinSpawnFast - _coinSpawnSlow) * t;
          _coinSpawnTimer = base * (0.85 + _rng.nextDouble() * 0.30);
        }
      }

      // ── Helper cooldown ─────────────────────────────────────────────────
      if (_helperHired && _helperCooldown > 0) {
        _helperCooldown = (_helperCooldown - dt).clamp(0.0, _helperCooldownMax);
      }

      final double speedMult = _waterActive ? _waterSpeedMult : 1.0;

      // ── Patch updates ───────────────────────────────────────────────────
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          final patch = _grid[r][c];
          if (patch.harvested || patch.rotten) continue;

          if (patch.progress < 1.0) {
            patch.progress =
                (patch.progress + patch.growSpeed * speedMult * dt).clamp(0.0, 1.0);
          } else {
            patch.rotTimer += dt;

            // Helper auto-save: rescues patches dangerously close to rotting
            if (_helperHired &&
                _helperUsesLeft > 0 &&
                _helperCooldown <= 0 &&
                patch.rotTimer > _rotWarnThreshold) {
              _helperUsesLeft--;
              _helperCooldown = _helperCooldownMax;
              _doHarvest(r, c, fromHelper: true);
              continue;
            }

            if (patch.rotTimer > _rotWindow) {
              patch.rotten = true;
            }
          }
        }
      }

      // ── FX particles ─────────────────────────────────────────────────────
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 160 * dt; // gravity
        p.life -= dt * 1.8;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // ── Score pops ───────────────────────────────────────────────────────
      for (final pop in _pops) {
        pop.y += pop.vy * dt;
        pop.life -= dt * 1.1;
      }
      _pops.removeWhere((pop) => pop.life <= 0);
      // Hard cap so a harvest frenzy can't unbounded-stack pops (each is a draw
      // + possible fade layer). Keep the most recent.
      if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
    }

    // Rebuild the widget tree (HUD text, fact cards, badges) at ~15fps — far
    // cheaper than 60fps, and the canvas already animates smoothly via ticker.
    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      setState(() {});
    }
  }

  // ── Harvest logic ─────────────────────────────────────────────────────────

  void _doHarvest(int r, int c, {bool fromHelper = false}) {
    final patch = _grid[r][c];
    if (patch.harvested || patch.rotten) return;

    patch.harvested = true;

    // Education: surface a fresh fact in the banner on a ripe pull (the payoff
    // moment) — non-repeating, no motion, no per-frame cost.
    if (patch.progress >= 0.9) {
      _currentFact = kOrganismFacts[_nextFactIndex()];
    }

    // Reward ripeness: coins go 0 → 1 → 2 → 5 as the potato matures, so
    // harvesting early (brown) earns nothing and waiting for green pays off.
    int points;
    int coinEarned;
    if (patch.progress >= 0.9) {
      points = patch.isGolden ? 50 : 15; // ripe / green — the payoff
      coinEarned = 5;
    } else if (patch.progress >= 0.75) {
      points = patch.isGolden ? 25 : 8;
      coinEarned = 2;
    } else if (patch.progress >= 0.5) {
      points = patch.isGolden ? 12 : 5;
      coinEarned = 1;
    } else {
      points = patch.isGolden ? 6 : 2; // too early
      coinEarned = 0;
    }
    if (patch.isGolden) coinEarned *= 2; // golden is premium

    // Combo multiplier (only for player taps, not helper). +5 per step above
    // ×1 (was +3) so chaining ripe harvests, not single golden pulls, is the
    // skill path. Report the chain length so the host's streak award (20/30)
    // can recognise mastery on the results screen.
    int comboBonus = 0;
    if (!fromHelper) {
      _combo++;
      _comboTimer = _comboWindow;
      widget.session.noteStreak(_combo);
      if (_combo >= 2) {
        comboBonus = (_combo - 1) * 5;
      }
    }

    final totalPoints = points + comboBonus;
    _coins += coinEarned;
    widget.session.addScore(totalPoints); // report to host scoreboard

    // ── Instructions auto-dismiss after 2 player harvests ────────────────
    if (!fromHelper && _showInstructions) {
      _instructionDismissHarvests++;
      if (_instructionDismissHarvests >= 2) {
        _showInstructions = false;
      }
    }

    // Auto-replant
    Future.delayed(Duration(milliseconds: _replantDelayMs), () {
      if (!mounted) return;
      setState(() {
        _grid[r][c] = _newPatch();
      });
    });
  }

  void _spawnHarvestFx(double px, double py, _PotatoPatch patch, int points) {
    final Color burstColor = patch.isGolden
        ? const Color(0xFFFFD700)
        : patch.progress >= 0.9
            ? const Color(0xFF66BB6A)
            : const Color(0xFFA5D6A7);

    final int count = patch.isGolden ? 14 : 8;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 60 + _rng.nextDouble() * 90;
      _fx.add(_FxParticle(
        x: px,
        y: py,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 30,
        life: 0.55 + _rng.nextDouble() * 0.35,
        color: burstColor,
        size: patch.isGolden ? 5 + _rng.nextDouble() * 3 : 3 + _rng.nextDouble() * 3,
      ));
    }

    // Score pop label
    final labelColor = _combo >= 3
        ? const Color(0xFFFF9800)
        : patch.isGolden
            ? const Color(0xFFFFD700)
            : Colors.white;
    final label = _combo >= 2 ? '+$points ×$_combo' : '+$points';
    _pops.add(_ScorePop(x: px, y: py - 12, label: label, color: labelColor));
  }

  // ── Fact bombardment ──────────────────────────────────────────────────────

  /// Pick a fact index that is not the same as the last one spawned.
  int _nextFactIndex() {
    if (kOrganismFacts.length <= 1) return 0;
    int idx;
    do {
      idx = _rng.nextInt(kOrganismFacts.length);
    } while (idx == _lastFactIndex);
    _lastFactIndex = idx;
    return idx;
  }

  /// Spawn one bonus coin in the field margin — anywhere in the play band that
  /// is NOT on top of the core grid (with a gap). Tries a few times, then gives
  /// up for this tick if the margin is too tight (graceful, never blocks).
  void _spawnBonusCoin() {
    final double gap = _coinBandGap + _kCoinRadius;
    final double bandH = _gridRegionBottom - _gridRegionTop;
    if (bandH <= 2 * _kCoinRadius) return;
    for (int attempt = 0; attempt < 8; attempt++) {
      final double x = _kCoinRadius + _rng.nextDouble() * (_geomW - 2 * _kCoinRadius);
      final double y =
          _gridRegionTop + _kCoinRadius + _rng.nextDouble() * (bandH - 2 * _kCoinRadius);
      final bool insideGrid = x > _gridLeft - gap &&
          x < _gridLeft + _gridW + gap &&
          y > _gridTop - gap &&
          y < _gridTop + _gridH + gap;
      if (insideGrid) continue;
      final bool rich = _rng.nextDouble() < _coinRichChance;
      _bonusCoins.add(_BonusCoin(
        x: x,
        y: y,
        life: _coinLifeMin + _rng.nextDouble() * (_coinLifeMax - _coinLifeMin),
        value: rich ? _coinRichValue : _coinValue,
      ));
      return;
    }
  }

  /// Single play-area-level tap handler. Coins are checked FIRST (they sit in
  /// the margin), then the tap is mapped to a core-grid cell. Coins never
  /// overlap the grid, so there's no double-trigger.
  void _onTapDown(TapDownDetails d) {
    if (_gameOver) return;
    final pos = d.localPosition;
    if (_tryCollectCoinAt(pos)) return;
    if (!_geomReady) return;
    final double lx = pos.dx - _gridLeft;
    final double ly = pos.dy - _gridTop;
    if (lx < 0 || ly < 0 || lx > _gridW || ly > _gridH) return;
    final int c = (lx / _stepCache).floor().clamp(0, _cols - 1);
    final int r = (ly / _stepCache).floor().clamp(0, _rows - 1);
    _harvest(
      r,
      c,
      _gridLeft + c * _stepCache + _patchSizeCache / 2,
      _gridTop + r * _stepCache + _patchSizeCache / 2,
    );
  }

  /// Collect the topmost coin under [pos], if any. Returns true if one was hit.
  bool _tryCollectCoinAt(Offset pos) {
    final double hit = _kCoinRadius + _kCoinHitPad;
    for (int i = _bonusCoins.length - 1; i >= 0; i--) {
      final coin = _bonusCoins[i];
      final double dx = pos.dx - coin.x;
      final double dy = pos.dy - coin.y;
      if (dx * dx + dy * dy <= hit * hit) {
        setState(() {
          _bonusCoins.removeAt(i);
          _coins += coin.value;
          _pops.add(_ScorePop(
            x: coin.x,
            y: coin.y,
            label: '+${coin.value}',
            color: const Color(0xFFFFD700),
          ));
          if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
        });
        return true;
      }
    }
    return false;
  }

  void _harvest(int r, int c, double px, double py) {
    if (_gameOver) return;
    final patch = _grid[r][c];
    if (patch.harvested || patch.rotten) return;

    setState(() {
      // Capture pre-harvest state for FX
      final bool wasGolden = patch.isGolden;
      final double prog = patch.progress;

      // Mirror _doHarvest's ripeness tiers for the floating +N label.
      int points;
      if (prog >= 0.9) {
        points = wasGolden ? 50 : 15;
      } else if (prog >= 0.75) {
        points = wasGolden ? 25 : 8;
      } else if (prog >= 0.5) {
        points = wasGolden ? 12 : 5;
      } else {
        points = wasGolden ? 6 : 2;
      }
      // Will be re-calculated in _doHarvest, but we need combo state for FX
      _doHarvest(r, c);
      _spawnHarvestFx(px, py, patch, points + (_combo > 1 ? (_combo - 1) * 5 : 0));
    });
  }

  // ── Powerup actions ───────────────────────────────────────────────────────

  void _hireHelper() {
    if (_coins >= 10) {
      setState(() {
        _coins -= 10;
        _helperHired = true;
        _helperUsesLeft = 5;
        _helperCooldown = 0;
      });
    }
  }

  void _activateWater() {
    if (_coins >= 3 && !_waterActive) {
      setState(() {
        _coins -= 3;
        _waterActive = true;
        _waterTimer = _waterDuration;
      });
    }
  }

  // ── Visual helpers ────────────────────────────────────────────────────────
  // (Patch fill/border/content rendering moved to _HarvestGridPainter. Score,
  // grade and restart are owned by the host's results screen, not the game.)

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const double hudHeight = 72.0;
      const double bottomBarHeight = 62.0;
      const double gridPadding = 12.0;
      // Clamp to non-negative: in a short/narrow viewport (e.g. a small web
      // window or iframe) the fixed HUD + bottom bar can exceed the height,
      // making these negative — a negative-sized SizedBox below throws a layout
      // assertion and the game goes black. Clamping degrades gracefully instead.
      // Reserve a strip below the grid for the fixed fact banner.
      final double availableH =
          (h - hudHeight - bottomBarHeight - _bannerHeight - gridPadding * 2)
              .clamp(0.0, double.infinity);
      final double availableW =
          (w - gridPadding * 2).clamp(0.0, double.infinity);
      const double spacing = 7.0;
      final double patchW =
          ((availableW - (_cols - 1) * spacing) / _cols).clamp(0.0, double.infinity);
      final double patchH =
          ((availableH - (_rows - 1) * spacing) / _rows).clamp(0.0, double.infinity);
      final double patchSize = patchW < patchH ? patchW : patchH;
      final double gridW = patchSize * _cols + spacing * (_cols - 1);
      final double gridH = patchSize * _rows + spacing * (_rows - 1);

      // Cache geometry for the out-of-build coin spawner and the play-area tap
      // hit-test. The core grid is centered in its region (Positioned + Center);
      // coins live in the surrounding band. Plain field writes (no setState) —
      // just a memo of the current layout for logic that runs off the ticker.
      _geomW = w;
      _gridRegionTop = hudHeight;
      _gridRegionBottom =
          (h - bottomBarHeight - _bannerHeight).clamp(0.0, double.infinity);
      final double regionW = availableW;
      final double regionH =
          (_gridRegionBottom - _gridRegionTop).clamp(0.0, double.infinity);
      _gridW = gridW;
      _gridH = gridH;
      _stepCache = patchSize + spacing;
      _patchSizeCache = patchSize;
      _gridLeft = gridPadding + (regionW - gridW) / 2;
      _gridTop = _gridRegionTop + (regionH - gridH) / 2;
      _geomReady = patchSize > 0 && regionH > 0;

      return Container(
        color: const Color(0xFF161616),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Single play-area tap surface. Translucent so it doesn't swallow
            // the action-button/banner taps layered above it; sits at the bottom
            // of the Stack and routes each tap to a bonus coin first, else to the
            // core grid cell (from the cached geometry). The grid + FX painters
            // above are gesture-less and fall through to this.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: _onTapDown,
              ),
            ),

            // ── HUD ────────────────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Combo indicator (hidden when combo is 0). Host owns the
                  // score + timer up top; this bar carries the Harvest economy.
                  AnimatedOpacity(
                    opacity: _combo >= 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF9800), width: 1),
                      ),
                      child: Text(
                        '×$_combo COMBO',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ),

                  // Coins + helper
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 14, color: Color(0xFFFFD700)),
                      const SizedBox(width: 2),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      if (_helperHired && _helperUsesLeft > 0) ...[
                        const SizedBox(width: 6),
                        const Text('🥔', style: TextStyle(fontSize: 12)),
                        Text(
                          '×$_helperUsesLeft',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Water boost badge ──────────────────────────────────────────
            if (_waterActive)
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '💧 Water ×${_waterSpeedMult.toStringAsFixed(1)}  ${_waterTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 11,
                        color: Color(0xFF90CAF9),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Grid ──────────────────────────────────────────────────────
            // Drawn in ONE CustomPaint pass (was 16 gradient+shadow Containers
            // rebuilt every frame from the 60fps game loop — a web GPU sink that
            // blacked the screen). Gesture-less: the play-area tap surface at the
            // bottom of the Stack owns all taps and maps them via cached geometry.
            Positioned(
              top: hudHeight,
              left: gridPadding,
              right: gridPadding,
              bottom: bottomBarHeight + _bannerHeight,
              child: Center(
                child: SizedBox(
                  width: gridW,
                  height: gridH,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _HarvestGridPainter(
                          grid: _grid,
                          rows: _rows,
                          cols: _cols,
                          patchSize: patchSize,
                          spacing: spacing,
                          rotWindow: _rotWindow,
                          rotWarn: _rotWarnThreshold,
                          waterActive: _waterActive,
                          anim: _elapsed,
                          repaint: _ticker,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── FX particles ──────────────────────────────────────────────
            // ── FX particles + score pops ─────────────────────────────────
            // Drawn in ONE CustomPaint pass. Previously these were dozens of
            // individual Positioned/Opacity widgets per harvest burst; on web
            // each Opacity forces an offscreen saveLayer, and a burst (peaking
            // ~5–6 harvests in) stalled the GPU for seconds — the screen went
            // black until the particles expired. A single painter has no per-
            // particle layers.
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    // Repaints every tick off the game clock — no setState /
                    // widget-tree rebuild needed to animate the canvas.
                    painter: _HarvestFxPainter(
                      fx: _fx,
                      pops: _pops,
                      coins: _bonusCoins,
                      coinFade: _coinFadeTime,
                      repaint: _ticker,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────
            if (!_gameOver)
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      label: 'Helper',
                      cost: 10,
                      icon: '🥔',
                      enabled: _coins >= 10,
                      activeColor: const Color(0xFFE19816),
                      activeBg: const Color(0xFF4E342E),
                      onTap: _hireHelper,
                    ),
                    _buildActionButton(
                      label: 'Water',
                      cost: 3,
                      iconWidget: Icon(
                        Icons.water_drop,
                        size: 14,
                        color: _coins >= 3 && !_waterActive
                            ? const Color(0xFF42A5F5)
                            : Colors.white24,
                      ),
                      enabled: _coins >= 3 && !_waterActive,
                      activeColor: const Color(0xFF42A5F5),
                      activeBg: const Color(0xFF1A3A4A),
                      onTap: _activateWater,
                    ),
                  ],
                ),
              ),

            // ── Fixed fact banner (the educational payload) ───────────────
            // A single, NON-MOVING strip just above the action bar, refreshed
            // only on ripe harvests. Because it never moves, a plain Text here
            // costs one layout when the fact changes — it can't trigger the
            // per-frame relayout the old swaying cards did. This is the E in
            // GAMES: organism facts still land, just without the jitter.
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomBarHeight,
              child: IgnorePointer(
                child: Container(
                  height: _bannerHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2E1B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _currentFact,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 10,
                      height: 1.2,
                      color: Color(0xFFCCE8CC),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      );
    });
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildActionButton({
    required String label,
    required int cost,
    String? icon,
    Widget? iconWidget,
    required bool enabled,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? activeBg : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled ? activeColor : Colors.white10,
            width: enabled ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Text(icon, style: const TextStyle(fontSize: 14))
            else if (iconWidget != null)
              iconWidget,
            const SizedBox(width: 5),
            Text(
              '$label ($cost)',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: enabled ? activeColor : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
