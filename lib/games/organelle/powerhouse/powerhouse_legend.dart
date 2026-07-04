import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Visual manual for POWERHOUSE — each card drawn with the SAME components and
/// style the live game uses (double-membrane mitochondrion + wavy cristae, gold
/// pump ring, the GLU/O₂ side tanks). Static + cheap: rendered once in the intro
/// carousel, never per frame. Every painter guards degenerate sizes so it can
/// never emit NaN / trigger the black-screen clamp bug.
/// ═══════════════════════════════════════════════════════════════════════════

// The game's own palette (mirrors powerhouse_game.dart + the registry accent).
const Color _kAccent = Color(0xFFE16416); // mitochondrion body (spec.accent)
const Color _kGlucose = Color(0xFF66BB6A);
const Color _kOxygen = Color(0xFF42A5F5);
const Color _kWarn = Color(0xFFFF7043);

/// Draws the mitochondrion exactly as the live painter does — outer + inner
/// membrane, wavy cristae, and (optionally) a gold pump-progress ring / charge
/// fill. All metrics are guarded upstream by the frame's size check.
void _drawMito(
  Canvas canvas,
  Offset center,
  double rx, {
  double o2Frac = 0.6,
  double pump = 0,
  bool stalled = false,
}) {
  if (rx <= 0) return;
  final double ry = rx * 0.66;

  // Aerobic-readiness glow scales with O₂ (the game's quiet teaching cue).
  final double glowA = (0.12 + 0.30 * o2Frac).clamp(0.0, 0.7);
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 2 + 26, height: ry * 2 + 26),
    Paint()
      ..color = (stalled ? Colors.redAccent : _kAccent).withValues(alpha: glowA)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
  );

  // Body (outer membrane) — same radial gradient as the game.
  final bodyRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
  canvas.drawOval(
    bodyRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Color.lerp(_kAccent, Colors.white, 0.30)!,
          _kAccent,
          Color.lerp(_kAccent, Colors.black, 0.45)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect),
  );
  // Inner membrane line (double membrane).
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 1.7, height: ry * 1.7),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(_kAccent, Colors.black, 0.3)!.withValues(alpha: 0.7),
  );

  // Cristae (inner folds), clipped to the inner ellipse.
  canvas.save();
  canvas.clipPath(Path()
    ..addOval(
        Rect.fromCenter(center: center, width: rx * 1.66, height: ry * 1.66)));
  final foldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(_kAccent, Colors.black, 0.25)!.withValues(alpha: 0.55);
  const int folds = 4;
  for (int i = 0; i < folds; i++) {
    final fy = center.dy - ry * 0.9 + (i + 1) * (ry * 1.8 / (folds + 1));
    final path = Path()..moveTo(center.dx - rx, fy);
    const int seg = 10;
    for (int s = 1; s <= seg; s++) {
      final fx0 = center.dx - rx + (2 * rx) * s / seg;
      final wob = math.sin(s * 1.1 + i * 2) * ry * 0.12;
      path.lineTo(fx0, fy + wob);
    }
    canvas.drawPath(path, foldPaint);
  }
  // Charge fill rising with the pump (the matrix energising).
  if (pump > 0) {
    final fillH = (ry * 2) * pump.clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTRB(center.dx - rx, center.dy + ry - fillH, center.dx + rx,
          center.dy + ry),
      Paint()..color = Potatuhs.gold.withValues(alpha: 0.16 + 0.18 * pump),
    );
  }
  canvas.restore();

  // Pump progress ring.
  final ringRect =
      Rect.fromCenter(center: center, width: rx * 2 + 14, height: ry * 2 + 14);
  canvas.drawArc(ringRect, 0, 2 * math.pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.08));
  if (pump > 0) {
    canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * pump.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = Potatuhs.gold.withValues(alpha: 0.95));
  }
}

/// Draws one side tank filled to [frac], mirroring the game's `_drawTank`.
void _drawTank(Canvas canvas, Rect r, double frac, Color color, String label,
    {int? cap}) {
  if (r.width <= 0 || r.height <= 0) return;
  final f = frac.clamp(0.0, 1.0);
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
  canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.06));
  final fillTop = r.bottom - r.height * f;
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.drawRect(Rect.fromLTRB(r.left, fillTop, r.right, r.bottom),
      Paint()..color = color.withValues(alpha: 0.85));
  if (cap != null && cap > 0) {
    final seg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.25);
    for (int i = 1; i < cap; i++) {
      final y = r.bottom - r.height * (i / cap);
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), seg);
    }
  }
  canvas.restore();
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: 0.7));
  GameFx.text(canvas, label, Offset(r.center.dx, r.top - 11), 10,
      color.withValues(alpha: 0.9),
      weight: FontWeight.w800);
}

