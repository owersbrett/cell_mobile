import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../potato.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards for STOCK IT.
//
// Every card is drawn from the SAME components the live game uses: the stock
// chart panel, the green HEALTHY band, the red STOCKOUT floor, the moving stock
// line, and the lead-time pipeline crates. No abstract diagrams — the player
// sees the literal surfaces they will meet in play.
//
// Cheap + static: they render once in the intro carousel, never per frame.
// Palette is the game's own (green 0xFF66BB6A / red 0xFFEF5350, reused verbatim
// from the live chart) plus lib/theme/potatuhs.dart — no new hex introduced.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kLegendGood = Color(0xFF66BB6A); // healthy — matches the live chart
const Color _kLegendBad = Color(0xFFEF5350); // stockout / overstock red

// ── Shared drawing kit (mirrors _StockChartPainter) ─────────────────────────

/// Draws the chart panel + the green HEALTHY band + the red STOCKOUT floor into
/// [r], exactly like the live chart. Fractions: 0 = empty shelf, 1 = panel top.
void _legendChartBase(Canvas canvas, Rect r,
    {double bandLow = 0.34, double bandHigh = 0.66, bool labels = true}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Potatuhs.inkPanel.withValues(alpha: 0.92),
          Potatuhs.inkDeep.withValues(alpha: 0.96),
        ],
      ).createShader(r),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Potatuhs.airForce.withValues(alpha: 0.30),
  );

  canvas.save();
  canvas.clipRRect(rr);
  double y(double f) => r.bottom - f.clamp(0.0, 1.0) * r.height;

  // Healthy band (shaded + dashed edges).
  canvas.drawRect(
    Rect.fromLTRB(r.left, y(bandHigh), r.right, y(bandLow)),
    Paint()..color = _kLegendGood.withValues(alpha: 0.12),
  );
  _legendDash(canvas, Offset(r.left, y(bandHigh)), Offset(r.right, y(bandHigh)),
      _kLegendGood.withValues(alpha: 0.55));
  _legendDash(canvas, Offset(r.left, y(bandLow)), Offset(r.right, y(bandLow)),
      _kLegendGood.withValues(alpha: 0.55));

  // Stockout floor (red, near the bottom).
  _legendDash(canvas, Offset(r.left, y(0.04)), Offset(r.right, y(0.04)),
      _kLegendBad.withValues(alpha: 0.6));
  canvas.restore();

  if (labels) {
    GameFx.text(canvas, 'HEALTHY', Offset(r.left + 32, y(bandHigh) + 8), 8,
        _kLegendGood.withValues(alpha: 0.85));
    GameFx.text(canvas, 'STOCKOUT', Offset(r.left + 36, y(0.04) - 8), 8,
        _kLegendBad.withValues(alpha: 0.85));
  }
}

/// Plots a stock line from normalised y-fractions across [r] (glow + core +
/// tip dot), the same treatment the live stock line gets.
void _legendLine(Canvas canvas, Rect r, List<double> fs, Color col,
    {double width = 2.6}) {
  if (fs.length < 2) return;
  double y(double f) => r.bottom - f.clamp(0.0, 1.0) * r.height;
  double x(int i) => r.left + i / (fs.length - 1) * r.width;
  final path = Path();
  for (var i = 0; i < fs.length; i++) {
    i == 0 ? path.moveTo(x(i), y(fs[i])) : path.lineTo(x(i), y(fs[i]));
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = col.withValues(alpha: 0.30)
      ..strokeWidth = width + 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = col
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawCircle(
      Offset(x(fs.length - 1), y(fs.last)), 3.4, Paint()..color = col);
}

void _legendDash(Canvas canvas, Offset a, Offset b, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1.0;
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  for (double d = 0; d < total; d += 10) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
  }
}

/// A pipeline crate (an airForce box with a potato poking out) — the same
/// object the live game shows as an incoming shipment chip.
void _legendCrate(Canvas canvas, Offset c, double s, {double alpha = 1.0}) {
  final rect = Rect.fromCenter(center: c, width: s, height: s * 0.82);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
  canvas.drawRRect(
      rr, Paint()..color = Potatuhs.airForce.withValues(alpha: 0.18 * alpha));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Potatuhs.airForce.withValues(alpha: 0.72 * alpha),
  );
  PotatoArt.paint(
    canvas,
    center: c.translate(0, -s * 0.06),
    rx: s * 0.30,
    ry: s * 0.24,
    seed: c.dx,
    color: Potatuhs.copper.withValues(alpha: alpha),
    eyes: false,
  );
}

// ── Frame 1: the core loop — keep stock in the band ─────────────────────────

void _legendBand(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.16,
      size.width * 0.84, size.height * 0.60);
  _legendChartBase(canvas, r);
  // Faint demand wobble (gold), like the live chart.
  _legendLine(canvas, r, const [0.44, 0.5, 0.45, 0.51, 0.46, 0.5],
      Potatuhs.gold.withValues(alpha: 0.5),
      width: 1.4);
  // Your stock line, hugging the healthy band.
  _legendLine(
      canvas, r, const [0.52, 0.58, 0.5, 0.56, 0.5, 0.54], _kLegendGood);
}

