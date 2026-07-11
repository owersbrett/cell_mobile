/// Structured lesson blocks for the LEARN explorer (Brett, 2026-07-07):
/// a lesson page is NOT title + subtitle + word-vomit. Anything tabular is a
/// table; anything worth remembering is a think-then-reveal that makes the
/// learner commit to an answer before seeing it; landmark quantities are
/// facts. Entity data files compose these as const lists.
library;

enum LessonSectionKind {
  /// A titled prose block — for narrative that genuinely is narrative.
  paragraph,

  /// Tabular truth: headers + rows. Use whenever content compares, ranks,
  /// enumerates, or maps one thing to another.
  table,

  /// A question the learner must sit with; the answer stays hidden until
  /// they choose to reveal it. The thinking IS the lesson.
  thinkReveal,

  /// One landmark fact or quantity, displayed big. Sparingly.
  fact,
}

class LessonSection {
  final LessonSectionKind kind;
  final String? title;

  /// Paragraph body, reveal answer, or the fact line.
  final String body;

  /// The think-reveal question.
  final String? prompt;

  final List<String> headers;
  final List<List<String>> rows;

  const LessonSection.paragraph({this.title, required this.body})
      : kind = LessonSectionKind.paragraph,
        prompt = null,
        headers = const [],
        rows = const [];

  const LessonSection.table(
      {this.title, required this.headers, required this.rows})
      : kind = LessonSectionKind.table,
        body = '',
        prompt = null;

  const LessonSection.thinkReveal(
      {this.title, required String question, required String answer})
      : kind = LessonSectionKind.thinkReveal,
        prompt = question,
        body = answer,
        headers = const [],
        rows = const [];

  const LessonSection.fact({this.title, required this.body})
      : kind = LessonSectionKind.fact,
        prompt = null,
        headers = const [],
        rows = const [];
}
