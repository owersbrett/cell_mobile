import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Paydirt was retired as a currency (collapsed into diamonds). The party
/// economy is ATP · diamonds · potatoes — nothing else. This guard keeps the
/// dead concept from creeping back into code or specs.
void main() {
  final banned = RegExp(r'pay\s?dirt', caseSensitive: false);

  test('no paydirt remnants in lib/ or docs/', () {
    final offenders = <String>[];
    for (final dir in ['lib', 'docs']) {
      final root = Directory(dir);
      if (!root.existsSync()) continue;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path;
        if (!path.endsWith('.dart') && !path.endsWith('.md')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (banned.hasMatch(lines[i])) {
            offenders.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Paydirt no longer exists — the currencies are ATP, diamonds, '
            'and potatoes. Found:\n${offenders.join('\n')}');
  });
}
