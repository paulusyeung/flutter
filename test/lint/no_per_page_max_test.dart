import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: enforce CLAUDE.md's "no `per_page=999999`" rule. Greps every
/// `.dart` file under `lib/` and fails if a list-endpoint hits the entire
/// dataset in one round-trip. Anything ≤ 200 is fine; we only flag the
/// pre-rebuild "fetch everything" anti-pattern.
void main() {
  test('lib/ does not contain `per_page=999999` (or any per_page > 200)', () {
    final pattern = RegExp(r'per_page=(\d+)');
    final offenders = <String>[];
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip generated files — we never write to them and they should not
      // contain large per_page values anyway, but keep the check focused.
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      for (final match in pattern.allMatches(content)) {
        final value = int.tryParse(match.group(1)!) ?? 0;
        if (value > 200) {
          // Find the surrounding line for a useful error message.
          final lineStart = content.lastIndexOf('\n', match.start) + 1;
          final lineEnd = content.indexOf('\n', match.end);
          final line = content
              .substring(lineStart, lineEnd == -1 ? content.length : lineEnd)
              .trim();
          offenders.add('${entity.path}:  $line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'CLAUDE.md forbids `per_page=999999` (or any per_page > 200). '
          'Lists must paginate. Found:\n  ${offenders.join('\n  ')}',
    );
  });
}
