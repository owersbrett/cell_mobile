import 'package:cell_mobile/data/person_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final letter = RegExp(r'\p{L}', unicode: true);
  final pattern = RegExp(
    PersonRegistry.aliasesByLengthDesc.map((a) => RegExp.escape(a.text)).join('|'),
  );
  final byAlias = {
    for (final a in PersonRegistry.aliasesByLengthDesc) a.text: a.person,
  };

  List<String> matches(String text) {
    final hits = <String>[];
    for (final m in pattern.allMatches(text)) {
      final before = m.start == 0 ? '' : text[m.start - 1];
      final after = m.end >= text.length ? '' : text[m.end];
      if ((before.isNotEmpty && letter.hasMatch(before)) ||
          (after.isNotEmpty && letter.hasMatch(after))) {
        continue;
      }
      hits.add('${m.group(0)}->${byAlias[m.group(0)]!.id}');
    }
    return hits;
  }

  test('links standalone Boole but not Boolean', () {
    expect(matches('George Boole showed Boolean algebra'), ['George Boole->boole']);
  });
  test('prefers full name over surname', () {
    expect(matches('work by Gottfried Leibniz here'), ['Gottfried Leibniz->leibniz']);
  });
  test('lowercase unit newtons does not match Newton', () {
    expect(matches('a force of 5 newtons'), isEmpty);
  });
  test('Newton possessive still links', () {
    expect(matches("Newton's laws"), ['Newton->newton']);
  });
  test('unicode names match', () {
    expect(matches('as Gödel and Schrödinger showed'),
        ['Gödel->godel', 'Schrödinger->schrodinger']);
  });
  test('every alias resolves to a real person id', () {
    for (final a in PersonRegistry.aliasesByLengthDesc) {
      expect(a.person.id, isNotEmpty);
    }
  });

  // Collision-avoidance regressions — the ambiguous/common surnames must NOT
  // auto-link, while the safe full-name forms do.
  test('Marie and Pierre Curie link distinctly; bare "curie" does not', () {
    expect(matches('work by Marie Curie and Pierre Curie'),
        ['Marie Curie->marie-curie', 'Pierre Curie->pierre-curie']);
    expect(matches('one curie of radioactivity'), isEmpty);
  });
  test('Peter Higgs links but the Higgs boson does not', () {
    expect(matches('Peter Higgs predicted the Higgs boson'),
        ['Peter Higgs->peter-higgs']);
  });
  test('van der Waals links in either case', () {
    expect(matches('the van der Waals forces'),
        ['van der Waals->johannes-van-der-waals']);
  });
  test('Haber process links but Haber-Bosch (two people) does not', () {
    expect(matches('the Haber process fixes nitrogen'),
        ['Haber process->fritz-haber']);
    expect(matches('the Haber-Bosch process'), isEmpty);
  });
  test('two different physicists named Anderson stay unlinked when bare', () {
    // Both carl-anderson and philip-anderson are full-name-only, so a bare
    // "Anderson" must never resolve to either.
    expect(matches('discovered by Anderson in 1936'), isEmpty);
  });
  test('no alias is a bare ambiguous surname on the blocklist', () {
    const banned = {
      'Curie', 'Anderson', 'Higgs', 'Lawrence', 'Fermi', 'Nobel',
      'Rutherford', 'Berkeley', 'Oort', 'Lee', 'Green', 'Wilson', 'Herman',
    };
    for (final a in PersonRegistry.aliasesByLengthDesc) {
      expect(banned.contains(a.text), isFalse,
          reason: '"${a.text}" is an unsafe bare surname alias');
    }
  });
}