// ── Frame 2: order ahead of the lead time ───────────────────────────────────

void _legendLeadTime(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final cy = size.height * 0.46;
  final left = size.width * 0.14;
  final right = size.width * 0.86;

  // The conveyor from ORDER to SHELF.
  final line = Paint()
    ..color = Potatuhs.airForce.withValues(alpha: 0.6)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(left, cy), Offset(right, cy), line);
  canvas.drawLine(Offset(right, cy), Offset(right - 9, cy - 6), line);
  canvas.drawLine(Offset(right, cy), Offset(right - 9, cy + 6), line);

  // Day ticks — the lead time you must order across.
  const days = 3;
  final tick = Paint()
    ..color = Potatuhs.textFaint
    ..strokeWidth = 1;
  for (var i = 1; i <= days; i++) {
    final x = left + (right - left) * i / (days + 1);
    canvas.drawLine(Offset(x, cy - 5), Offset(x, cy + 5), tick);
    GameFx.text(canvas, '+${i}d', Offset(x, cy + 16), 8, Potatuhs.textFaint);
  }

  // Endpoints.
  GameFx.text(canvas, 'ORDER', Offset(left, cy - 20), 10, Potatuhs.gold,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'SHELF', Offset(right, cy - 20), 10, _kLegendGood,
      weight: FontWeight.w800);

  // A crate in transit — it lands only after the lead time.
  final crateS = size.width * 0.15;
  _legendCrate(canvas,
      Offset(left + (right - left) * 2 / (days + 1), cy - crateS * 0.55),
      crateS);
  // A faded crate just leaving the order desk.
  _legendCrate(canvas, Offset(left + 6, cy - crateS * 0.55), crateS * 0.8,
      alpha: 0.4);
}

// ── Frame 3: both dangers — stockout AND overstock ──────────────────────────

void _legendDanger(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final gap = size.width * 0.05;
  final marginX = size.width * 0.06;
  final w = (size.width - marginX * 2 - gap) / 2;
  final top = size.height * 0.16;
  final h = size.height * 0.54;

  final r1 = Rect.fromLTWH(marginX, top, w, h);
  _legendChartBase(canvas, r1, labels: false);
  _legendLine(canvas, r1, const [0.55, 0.4, 0.22, 0.1, 0.04, 0.04], _kLegendBad);
  GameFx.text(canvas, 'STOCKOUT', Offset(r1.center.dx, r1.bottom + 14), 9,
      _kLegendBad,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'lost sales', Offset(r1.center.dx, r1.bottom + 26), 8,
      Potatuhs.textFaint);

  final r2 = Rect.fromLTWH(marginX + w + gap, top, w, h);
  _legendChartBase(canvas, r2, labels: false);
  _legendLine(
      canvas, r2, const [0.6, 0.76, 0.88, 0.95, 0.9, 0.92], Potatuhs.sienna);
  GameFx.text(canvas, 'OVERSTOCK', Offset(r2.center.dx, r2.bottom + 14), 9,
      Potatuhs.sienna,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'holding fees', Offset(r2.center.dx, r2.bottom + 26), 8,
      Potatuhs.textFaint);
}

// ── Frame 4: the escalation — the bullwhip ──────────────────────────────────

void _legendBullwhip(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.16,
      size.width * 0.84, size.height * 0.60);
  _legendChartBase(canvas, r, labels: false);
  // Demand barely wobbles (small gold line)...
  _legendLine(canvas, r, const [0.48, 0.52, 0.46, 0.5, 0.47, 0.51, 0.48],
      Potatuhs.gold.withValues(alpha: 0.6),
      width: 1.4);
  // ...but panic-ordering whips your stock band-to-band (big red swing).
  _legendLine(
      canvas, r, const [0.5, 0.9, 0.12, 0.92, 0.08, 0.85, 0.2], _kLegendBad);

  // The bullwhip badge, mirroring the live meter.
  final box = Rect.fromLTWH(r.right - 116, r.top + 6, 110, 28);
  canvas.drawRRect(
    RRect.fromRectAndRadius(box, const Radius.circular(8)),
    Paint()..color = Colors.black.withValues(alpha: 0.4),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(box, const Radius.circular(8)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kLegendBad.withValues(alpha: 0.6),
  );
  GameFx.text(canvas, 'BULLWHIP! ×3.0', box.center, 10.5, _kLegendBad,
      weight: FontWeight.w800);
}

// ── The exported manual ─────────────────────────────────────────────────────

/// The visual manual for STOCK IT — wired into the registry spec.
final List<LegendFrame> stockItLegendFrames = [
  const LegendFrame(
    caption: 'Keep your stock line inside the green HEALTHY band',
    paint: _legendBand,
  ),
  const LegendFrame(
    caption: 'Orders land AFTER a lead time — order for the future',
    paint: _legendLeadTime,
  ),
  const LegendFrame(
    caption: 'Empty shelves lose sales; hoarding stock costs fees',
    paint: _legendDanger,
  ),
  const LegendFrame(
    caption: 'Chasing spikes whips stock wild — the BULLWHIP',
    paint: _legendBullwhip,
  ),
];
