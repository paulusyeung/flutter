import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: no user value may be string-interpolated into a SQL `LIKE`
/// literal. The DAO free-text search helpers used to build
/// `CustomExpression<bool>("... LIKE '$needle' ...")`, concatenating the raw
/// search term straight into the query. That both broke on a literal `'`
/// (searching `O'Brien` threw) and was injectable. The fixed form binds the
/// term as a `?` parameter via Drift's `.like()` — see
/// `lib/data/db/dao/_payload_search.dart`.
///
/// The signature we forbid is a single quote immediately followed by a Dart
/// interpolation inside a LIKE clause: `LIKE '$`. Parameter-bound `.like()`
/// never produces this. Manually-escaped equality interpolation
/// (`= '$escaped'` after `replaceAll("'", "''")`, as in
/// `paymentablesContainsInvoice`) is a different, safe pattern and is not
/// matched by this lint.
void main() {
  test("lib/ contains no interpolated SQL LIKE (`LIKE '\$`)", () {
    final pattern = RegExp(r"LIKE\s+'\$");
    final offenders = <String>[];
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ should exist');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;

      final content = entity.readAsStringSync();
      for (final match in pattern.allMatches(content)) {
        final lineStart = content.lastIndexOf('\n', match.start) + 1;
        final lineEnd = content.indexOf('\n', match.end);
        final line = content
            .substring(lineStart, lineEnd == -1 ? content.length : lineEnd)
            .trim();
        offenders.add('${entity.path}:  $line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Interpolating a user value into a SQL LIKE literal is injectable '
          'and breaks on apostrophes. Build the column with '
          'CustomExpression<String>(...) and chain Drift\'s .like(needle) so '
          'the term is bound as a parameter — use payloadJsonLike() in '
          'lib/data/db/dao/_payload_search.dart. Offenders:\n'
          '${offenders.join('\n')}',
    );
  });
}
