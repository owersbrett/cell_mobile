import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Starch Factory — conveyor belt sorting
// Route colored glucose to matching lane endpoints. Endpoints swap positions.
// ---------------------------------------------------------------------------

enum _MolColor { amber, cyan, green, purple, pink }

Color _molC(_MolColor c) {
  switch (c) {
    case _MolColor.amber:  return const Color(0xFFE19816);
    case _MolColor.cyan:   return const Color(0xFF4FC3F7);
    case _MolColor.green:  return const Color(0xFF66BB6A);
    case _MolColor.purple: return const Color(0xFFCE93D8);
    case _MolColor.pink:   return const Color(0xFFEF9A9A);
  }
}

String _molL(_MolColor c) {
  switch (c) {
    case _MolColor.amber:  return 'G';
    case _MolColor.cyan:   return 'A';
    case _MolColor.green:  return 'B';
    case _MolColor.purple: return 'P';
    case _MolColor.pink:   return 'D';
  }
}

// ---- data classes ---------------------------------------------------------

class _Mol {
  double x;        // normalised 0-1 (0=left edge, 1=right edge)
  int lane;         // 0, 1, 2
  double visualY;   // animated pixel Y for smooth lane slide
  _MolColor color;
  bool active;
  bool resolved;
  bool correct;
  double resolveAge; // seconds since resolved (for exit anim)

  _Mol({
    required this.x, required this.lane, required this.visualY,
    required this.color,
  })  : active = false, resolved = false, correct = false, resolveAge = 0;
}

class _Float {
  double x, y, age;
  String text;
  Color color;
  _Float({required this.x, required this.y, required this.text,
    required this.color}) : age = 0;
}

// ---- widget ---------------------------------------------------------------

class StarchFactoryGame extends StatefulWidget {
  const StarchFactoryGame({Key? key}) : super(key: key);
  @override
  State<StarchFactoryGame> createState() => _StarchFactoryGameState();
}

