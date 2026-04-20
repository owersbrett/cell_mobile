import 'dart:math';
import 'dart:ui' as ui;

import 'package:cell_mobile/game/game_state.dart';
import 'package:flutter/material.dart';

class GameRenderer extends CustomPainter {
  final GameState gameState;
  final Size screenSize;
  final Map<int, ui.Image> organelleImages;

  GameRenderer({
    required this.gameState,
    required this.screenSize,
    required this.organelleImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cam = gameState.player.center;
    final cameraX = cam.x - size.width / 2;
    final cameraY = cam.y - size.height / 2;

    canvas.save();
    canvas.translate(-cameraX, -cameraY);

    _drawBackground(canvas, cameraX, cameraY, size);
    _drawWorldBorder(canvas);
    _drawPellets(canvas, cameraX, cameraY, size);
    _drawObstacles(canvas);
    _drawOrganellePickups(canvas);
    _drawEjectedMass(canvas);
    _drawAICells(canvas);
    _drawPlayerBlobs(canvas);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, double cx, double cy, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0A0A1A);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameState.worldWidth, gameState.worldHeight),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = 0.5;
    const gridSize = 100.0;
    final startX = ((cx / gridSize).floor() * gridSize).clamp(0.0, gameState.worldWidth);
    final endX = ((cx + size.width) / gridSize).ceil() * gridSize;
    final startY = ((cy / gridSize).floor() * gridSize).clamp(0.0, gameState.worldHeight);
    final endY = ((cy + size.height) / gridSize).ceil() * gridSize;

