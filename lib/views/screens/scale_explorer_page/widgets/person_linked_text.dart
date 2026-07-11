import 'package:cell_mobile/data/person_registry.dart';
import 'package:cell_mobile/views/screens/scale_explorer_page/widgets/person_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders lesson prose, but any name in the [PersonRegistry] becomes a
/// tappable span (tinted + underlined in the scale accent) that opens that
/// person's profile card. Content files stay plain strings — linking is
/// entirely registry-driven, so new content links for free and there are never
/// dead links (an unknown name simply renders as normal text).
class PersonLinkedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color accent;
  const PersonLinkedText({
    super.key,
    required this.text,
    required this.style,
    required this.accent,
  });

  @override
  State<PersonLinkedText> createState() => _PersonLinkedTextState();
}

class _PersonLinkedTextState extends State<PersonLinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  /// Combined alias pattern, longest alias first so multi-word names win over
  /// their bare surnames. Built once — the registry is const.
  static final RegExp _pattern = RegExp(
    PersonRegistry.aliasesByLengthDesc
        .map((a) => RegExp.escape(a.text))
        .join('|'),
  );

  static final Map<String, Person> _byAlias = {
    for (final a in PersonRegistry.aliasesByLengthDesc) a.text: a.person,
  };

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  bool _isLetter(String ch) => ch.isNotEmpty && _letter.hasMatch(ch);

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final text = widget.text;
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final m in _pattern.allMatches(text)) {
      // Whole-word guard: reject if a letter hugs either edge (so "Boole" does
      // not fire inside "Boolean", and lowercase "newtons" never matches the
      // capitalised alias "Newton").
      final before = m.start == 0 ? '' : text[m.start - 1];
      final after = m.end >= text.length ? '' : text[m.end];
      if (_isLetter(before) || _isLetter(after)) continue;

      final person = _byAlias[m.group(0)];
      if (person == null) continue;

      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => showPersonCard(context, person, widget.accent);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: TextStyle(
          color: widget.accent,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: widget.accent.withValues(alpha: 0.5),
          decorationThickness: 1.5,
        ),
        recognizer: recognizer,
      ));
      cursor = m.end;
    }

    if (spans.isEmpty) {
      // No names — a plain Text is cheaper and avoids recognizer churn.
      return Text(text, style: widget.style);
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: widget.style, children: spans),
    );
  }
}