class _StarchFactoryGameState extends State<StarchFactoryGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  bool _started = false;
  bool _gameOver = false;
  double _elapsed = 0;
  int _score = 0;

  // Starch reserve (health bar) 0-1
  double _starch = 0.85;
  double _drainRate = 0.018;

  // Lanes — index = lane number, value = what color that lane accepts
  List<_MolColor> _laneColors = [_MolColor.amber, _MolColor.cyan, _MolColor.green];

  // Swap animation
  double _swapTimer = 10.0;
  double _swapCooldown = 10.0;
  bool _swapWarning = false;     // true 1.5 s before swap
  bool _swapping = false;        // true during the slide animation
  double _swapProgress = 0;      // 0-1
  int _swapA = 0, _swapB = 1;   // which two lanes swap
  List<_MolColor> _preSwapColors = [];

  // Molecules
  final List<_Mol> _mols = [];
  double _scrollSpeed = 0.14;    // normalised units / sec

  // Chains behind endpoints (visual only — length per lane)
  final List<int> _chainLen = [2, 2, 2];

  // Score floats
  final List<_Float> _floats = [];

  // Input — tap to select lane, tap again to swap
  int? _selectedLane;

  // Stats
  int _combo = 0;
  int _totalRouted = 0;
  int _correctRoutes = 0;

  Size _sz = Size.zero;
  double _lastTime = 0;

  // ---- lifecycle ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() { _ticker.dispose(); super.dispose(); }

  int get _laneCount => _laneColors.length;

  double _laneY(int lane) {
    if (_sz.height == 0) return 0;
    const top = 0.20;
    const bot = 0.76;
    final n = _laneCount;
    if (n <= 1) return _sz.height * (top + bot) / 2;
    return _sz.height * (top + (bot - top) * lane / (n - 1));
  }

  static const double _endpointX = 0.82; // normalised

  // ---- tick ---------------------------------------------------------------

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (!_started || _gameOver) return;

    setState(() {
      _elapsed += dt;

      // Drain starch
      _starch -= _drainRate * dt;
      if (_starch <= 0) { _starch = 0; _gameOver = true; return; }

      // Difficulty ramp
      _scrollSpeed = 0.14 + (_elapsed / 90) * 0.18;
      _drainRate = 0.018 + (_elapsed / 90) * 0.012;

      // Add lanes at score thresholds
      if (_score >= 1000 && _laneColors.length == 3) {
        _laneColors.add(_MolColor.purple);
        _chainLen.add(2);
      }
      if (_score >= 10000 && _laneColors.length == 4) {
        _laneColors.add(_MolColor.pink);
        _chainLen.add(2);
      }

      // ---- molecules ----
      _Mol? leader;
      for (final m in _mols) {
        if (!m.resolved) {
          m.x += _scrollSpeed * dt;
          // Smooth lane slide
          final targetY = _laneY(m.lane);
          m.visualY += (targetY - m.visualY) * (dt * 14).clamp(0.0, 1.0);
          leader ??= m;
        } else {
          m.resolveAge += dt;
        }
      }
      _mols.removeWhere((m) => m.resolved && m.resolveAge > 0.6);

      // Activate leader
      if (leader != null && !leader.active) leader.active = true;

      // Resolve leader if past endpoint
      if (leader != null && leader.x >= _endpointX) {
        _resolve(leader);
      }

      // Spawn next molecule if needed
      final unresolvedCount = _mols.where((m) => !m.resolved).length;
      if (unresolvedCount < 3 && _sz != Size.zero) {
        // Space them out
        final lastUnresolved = _mols.lastWhere(
          (m) => !m.resolved,
          orElse: () => _Mol(x: 1.0, lane: 0, visualY: 0, color: _MolColor.amber),
        );
        if (lastUnresolved.x > 0.22 || unresolvedCount == 0) {
          _spawnMol();
        }
      }

      // ---- swap timer ----
      _swapTimer -= dt;
      _swapCooldown = (10.0 - (_elapsed / 90) * 5).clamp(4.5, 10.0);

      if (!_swapping) {
        _swapWarning = _swapTimer < 1.5 && _swapTimer > 0;
        if (_swapTimer <= 0) {
          _beginSwap();
          _swapTimer = _swapCooldown;
        }
      }

      if (_swapping) {
        _swapProgress += dt * 2.8; // ~0.36 s
        if (_swapProgress >= 1) {
          _swapping = false;
          _swapProgress = 0;
          _swapWarning = false;
        }
      }

      // Floats
      for (final f in _floats) { f.age += dt; f.y -= 34 * dt; }
      _floats.removeWhere((f) => f.age > 1.2);
    });
  }

  // ---- spawning -----------------------------------------------------------

  void _spawnMol() {
    final lane = _rng.nextInt(_laneCount);
    final color = _laneColors[_rng.nextInt(_laneCount)];
    final mol = _Mol(
      x: -0.06,
      lane: lane,
      visualY: _laneY(lane),
      color: color,
    );
    if (_mols.where((m) => !m.resolved).isEmpty) mol.active = true;
    _mols.add(mol);
  }

  // ---- resolve ------------------------------------------------------------

  void _resolve(_Mol mol) {
    mol.resolved = true;
    _totalRouted++;

    final accepts = _laneColors[mol.lane];
    final ex = _sz.width * _endpointX;
    final ey = _laneY(mol.lane);

    if (mol.color == accepts) {
      mol.correct = true;
      _combo++;
      int pts = 10;
      if (_combo >= 3) pts = (pts * (1 + _combo * 0.15)).round();
      if (_starch < 0.2) pts += 10;
      _score += pts;
      _starch = (_starch + 0.055).clamp(0.0, 1.0);
      _correctRoutes++;
      _chainLen[mol.lane] = (_chainLen[mol.lane] + 1).clamp(0, 12);
      _floats.add(_Float(x: ex, y: ey, text: '+$pts', color: _molC(mol.color)));
    } else {
      mol.correct = false;
      _combo = 0;
      _starch = (_starch - 0.07).clamp(0.0, 1.0);
      _chainLen[mol.lane] = (_chainLen[mol.lane] - 1).clamp(0, 12);
      _floats.add(_Float(x: ex, y: ey, text: 'MISS', color: const Color(0xFFEF5350)));
    }

    // Activate next
    for (final m in _mols) {
      if (!m.resolved) { m.active = true; break; }
    }
  }

  // ---- swap ---------------------------------------------------------------

  void _beginSwap() {
    _preSwapColors = List.from(_laneColors);
    // Pick two different lanes to swap
    final n = _laneCount;
    _swapA = _rng.nextInt(n);
    _swapB = (_swapA + 1 + _rng.nextInt(n - 1)) % n;
    // Commit the color swap immediately (gameplay uses new assignment)
    final tmp = _laneColors[_swapA];
    _laneColors[_swapA] = _laneColors[_swapB];
    _laneColors[_swapB] = tmp;
    _swapping = true;
    _swapProgress = 0;
  }

  // ---- input — tap lane to select, tap another to swap -------------------

  int _nearestLane(double y) {
    int best = 0;
    double bestDist = (y - _laneY(0)).abs();
    for (int i = 1; i < _laneCount; i++) {
      final d = (y - _laneY(i)).abs();
      if (d < bestDist) { bestDist = d; best = i; }
    }
    return best;
  }

  void _onTapDown(Offset pos) {
    if (_gameOver) { _restart(); return; }
    if (!_started) { _started = true; _spawnMol(); return; }

    final tapped = _nearestLane(pos.dy);

    if (_selectedLane == null) {
      // First tap — select this lane
      _selectedLane = tapped;
    } else if (_selectedLane == tapped) {
      // Tapped same lane — deselect
      _selectedLane = null;
    } else {
      // Second tap on a different lane — swap all molecules between the two
      _swapLanes(_selectedLane!, tapped);
      _selectedLane = null;
    }
  }

  void _swapLanes(int a, int b) {
    for (final m in _mols) {
      if (m.resolved) continue;
      if (m.lane == a) {
        m.lane = b;
      } else if (m.lane == b) {
        m.lane = a;
      }
      // visualY will animate smoothly in tick via lerp
    }
  }

  void _restart() {
    setState(() {
      _started = true; _gameOver = false; _elapsed = 0; _score = 0;
      _starch = 0.85; _drainRate = 0.018; _scrollSpeed = 0.14;
      _laneColors = [_MolColor.amber, _MolColor.cyan, _MolColor.green];
      _swapTimer = 10; _swapCooldown = 10; _swapping = false; _swapWarning = false;
      _mols.clear(); _floats.clear(); _combo = 0; _selectedLane = null;
      _totalRouted = 0; _correctRoutes = 0;
      _chainLen.clear(); _chainLen.addAll([2, 2, 2]);
      _spawnMol();
    });
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _onTapDown(d.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _StarchPainter(
              sz: _sz,
              mols: _mols,
              laneColors: _laneColors,
              chainLen: _chainLen,
              floats: _floats,
              starch: _starch,
              score: _score,
              combo: _combo,
              elapsed: _elapsed,
              scrollSpeed: _scrollSpeed,
              started: _started,
              gameOver: _gameOver,
              swapWarning: _swapWarning,
              swapping: _swapping,
              swapProgress: _swapProgress,
              swapA: _swapA,
              swapB: _swapB,
              preSwapColors: _preSwapColors,
              totalRouted: _totalRouted,
              correctRoutes: _correctRoutes,
              laneYFn: _laneY,
              selectedLane: _selectedLane,
              laneCount: _laneCount,
              swapTimerValue: _swapTimer,
              swapCooldownValue: _swapCooldown,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _StarchPainter extends CustomPainter {
  final Size sz;
  final List<_Mol> mols;
  final List<_MolColor> laneColors;
  final List<int> chainLen;
  final List<_Float> floats;
  final double starch, elapsed, scrollSpeed;
  final int score, combo, totalRouted, correctRoutes;
  final bool started, gameOver, swapWarning, swapping;
  final double swapProgress;
  final int swapA, swapB;
  final List<_MolColor> preSwapColors;
  final double Function(int) laneYFn;
  final int? selectedLane;
  final int laneCount;
  final double swapTimerValue;
  final double swapCooldownValue;

  _StarchPainter({
    required this.sz, required this.mols, required this.laneColors,
    required this.chainLen, required this.floats,
    required this.starch, required this.score, required this.combo,
    required this.elapsed, required this.scrollSpeed,
    required this.started, required this.gameOver,
    required this.swapWarning, required this.swapping,
    required this.swapProgress, required this.swapA, required this.swapB,
    required this.preSwapColors, required this.totalRouted,
    required this.correctRoutes, required this.laneYFn,
    required this.selectedLane, required this.laneCount,
    required this.swapTimerValue, required this.swapCooldownValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background — warm dark amyloplast
    canvas.drawRect(Offset.zero & size, Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5), size.height * 0.8,
        [const Color(0xFF1A1200), const Color(0xFF0A0800), Colors.black],
        [0.0, 0.6, 1.0]));

    if (!started) { _drawStart(canvas, size); return; }
    if (gameOver) { _drawGameOver(canvas, size); return; }

    // ---- swap countdown indicator ----
    if (!swapping) {
      final frac = (swapTimerValue / swapCooldownValue).clamp(0.0, 1.0);
      final barW = 60.0;
      final barH = 4.0;
      final bx = (size.width - barW) / 2;
      final by = 28.0;
      // Track background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barW, barH), const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.06));
      // Fill — shrinks as timer runs down
      final fillW = barW * frac;
      Color timerC = Colors.white24;
      if (frac < 0.25) {
        final pulse = (0.5 + 0.5 * sin(elapsed * 10)).clamp(0.0, 1.0);
        timerC = Color.lerp(const Color(0xFFFF8A65), Colors.white38, pulse)!;
      }
      if (fillW > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bx, by, fillW, barH), const Radius.circular(2)),
          Paint()..color = timerC);
      }
    }

    // ---- conveyor lanes ----
    for (int i = 0; i < laneCount; i++) {
      final y = laneYFn(i);
      final isSelected = selectedLane == i;
      // Lane background strip
      canvas.drawRect(
        Rect.fromCenter(center: Offset(size.width / 2, y),
          width: size.width - 20, height: 38),
        Paint()..color = Colors.white.withValues(alpha: isSelected ? 0.08 : 0.03));
      // Selected lane border
      if (isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(size.width / 2, y),
              width: size.width - 20, height: 38),
            const Radius.circular(4)),
          Paint()..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
      // Animated dashes
      final dashW = 10.0;
      final dashGap = 22.0;
      final offset = (elapsed * scrollSpeed * size.width * 0.8) % dashGap;
      for (double dx = -offset + 10; dx < size.width - 10; dx += dashGap) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dx, y - 1, dashW, 2), const Radius.circular(1)),
          Paint()..color = Colors.white.withValues(alpha: 0.05));
      }
    }

    // ---- endpoints ----
    final epX = size.width * _StarchFactoryGameState._endpointX;
    for (int i = 0; i < laneCount; i++) {
      double ey = laneYFn(i);
      _MolColor col = laneColors[i];

      // During swap animation, lerp endpoint Y positions
      if (swapping && preSwapColors.isNotEmpty) {
        if (i == swapA || i == swapB) {
          final otherLane = i == swapA ? swapB : swapA;
          final fromY = laneYFn(otherLane);
          final toY = laneYFn(i);
          ey = fromY + (toY - fromY) * swapProgress;
          // Use post-swap color (already committed)
        }
      }

      final c = _molC(col);
      // Glow
      canvas.drawCircle(Offset(epX, ey), 28, Paint()
        ..shader = ui.Gradient.radial(Offset(epX, ey), 28,
          [c.withValues(alpha: 0.25), Colors.transparent]));
      // Hexagon
      _drawHex(canvas, Offset(epX, ey), 16, c);
      // Label
      final tp = TextPainter(
        text: TextSpan(text: _molL(col),
          style: TextStyle(fontFamily: 'Avenir', fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(epX - tp.width / 2, ey - tp.height / 2));

      // Warning pulse
      if (swapWarning) {
        final pulse = (0.5 + 0.5 * sin(elapsed * 8)).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(epX, ey), 22, Paint()
          ..color = Colors.white.withValues(alpha: pulse * 0.3)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      // Chain segments behind endpoint
      final nodeSpacing = 16.0;
      for (int n = 0; n < chainLen[i]; n++) {
        final nx = epX + (n + 1) * nodeSpacing;
        if (nx > size.width - 5) break;
        final a = (1.0 - n / 12).clamp(0.2, 0.7);
        _drawHex(canvas, Offset(nx, laneYFn(i)), 6,
          c.withValues(alpha: a));
        if (n > 0) {
          canvas.drawLine(
            Offset(nx - nodeSpacing, laneYFn(i)), Offset(nx, laneYFn(i)),
            Paint()..color = c.withValues(alpha: a * 0.5)..strokeWidth = 2);
        }
      }
    }

    // ---- molecules ----
    for (final m in mols) {
      if (m.resolved && m.resolveAge > 0.5) continue;
      final mx = m.x * size.width;
      final my = m.visualY;
      double alpha = 1.0;
      double scale = 1.0;

      if (m.resolved) {
        final t = m.resolveAge / 0.5;
        alpha = (1 - t).clamp(0.0, 1.0);
        scale = m.correct ? 1.0 + t * 0.4 : 1.0 - t * 0.5;
      }

      final c = _molC(m.color);
      final r = 14.0 * scale;

      // Hexagon
      _drawHex(canvas, Offset(mx, my), r,
        c.withValues(alpha: alpha));
      // Label
      if (scale > 0.3) {
        final tp = TextPainter(
          text: TextSpan(text: _molL(m.color),
            style: TextStyle(fontFamily: 'Avenir', fontSize: 11 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: alpha * 0.9))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(mx - tp.width / 2, my - tp.height / 2));
      }

      // Resolve flash
      if (m.resolved && m.resolveAge < 0.15) {
        final flash = (1 - m.resolveAge / 0.15);
        canvas.drawCircle(Offset(mx, my), 30 * flash, Paint()
          ..color = (m.correct ? c : const Color(0xFFEF5350))
              .withValues(alpha: flash * 0.3));
      }
    }

    // ---- starch bar ----
    _drawStarchBar(canvas, size);

    // ---- floats ----
    for (final f in floats) {
      final a = (1 - f.age / 1.2).clamp(0.0, 1.0);
      final s = 1 + f.age * 0.2;
      final tp = TextPainter(
        text: TextSpan(text: f.text,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 20 * s,
            fontWeight: FontWeight.bold,
            color: f.color.withValues(alpha: a))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x - tp.width / 2, f.y - tp.height / 2));
    }

    // ---- HUD ----
    _centered(canvas, size, '$score', 18, Colors.white38, size.height / 2 - 48);
    if (combo >= 3) {
      _centered(canvas, size, 'x$combo', 14,
        const Color(0xFFFFD740), size.height / 2 - 70);
    }
  }

  // ---- helpers ------------------------------------------------------------

  void _drawStarchBar(Canvas canvas, Size size) {
    const barH = 12.0;
    final barW = size.width - 40;
    const barY = 10.0;
    const barX = 20.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));

    final fill = barW * starch.clamp(0.0, 1.0);
    Color barC;
    if (starch > 0.5) {
      barC = Color.lerp(const Color(0xFFFFEB3B), const Color(0xFF4CAF50),
        (starch - 0.5) * 2)!;
    } else {
      barC = Color.lerp(const Color(0xFFF44336), const Color(0xFFFFEB3B),
        starch * 2)!;
    }
    if (fill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, fill, barH), const Radius.circular(6)),
        Paint()..color = barC);
    }

    // Pulse when low
    if (starch < 0.25) {
      final pulse = (0.5 + 0.5 * sin(elapsed * 6)).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX - 2, barY - 2, barW + 4, barH + 4),
          const Radius.circular(8)),
        Paint()..color = const Color(0xFFF44336).withValues(alpha: pulse * 0.25)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    final label = TextPainter(
      text: TextSpan(text: 'STARCH',
        style: TextStyle(fontFamily: 'Avenir', fontSize: 8,
          fontWeight: FontWeight.bold,
          color: starch > 0.4 ? Colors.black54 : Colors.white54)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(barX + (barW - label.width) / 2, barY + 1));
  }

  void _drawHex(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * pi / 3) - pi / 6;
      final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }

  void _centered(Canvas c, Size s, String text, double fs, Color col,
      double yOff) {
    final tp = TextPainter(
      text: TextSpan(text: text,
        style: TextStyle(fontFamily: 'Avenir', fontSize: fs,
          fontWeight: FontWeight.w300, color: col)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2,
      (s.height - tp.height) / 2 + yOff));
  }

  void _drawStart(Canvas canvas, Size size) {
    _centered(canvas, size, 'Starch Factory', 28,
      const Color(0xFFE19816), -50);
    _centered(canvas, size, 'Inside the Amyloplast', 14,
      Colors.white30, -16);
    _centered(canvas, size, 'Tap two lanes to swap.\nRoute molecules to matching funnels.', 15,
      Colors.white24, 24);
    _centered(canvas, size, 'Tap to start', 16, Colors.white54, 70);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.7));
    _centered(canvas, size, 'DEPLETED', 38, const Color(0xFFF44336), -60);
    _centered(canvas, size, '$score', 52, Colors.white70, -8);
    final pct = totalRouted > 0
        ? '${(correctRoutes / totalRouted * 100).round()}%' : '-';
    _centered(canvas, size, '$totalRouted routed  ·  $pct accuracy', 14,
      Colors.white38, 36);
    _centered(canvas, size, '${elapsed.toStringAsFixed(1)}s survived', 14,
      Colors.white30, 56);
    _centered(canvas, size, 'Tap to play again', 14, Colors.white24, 86);
  }

  @override
  bool shouldRepaint(covariant _StarchPainter old) => true;
}
