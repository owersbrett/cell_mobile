import 'dart:math';

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// COMPANION PLANTING — adjacency-puzzle garden (BioScale.farmSystem)
//
// Place crop tiles onto a garden GRID so orthogonal NEIGHBORS help, not hurt.
// Good pairings (Three Sisters: corn+beans+squash; basil/marigold near tomato)
// score and thrive; bad neighbors (fennel near almost anything; onions next to
// beans; potato beside tomato) wilt. Each placement flashes a "+helps / -hurts"
// cue so the relationships are learnable. A brief GROWTH phase after the plot
// fills rewards good layouts. Accelerate: bigger plots + more crops with
// subtler relationships.
//
// HOST owns the clock, the 3·2·1 countdown, the score HUD and the results
// screen. This widget renders ONLY the play area, runs on ONE Ticker driving a
// single CustomPainter, and gates all progress on session.isRunning.
// ============================================================================

// ---------------------------------------------------------------------------
// Crop definitions
// ---------------------------------------------------------------------------

enum _Crop {
  corn,
  bean,
  squash,
  marigold,
  tomato,
  basil,
  potato,
  onion,
  fennel,
  carrot,
  cabbage,
  lettuce,
}

/// The procedural silhouette each crop draws as. Drives [_drawCrop] so every
/// tile reads as a distinct PLANT (stalk/vine/fruit/bulb/tuber/frond/head), not
/// a lettered orb. Purely visual — never referenced by scoring or the palette.
enum _Form {
  cornStalk, // tall stalk, blade leaves, a cob + tassel
  beanVine, // climbing vine, heart leaves, hanging pods
  squashSprawl, // low broad lobed leaves + a round gourd
  flower, // marigold — layered petal bloom on a stem
  fruitBush, // tomato — bushy stem with hanging round fruit
  herb, // basil — paired ovate leaves up a stem
  tuber, // potato — leafy top + earthy tuber in the soil
  bulb, // onion — layered bulb with green shoots
  frond, // fennel — feathery umbel fronds (the loner)
  taproot, // carrot — ferny top + orange root down into soil
  leafHead, // cabbage — tight rosette of wrapped leaves
  looseLeaf, // lettuce — open ruffled rosette
}

class _CropInfo {
  final String label;
  final String glyph; // 1–2 char badge initial (kept for at-a-glance ID)
  final Color color; // signature crop colour (fruit/flower/root)
  final Color leaf; // foliage colour for this crop's greens
  final _Form form; // how it's drawn
  const _CropInfo(this.label, this.glyph, this.color, this.leaf, this.form);
}

// Foliage greens, warm and varied so beds don't read as one flat green.
const Color _leafDeep = Color(0xFF3E7D3A);
const Color _leafMid = Color(0xFF5FA24B);
const Color _leafBright = Color(0xFF8ABF5A);
const Color _leafBlue = Color(0xFF4E8C6A); // cabbage / cool greens

const Map<_Crop, _CropInfo> _kCrops = {
  _Crop.corn:
      _CropInfo('Corn', 'Co', Color(0xFFFFD54F), _leafBright, _Form.cornStalk),
  _Crop.bean:
      _CropInfo('Beans', 'Be', Color(0xFF66BB6A), _leafMid, _Form.beanVine),
  _Crop.squash: _CropInfo(
      'Squash', 'Sq', Color(0xFFFF8A65), _leafDeep, _Form.squashSprawl),
  _Crop.marigold:
      _CropInfo('Marigold', 'Mg', Color(0xFFFFB300), _leafMid, _Form.flower),
  _Crop.tomato:
      _CropInfo('Tomato', 'To', Color(0xFFEF5350), _leafDeep, _Form.fruitBush),
  _Crop.basil:
      _CropInfo('Basil', 'Ba', Color(0xFF3FB98C), _leafMid, _Form.herb),
  _Crop.potato:
      _CropInfo('Potato', 'Po', Color(0xFFC9A98F), _leafMid, _Form.tuber),
  _Crop.onion:
      _CropInfo('Onion', 'On', Color(0xFFCE93D8), _leafBright, _Form.bulb),
  _Crop.fennel:
      _CropInfo('Fennel', 'Fe', Color(0xFFC0CA33), Color(0xFF9CB84A), _Form.frond),
  _Crop.carrot:
      _CropInfo('Carrot', 'Ca', Color(0xFFFF8A26), _leafBright, _Form.taproot),
  _Crop.cabbage:
      _CropInfo('Cabbage', 'Cb', Color(0xFF6FB98C), _leafBlue, _Form.leafHead),
  _Crop.lettuce:
      _CropInfo('Lettuce', 'Le', Color(0xFF9CCC65), _leafBright, _Form.looseLeaf),
};

// Friendly companion pairs (symmetric). Real companion-planting relationships:
// nitrogen fixing, pest repulsion, shade, pollinator attraction.
const List<List<_Crop>> _kFriendPairs = [
  // Three Sisters
  [_Crop.corn, _Crop.bean],
  [_Crop.corn, _Crop.squash],
  [_Crop.bean, _Crop.squash],
  // Marigold the pest-repeller
  [_Crop.marigold, _Crop.tomato],
  [_Crop.marigold, _Crop.potato],
  [_Crop.marigold, _Crop.bean],
  [_Crop.marigold, _Crop.squash],
  // Basil + tomato (pest repel + flavour)
  [_Crop.basil, _Crop.tomato],
  // Beans fix nitrogen → feed heavy feeders
  [_Crop.bean, _Crop.cabbage],
  [_Crop.bean, _Crop.potato],
  [_Crop.potato, _Crop.corn],
  [_Crop.potato, _Crop.cabbage],
  // Carrot / onion / lettuce trio
  [_Crop.carrot, _Crop.onion],
  [_Crop.carrot, _Crop.tomato],
  [_Crop.carrot, _Crop.lettuce],
  [_Crop.onion, _Crop.cabbage],
  [_Crop.lettuce, _Crop.onion],
];

// Antagonistic pairs (symmetric). Allelopathy, shared pests, competition.
const List<List<_Crop>> _kFoePairs = [
  [_Crop.onion, _Crop.bean], // alliums inhibit legume nodulation
  [_Crop.potato, _Crop.tomato], // both nightshades — blight + beetles
  [_Crop.potato, _Crop.squash], // heavy feeders compete
  [_Crop.tomato, _Crop.corn], // shared earworm / fruitworm
  [_Crop.cabbage, _Crop.tomato],
  // Fennel — allelopathic loner, antagonises nearly everything
  [_Crop.fennel, _Crop.tomato],
  [_Crop.fennel, _Crop.bean],
  [_Crop.fennel, _Crop.corn],
  [_Crop.fennel, _Crop.carrot],
  [_Crop.fennel, _Crop.cabbage],
  [_Crop.fennel, _Crop.potato],
  [_Crop.fennel, _Crop.squash],
  [_Crop.fennel, _Crop.onion],
  [_Crop.fennel, _Crop.basil],
  [_Crop.fennel, _Crop.lettuce],
];

int _pairKey(_Crop a, _Crop b) {
  final x = a.index, y = b.index;
  return x < y ? x * 100 + y : y * 100 + x;
}

final Map<int, int> _kRelations = () {
  final m = <int, int>{};
  for (final p in _kFriendPairs) {
    m[_pairKey(p[0], p[1])] = 1;
  }
  for (final p in _kFoePairs) {
    m[_pairKey(p[0], p[1])] = -1;
  }
  return m;
}();