    for (double x = startX; x <= endX && x <= gameState.worldWidth; x += gridSize) {
      canvas.drawLine(Offset(x, startY), Offset(x, min(endY, gameState.worldHeight)), gridPaint);
    }
    for (double y = startY; y <= endY && y <= gameState.worldHeight; y += gridSize) {
      canvas.drawLine(Offset(startX, y), Offset(min(endX, gameState.worldWidth), y), gridPaint);
    }
  }

  void _drawWorldBorder(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF3A3A5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(Rect.fromLTWH(0, 0, gameState.worldWidth, gameState.worldHeight), paint);
  }

  void _drawPellets(Canvas canvas, double cx, double cy, Size size) {
    // Only draw visible pellets
    final viewRect = Rect.fromLTWH(cx - 50, cy - 50, size.width + 100, size.height + 100);

    for (final p in gameState.pellets) {
      if (!viewRect.contains(Offset(p.position.x, p.position.y))) continue;
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(p.position.x, p.position.y), p.size, paint);
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in gameState.obstacles) {
      // Spiky virus-like obstacle
      final cx = obs.position.x;
      final cy = obs.position.y;
      final r = obs.radius;

      // Core
      final corePaint = Paint()
        ..color = const Color(0xFF442222)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * 0.7, corePaint);

      // Spikes
      final spikePaint = Paint()
        ..color = const Color(0xFF883333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        canvas.drawLine(
          Offset(cx + cos(angle) * r * 0.5, cy + sin(angle) * r * 0.5),
          Offset(cx + cos(angle) * r, cy + sin(angle) * r),
          spikePaint,
        );
        // Spike tip dot
        final tipPaint = Paint()..color = const Color(0xFFAA4444);
        canvas.drawCircle(Offset(cx + cos(angle) * r, cy + sin(angle) * r), 2.5, tipPaint);
      }

      // Warning border
      final borderPaint = Paint()
        ..color = const Color(0x44FF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), r + 5, borderPaint);
    }
  }

  void _drawOrganellePickups(Canvas canvas) {
    for (final o in gameState.organellePickups) {
      final pulse = 1.0 + sin(o.pulsePhase) * 0.15;
      final r = 22.0 * pulse;

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0x4400DDFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(o.position.x, o.position.y), r + 8, glowPaint);

      // Background
      final bgPaint = Paint()
        ..color = const Color(0xFF0A1A2A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(o.position.x, o.position.y), r, bgPaint);

      // Border
      final borderPaint = Paint()
        ..color = const Color(0xFF00AAFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(o.position.x, o.position.y), r, borderPaint);

      // Organelle image
      if (organelleImages.containsKey(o.organelleIndex)) {
        final img = organelleImages[o.organelleIndex]!;
        final imgSize = r * 1.5;
        canvas.save();
        canvas.translate(o.position.x, o.position.y);
        final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        final dstRect = Rect.fromCenter(center: Offset.zero, width: imgSize, height: imgSize);
        canvas.drawImageRect(img, srcRect, dstRect, Paint());
        canvas.restore();
      }
    }
  }

  void _drawEjectedMass(Canvas canvas) {
    for (final e in gameState.ejectedMasses) {
      final alpha = (e.lifetime / 3.0).clamp(0.0, 1.0);
      final paint = Paint()..color = e.color.withValues(alpha: alpha * 0.7);
      canvas.drawCircle(Offset(e.position.x, e.position.y), 6, paint);
    }
  }

  void _drawPlayerBlobs(Canvas canvas) {
    for (final blob in gameState.player.blobs) {
      final pos = blob.position;
      final r = blob.radius;

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0x2288DD44)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(pos.x, pos.y), r + 8, glowPaint);

      // Body fill — gets more opaque as you grow
      final fillAlpha = (0.3 + blob.mass * 0.001).clamp(0.0, 0.6);
      final bodyPaint = Paint()
        ..color = Color.fromRGBO(136, 204, 51, fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pos.x, pos.y), r, bodyPaint);

      // Membrane
      final membranePaint = Paint()
        ..color = const Color(0xFFAADD44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(pos.x, pos.y), r, membranePaint);

      // Mass text
      final tp = TextPainter(
        text: TextSpan(
          text: '${blob.mass.round()}',
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Avenir'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.x - tp.width / 2, pos.y - tp.height / 2));
    }

    // Draw ability icons around the main blob
    if (gameState.player.abilities.isNotEmpty && gameState.player.blobs.isNotEmpty) {
      final mainBlob = gameState.player.blobs.first;
      final r = mainBlob.radius;
      for (int i = 0; i < gameState.player.abilities.length; i++) {
        final ability = gameState.player.abilities[i];
        final angle = -pi / 2 + i * (2 * pi / gameState.player.abilities.length);
        final ax = mainBlob.position.x + cos(angle) * (r + 18);
        final ay = mainBlob.position.y + sin(angle) * (r + 18);

        if (organelleImages.containsKey(ability.organelleIndex)) {
          final img = organelleImages[ability.organelleIndex]!;
          final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
          final dstRect = Rect.fromCenter(center: Offset(ax, ay), width: 16, height: 16);
          canvas.drawImageRect(img, srcRect, dstRect, Paint());
        } else {
          final dotPaint = Paint()..color = const Color(0xFF00AAFF);
          canvas.drawCircle(Offset(ax, ay), 4, dotPaint);
        }
      }
    }
  }

  void _drawAICells(Canvas canvas) {
    for (final ai in gameState.aiCells) {
      final pos = ai.position;
      final r = ai.radius;

      final glowPaint = Paint()
        ..color = ai.color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(pos.x, pos.y), r + 6, glowPaint);

      final fillAlpha = (0.2 + ai.mass * 0.001).clamp(0.0, 0.5);
      final bodyPaint = Paint()
        ..color = ai.color.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pos.x, pos.y), r, bodyPaint);

      final membranePaint = Paint()
        ..color = ai.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(pos.x, pos.y), r, membranePaint);

      // Mass text
      final tp = TextPainter(
        text: TextSpan(
          text: '${ai.mass.round()}',
          style: TextStyle(color: ai.color.withValues(alpha: 0.6), fontSize: 10, fontFamily: 'Avenir'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.x - tp.width / 2, pos.y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant GameRenderer oldDelegate) => true;
}
