import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/views/advanced/generated_numbers/generated_numbers_validation.dart';

void main() {
  group('violatesClientCounterRule', () {
    test('null / empty / no client_counter → valid', () {
      expect(violatesClientCounterRule(null), isFalse);
      expect(violatesClientCounterRule(''), isFalse);
      expect(violatesClientCounterRule(r'{$counter}'), isFalse);
      expect(violatesClientCounterRule(r'INV-{$year}'), isFalse);
    });

    test('{\$client_counter} alone → violation', () {
      expect(violatesClientCounterRule(r'{$client_counter}'), isTrue);
      expect(violatesClientCounterRule(r'X-{$client_counter}-Y'), isTrue);
    });

    test('{\$client_counter} with a distinguisher → valid', () {
      expect(
        violatesClientCounterRule(r'{$client_counter}{$counter}'),
        isFalse,
      );
      expect(
        violatesClientCounterRule(r'{$client_counter}-{$client_number}'),
        isFalse,
      );
      expect(
        violatesClientCounterRule(r'{$client_counter}-{$client_id_number}'),
        isFalse,
      );
    });

    test(
      '{\$client_counter} does not accidentally satisfy the {\$counter} check',
      () {
        // The token contains the substring "counter}" but not "{$counter}",
        // so it must still be flagged when it stands alone.
        expect(violatesClientCounterRule(r'{$client_counter}'), isTrue);
      },
    );

    test('every pattern key the page validates is covered', () {
      expect(kNumberPatternKeys, contains('invoice_number_pattern'));
      expect(kNumberPatternKeys, contains('client_number_pattern'));
      expect(kNumberPatternKeys.length, 12);
    });
  });
}