/// +1 = helps, -1 = hurts, 0 = neutral (same crop is neutral).
int _relation(_Crop a, _Crop b) =>
    a == b ? 0 : (_kRelations[_pairKey(a, b)] ?? 0);

// ---------------------------------------------------------------------------
// Lightweight transient objects
// ---------------------------------------------------------------------------

class _Tile {
  final _Crop crop;
  double x, y, homeX, homeY;
  _Tile(this.crop, this.x, this.y)
      : homeX = x,
        homeY = y;
}

class _Cell {
  _Crop crop;
  double age; // grow-in animation
  double thrive; // set in growth phase: >0 thrives, <0 wilts, 0 neutral
  _Cell(this.crop)
      : age = 0,
        thrive = 0;
}

class _Link {
  final Offset a, b;
  final Color color;
  double age;
  _Link(this.a, this.b, this.color) : age = 0;
}

class _Pop {
  double x, y, age;
  final String text;
  final Color color;
  _Pop(this.x, this.y, this.text, this.color) : age = 0;
}

class _Dot {
  double x, y, vx, vy, life, size;
  final Color color;
  _Dot(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color);
}

/// An expanding celebratory ring — fired when a clean friendly pairing lands,
/// so a good companion match reads as a satisfying "pop". Cosmetic only.
class _Ring {
  final double x, y;
  double age;
  final Color color;
  _Ring(this.x, this.y, this.color) : age = 0;
}

enum _Phase { placing, growth }

// ═══════════════════════════════════════════════════════════════════════════
// PROCEDURAL PLANT ART — the visual heart of the game.
//
// Every crop draws as a distinct, characterful plant grown FROM the soil: a
// stalk/vine/bush/bulb/tuber/frond with real leaves and fruit, gently swaying,
// sprouting in on placement and swelling/browning in the growth phase. No
// raster assets — pure Canvas. All paints/paths are built per call (cheap: a
// handful of fills per plant) but sway/pulse phase is derived from a shared
// clock so motion is continuous without any per-frame allocation growth.
//
// Contract: purely cosmetic. `crop`, scoring and geometry are untouched — this
// only changes how a planted/held crop LOOKS.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kHelpGreen = Color(0xFF8BE58B); // "+helps" link + thrive glow
const Color _kHurtRed = Color(0xFFFF6B6B); // "−hurts" link + wilt cue
const Color _kThriveTint = Color(0xFFB9F6CA); // healthy leaf tint (growth)
const Color _kWiltTint = Color(0xFF6D4C41); // browned wilt tint (growth)

/// A single crop leaf: a tapered blade with a centre vein, drawn from [base]
/// out to [tip] with a given [width] and [color].
void _leaf(Canvas canvas, Offset base, Offset tip, double width, Color color,
    {double curl = 0.0}) {
  final dir = tip - base;
  final len = dir.distance;
  if (len < 0.5) return;
  final ux = dir.dx / len, uy = dir.dy / len;
  final nx = -uy, ny = ux; // perpendicular
  final mid = Offset(base.dx + ux * len * 0.5 + nx * curl * len,
      base.dy + uy * len * 0.5 + ny * curl * len);
  final path = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(
        mid.dx + nx * width, mid.dy + ny * width, tip.dx, tip.dy)
    ..quadraticBezierTo(
        mid.dx - nx * width, mid.dy - ny * width, base.dx, base.dy)
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(color, Colors.white, 0.28)!, color],
      ).createShader(Rect.fromPoints(base, tip)),
  );
  // Centre vein.
  canvas.drawLine(
    base,
    Offset.lerp(base, tip, 0.9)!,
    Paint()
      ..color = Color.lerp(color, Colors.black, 0.25)!.withValues(alpha: 0.4)
      ..strokeWidth = 0.9,
  );
}

/// A soft round fruit/gourd/bulb body (mini-orb, cheaper than GameFx.orb, no
/// per-call glow) with a specular dot.
void _berry(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Color.lerp(color, Colors.white, 0.5)!,
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  canvas.drawCircle(c.translate(-r * 0.3, -r * 0.34), r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.6));
}

