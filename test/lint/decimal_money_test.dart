import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: enforce CLAUDE.md's "money is `Decimal`, never `double`" rule
/// for domain models. Scans every entity domain model and fails if a known
/// money field is declared as `double` or `num`.
///
/// The list of money field names mirrors the conventions in
/// `lib/data/models/domain/*.dart` and `admin-portal`'s entity definitions.
/// New money fields should be added here as entities ship.
void main() {
  test('domain models use Decimal for money fields', () {
    const moneyFieldNames = [
      'amount',
      'balance',
      'price',
      'cost',
      'total',
      'subtotal',
      'paidToDate',
      'creditBalance',
      'discount',
      'tax',
      'taxRate',
      'taxRate1',
      'taxRate2',
      'taxRate3',
      'paymentAmount',
      'partial',
      'partialDue',
      'lineTotal',
      'unitCost',
      'minAmount',
      'maxAmount',
    ];

    final dir = Directory('lib/data/models/domain');
    expect(dir.existsSync(), isTrue, reason: 'domain models dir should exist');

    final offenders = <String>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;

      final content = entity.readAsStringSync();
      for (final fieldName in moneyFieldNames) {
        // Match a field declaration: `<Type> <fieldName>[, )?]`. We catch
        // `double balance`, `num balance`, etc. Decimal is fine; bool/int
        // also pass because they're not the type we're warning about.
        // The negative lookahead avoids matching `Decimal? balance` (which
        // is fine).
        final re = RegExp(
          r'\b(double|num)\s+' + fieldName + r'\b',
          multiLine: true,
        );
        for (final match in re.allMatches(content)) {
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
          'CLAUDE.md mandates `Decimal` for money fields, never `double` '
          'or `num`. Found:\n  ${offenders.join('\n  ')}',
    );
  });
}
