import 'dart:ui' as ui;

import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/game/game_state.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'game_controller.dart';
import 'game_renderer.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final Ticker _ticker;
  Duration _lastTickTime = Duration.zero;

  // Joystick state
  Offset? _joystickCenter;
  Offset? _joystickKnob;
  static const double _joystickRadius = 55.0;
  static const double _joystickKnobRadius = 18.0;

  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  late final FocusNode _focusNode;

  // Pre-loaded organelle images
  final Map<int, ui.Image> _organelleImages = {};

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onGameStateChanged);
    _focusNode = FocusNode();

    _ticker = createTicker(_onTick);
    _ticker.start();

    _loadImages();
  }

  Future<void> _loadImages() async {
    for (int i = 0; i < organelles.length; i++) {
      try {
        final path = organelles[i].mainImagePath;
        final data = await rootBundle.load(path);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _organelleImages[i] = frame.image;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTickTime == Duration.zero
        ? 1.0 / 60.0
        : (elapsed - _lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;
    final clampedDt = dt.clamp(0.0, 0.05);

    // Apply keyboard direction
    _applyKeyboardInput();

    _controller.tick(clampedDt);
  }

  void _applyKeyboardInput() {
    // Only apply if no joystick active
    if (_joystickCenter != null) return;

    double dx = 0, dy = 0;
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1;
    }

    if (dx != 0 || dy != 0) {
      // Normalize diagonal so it's not faster
      final mag = dx * dx + dy * dy;
      if (mag > 1) {
        final s = 1.0 / sqrt(mag);
        dx *= s;
        dy *= s;
      }
      _controller.setJoystickDirection(Vec2(dx, dy));
    } else {
      // Only clear if no joystick either
      if (_joystickCenter == null) {
        _controller.setJoystickDirection(Vec2.zero);
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);

      // Space = dash
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _controller.dash();
      }
      // E = eject mass
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        _controller.ejectMass();
      }

      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _ticker.stop();
    _ticker.dispose();
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleJoystickStart(DragStartDetails details) {
    final pos = details.localPosition;
    setState(() {
      _joystickCenter = pos;
      _joystickKnob = pos;
    });
  }

  void _handleJoystickUpdate(DragUpdateDetails details) {
    if (_joystickCenter == null) return;
    final pos = details.localPosition;
    final delta = pos - _joystickCenter!;
    final dist = delta.distance;

    Offset knob;
    if (dist > _joystickRadius) {
      knob = _joystickCenter! +
          Offset.fromDirection(delta.direction, _joystickRadius);
    } else {
      knob = pos;
    }

    setState(() {
      _joystickKnob = knob;
    });

    final dir = knob - _joystickCenter!;
    final normalizedDist = (dir.distance / _joystickRadius).clamp(0.0, 1.0);
    if (normalizedDist > 0.1) {
      final normalized = Offset(dir.dx / dir.distance, dir.dy / dir.distance);
      _controller.setJoystickDirection(
        Vec2(normalized.dx * normalizedDist, normalized.dy * normalizedDist),
      );
    } else {
      _controller.setJoystickDirection(Vec2.zero);
    }
  }

  void _handleJoystickEnd(DragEndDetails details) {
    setState(() {
      _joystickCenter = null;
      _joystickKnob = null;
    });
    _controller.setJoystickDirection(Vec2.zero);
  }

  void _goBack() {
    context.read<NavigationBloc>().add(
          NavigateToScreen(AppScreen.cellInteractive),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final screenSize = MediaQuery.of(context).size;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: Stack(
          children: [
            // Game canvas
            GestureDetector(
              onPanStart: _handleJoystickStart,
              onPanUpdate: _handleJoystickUpdate,
              onPanEnd: _handleJoystickEnd,
              child: CustomPaint(
                painter: GameRenderer(
                  gameState: state,
                  screenSize: screenSize,
                  organelleImages: _organelleImages,
                ),
                size: screenSize,
              ),
            ),

            // HUD
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (state.player.hasDash)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x88000000),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: state.player.dashCooldown > 0
                                  ? const Color(0x44AADD44)
                                  : const Color(0xFFAADD44),
                            ),
                          ),
                          child: Text(
                            state.player.dashCooldown > 0
                                ? '${state.player.dashCooldown.toStringAsFixed(1)}s'
                                : 'DASH',
                            style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 12,
                              color: state.player.dashCooldown > 0
                                  ? const Color(0x88AADD44)
                                  : const Color(0xFFAADD44),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x88000000),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.player.totalMass.round()}',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 20,
                            color: Color(0xFFAADD44),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Joystick overlay — directional diamond style
            if (_joystickCenter != null && _joystickKnob != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DirectionalPadPainter(
                      center: _joystickCenter!,
                      knob: _joystickKnob!,
                      baseRadius: _joystickRadius,
                      knobRadius: _joystickKnobRadius,
                    ),
                  ),
                ),
              ),

            // Input hint
            if (_joystickCenter == null)
              Positioned(
                bottom: 60,
                left: 40,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x44000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Drag to move · WASD · Space=Dash · E=Eject',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 13,
                      color: Color(0x88FFFFFF),
                    ),
                  ),
                ),
              ),

            // Win overlay
            if (state.gameWon)
              Positioned.fill(
                child: Container(
                  color: const Color(0xCC000000),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cell Complete!',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 36,
                            color: Color(0xFFAADD44),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You dominated the petri dish!',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B3D7F),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              onPressed: () => _controller.restart(),
                              child: const Text('Play Again',
                                  style: TextStyle(
                                      fontFamily: 'Avenir',
                                      fontSize: 18,
                                      color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A2E),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              onPressed: _goBack,
                              child: const Text('Back to Cell',
                                  style: TextStyle(
                                      fontFamily: 'Avenir',
                                      fontSize: 18,
                                      color: Colors.white70)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Directional pad style joystick — crosshair with diamond indicators
class _DirectionalPadPainter extends CustomPainter {
  final Offset center;
  final Offset knob;
  final double baseRadius;
  final double knobRadius;

  _DirectionalPadPainter({
    required this.center,
    required this.knob,
    required this.baseRadius,
    required this.knobRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer ring — thin, subtle
    final ringPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, baseRadius, ringPaint);

    // Crosshair lines
    final crossPaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      center + Offset(0, -baseRadius * 0.7),
      center + Offset(0, baseRadius * 0.7),
      crossPaint,
    );
    canvas.drawLine(
      center + Offset(-baseRadius * 0.7, 0),
      center + Offset(baseRadius * 0.7, 0),
      crossPaint,
    );

    // Direction indicator triangles at cardinal points
    final triPaint = Paint()
      ..color = const Color(0x25FFFFFF)
      ..style = PaintingStyle.fill;
    final triSize = 6.0;
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      final tipX = center.dx + (baseRadius * 0.8) * Offset.fromDirection(angle).dx;
      final tipY = center.dy + (baseRadius * 0.8) * Offset.fromDirection(angle).dy;
      final perpX = Offset.fromDirection(angle + 3.14159 / 2).dx * triSize;
      final perpY = Offset.fromDirection(angle + 3.14159 / 2).dy * triSize;
      final baseX = center.dx + (baseRadius * 0.6) * Offset.fromDirection(angle).dx;
      final baseY = center.dy + (baseRadius * 0.6) * Offset.fromDirection(angle).dy;

      final path = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(baseX + perpX, baseY + perpY)
        ..lineTo(baseX - perpX, baseY - perpY)
        ..close();
      canvas.drawPath(path, triPaint);
    }

    // Direction line from center to knob
    final delta = knob - center;
    if (delta.distance > 3) {
      final linePaint = Paint()
        ..color = const Color(0x44E19816)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, knob, linePaint);
    }

    // Knob — small diamond shape
    final knobPaint = Paint()
      ..color = const Color(0xAAE19816)
      ..style = PaintingStyle.fill;
    final knobPath = Path()
      ..moveTo(knob.dx, knob.dy - knobRadius)
      ..lineTo(knob.dx + knobRadius * 0.7, knob.dy)
      ..lineTo(knob.dx, knob.dy + knobRadius)
      ..lineTo(knob.dx - knobRadius * 0.7, knob.dy)
      ..close();
    canvas.drawPath(knobPath, knobPaint);

    // Knob border
    final knobBorder = Paint()
      ..color = const Color(0xDDE19816)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(knobPath, knobBorder);
  }

  @override
  bool shouldRepaint(covariant _DirectionalPadPainter oldDelegate) =>
      center != oldDelegate.center || knob != oldDelegate.knob;
}
