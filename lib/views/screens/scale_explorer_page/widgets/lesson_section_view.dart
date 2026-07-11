import 'package:cell_mobile/models/lesson_section.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/views/screens/scale_explorer_page/widgets/person_linked_text.dart';
import 'package:flutter/material.dart';

/// Renders one structured lesson block in the scale explorer, themed by the
/// scale's color. Tables get real table treatment; think-reveals hide their
/// answer behind a deliberate tap so the learner commits to thinking first.
class LessonSectionView extends StatelessWidget {
  final LessonSection section;
  final Color color;
  const LessonSectionView(
      {super.key, required this.section, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (section.kind) {
      case LessonSectionKind.paragraph:
        return _paragraph();
      case LessonSectionKind.table:
        return _table();
      case LessonSectionKind.thinkReveal:
        return _ThinkReveal(section: section, color: color);
      case LessonSectionKind.fact:
        return _fact();
    }
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: Potatuhs.body(size: 12, weight: FontWeight.w700, color: color)
              .copyWith(letterSpacing: 2.5),
        ),
      );

  Widget _paragraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) _sectionTitle(section.title!),
        PersonLinkedText(
          text: section.body,
          accent: color,
          style: Potatuhs.body(
              size: 15,
              weight: FontWeight.w400,
              color: Potatuhs.textSecondary,
              height: 1.6),
        ),
      ],
    );
  }

  Widget _fact() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title != null) _sectionTitle(section.title!),
          PersonLinkedText(
            text: section.body,
            accent: color,
            style: Potatuhs.body(
                size: 17,
                weight: FontWeight.w600,
                color: Potatuhs.textPrimary,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) _sectionTitle(section.title!),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              verticalInside:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            children: [
              TableRow(
                decoration:
                    BoxDecoration(color: color.withValues(alpha: 0.16)),
                children: [
                  for (final h in section.headers)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Text(
                        h.toUpperCase(),
                        style: Potatuhs.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: color)
                            .copyWith(letterSpacing: 1.5),
                      ),
                    ),
                ],
              ),
              for (var i = 0; i < section.rows.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i.isOdd
                        ? Colors.white.withValues(alpha: 0.025)
                        : Colors.transparent,
                  ),
                  children: [
                    for (final cell in section.rows[i])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          cell,
                          style: Potatuhs.body(
                              size: 13,
                              color: Potatuhs.textPrimary,
                              height: 1.35),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The think-then-reveal block: the question is always visible; the answer
/// costs a deliberate tap. Revealing animates open so the payoff lands.
class _ThinkReveal extends StatefulWidget {
  final LessonSection section;
  final Color color;
  const _ThinkReveal({required this.section, required this.color});

  @override
  State<_ThinkReveal> createState() => _ThinkRevealState();
}

class _ThinkRevealState extends State<_ThinkReveal> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final s = widget.section;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                (s.title ?? 'THINK').toUpperCase(),
                style: Potatuhs.body(
                        size: 12, weight: FontWeight.w700, color: color)
                    .copyWith(letterSpacing: 2.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PersonLinkedText(
            text: s.prompt ?? '',
            accent: color,
            style: Potatuhs.body(
                size: 15,
                weight: FontWeight.w600,
                color: Potatuhs.textPrimary,
                height: 1.45),
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _revealed
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PersonLinkedText(
                      text: s.body,
                      accent: color,
                      style: Potatuhs.body(
                          size: 14,
                          color: Potatuhs.textPrimary,
                          height: 1.5),
                    ),
                  )
                : GestureDetector(
                    onTap: () => setState(() => _revealed = true),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          'REVEAL THE ANSWER',
                          style: Potatuhs.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: color)
                              .copyWith(letterSpacing: 2),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