/// Draw crop [crop] centred at [center], sized to [scale] (roughly the plant's
/// half-height). [sway] radians drives idle motion; [sprout] 0→1 grows it in;
/// [thrive] >0 healthy-swell/glow, <0 wilt/brown. This is the ONE routine every
/// planted plant, tray tile and legend card renders through.
void _drawCrop(Canvas canvas, Offset center, _Crop crop, double scale,
    {double sway = 0, double sprout = 1, double thrive = 0}) {
  final info = _kCrops[crop]!;
  final s = scale * (0.55 + 0.45 * Curves.easeOutBack.transform(sprout.clamp(0, 1)));
  // Health response.
  var leaf = info.leaf;
  var fruit = info.color;
  double vigor = 1.0;
  if (thrive > 0) {
    vigor = 1.14;
    leaf = Color.lerp(leaf, _kThriveTint, 0.30)!;
    fruit = Color.lerp(fruit, _kThriveTint, 0.15)!;
  } else if (thrive < 0) {
    vigor = 0.8;
    leaf = Color.lerp(leaf, _kWiltTint, 0.55)!;
    fruit = Color.lerp(fruit, _kWiltTint, 0.4)!;
  }
  final h = s * vigor; // plant reach upward
  final swayX = sin(sway) * s * 0.10;

  // Soil mound the plant rises from (grounds it in the bed).
  canvas.drawOval(
    Rect.fromCenter(
        center: center.translate(0, h * 0.72), width: s * 1.7, height: s * 0.5),
    Paint()..color = const Color(0xFF2A1B13).withValues(alpha: 0.55),
  );

  final baseY = center.dy + h * 0.62; // where stems emerge from soil
  Offset stemBase = Offset(center.dx, baseY);
  Offset top = Offset(center.dx + swayX, center.dy - h * 0.7);

  void stem(Color c, double w) {
    final path = Path()
      ..moveTo(stemBase.dx - w, stemBase.dy)
      ..quadraticBezierTo(
          center.dx + swayX * 0.5, center.dy, top.dx, top.dy)
      ..quadraticBezierTo(
          center.dx + swayX * 0.5, center.dy, stemBase.dx + w, stemBase.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = c);
  }

  switch (info.form) {
    case _Form.cornStalk:
      stem(const Color(0xFF7CB342), s * 0.14);
      for (int i = 0; i < 4; i++) {
        final f = i / 3.0;
        final anchor = Offset.lerp(stemBase, top, 0.25 + f * 0.55)!;
        final side = i.isEven ? 1.0 : -1.0;
        _leaf(canvas, anchor,
            anchor.translate(side * s * (0.9 - f * 0.3), -s * (0.2 + f * 0.4)),
            s * 0.14, leaf,
            curl: side * 0.25);
      }
      // The cob.
      _berry(canvas, Offset.lerp(stemBase, top, 0.62)!.translate(s * 0.22, 0),
          s * 0.26, fruit);
      // Tassel.
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(
            top,
            top.translate(i * s * 0.16, -s * 0.28),
            Paint()
              ..color = const Color(0xFFE9C46A)
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round);
      }
      break;

    case _Form.beanVine:
      // A curling climbing vine.
      final vine = Path()..moveTo(stemBase.dx, stemBase.dy);
      for (double t = 0; t <= 1.0; t += 0.1) {
        final p = Offset.lerp(stemBase, top, t)!
            .translate(sin(t * 8 + sway) * s * 0.16, 0);
        vine.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          vine,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.1
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF6B9B3F));
      for (int i = 0; i < 4; i++) {
        final f = 0.2 + i * 0.22;
        final a = Offset.lerp(stemBase, top, f)!
            .translate(sin(f * 8 + sway) * s * 0.16, 0);
        final side = i.isEven ? 1.0 : -1.0;
        _leaf(canvas, a, a.translate(side * s * 0.55, -s * 0.3), s * 0.16, leaf);
      }
      // Hanging pods.
      for (int i = 0; i < 2; i++) {
        final a = Offset.lerp(stemBase, top, 0.5 + i * 0.25)!;
        canvas.drawLine(a, a.translate(-s * 0.1, s * 0.4),
            Paint()..color = fruit..strokeWidth = s * 0.14..strokeCap = StrokeCap.round);
      }
      break;

    case _Form.squashSprawl:
      // Low, broad sprawling lobed leaves + a gourd sitting in them.
      for (int i = 0; i < 5; i++) {
        final ang = pi + (i / 4.0) * pi; // fan across the top of soil
        final dir = Offset(cos(ang), sin(ang) * 0.7);
        final anchor = center.translate(0, h * 0.2);
        _leaf(
            canvas,
            anchor,
            anchor + dir * s * 1.05,
            s * 0.3,
            Color.lerp(leaf, Colors.black, i.isOdd ? 0.12 : 0)!,
            curl: (i - 2) * 0.12);
      }
      _berry(canvas, center.translate(swayX, h * 0.28), s * 0.42, fruit);
      // Ribs on the gourd.
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(
            center.translate(swayX + i * s * 0.14, h * 0.28 - s * 0.36),
            center.translate(swayX + i * s * 0.18, h * 0.28 + s * 0.36),
            Paint()
              ..color = Color.lerp(fruit, Colors.black, 0.3)!.withValues(alpha: 0.4)
              ..strokeWidth = 1.2);
      }
      break;

    case _Form.flower:
      stem(const Color(0xFF5FA24B), s * 0.09);
      for (int i = 0; i < 2; i++) {
        final a = Offset.lerp(stemBase, top, 0.4 + i * 0.2)!;
        final side = i.isEven ? 1.0 : -1.0;
        _leaf(canvas, a, a.translate(side * s * 0.45, -s * 0.1), s * 0.12, leaf);
      }
      // Layered petal bloom.
      final bloom = top.translate(0, -s * 0.05);
      for (int layer = 0; layer < 2; layer++) {
        final pr = s * (0.5 - layer * 0.16);
        final petalC = layer == 0
            ? fruit
            : Color.lerp(fruit, Colors.deepOrange, 0.45)!;
        const n = 8;
        for (int i = 0; i < n; i++) {
          final ang = i / n * 2 * pi + layer * 0.4 + sway * 0.3;
          _berry(canvas, bloom + Offset(cos(ang), sin(ang)) * pr * 0.7,
              pr * 0.42, petalC);
        }
      }
      _berry(canvas, bloom, s * 0.2, const Color(0xFF6D4C22));
      break;

    case _Form.fruitBush:
      stem(const Color(0xFF4E7A38), s * 0.11);
      for (int i = 0; i < 4; i++) {
        final f = 0.25 + i * 0.2;
        final a = Offset.lerp(stemBase, top, f)!;
        final side = i.isEven ? 1.0 : -1.0;
        _leaf(canvas, a, a.translate(side * s * 0.55, -s * 0.2), s * 0.14, leaf);
      }
      // Hanging tomatoes.
      _berry(canvas, center.translate(-s * 0.28 + swayX, s * 0.1), s * 0.24, fruit);
      _berry(canvas, center.translate(s * 0.3 + swayX, s * 0.28), s * 0.2, fruit);
      _berry(canvas, center.translate(swayX, h * 0.0), s * 0.26, fruit);
      break;

    case _Form.herb:
      stem(const Color(0xFF4E9C6A), s * 0.09);
      for (int i = 0; i < 3; i++) {
        final f = 0.3 + i * 0.22;
        final a = Offset.lerp(stemBase, top, f)!;
        _leaf(canvas, a, a.translate(-s * 0.5, -s * 0.18), s * 0.17, leaf);
        _leaf(canvas, a, a.translate(s * 0.5, -s * 0.18), s * 0.17, leaf);
      }
      // Top pair.
      _leaf(canvas, top, top.translate(-s * 0.28, -s * 0.4), s * 0.13, leaf);
      _leaf(canvas, top, top.translate(s * 0.28, -s * 0.4), s * 0.13, leaf);
      break;

    case _Form.tuber:
      // Earthy tuber half-buried, leafy top.
      _berry(canvas, center.translate(swayX * 0.5, h * 0.5), s * 0.44, fruit);
      // "Eyes" on the potato.
      for (int i = 0; i < 3; i++) {
        final ang = -0.6 + i * 0.6;
        canvas.drawCircle(
            center.translate(swayX * 0.5 + cos(ang) * s * 0.24,
                h * 0.5 + sin(ang) * s * 0.2),
            s * 0.05,
            Paint()..color = Color.lerp(fruit, Colors.black, 0.4)!);
      }
      for (int i = 0; i < 4; i++) {
        final side = (i - 1.5);
        final base = center.translate(swayX * 0.3, h * 0.1);
        _leaf(canvas, base,
            base.translate(side * s * 0.4, -s * (0.7 - side.abs() * 0.15)),
            s * 0.14, leaf);
      }
      break;

    case _Form.bulb:
      // Layered onion bulb with green shoots.
      final bulbC = center.translate(swayX * 0.5, h * 0.45);
      _berry(canvas, bulbC, s * 0.4, fruit);
      for (int i = -1; i <= 1; i++) {
        canvas.drawLine(
            bulbC.translate(0, -s * 0.36),
            bulbC.translate(i * s * 0.22, -s * 0.36 + s * 0.7),
            Paint()
              ..color = Color.lerp(fruit, Colors.black, 0.35)!.withValues(alpha: 0.5)
              ..strokeWidth = 1.0);
      }
      for (int i = 0; i < 4; i++) {
        final side = (i - 1.5);
        final base = bulbC.translate(0, -s * 0.34);
        _leaf(canvas, base,
            base.translate(side * s * 0.28, -s * (0.9 - side.abs() * 0.1)),
            s * 0.09, leaf);
      }
      break;

    case _Form.frond:
      // Feathery fennel — the allelopathic loner. Wispy umbel.
      const rng = 5;
      for (int i = 0; i < rng; i++) {
        final ang = -pi / 2 + (i - (rng - 1) / 2) * 0.5;
        final tip = center + Offset(cos(ang), sin(ang)) * h * 0.95 +
            Offset(swayX, 0);
        canvas.drawLine(
            stemBase, tip,
            Paint()
              ..color = leaf
              ..strokeWidth = s * 0.06
              ..strokeCap = StrokeCap.round);
        // Feather barbs.
        for (double t = 0.4; t < 1.0; t += 0.2) {
          final p = Offset.lerp(stemBase, tip, t)!;
          _leaf(canvas, p, p.translate(-s * 0.14, -s * 0.16), s * 0.05,
              Color.lerp(leaf, Colors.white, 0.15)!);
          _leaf(canvas, p, p.translate(s * 0.14, -s * 0.16), s * 0.05,
              Color.lerp(leaf, Colors.white, 0.15)!);
        }
      }
      // Yellow umbel flower dots.
      for (int i = 0; i < 5; i++) {
        final ang = -pi / 2 + (i - 2) * 0.4;
        _berry(canvas, center + Offset(cos(ang), sin(ang)) * h * 0.85,
            s * 0.08, fruit);
      }
      break;

    case _Form.taproot:
      // Orange root plunging into soil, ferny top.
      final rootTop = center.translate(swayX * 0.3, h * 0.12);
      final rootTip = center.translate(swayX * 0.1, h * 0.85);
      final rootPath = Path()
        ..moveTo(rootTop.dx - s * 0.26, rootTop.dy)
        ..quadraticBezierTo(rootTip.dx - s * 0.02, (rootTop.dy + rootTip.dy) / 2,
            rootTip.dx, rootTip.dy)
        ..quadraticBezierTo(rootTip.dx + s * 0.02, (rootTop.dy + rootTip.dy) / 2,
            rootTop.dx + s * 0.26, rootTop.dy)
        ..close();
      canvas.drawPath(
          rootPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(fruit, Colors.white, 0.25)!, fruit],
            ).createShader(Rect.fromPoints(rootTop, rootTip)));
      for (double ry = 0.3; ry < 0.9; ry += 0.2) {
        final p = Offset.lerp(rootTop, rootTip, ry)!;
        canvas.drawLine(p.translate(-s * 0.18 * (1 - ry), 0),
            p.translate(s * 0.18 * (1 - ry), 0),
            Paint()..color = Color.lerp(fruit, Colors.black, 0.3)!.withValues(alpha: 0.4)..strokeWidth = 0.8);
      }
      for (int i = 0; i < 5; i++) {
        final side = (i - 2);
        _leaf(canvas, rootTop,
            rootTop.translate(side * s * 0.28, -s * (0.85 - side.abs() * 0.12)),
            s * 0.07, leaf);
      }
      break;

    case _Form.leafHead:
      // Cabbage — tight wrapped rosette.
      final headC = center.translate(swayX * 0.4, h * 0.28);
      for (int layer = 3; layer >= 0; layer--) {
        final lr = s * (0.42 + layer * 0.13);
        final lc = Color.lerp(leaf, Colors.black, layer * 0.08)!;
        for (int i = 0; i < 6; i++) {
          final ang = i / 6 * 2 * pi + layer * 0.5;
          _berry(canvas, headC + Offset(cos(ang), sin(ang) * 0.8) * lr * 0.5,
              lr * 0.4, Color.lerp(lc, fruit, 0.3)!);
        }
      }
      _berry(canvas, headC, s * 0.34, Color.lerp(fruit, Colors.white, 0.2)!);
      break;

    case _Form.looseLeaf:
      // Lettuce — open ruffled rosette of upright leaves.
      final baseC = center.translate(swayX * 0.4, h * 0.4);
      for (int i = 0; i < 7; i++) {
        final ang = -pi / 2 + (i - 3) * 0.42;
        final tip = baseC + Offset(cos(ang), sin(ang)) * h * 0.9;
        _leaf(canvas, baseC, tip, s * 0.2,
            Color.lerp(leaf, Colors.white, (i.isEven ? 0.18 : 0.0))!,
            curl: (i - 3) * 0.06);
      }
      break;
  }

  // Thrive/wilt glow overlay (kept subtle, drawn last so it reads on top).
  if (thrive > 0) {
    canvas.drawCircle(
        center,
        s * 1.1,
        Paint()
          ..color = _kHelpGreen.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL garden
// components (the same soil beds, crop orbs and help/hurt links the live game
// renders). Static and cheap: painted once on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

/// One rounded soil bed, mirroring `_GardenPainter._drawGrid`. [tint] draws the
/// green/red/neutral hover ring; otherwise a faint white edge.
void _legendCell(Canvas canvas, Rect rect,
    {Color? tint, bool occupied = false}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));
  canvas.drawRRect(
    rr,
    Paint()
      ..color = _GardenPainter._soil.withValues(alpha: occupied ? 0.85 : 0.5),
  );
  if (tint != null) {
    canvas.drawRRect(rr, Paint()..color = tint.withValues(alpha: 0.18));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = tint.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  } else {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withValues(alpha: occupied ? 0.05 : 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// One planted crop, mirroring `_GardenPainter._drawPlants`: the real
/// procedural plant + its badge. [thrive] > 0 swells + green-glows it; < 0
/// shrinks + browns it.
void _legendPlant(Canvas canvas, Offset center, _Crop crop, double radius,
    {double thrive = 0}) {
  final info = _kCrops[crop]!;
  _drawCrop(canvas, center.translate(0, radius * 0.5), crop, radius * 1.7,
      thrive: thrive);
  // Small ID badge tucked at the base so first-timers can name the crop.
  GameFx.text(canvas, info.glyph, center.translate(0, radius * 0.95),
      radius * 0.5, Colors.white.withValues(alpha: 0.9),
      weight: FontWeight.w800, glow: 0.4);
}

/// A help/hurt relationship beam, mirroring `_GardenPainter._drawLinks`.
void _legendLink(Canvas canvas, Offset a, Offset b, Color color) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );
}

/// A small downward chevron drop cue (as in the placing preview).
void _legendDrop(Canvas canvas, Offset tip, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(tip.translate(-8, -9), tip, p);
  canvas.drawLine(tip.translate(8, -9), tip, p);
}

// Frame 1 — the verb: drag a crop tile from the tray onto an empty soil cell.
void _legendPlace(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gx = size.width / 2 - cs;
  final gy = size.height * 0.34;
  final cells = <Rect>[];
  for (int r = 0; r < 2; r++) {
    for (int c = 0; c < 2; c++) {
      cells.add(Rect.fromLTWH(gx + c * cs + 3, gy + r * cs + 3, cs - 6, cs - 6));
    }
  }
  // i0 already planted (corn); i1 is the green-tinted drop target.
  for (int i = 0; i < 4; i++) {
    _legendCell(canvas, cells[i],
        tint: i == 1 ? _kHelpGreen : null, occupied: i == 0);
  }
  _legendPlant(canvas, cells[0].center, _Crop.corn, cs * 0.30);
  // Beans tile hovering above the target, dropping in.
  final tileC = Offset(cells[1].center.dx, gy - cs * 0.62);
  _legendPlant(canvas, tileC, _Crop.bean, cs * 0.30);
  _legendDrop(canvas, Offset(cells[1].center.dx, gy - cs * 0.14),
      _kHelpGreen);
}

// Frame 2 — how to score: friendly neighbours flash a green "+helps" link.
void _legendHelps(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gy = size.height * 0.40;
  final left = Rect.fromCenter(
      center: Offset(size.width * 0.5 - cs * 0.55, gy),
      width: cs,
      height: cs);
  final right = Rect.fromCenter(
      center: Offset(size.width * 0.5 + cs * 0.55, gy),
      width: cs,
      height: cs);
  _legendCell(canvas, left, occupied: true);
  _legendCell(canvas, right, occupied: true);
  _legendLink(canvas, left.center, right.center, _kHelpGreen);
  _legendPlant(canvas, left.center, _Crop.corn, cs * 0.30);
  _legendPlant(canvas, right.center, _Crop.bean, cs * 0.30);
  GameFx.text(canvas, '+helps  +12', Offset(size.width * 0.5, gy - cs * 0.85),
      13, _kHelpGreen,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame 3 — the danger: bad neighbours flash a red "−hurts" link + break combo.
void _legendHurts(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.28).clamp(24.0, 92.0);
  final gy = size.height * 0.40;
  final left = Rect.fromCenter(
      center: Offset(size.width * 0.5 - cs * 0.55, gy),
      width: cs,
      height: cs);
  final right = Rect.fromCenter(
      center: Offset(size.width * 0.5 + cs * 0.55, gy),
      width: cs,
      height: cs);
  _legendCell(canvas, left, occupied: true);
  _legendCell(canvas, right, occupied: true);
  _legendLink(canvas, left.center, right.center, _kHurtRed);
  // Potato beside tomato — both nightshades, a classic foe pairing.
  _legendPlant(canvas, left.center, _Crop.potato, cs * 0.30, thrive: -1);
  _legendPlant(canvas, right.center, _Crop.tomato, cs * 0.30, thrive: -1);
  GameFx.text(canvas, '−hurts', Offset(size.width * 0.5, gy - cs * 0.85), 13,
      _kHurtRed,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame 4 — the payoff/twist: fill the bed foe-free for a FLAWLESS harvest.
void _legendFlawless(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cs = (min(size.width, size.height) * 0.20).clamp(18.0, 60.0);
  final gx = size.width / 2 - cs * 1.5;
  final gy = size.height * 0.24;
  // 3×3, all friend/neutral crops → every plant thrives, zero foes.
  const layout = [
    _Crop.corn, _Crop.bean, _Crop.squash, //
    _Crop.bean, _Crop.squash, _Crop.corn, //
    _Crop.marigold, _Crop.corn, _Crop.bean,
  ];
  for (int i = 0; i < 9; i++) {
    final c = i % 3, r = i ~/ 3;
    final rect = Rect.fromLTWH(gx + c * cs + 3, gy + r * cs + 3, cs - 6, cs - 6);
    _legendCell(canvas, rect, occupied: true);
    _legendPlant(canvas, rect.center, layout[i], cs * 0.30, thrive: 1);
  }
  GameFx.text(canvas, 'FLAWLESS PLOT', Offset(size.width * 0.5, gy + cs * 3.3),
      14, Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.6);
}

/// The visual manual for Companion Planting — wired into the registry spec.
final List<LegendFrame> companionPlantingLegendFrames = [
  const LegendFrame(
      caption: 'Drag crop tiles from the tray onto empty soil',
      paint: _legendPlace),
  const LegendFrame(
      caption: 'Friends touching flash green: +12 each',
      paint: _legendHelps),
  const LegendFrame(
      caption: 'Foes flash red — they wilt and break your combo',
      paint: _legendHurts),
  const LegendFrame(
      caption: 'Fill the bed foe-free for a FLAWLESS harvest bonus',
      paint: _legendFlawless),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class CompanionPlantingGame extends StatefulWidget {
  final MiniGameSession session;
  const CompanionPlantingGame({super.key, required this.session});

  @override
  State<CompanionPlantingGame> createState() => _CompanionPlantingGameState();
}

class _CompanionPlantingGameState extends State<CompanionPlantingGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final int _seed;
  late Random _rng;
  double _lastT = 0;
  double _clock = 0;

  // ---- run state ----
  int _combo = 0;
  int _plotsCompleted = 0;
  int _flawlessStreak = 0;
  int _level = 0;

  // ---- plot ----
  int _cols = 3, _rows = 3;
  List<_Cell?> _grid = [];
  List<_Crop> _palette = [];
  final List<_Tile> _hand = [];
  static const int _handSize = 5;

  // ---- phase ----
  _Phase _phase = _Phase.placing;
  double _growthAge = 0;
  bool _growthAwarded = false;

  // ---- input ----
  int? _dragIndex;
  int? _hoverCell;

  // ---- effects ----
  final List<_Link> _links = [];
  final List<_Pop> _pops = [];
  final List<_Dot> _fx = [];
  final List<_Ring> _rings = [];

  // ---- geometry ----
  Size _sz = Size.zero;
  Offset _origin = Offset.zero;
  double _cellSize = 0;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    _rng = Random(_seed);
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _startPlot();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free placement per host tick (~250ms). This plays Companion
  /// Planting *well*, not randomly: it scores every (hand-tile × empty-cell)
  /// combo with the game's OWN friend/foe rules — summing [_relation] over the
  /// occupied orthogonal neighbours ([_neighbors]) — and drops the tile into the
  /// spot with the best net benefit, always preferring a placement that creates
  /// NO foe adjacency (a foe-free spot nets ≥ 0, so whenever one exists we take
  /// it and never wilt a neighbour). Ties resolve to the first candidate in
  /// hand/grid order → fully deterministic. It calls the game's own
  /// [_placeTile]; the host owns the clock, so the round still ends on time
  /// while the bot banks real points and fills flawless plots.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.placing) return; // growth phase self-advances
    if (_hand.isEmpty) return;

    // Gather the empty cells once.
    final empties = <int>[];
    for (int i = 0; i < _grid.length; i++) {
      if (_grid[i] == null) empties.add(i);
    }
    if (empties.isEmpty) return;

    _Tile? bestTile;
    int bestCell = -1;
    int bestNet = 0;
    bool bestFoeFree = false;
    bool found = false;

    for (final tile in _hand) {
      for (final cell in empties) {
        int net = 0;
        bool foe = false;
        for (final n in _neighbors(cell)) {
          final occ = _grid[n];
          if (occ == null) continue;
          final rel = _relation(tile.crop, occ.crop);
          net += rel;
          if (rel < 0) foe = true;
        }
        final foeFree = !foe;
        // Ranking: any foe-free spot beats any spot that wilts a neighbour;
        // within the same class prefer higher net; ties keep the first seen.
        final better = !found ||
            (foeFree && !bestFoeFree) ||
            (foeFree == bestFoeFree && net > bestNet);
        if (better) {
          found = true;
          bestTile = tile;
          bestCell = cell;
          bestNet = net;
          bestFoeFree = foeFree;
        }
      }
    }

    if (bestTile == null || bestCell < 0) return;
    setState(() => _placeTile(bestTile!, bestCell));
  }

  // ---- plot setup ----------------------------------------------------------

  /// Plot dimensions per level — bigger plots as the climb continues.
  List<int> _plotForLevel(int lvl) {
    switch (lvl) {
      case 0:
        return [3, 3];
      case 1:
        return [4, 3];
      case 2:
        return [4, 4];
      case 3:
        return [4, 4];
      case 4:
        return [5, 4];
      default:
        return [5, 5];
    }
  }

  /// Crop palette per level. Early levels are all friends/neutral (pure
  /// positive feedback); foes (fennel, onion×bean, potato×tomato) enter later.
  List<_Crop> _paletteForLevel(int lvl) {
    final p = <_Crop>[_Crop.corn, _Crop.bean, _Crop.squash, _Crop.marigold];
    if (lvl >= 1) p.addAll([_Crop.tomato, _Crop.basil]);
    if (lvl >= 2) p.addAll([_Crop.potato, _Crop.onion]);
    if (lvl >= 3) p.add(_Crop.fennel);
    if (lvl >= 4) p.addAll([_Crop.carrot, _Crop.cabbage]);
    if (lvl >= 5) p.add(_Crop.lettuce);
    return p;
  }

  void _startPlot() {
    _level = _plotsCompleted.clamp(0, 6);
    final dim = _plotForLevel(_level);
    _cols = dim[0];
    _rows = dim[1];
    _grid = List<_Cell?>.filled(_cols * _rows, null);
    _palette = _paletteForLevel(_level);
    _hand.clear();
    _links.clear();
    _rings.clear();
    _phase = _Phase.placing;
    _growthAge = 0;
    _growthAwarded = false;
    _dragIndex = null;
    _hoverCell = null;
    _computeGrid();
    _refillHand();
  }

  int get _placedCount => _grid.where((c) => c != null).length;
  int get _totalCells => _cols * _rows;

  void _refillHand() {
    while (_hand.length < _handSize &&
        _placedCount + _hand.length < _totalCells) {
      _hand.add(_Tile(_palette[_rng.nextInt(_palette.length)], 0, 0));
    }
    _layoutHand();
  }

  void _computeGrid() {
    if (_sz == Size.zero) return;
    const top = 64.0;
    final trayTop = _sz.height * 0.66;
    final areaW = _sz.width - 32;
    final areaH = (trayTop - top - 12).clamp(40.0, double.infinity);
    _cellSize = min(areaW / _cols, areaH / _rows);
    final gridW = _cellSize * _cols;
    final gridH = _cellSize * _rows;
    _origin = Offset(
      (_sz.width - gridW) / 2,
      top + (areaH - gridH) / 2,
    );
  }

  void _layoutHand() {
    if (_sz == Size.zero || _hand.isEmpty) return;
    final n = _hand.length;
    final spacing = (_sz.width - 32) / _handSize;
    final tileW = spacing.clamp(56.0, 92.0);
    final startX = _sz.width / 2 - (n - 1) * tileW / 2;
    final y = _sz.height * 0.86;
    for (int i = 0; i < n; i++) {
      _hand[i].x = startX + i * tileW;
      _hand[i].y = y;
      _hand[i].homeX = _hand[i].x;
      _hand[i].homeY = _hand[i].y;
    }
  }

  // ---- geometry helpers ----------------------------------------------------

  Offset _cellCenter(int idx) {
    final c = idx % _cols, r = idx ~/ _cols;
    return Offset(
      _origin.dx + (c + 0.5) * _cellSize,
      _origin.dy + (r + 0.5) * _cellSize,
    );
  }

  int? _cellAt(Offset p) {
    if (_cellSize <= 0) return null;
    final lx = p.dx - _origin.dx, ly = p.dy - _origin.dy;
    if (lx < 0 || ly < 0) return null;
    final c = (lx / _cellSize).floor(), r = (ly / _cellSize).floor();
    if (c < 0 || c >= _cols || r < 0 || r >= _rows) return null;
    return r * _cols + c;
  }

  List<int> _neighbors(int idx) {
    final c = idx % _cols, r = idx ~/ _cols;
    final out = <int>[];
    if (c > 0) out.add(idx - 1);
    if (c < _cols - 1) out.add(idx + 1);
    if (r > 0) out.add(idx - _cols);
    if (r < _rows - 1) out.add(idx + _cols);
    return out;
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (!widget.session.isRunning) return;

    setState(() {
      _clock += dt;

      for (final c in _grid) {
        if (c != null) c.age += dt;
      }
      for (final l in _links) {
        l.age += dt;
      }
      _links.removeWhere((l) => l.age > 0.9);
      for (final p in _pops) {
        p.age += dt;
        p.y -= 26 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.3);
      for (final d in _fx) {
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vy += 200 * dt;
        d.life -= dt;
      }
      _fx.removeWhere((d) => d.life <= 0);
      for (final rg in _rings) {
        rg.age += dt;
      }
      _rings.removeWhere((rg) => rg.age > 0.6);

      if (_phase == _Phase.growth) {
        _growthAge += dt;
        if (_growthAge > 0.15 && !_growthAwarded) _awardGrowth();
        if (_growthAge > 1.6) {
          _plotsCompleted++;
          _startPlot();
        }
      }
    });
  }

  // ---- placement -----------------------------------------------------------

  void _placeTile(_Tile tile, int cell) {
    _grid[cell] = _Cell(tile.crop);
    _hand.remove(tile);

    // Score adjacency against already-placed neighbours.
    int friends = 0, foes = 0;
    final here = _cellCenter(cell);
    for (final n in _neighbors(cell)) {
      final occ = _grid[n];
      if (occ == null) continue;
      final rel = _relation(tile.crop, occ.crop);
      if (rel > 0) {
        friends++;
        _links.add(_Link(here, _cellCenter(n), const Color(0xFF8BE58B)));
      } else if (rel < 0) {
        foes++;
        _links.add(_Link(here, _cellCenter(n), const Color(0xFFFF6B6B)));
      }
    }

    if (foes == 0 && friends > 0) {
      _combo++;
    } else if (foes > 0) {
      _combo = 0;
    }

    int pts = friends * 12;
    if (foes == 0 && friends > 0 && _combo > 1) pts += _combo * 4;
    if (pts > 0) {
      widget.session.addScore(pts);
      _burst(here, _kCrops[tile.crop]!.color, 10);
    }
    // Extra juice for a CLEAN companion match (friends, no foes): a green
    // celebratory ring + a sparkle of leafy motes — the "good pairing" moment.
    if (foes == 0 && friends > 0) {
      _rings.add(_Ring(here.dx, here.dy, _kHelpGreen));
      _burst(here, const Color(0xFFB9F6CA), 6);
    } else if (foes > 0) {
      // A small red pulse so a bad neighbour reads as a jolt.
      _rings.add(_Ring(here.dx, here.dy, _kHurtRed));
    }

    // Learnable cue.
    if (friends > 0) {
      _pops.add(_Pop(here.dx, here.dy - _cellSize * 0.5,
          '+helps ×$friends', const Color(0xFF8BE58B)));
    }
    if (foes > 0) {
      _pops.add(_Pop(here.dx, here.dy + _cellSize * 0.5,
          '−hurts ×$foes', const Color(0xFFFF6B6B)));
    }

    _refillHand();

    if (_placedCount >= _totalCells) {
      _phase = _Phase.growth;
      _growthAge = 0;
      _growthAwarded = false;
    }
  }

  /// Growth phase: each plant's net (friend − foe) neighbours decide whether it
  /// thrives (bonus) or wilts. A foe-free plot is a flawless harvest bonus.
  void _awardGrowth() {
    _growthAwarded = true;
    int bonus = 0;
    int foeEdges = 0;
    for (int i = 0; i < _grid.length; i++) {
      final cell = _grid[i];
      if (cell == null) continue;
      int net = 0;
      for (final n in _neighbors(i)) {
        final occ = _grid[n];
        if (occ == null) continue;
        final rel = _relation(cell.crop, occ.crop);
        net += rel;
        if (rel < 0) foeEdges++;
      }
      cell.thrive = net.toDouble();
      if (net > 0) {
        final b = 8 * net;
        bonus += b;
        _burst(_cellCenter(i), const Color(0xFF8BE58B), 8);
      }
    }
    // foeEdges double-counts each bad edge (both endpoints) — that's fine, it
    // just makes a clean plot the clear target.
    final flawless = foeEdges == 0;
    if (flawless) {
      _flawlessStreak++;
      widget.session.noteStreak(_flawlessStreak);
      final hb = 25 + _level * 10;
      bonus += hb;
      final mid = Offset(_sz.width / 2, _origin.dy + _rows * _cellSize / 2);
      _pops.add(_Pop(mid.dx, mid.dy,
          'FLAWLESS PLOT  +$hb', const Color(0xFFFFD54F)));
    } else {
      _flawlessStreak = 0;
    }
    if (bonus > 0) {
      widget.session.addScore(bonus);
    }
  }

  void _burst(Offset at, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 50 + _rng.nextDouble() * 110;
      _fx.add(_Dot(at.dx, at.dy, cos(a) * spd, sin(a) * spd - 30,
          0.4 + _rng.nextDouble() * 0.4, 2 + _rng.nextDouble() * 3, color));
    }
  }

  // ---- input ---------------------------------------------------------------

  void _onPanStart(Offset pos) {
    if (!widget.session.isRunning || _phase != _Phase.placing) return;
    double best = double.infinity;
    int bestI = -1;
    for (int i = 0; i < _hand.length; i++) {
      final t = _hand[i];
      final d = (pos - Offset(t.x, t.y)).distance;
      if (d < 54 && d < best) {
        best = d;
        bestI = i;
      }
    }
    if (bestI >= 0) _dragIndex = bestI;
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex == null || _dragIndex! >= _hand.length) return;
    setState(() {
      _hand[_dragIndex!].x = pos.dx;
      _hand[_dragIndex!].y = pos.dy;
      final cell = _cellAt(pos);
      _hoverCell = (cell != null && _grid[cell] == null) ? cell : null;
    });
  }

  void _onPanEnd() {
    if (_dragIndex == null || _dragIndex! >= _hand.length) return;
    final tile = _hand[_dragIndex!];
    final cell = _cellAt(Offset(tile.x, tile.y));
    setState(() {
      if (cell != null && _grid[cell] == null) {
        _placeTile(tile, cell);
      } else {
        tile.x = tile.homeX;
        tile.y = tile.homeY;
      }
      _dragIndex = null;
      _hoverCell = null;
    });
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        _sz = newSz;
        _computeGrid();
        _layoutHand();
      }
      // Hover preview net, for the cell tint.
      int hoverNet = 0;
      if (_hoverCell != null && _dragIndex != null &&
          _dragIndex! < _hand.length) {
        final crop = _hand[_dragIndex!].crop;
        for (final n in _neighbors(_hoverCell!)) {
          final occ = _grid[n];
          if (occ != null) hoverNet += _relation(crop, occ.crop);
        }
      }
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GardenPainter(
              clock: _clock,
              running: widget.session.isRunning,
              phase: _phase,
              growthAge: _growthAge,
              cols: _cols,
              rows: _rows,
              origin: _origin,
              cellSize: _cellSize,
              grid: _grid,
              hand: _hand,
              dragIndex: _dragIndex,
              hoverCell: _hoverCell,
              hoverNet: hoverNet,
              links: _links,
              pops: _pops,
              fx: _fx,
              rings: _rings,
              combo: _combo,
              level: _level,
              plots: _plotsCompleted,
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GardenPainter extends CustomPainter {
  final double clock;
  final bool running;
  final _Phase phase;
  final double growthAge;
  final int cols, rows;
  final Offset origin;
  final double cellSize;
  final List<_Cell?> grid;
  final List<_Tile> hand;
  final int? dragIndex;
  final int? hoverCell;
  final int hoverNet;
  final List<_Link> links;
  final List<_Pop> pops;
  final List<_Dot> fx;
  final List<_Ring> rings;
  final int combo;
  final int level;
  final int plots;

  _GardenPainter({
    required this.clock,
    required this.running,
    required this.phase,
    required this.growthAge,
    required this.cols,
    required this.rows,
    required this.origin,
    required this.cellSize,
    required this.grid,
    required this.hand,
    required this.dragIndex,
    required this.hoverCell,
    required this.hoverNet,
    required this.links,
    required this.pops,
    required this.fx,
    required this.rings,
    required this.combo,
    required this.level,
    required this.plots,
  });

  static const Color _soil = Color(0xFF3E2C22);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    GameFx.atmosphere(canvas, size, const Color(0xFF4C7A2F), clock, motes: 22);

    _drawGrid(canvas);
    _drawBonds(canvas); // persistent companion tendrils / foe rifts at rest
    _drawLinks(canvas); // transient flash on a fresh placement
    _drawPlants(canvas);
    if (phase == _Phase.placing) _drawHand(canvas);
    _drawParticles(canvas);
    _drawRings(canvas);
    _drawPops(canvas);
    _drawHud(canvas, size);
    if (!running) _drawReady(canvas, size);
  }

  // ---- grid ----------------------------------------------------------------

  void _drawGrid(Canvas canvas) {
    if (cellSize <= 0) return;
    const inset = 3.0;
    // A whole-plot raised garden frame behind the beds (warm timber edge).
    final plotRect = Rect.fromLTWH(origin.dx - 4, origin.dy - 4,
        cols * cellSize + 8, rows * cellSize + 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF4A3122).withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plotRect, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF63432C).withValues(alpha: 0.7),
    );

    for (int i = 0; i < cols * rows; i++) {
      final c = i % cols, r = i ~/ cols;
      final rect = Rect.fromLTWH(
        origin.dx + c * cellSize + inset,
        origin.dy + r * cellSize + inset,
        cellSize - inset * 2,
        cellSize - inset * 2,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));
      final occupied = grid[i] != null;
      // Tilled soil bed — a warm vertical gradient (top lighter, bottom dark),
      // reading as a real earth mound rather than a flat panel.
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: occupied
                ? [const Color(0xFF4A3221), const Color(0xFF2C1D13)]
                : [const Color(0xFF3E2C22), const Color(0xFF261912)],
          ).createShader(rect),
      );
      // Furrow grain: a few horizontal tilled lines (static, cheap).
      final furrow = Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..strokeWidth = 1;
      for (int f = 1; f <= 3; f++) {
        final fy = rect.top + rect.height * f / 4;
        canvas.drawLine(Offset(rect.left + 4, fy),
            Offset(rect.right - 4, fy), furrow);
      }
      // Hover tint: green if net friendly, red if net hostile.
      if (i == hoverCell) {
        final hint = hoverNet > 0
            ? _kHelpGreen
            : hoverNet < 0
                ? _kHurtRed
                : Colors.white;
        canvas.drawRRect(rr, Paint()..color = hint.withValues(alpha: 0.2));
        canvas.drawRRect(
          rr,
          Paint()
            ..color = hint.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        // Corner ticks so the drop target pops even at speed.
        if (hoverNet != 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(9)),
            Paint()
              ..color = hint.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      } else {
        canvas.drawRRect(
          rr,
          Paint()
            ..color = const Color(0xFF6B4A32).withValues(alpha: occupied ? 0.3 : 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  /// Persistent companion "tendrils" between adjacent PLANTED crops: a soft
  /// green tendril where two friends touch (they visibly help each other, at
  /// rest — the Three Sisters read as a helping trio), a faint red rift where
  /// two foes touch. Each edge drawn once. Purely cosmetic overlay.
  void _drawBonds(Canvas canvas) {
    if (cellSize <= 0) return;
    final pulse = 0.5 + 0.5 * sin(clock * 2.2);
    for (int i = 0; i < grid.length; i++) {
      final a = grid[i];
      if (a == null) continue;
      final c = i % cols, r = i ~/ cols;
      // Only look right + down so each edge is handled once.
      final right = (c < cols - 1) ? i + 1 : -1;
      final down = (r < rows - 1) ? i + cols : -1;
      for (final n in [right, down]) {
        if (n < 0) continue;
        final b = grid[n];
        if (b == null) continue;
        final rel = _relation(a.crop, b.crop);
        if (rel == 0) continue;
        final pa = _center(i), pb = _center(n);
        final mid = Offset.lerp(pa, pb, 0.5)!;
        if (rel > 0) {
          // Curved tendril arcing between the two plants.
          final perp = (pb - pa);
          final nrm = Offset(-perp.dy, perp.dx);
          final len = perp.distance;
          final ctrl = mid + nrm / (len == 0 ? 1 : len) * (6 + 4 * pulse);
          final path = Path()
            ..moveTo(pa.dx, pa.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, pb.dx, pb.dy);
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round
              ..color = _kHelpGreen.withValues(alpha: 0.28 + 0.18 * pulse)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
          // A little sprouting node at the midpoint.
          canvas.drawCircle(ctrl, 2.0 + pulse,
              Paint()..color = _kHelpGreen.withValues(alpha: 0.5));
        } else {
          // Foe rift: a jagged faint red spark.
          canvas.drawLine(
            pa,
            pb,
            Paint()
              ..color = _kHurtRed.withValues(alpha: 0.16 + 0.1 * pulse)
              ..strokeWidth = 1.6
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
          canvas.drawCircle(mid, 2.2,
              Paint()..color = _kHurtRed.withValues(alpha: 0.35));
        }
      }
    }
  }

  Offset _center(int idx) => Offset(
        origin.dx + (idx % cols + 0.5) * cellSize,
        origin.dy + (idx ~/ cols + 0.5) * cellSize,
      );

  // ---- relationship links --------------------------------------------------

  void _drawLinks(Canvas canvas) {
    for (final l in links) {
      final a = (1 - l.age / 0.9).clamp(0.0, 1.0);
      canvas.drawLine(
        l.a,
        l.b,
        Paint()
          ..color = l.color.withValues(alpha: 0.7 * a)
          ..strokeWidth = 3 * a + 1
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ---- plants --------------------------------------------------------------

  void _drawPlants(Canvas canvas) {
    if (cellSize <= 0) return;
    for (int i = 0; i < grid.length; i++) {
      final cell = grid[i];
      if (cell == null) continue;
      final info = _kCrops[cell.crop]!;
      final center = Offset(
        origin.dx + (i % cols + 0.5) * cellSize,
        origin.dy + (i ~/ cols + 0.5) * cellSize,
      );
      // Sprout-in on placement; idle sway phase-shifted per cell.
      final sprout = (cell.age / 0.35).clamp(0.0, 1.0);
      final sway = clock * 1.4 + i * 1.3;

      // Growth-phase thrive/wilt drives the plant's health look.
      double thrive = 0;
      if (phase == _Phase.growth && growthAge > 0.15) {
        final g = ((growthAge - 0.15) / 0.6).clamp(0.0, 1.0);
        thrive = cell.thrive.sign * g;
      }

      // Plant sits ~centred, sized to the cell. _drawCrop grounds it in soil.
      _drawCrop(canvas, center.translate(0, cellSize * 0.06), cell.crop,
          cellSize * 0.34,
          sway: sway, sprout: sprout, thrive: thrive);

      // A compact ID badge in a soil-dark chip at the plant's base — keeps the
      // learnable crop label without covering the artwork.
      if (sprout > 0.7) {
        final badgeC = center.translate(0, cellSize * 0.40);
        canvas.drawCircle(badgeC, cellSize * 0.13,
            Paint()..color = Colors.black.withValues(alpha: 0.4));
        GameFx.text(canvas, info.glyph, badgeC, cellSize * 0.16,
            Colors.white.withValues(alpha: 0.92),
            weight: FontWeight.w800);
      }
    }
  }

  // ---- hand / tray ---------------------------------------------------------

  void _drawHand(Canvas canvas) {
    for (int i = 0; i < hand.length; i++) {
      final t = hand[i];
      final info = _kCrops[t.crop]!;
      final dragging = i == dragIndex;
      final pos = Offset(t.x, t.y);
      final r = dragging ? cellSize * 0.34 : 24.0;
      final radius = r.clamp(20.0, 32.0);

      // A little terracotta seedling pot the crop grows out of, so tray tiles
      // read as "ready to plant" rather than floating orbs.
      final potTop = pos.translate(0, radius * 0.5);
      final potPath = Path()
        ..moveTo(potTop.dx - radius * 0.7, potTop.dy)
        ..lineTo(potTop.dx - radius * 0.5, potTop.dy + radius * 0.7)
        ..lineTo(potTop.dx + radius * 0.5, potTop.dy + radius * 0.7)
        ..lineTo(potTop.dx + radius * 0.7, potTop.dy)
        ..close();
      if (dragging) {
        canvas.drawCircle(pos, radius + 10,
            Paint()..color = info.color.withValues(alpha: 0.2));
      }
      canvas.drawPath(
          potPath,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB86F4B), Color(0xFF7A4527)],
            ).createShader(potPath.getBounds()));
      canvas.drawLine(
          potTop.translate(-radius * 0.68, 0),
          potTop.translate(radius * 0.68, 0),
          Paint()
            ..color = const Color(0xFF3E2116).withValues(alpha: 0.6)
            ..strokeWidth = radius * 0.14);

      // The plant itself, gently swaying.
      final sway = clock * 1.4 + i * 0.9;
      _drawCrop(canvas, pos.translate(0, -radius * 0.15), t.crop, radius * 0.95,
          sway: sway, sprout: 1);

      // Badge + name below the pot.
      GameFx.text(
        canvas,
        info.label,
        Offset(t.x, potTop.dy + radius * 0.9 + 8),
        11,
        Colors.white.withValues(alpha: 0.75),
        weight: FontWeight.w700,
      );
    }
  }

  // ---- particles / pops ----------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final d in fx) {
      final a = d.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(d.x, d.y), d.size * a,
          Paint()..color = d.color.withValues(alpha: a));
    }
  }

  void _drawRings(Canvas canvas) {
    for (final rg in rings) {
      final t = (rg.age / 0.6).clamp(0.0, 1.0);
      final radius = cellSize * (0.3 + 0.6 * Curves.easeOut.transform(t));
      final alpha = (1 - t) * 0.7;
      canvas.drawCircle(
        Offset(rg.x, rg.y),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - t) + 1
          ..color = rg.color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawPops(Canvas canvas) {
    for (final p in pops) {
      final a = (1 - p.age / 1.3).clamp(0.0, 1.0);
      GameFx.text(canvas, p.text, Offset(p.x, p.y), 13 + p.age * 1.5,
          p.color.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.5 * a);
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Phase / plot label (top-left). Host draws the run timer + score.
    final label = phase == _Phase.growth ? 'GROWING…' : 'PLANT THE PLOT';
    GameFx.text(canvas, label, const Offset(64, 22), 11,
        Colors.white.withValues(alpha: 0.45),
        weight: FontWeight.w700);
    if (plots > 0) {
      GameFx.text(canvas, '×$plots harvested', const Offset(70, 40), 10,
          Colors.white.withValues(alpha: 0.3),
          weight: FontWeight.w600);
    }

    // Level pips (top-right).
    for (int i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(size.width - 16 - i * 9.0, 18),
        2.6,
        Paint()
          ..color = i < level
              ? const Color(0xFFAED581).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
      );
    }

    // Combo (bottom-right).
    if (combo > 1) {
      GameFx.text(canvas, 'x$combo', Offset(size.width - 30, size.height - 44),
          17, const Color(0xFFAED581),
          weight: FontWeight.w800, glow: 0.5);
    }
  }

  void _drawReady(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'Place crops so neighbours help',
      Offset(size.width / 2, size.height * 0.74),
      13,
      Colors.white.withValues(alpha: 0.5),
      weight: FontWeight.w600,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPainter old) => true;
}
