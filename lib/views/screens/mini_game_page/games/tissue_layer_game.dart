import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ============================================================================
// Layer Builder — drag tissue types into the correct zone of a plant
// cross-section viewed through a microscope lens.
// ============================================================================

// --- zone definitions -------------------------------------------------------

enum _TissueZone { pith, vascular, cortex, epidermis }

class _ZoneInfo {
  final double innerFrac; // fraction of cross-section radius (0 = center)
  final double outerFrac;
  final Color color;
  final String label;
  const _ZoneInfo(this.innerFrac, this.outerFrac, this.color, this.label);
}

const Map<_TissueZone, _ZoneInfo> _kZones = {
  _TissueZone.pith:      _ZoneInfo(0.00, 0.24, Color(0xFFA5D6A7), 'Pith'),
  _TissueZone.vascular:  _ZoneInfo(0.24, 0.50, Color(0xFFEF5350), 'Vascular'),
  _TissueZone.cortex:    _ZoneInfo(0.50, 0.78, Color(0xFF66BB6A), 'Cortex'),
  _TissueZone.epidermis: _ZoneInfo(0.78, 1.00, Color(0xFF42A5F5), 'Epidermis'),
};

const _kOrganNames = ['Stem', 'Root', 'Leaf'];

// --- data classes -----------------------------------------------------------

class _DragPiece {
  final _TissueZone zone;
  double x, y;
  _DragPiece(this.zone, this.x, this.y);
}

class _ZoneFill {
  final _TissueZone zone;
  double age;
  _ZoneFill(this.zone) : age = 0;
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup(this.x, this.y, this.text, this.color) : age = 0;
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
    this.size = 4,
  });
}

// --- widget -----------------------------------------------------------------

class TissueLayerGame extends StatefulWidget {
  const TissueLayerGame({Key? key}) : super(key: key);
  @override
  State<TissueLayerGame> createState() => _TissueLayerGameState();
}

