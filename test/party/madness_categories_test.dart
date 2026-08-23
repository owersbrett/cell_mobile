import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/party/madness/madness_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every BioScale belongs to exactly one madness category', () {
    final seen = <BioScale>[];
    for (final c in kMadnessCategories) {
      seen.addAll(c.scales);
    }
    expect(seen.toSet().length, seen.length, reason: 'no scale twice');
    expect(seen.toSet(), BioScale.values.toSet(), reason: 'all scales mapped');
  });

  test('categoryOf resolves every scale', () {
    for (final s in BioScale.values) {
      expect(madnessCategoryOf(s).scales, contains(s));
    }
  });
}
