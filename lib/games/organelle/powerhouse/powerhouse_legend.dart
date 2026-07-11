import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Visual manual for POWERHOUSE — three cards, one per respiration stage, each
/// drawn with the SAME components the live game uses. Static + cheap: rendered
/// once in the intro carousel, never per frame. Every painter guards degenerate
/// sizes so it can never emit NaN / trigger the black-screen clamp bug.
/// ═══════════════════════════════════════════════════════════════════════════

const Color _kAccent = Color(0xFFE16416); // mitochondrion body (spec.accent)
const Color _kGlucose = Color(0xFF66BB6A);
const Color _kOxygen = Color(0xFF42A5F5);
const Color _kKrebs = Color(0xFF7E57C2);

void _housing(Canvas canvas, Offset center, double r) {
  final bodyRect = Rect.fromCircle(center: center, radius: r + 8);
  canvas.drawOval(
    bodyRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Color.lerp(_kAccent, Colors.white, 0.22)!,
          Color.lerp(_kAccent, Colors.black, 0.30)!,
          Color.lerp(_kAccent, Colors.black, 0.62)!,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(bodyRect),
  );
  canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Color.lerp(_kAccent, Colors.black, 0.35)!
            .withValues(alpha: 0.7));
  canvas.drawCircle(
      center, r - 2, Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.55));
}

void _carbonChain(Canvas canvas, Offset at, int n, double rad, Color c) {
  final spacing = rad * 1.7;
  final startX = at.dx - spacing * (n - 1) / 2;
  for (int i = 0; i < n; i++) {
    GameFx.orb(canvas, Offset(startX + i * spacing, at.dy), rad, c, glow: 0.8);
  }
  for (int i = 0; i < n - 1; i++) {
    canvas.drawLine(
        Offset(startX + i * spacing, at.dy),
        Offset(startX + (i + 1) * spacing, at.dy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 2);
  }
}

// ── Frame 1 — GLYCOLYSIS: split the sliding glucose at the cut line ──────────
void _legendGlycolysis(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final center = Offset(w * 0.5, h * 0.46);
  final r = math.min(w * 0.28, 78.0);
  _housing(canvas, center, r);

  final trackHalf = r * 0.78;
  canvas.drawLine(
      Offset(center.dx - trackHalf, center.dy),
      Offset(center.dx + trackHalf, center.dy),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
  // Cut line + window.
  canvas.drawRect(
      Rect.fromCenter(
          center: center, width: trackHalf * 0.36, height: r * 1.0),
      Paint()..color = _kGlucose.withValues(alpha: 0.12));
  canvas.drawLine(
      Offset(center.dx, center.dy - r * 0.5),
      Offset(center.dx, center.dy + r * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2);
  _carbonChain(canvas, center, 6, r * 0.14, _kGlucose);

  GameFx.text(canvas, 'C₆ → 2 × C₃', Offset(center.dx, center.dy + r * 0.66), 11,
      _kGlucose, weight: FontWeight.w700);
  GameFx.text(canvas, 'TAP when it hits the CENTER line',
      Offset(center.dx, h * 0.88), 11, Potatuhs.textSecondary,
      weight: FontWeight.w800);
}

// ── Frame 2 — KREBS: hit the marker through each gate on the turning ring ────
void _legendKrebs(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final center = Offset(w * 0.5, h * 0.46);
  final r = math.min(w * 0.28, 78.0);
  _housing(canvas, center, r);

  final ringR = r * 0.78;
  canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = _kKrebs.withValues(alpha: 0.22));
  // Three gates, one already hit (gold).
  const gates = [0.0, 2.1, 4.2];
  for (int i = 0; i < gates.length; i++) {
    final gp = Offset(center.dx + math.cos(gates[i] - math.pi / 2) * ringR,
        center.dy + math.sin(gates[i] - math.pi / 2) * ringR);
    GameFx.orb(canvas, gp, r * 0.11, i == 0 ? Potatuhs.gold : _kKrebs, glow: 0.9);
  }
  // Marker.
  const mAng = 1.0 - math.pi / 2;
  final mp = Offset(
      center.dx + math.cos(mAng) * ringR, center.dy + math.sin(mAng) * ringR);
  GameFx.orb(canvas, mp, r * 0.08, Colors.white, glow: 1.0);

  GameFx.text(canvas, 'CO₂ + NADH', Offset(center.dx, center.dy), 11,
      _kKrebs.withValues(alpha: 0.9), weight: FontWeight.w700);
  GameFx.text(canvas, 'TAP the marker through each GATE',
      Offset(center.dx, h * 0.88), 11, Potatuhs.textSecondary,
      weight: FontWeight.w800);
}

// ── Frame 3 — ELECTRON TRANSPORT: pump H⁺, then release the rotor in-zone ────
void _legendEtc(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w <= 0 || h <= 0) return;
  final center = Offset(w * 0.5, h * 0.44);
  final r = math.min(w * 0.28, 78.0);
  _housing(canvas, center, r);

  // Two pumps.
  for (final side in [-1.0, 1.0]) {
    final at = Offset(center.dx + side * r * 0.62, center.dy);
    GameFx.orb(canvas, at, r * 0.2, _kOxygen, glow: 0.9);
    canvas.drawLine(
        Offset(at.dx, at.dy - r * 0.1),
        Offset(at.dx, at.dy + r * 0.1),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = 3);
  }

  // Rotor with green release zone at top.
  final rr = r * 0.34;
  canvas.drawArc(
      Rect.fromCircle(center: center, radius: rr),
      -math.pi / 2 - 0.45,
      0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF66E0A3).withValues(alpha: 0.8));
  GameFx.orb(canvas, center, rr * 0.35, Potatuhs.gold, glow: 1.0);
  final tip = Offset(center.dx, center.dy - rr);
  canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
  GameFx.orb(canvas, tip, rr * 0.16, Colors.white, glow: 1.0);

  // Label the two pumps so the LEFT/RIGHT alternation reads at a glance.
  GameFx.text(canvas, 'LEFT', Offset(center.dx - r * 0.62, center.dy + r * 0.34),
      9, Colors.white.withValues(alpha: 0.7), weight: FontWeight.w800);
  GameFx.text(canvas, 'RIGHT', Offset(center.dx + r * 0.62, center.dy + r * 0.34),
      9, Colors.white.withValues(alpha: 0.7), weight: FontWeight.w800);
  GameFx.text(canvas, 'ALTERNATE L/R, then TAP in the GREEN',
      Offset(center.dx, h * 0.88), 11, Potatuhs.textSecondary,
      weight: FontWeight.w800);
}

/// The visual manual for Powerhouse — wired into the registry spec. Each card
/// teaches ONE of the three inputs (split / cycle / pump+release) using the same
/// components the live game draws, so the intro maps 1:1 to play.
final List<LegendFrame> powerhouseLegendFrames = [
  const LegendFrame(
      caption:
          'RUSH TO STACK ATP · Stage 1 GLYCOLYSIS — TAP when the glucose (C₆) is on the centre line to SPLIT it into two pyruvate (C₃)',
      paint: _legendGlycolysis),
  const LegendFrame(
      caption:
          'Stage 2 KREBS — TAP the sweeping marker through each lit GATE (CO₂ out, NADH in) to complete the turn',
      paint: _legendKrebs),
  const LegendFrame(
      caption:
          'Stage 3 ELECTRON TRANSPORT — alternate-TAP the LEFT/RIGHT pumps to charge H⁺, then TAP to RELEASE the rotor in the green zone (the big ATP payoff)',
      paint: _legendEtc),
];