class _TissueLayerGameState extends State<TissueLayerGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _timeRemaining = 90.0;
  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  bool _started = false;
  int _round = 0;
  int _sectionsCompleted = 0;
  int _combo = 0;

  final Set<_TissueZone> _filled = {};
  final List<_ZoneFill> _fillAnims = [];
  double _completeAge = -1; // >=0 while celebrating a finished section

  final List<_DragPiece> _pieces = [];
  int? _dragIndex;
  _TissueZone? _hoveredZone;

  final List<_FxDot> _fx = [];
  final List<_Popup> _pops = [];
  double _wrongFlash = 0;

  Size _sz = Size.zero;
  double _lastT = 0;

  Offset get _center => Offset(_sz.width / 2, _sz.height * 0.38);
  double get _radius => min(_sz.width * 0.44, _sz.height * 0.30);

  // ---- lifecycle -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
        vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- init ----------------------------------------------------------------

  void _initGame() {
    _timeRemaining = 90;
    _score = 0;
    _lives = 3;
    _round = 0;
    _combo = 0;
    _sectionsCompleted = 0;
    _gameOver = false;
    _filled.clear();
    _fillAnims.clear();
    _completeAge = -1;
    _fx.clear();
    _pops.clear();
    _wrongFlash = 0;
    _dragIndex = null;
    _hoveredZone = null;
    _buildPieces();
  }

  void _buildPieces() {
    _pieces.clear();
    final remaining = _TissueZone.values
        .where((z) => !_filled.contains(z))
        .toList()
      ..shuffle(_rng);
    final n = remaining.length;
    for (int i = 0; i < n; i++) {
      final px = _sz.width / 2 + (i - (n - 1) / 2.0) * 90;
      final py = _sz.height * 0.82;
      _pieces.add(_DragPiece(remaining[i], px, py));
    }
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (_gameOver || !_started) return;

    setState(() {
      _timeRemaining -= dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _gameOver = true;
        return;
      }

      // Cross-section completion celebration
      if (_completeAge >= 0) {
        _completeAge += dt;
        if (_completeAge > 1.2) {
          _completeAge = -1;
          _filled.clear();
          _fillAnims.clear();
          _round = (_round + 1) % _kOrganNames.length;
          _buildPieces();
        }
      }

      // Fill animations
      for (final f in _fillAnims) {
        f.age += dt;
      }

      // Particles
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 150 * dt;
        p.life -= dt;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // Popups
      for (final p in _pops) {
        p.age += dt;
        p.y -= 30 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.5);

      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt).clamp(0.0, 1.0);
    });
  }

  // ---- zone hit test -------------------------------------------------------

  _TissueZone? _hitZone(Offset pos) {
    final dx = pos.dx - _center.dx;
    final dy = pos.dy - _center.dy;
    final frac = sqrt(dx * dx + dy * dy) / _radius;
    for (final z in _TissueZone.values) {
      final info = _kZones[z]!;
      if (frac >= info.innerFrac && frac <= info.outerFrac) return z;
    }
    return null;
  }

  // ---- input ---------------------------------------------------------------

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
    if (_completeAge >= 0) return;

    double best = double.infinity;
    int bestI = -1;
    for (int i = 0; i < _pieces.length; i++) {
      final p = _pieces[i];
      final d = sqrt(pow(pos.dx - p.x, 2) + pow(pos.dy - p.y, 2));
      if (d < 50 && d < best) {
        best = d;
        bestI = i;
      }
    }
    if (bestI >= 0) _dragIndex = bestI;
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex != null && _dragIndex! < _pieces.length) {
      _pieces[_dragIndex!].x = pos.dx;
      _pieces[_dragIndex!].y = pos.dy;
      _hoveredZone = _hitZone(pos);
    }
  }

  void _onPanEnd() {
    if (_dragIndex == null || _dragIndex! >= _pieces.length) return;
    final piece = _pieces[_dragIndex!];
    _hoveredZone = null;
    final zone = _hitZone(Offset(piece.x, piece.y));

    if (zone != null && !_filled.contains(zone)) {
      if (zone == piece.zone) {
        // ---- correct placement ----
        _filled.add(zone);
        _fillAnims.add(_ZoneFill(zone));
        _combo++;
        final pts = 10 + _combo * 5;
        _score += pts;

        final info = _kZones[zone]!;
        final midR = (info.innerFrac + info.outerFrac) / 2 * _radius;
        for (int i = 0; i < 20; i++) {
          final a = _rng.nextDouble() * 2 * pi;
          _fx.add(_FxDot(
            x: _center.dx + cos(a) * midR,
            y: _center.dy + sin(a) * midR,
            vx: (_rng.nextDouble() - 0.5) * 140,
            vy: -_rng.nextDouble() * 100 - 40,
            life: 0.4 + _rng.nextDouble() * 0.5,
            color: info.color,
            size: 3 + _rng.nextDouble() * 4,
          ));
        }
        _pops.add(_Popup(piece.x, piece.y - 20, '+$pts', info.color));
        _pieces.removeAt(_dragIndex!);
        _dragIndex = null;

        // Check if cross-section is complete
        if (_filled.length == _TissueZone.values.length) {
          _sectionsCompleted++;
          final bonus = 50 + _sectionsCompleted * 10;
          _score += bonus;
          _completeAge = 0;
          _pops.add(_Popup(
            _center.dx,
            _center.dy - 30,
            '${_kOrganNames[_round]} +$bonus',
            Colors.white,
          ));
          for (int i = 0; i < 35; i++) {
            final a = _rng.nextDouble() * 2 * pi;
            final spd = 80 + _rng.nextDouble() * 180;
            _fx.add(_FxDot(
              x: _center.dx,
              y: _center.dy,
              vx: cos(a) * spd,
              vy: sin(a) * spd - 40,
              life: 0.6 + _rng.nextDouble() * 0.6,
              color: _kZones[_TissueZone.values[_rng.nextInt(4)]]!.color,
              size: 3 + _rng.nextDouble() * 5,
            ));
          }
        }
      } else {
        // ---- wrong zone ----
        _combo = 0;
        _lives--;
        _timeRemaining = (_timeRemaining - 5).clamp(0.0, 90.0);
        _wrongFlash = 0.25;
        _pops.add(
            _Popup(piece.x, piece.y - 20, '-5s', const Color(0xFFFF5252)));
        _returnPieces();
        _dragIndex = null;
        if (_lives <= 0) _gameOver = true;
      }
    } else {
      // Dropped outside or on already-filled zone — return
      _returnPieces();
      _dragIndex = null;
    }
  }

  void _returnPieces() {
    final n = _pieces.length;
    for (int i = 0; i < n; i++) {
      _pieces[i].x = _sz.width / 2 + (i - (n - 1) / 2.0) * 90;
      _pieces[i].y = _sz.height * 0.82;
    }
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        onTapDown: (d) {
          if (_gameOver || !_started) _onPanStart(d.localPosition);
        },
        child: ClipRect(
          child: CustomPaint(
            painter: _CrossSectionPainter(
              filled: Set.of(_filled),
              fillAnims: List.of(_fillAnims),
              pieces: List.of(_pieces),
              dragIndex: _dragIndex,
              hoveredZone: _hoveredZone,
              center: _center,
              radius: _radius,
              timeRemaining: _timeRemaining,
              score: _score,
              lives: _lives,
              combo: _combo,
              round: _round,
              sectionsCompleted: _sectionsCompleted,
              completeAge: _completeAge,
              particles: List.of(_fx),
              popups: List.of(_pops),
              wrongFlash: _wrongFlash,
              gameOver: _gameOver,
              started: _started,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter ---------------------------------------------------------------

class _CrossSectionPainter extends CustomPainter {
  final Set<_TissueZone> filled;
  final List<_ZoneFill> fillAnims;
  final List<_DragPiece> pieces;
  final int? dragIndex;
  final _TissueZone? hoveredZone;
  final Offset center;
  final double radius;
  final double timeRemaining;
  final int score;
  final int lives;
  final int combo;
  final int round;
  final int sectionsCompleted;
  final double completeAge;
  final List<_FxDot> particles;
  final List<_Popup> popups;
  final double wrongFlash;
  final bool gameOver;
  final bool started;

  _CrossSectionPainter({
    required this.filled,
    required this.fillAnims,
    required this.pieces,
    required this.dragIndex,
    required this.hoveredZone,
    required this.center,
    required this.radius,
    required this.timeRemaining,
    required this.score,
    required this.lives,
    required this.combo,
    required this.round,
    required this.sectionsCompleted,
    required this.completeAge,
    required this.particles,
    required this.popups,
    required this.wrongFlash,
    required this.gameOver,
    required this.started,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF070714));

    // Wrong-placement flash
    if (wrongFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 23, 68, wrongFlash * 0.15));
    }

    if (!started && !gameOver) {
      _drawPreGame(canvas, size);
      return;
    }

    _drawCrossSection(canvas, size);
    _drawPieces(canvas);
    _drawParticles(canvas);
    _drawPopups(canvas);
    _drawHud(canvas, size);

    if (gameOver) _drawGameOver(canvas, size);
  }

  // ---- cross-section -------------------------------------------------------

  void _drawCrossSection(Canvas canvas, Size size) {
    // Microscope field ring
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Subtle lens vignette
    canvas.drawCircle(
      center,
      radius + 20,
      Paint()
        ..shader = ui.Gradient.radial(center, radius + 20, [
          Colors.transparent,
          Colors.transparent,
          const Color(0x10FFFFFF),
          Colors.transparent,
        ], [
          0.0,
          0.82,
          0.92,
          1.0
        ]),
    );

    // Zones — draw outside-in so inner rings paint on top
    final order = [
      _TissueZone.epidermis,
      _TissueZone.cortex,
      _TissueZone.vascular,
      _TissueZone.pith,
    ];

    for (final zone in order) {
      final info = _kZones[zone]!;
      final outerR = radius * info.outerFrac;
      final innerR = radius * info.innerFrac;
      final isFilled = filled.contains(zone);
      final isHovered = hoveredZone == zone && !isFilled;

      if (isFilled) {
        _drawFilledZone(canvas, zone, info, innerR, outerR);
      } else {
        _drawEmptyZone(canvas, zone, info, innerR, outerR, isHovered);
      }
    }

    // Completion celebration glow
    if (completeAge >= 0 && completeAge < 1.2) {
      final a = sin(completeAge / 1.2 * pi) * 0.25;
      canvas.drawCircle(
        center,
        radius * (1.0 + completeAge * 0.08),
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    // Organ label
    if (started) {
      final tp = TextPainter(
        text: TextSpan(
          text: _kOrganNames[round],
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(center.dx - tp.width / 2, center.dy - radius - 28));
    }
  }

  void _drawFilledZone(Canvas canvas, _TissueZone zone, _ZoneInfo info,
      double innerR, double outerR) {
    final anim = fillAnims.firstWhere((f) => f.zone == zone,
        orElse: () => _ZoneFill(zone)..age = 10);
    final fillAlpha =
        anim.age < 0.4 ? (anim.age / 0.4).clamp(0.0, 1.0) : 1.0;
    final pulse =
        anim.age < 0.6 ? sin(anim.age / 0.6 * pi) * 0.2 : 0.0;

    // Ring fill
    if (innerR > 0) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outerR))
        ..addOval(Rect.fromCircle(center: center, radius: innerR));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color =
              info.color.withValues(alpha: (0.32 + pulse) * fillAlpha),
      );
    } else {
      canvas.drawCircle(
        center,
        outerR,
        Paint()
          ..color =
              info.color.withValues(alpha: (0.32 + pulse) * fillAlpha),
      );
    }

    // Cell-like dots (organic texture)
    final midR = (innerR + outerR) / 2;
    final dotCount = zone == _TissueZone.pith ? 6 : 12;
    final dotR = (outerR - innerR) * 0.07;
    for (int i = 0; i < dotCount; i++) {
      final a = (i / dotCount) * 2 * pi + zone.index * 1.5;
      final r = midR + (outerR - innerR) * 0.25 * sin(i * 3.7);
      canvas.drawCircle(
        Offset(center.dx + cos(a) * r, center.dy + sin(a) * r),
        dotR,
        Paint()..color = info.color.withValues(alpha: 0.14 * fillAlpha),
      );
    }

    // Second layer of smaller dots offset for density
    for (int i = 0; i < dotCount; i++) {
      final a = (i / dotCount) * 2 * pi + zone.index * 1.5 + 0.3;
      final r = midR + (outerR - innerR) * 0.15 * cos(i * 2.3);
      canvas.drawCircle(
        Offset(center.dx + cos(a) * r, center.dy + sin(a) * r),
        dotR * 0.7,
        Paint()..color = info.color.withValues(alpha: 0.10 * fillAlpha),
      );
    }

    // Ring border
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..color = info.color.withValues(alpha: 0.45 * fillAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    if (innerR > 0) {
      canvas.drawCircle(
        center,
        innerR,
        Paint()
          ..color = info.color.withValues(alpha: 0.25 * fillAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Zone name inside filled ring
    final labelR = (innerR + outerR) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: info.label,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: info.color.withValues(alpha: 0.55 * fillAlpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - labelR - tp.height / 2));
  }

  void _drawEmptyZone(Canvas canvas, _TissueZone zone, _ZoneInfo info,
      double innerR, double outerR, bool isHovered) {
    final alpha = isHovered ? 0.35 : 0.10;

    // Dashed ring outlines
    _drawDashedCircle(
        canvas, center, outerR, info.color.withValues(alpha: alpha));
    if (innerR > 0) {
      _drawDashedCircle(
          canvas, center, innerR, info.color.withValues(alpha: alpha * 0.7));
    }

    // Hover fill
    if (isHovered) {
      if (innerR > 0) {
        final path = Path()
          ..addOval(Rect.fromCircle(center: center, radius: outerR))
          ..addOval(Rect.fromCircle(center: center, radius: innerR));
        path.fillType = PathFillType.evenOdd;
        canvas.drawPath(
            path, Paint()..color = info.color.withValues(alpha: 0.06));
      } else {
        canvas.drawCircle(
            center, outerR, Paint()..color = info.color.withValues(alpha: 0.06));
      }
    }

    // Label at top of ring
    final labelR = (innerR + outerR) / 2;
    final tp = TextPainter(
      text: TextSpan(
        text: info.label,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 11,
          fontWeight: FontWeight.w300,
          color: info.color.withValues(alpha: isHovered ? 0.55 : 0.22),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - labelR - tp.height / 2));
  }

  void _drawDashedCircle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const segments = 36;
    const gapFrac = 0.4;
    for (int i = 0; i < segments; i++) {
      final startA = i / segments * 2 * pi;
      final sweep = (1 - gapFrac) / segments * 2 * pi;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), startA, sweep, false, paint);
    }
  }

  // ---- pieces at bottom ----------------------------------------------------

  void _drawPieces(Canvas canvas) {
    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final info = _kZones[p.zone]!;
      final isDragging = i == dragIndex;
      const chipW = 76.0;
      const chipH = 34.0;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(p.x, p.y), width: chipW, height: chipH),
        const Radius.circular(8),
      );

      // Drag glow
      if (isDragging) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(p.x, p.y),
                width: chipW + 14,
                height: chipH + 14),
            const Radius.circular(15),
          ),
          Paint()..color = info.color.withValues(alpha: 0.18),
        );
      }

      // Chip fill
      canvas.drawRRect(
          rect,
          Paint()
            ..color = info.color.withValues(alpha: isDragging ? 0.7 : 0.45));

      // Chip border
      canvas.drawRRect(
        rect,
        Paint()
          ..color = info.color.withValues(alpha: isDragging ? 0.9 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: info.label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                Colors.white.withValues(alpha: isDragging ? 0.95 : 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }
  }

  // ---- effects -------------------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final a = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * a,
        Paint()..color = p.color.withValues(alpha: a),
      );
    }
  }

  void _drawPopups(Canvas canvas) {
    for (final p in popups) {
      final a = (1 - p.age / 1.5).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 16 + p.age * 2,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: a),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Lives — top-left
    for (int i = 0; i < 3; i++) {
      final cx = 20.0 + i * 20.0;
      if (i < lives) {
        canvas.drawCircle(
            Offset(cx, 20), 6, Paint()..color = const Color(0xFF4CAF50));
      } else {
        canvas.drawCircle(
          Offset(cx, 20),
          6,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Timer — top-right
    final timeTp = TextPainter(
      text: TextSpan(
        text: '${timeRemaining.toInt()}s',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white
              .withValues(alpha: timeRemaining < 15 ? 0.8 : 0.5),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timeTp.paint(canvas, Offset(size.width - timeTp.width - 16, 14));

    // Score — bottom center
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas,
        Offset((size.width - scoreTp.width) / 2, size.height - 40));

    // Combo
    if (combo > 1) {
      final comboTp = TextPainter(
        text: TextSpan(
          text: 'x$combo',
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFB74D),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      comboTp.paint(canvas,
          Offset(size.width - comboTp.width - 16, size.height - 40));
    }

    // Sections completed count — bottom-left
    if (sectionsCompleted > 0) {
      final secTp = TextPainter(
        text: TextSpan(
          text: '\u00D7$sectionsCompleted',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      secTp.paint(canvas, Offset(16, size.height - 36));
    }
  }

  // ---- screens -------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    _txt(canvas, size, 'Layer Builder', 26, Colors.white54, -50);
    _txt(canvas, size, 'Drag tissues into the correct', 13, Colors.white24, -8);
    _txt(canvas, size, 'zone of the plant cross-section', 13, Colors.white24,
        10);
    _txt(canvas, size, 'Tap to start', 13, Colors.white24, 46);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.8));
    _txt(canvas, size, 'GAME OVER', 34, Colors.white54, -50);
    _txt(canvas, size, '$score', 48, Colors.white70, 5);
    _txt(canvas, size, '$sectionsCompleted cross-sections completed', 13,
        Colors.white38, 55);
    _txt(canvas, size, 'Tap to restart', 13, Colors.white24, 80);
  }

  void _txt(Canvas canvas, Size size, String text, double fontSize,
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
  bool shouldRepaint(covariant _CrossSectionPainter old) => true;
}
