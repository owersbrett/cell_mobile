import 'dart:math' as math;

import 'package:cell_mobile/data/person_registry.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The person profile card — a Potatuhs-styled bottom sheet that pops when a
/// reader taps a name-dropped historical figure in the LEARN content. Procedural
/// monogram medallion (no raster portraits, per the asset rule), a few genuinely
/// interesting facts, and a LEARN MORE button that opens the reader's browser.
void showPersonCard(BuildContext context, Person person, Color accent) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _PersonCard(person: person, accent: accent),
  );
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final Color accent;
  const _PersonCard({required this.person, required this.accent});

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(person.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${person.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
          boxShadow: Potatuhs.glow(accent, strength: 0.28, blur: 40),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Potatuhs.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Medallion(monogram: person.monogram, accent: accent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: Potatuhs.display(
                              size: 22, color: Potatuhs.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.lifespan,
                          style: Potatuhs.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: accent),
                        ),
                        Text(
                          person.role,
                          style: Potatuhs.body(
                              size: 13,
                              weight: FontWeight.w400,
                              color: Potatuhs.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final fact in person.facts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7, right: 12),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          fact,
                          style: Potatuhs.body(
                            size: 14.5,
                            weight: FontWeight.w400,
                            color: Potatuhs.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              _LearnMoreButton(onTap: () => _launch(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The learn-more CTA — solid house green with an ink border and glyph (the
/// PotatuhsButton sticker language), so it reads as a live action rather than
/// the washed-out accent tint that looked disabled.
class _LearnMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LearnMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Potatuhs.go,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: Potatuhs.glow(Potatuhs.go, strength: 0.35),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new, size: 18, color: Potatuhs.ink),
              const SizedBox(width: 10),
              Text(
                'LEARN MORE',
                style: Potatuhs.body(
                        size: 14, weight: FontWeight.w800, color: Potatuhs.ink)
                    .copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Procedural monogram medallion — a brand-gradient disc with a soft ring and
/// the person's initials. No portraits; fully Canvas-drawn.
class _Medallion extends StatelessWidget {
  final String monogram;
  final Color accent;
  const _Medallion({required this.monogram, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _MedallionPainter(accent),
        child: Center(
          child: Text(
            monogram,
            style: Potatuhs.display(size: 22, color: Potatuhs.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  final Color accent;
  _MedallionPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    // Radial fill: accent core fading to ink.
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(accent, Potatuhs.textPrimary, 0.15)!
              .withValues(alpha: 0.9),
          accent.withValues(alpha: 0.35),
          Potatuhs.ink.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r - 2, fill);
    // Bright rim.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.85);
    canvas.drawCircle(center, r - 2, rim);
    // A few decorative tick marks around the ring (a "coin" feel).
    final tick = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
          center + o * (r - 1), center + o * (r - 4.5), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) => old.accent != accent;
}