// ── Frame 1 — the core object + verb: feed the tanks, tap the mitochondrion ──
void _legendCore(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final center = Offset(w * 0.5, h * 0.46);
  final rx = math.min(w * 0.24, 74.0);

  // Side tanks (green glucose left, blue oxygen right).
  final th = h * 0.5;
  final ty = h * 0.22;
  _drawTank(canvas, Rect.fromLTWH(w * 0.06, ty, 18, th), 0.6, _kGlucose, 'GLU',
      cap: 4);
  _drawTank(canvas, Rect.fromLTWH(w * 0.94 - 18, ty, 18, th), 0.65, _kOxygen,
      'O₂');

  _drawMito(canvas, center, rx, o2Frac: 0.65, pump: 0.5);

  // Tap cue on the organelle.
  final tp = center.translate(rx * 0.35, rx * 0.2);
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.85);
  canvas.drawCircle(tp, 12, ring);
  canvas.drawCircle(tp, 3.2, Paint()..color = Colors.white.withValues(alpha: 0.9));

  GameFx.text(canvas, 'TAP TO RESPIRE', Offset(center.dx, h * 0.86), 11,
      Potatuhs.textSecondary,
      weight: FontWeight.w800);
}

// ── Frame 2 — how to score: oxygen on hand sets the ATP yield ────────────────
void _legendYield(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final rx = math.min(w * 0.17, 52.0);
  final cyc = h * 0.42;

  // Left: full O₂ → aerobic, big gold payoff.
  final lx = w * 0.28;
  _drawMito(canvas, Offset(lx, cyc), rx, o2Frac: 1.0, pump: 1.0);
  GameFx.text(canvas, '+36 ATP', Offset(lx, cyc - rx - 22), 15, Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.5);
  GameFx.text(canvas, 'FULL O₂ · AEROBIC', Offset(lx, h * 0.82), 10, _kOxygen,
      weight: FontWeight.w700);

  // Right: no O₂ → anaerobic, tiny payoff.
  final rxc = w * 0.72;
  _drawMito(canvas, Offset(rxc, cyc), rx, o2Frac: 0.0, pump: 1.0);
  GameFx.text(canvas, '+2 ATP', Offset(rxc, cyc - rx - 22), 13,
      const Color(0xFFB0A06A),
      weight: FontWeight.w800);
  GameFx.text(canvas, 'NO O₂ · ANAEROBIC', Offset(rxc, h * 0.82), 10,
      Potatuhs.textFaint,
      weight: FontWeight.w700);
}

// ── Frame 3 — the danger: overfeeding a full tank stalls production ──────────
void _legendStall(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final center = Offset(w * 0.5, h * 0.5);
  final rx = math.min(w * 0.22, 68.0);

  // A brimming (overfilled) tank beside a red, stalled organelle.
  final th = h * 0.5;
  _drawTank(canvas, Rect.fromLTWH(w * 0.08, h * 0.24, 18, th), 1.0, _kOxygen,
      'O₂');
  _drawMito(canvas, center, rx, o2Frac: 1.0, pump: 0, stalled: true);

  GameFx.text(canvas, 'OXYGEN FULL', Offset(center.dx, center.dy - rx - 26), 14,
      _kWarn,
      weight: FontWeight.w800, glow: 0.5);
  GameFx.text(canvas, 'Feeding a full tank = stall', Offset(center.dx, h * 0.88),
      11, Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

// ── Frame 4 — the escalation: oxygen leaks faster as the run goes on ─────────
void _legendDrain(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final th = h * 0.52;
  final ty = h * 0.24;
  const tw = 18.0;

  // Three tanks, draining lower left→right = time passing.
  final fracs = [0.8, 0.45, 0.15];
  final labels = ['EARLY', 'MID', 'LATE'];
  for (int i = 0; i < 3; i++) {
    final cx = w * (0.24 + i * 0.26);
    _drawTank(canvas, Rect.fromLTWH(cx - tw / 2, ty, tw, th), fracs[i], _kOxygen,
        'O₂');
    GameFx.text(canvas, labels[i], Offset(cx, ty + th + 16), 10,
        i == 2 ? _kWarn : Potatuhs.textFaint,
        weight: FontWeight.w700);
    // Down-arrow drain cue between tanks, growing = faster leak.
    if (i < 2) {
      final ax = w * (0.37 + i * 0.26);
      final ay = h * 0.5;
      final p = Paint()
        ..color = _kWarn.withValues(alpha: 0.55 + 0.35 * i)
        ..strokeWidth = 2.4 + i * 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(ax, ay - 8), Offset(ax, ay + 8), p);
      canvas.drawLine(Offset(ax - 5, ay + 3), Offset(ax, ay + 8), p);
      canvas.drawLine(Offset(ax + 5, ay + 3), Offset(ax, ay + 8), p);
    }
  }
  GameFx.text(canvas, 'O₂ leaks faster over time', Offset(w * 0.5, h * 0.9), 11,
      Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

/// The visual manual for Powerhouse — wired into the registry spec.
final List<LegendFrame> powerhouseLegendFrames = [
  const LegendFrame(
      caption: 'Feed the GLU + O₂ tanks, tap the mitochondrion to respire',
      paint: _legendCore),
  const LegendFrame(
      caption: 'Full oxygen mints +36 ATP; no oxygen = just +2',
      paint: _legendYield),
  const LegendFrame(
      caption: 'Feeding a full tank backs it up and stalls production',
      paint: _legendStall),
  const LegendFrame(
      caption: 'Oxygen leaks faster over time — keep re-feeding it',
      paint: _legendDrain),
];
