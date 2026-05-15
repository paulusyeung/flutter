import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/payments/widgets/edit/payment_allocations_section.dart';

void main() {
  AllocationTarget target(
    String id, {
    num balance = 100,
    num partial = 0,
    String number = 'INV-1',
  }) =>
      AllocationTarget(
        id: id,
        number: number,
        balance: Decimal.parse(balance.toString()),
        partial: Decimal.parse(partial.toString()),
      );

  group('computeAutoFillAmount — invoice', () {
    test('prefers partial when nonzero (mirrors admin-portal fromInvoice)',
        () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.invoice,
        target: target('i1', balance: 500, partial: 50),
        paymentAmount: Decimal.zero,
        allocatedExcludingThisRow: Decimal.zero,
      );
      expect(amount, Decimal.parse('50'));
    });

    test('falls back to balance when partial is zero', () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.invoice,
        target: target('i1', balance: 200),
        paymentAmount: Decimal.zero,
        allocatedExcludingThisRow: Decimal.zero,
      );
      expect(amount, Decimal.parse('200'));
    });

    test('caps at remaining headroom when paymentAmount is set', () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.invoice,
        target: target('i1', balance: 200),
        paymentAmount: Decimal.parse('150'),
        allocatedExcludingThisRow: Decimal.parse('50'),
      );
      // headroom = 150 - 50 = 100; pick=200 → capped at 100.
      expect(amount, Decimal.parse('100'));
    });

    test('zero when headroom is already exhausted', () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.invoice,
        target: target('i1', balance: 100),
        paymentAmount: Decimal.parse('100'),
        allocatedExcludingThisRow: Decimal.parse('100'),
      );
      expect(amount, Decimal.zero);
    });

    test('no cap when paymentAmount is zero (user has not seeded)', () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.invoice,
        target: target('i1', balance: 999),
        paymentAmount: Decimal.zero,
        allocatedExcludingThisRow: Decimal.parse('500'),
      );
      expect(amount, Decimal.parse('999'));
    });
  });

  group('computeAutoFillAmount — credit', () {
    test('credit is unbounded — returns preferred amount regardless of cap',
        () {
      final amount = computeAutoFillAmount(
        kind: AllocationKind.credit,
        target: target('c1', balance: 75),
        paymentAmount: Decimal.parse('100'),
        allocatedExcludingThisRow: Decimal.parse('100'),
      );
      expect(amount, Decimal.parse('75'));
    });
  });
}
