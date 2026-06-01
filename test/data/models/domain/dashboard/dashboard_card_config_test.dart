import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_card_config.dart';

void main() {
  group('DashboardCardConfig', () {
    test('the 13 field keys match React exactly, in order', () {
      expect(kDashboardCardFields, const [
        'active_invoices',
        'outstanding_invoices',
        'completed_payments',
        'refunded_payments',
        'active_quotes',
        'unapproved_quotes',
        'logged_tasks',
        'invoiced_tasks',
        'paid_tasks',
        'logged_expenses',
        'pending_expenses',
        'invoiced_expenses',
        'invoice_paid_expenses',
      ]);
    });

    test('fieldLabelKey mirrors React FIELDS_LABELS (total_<field>)', () {
      expect(fieldLabelKey('active_invoices'), 'total_active_invoices');
      expect(
        fieldLabelKey('invoice_paid_expenses'),
        'total_invoice_paid_expenses',
      );
    });

    test('isTaskField only for the three *_tasks fields', () {
      expect(isTaskField('logged_tasks'), isTrue);
      expect(isTaskField('invoiced_tasks'), isTrue);
      expect(isTaskField('paid_tasks'), isTrue);
      expect(isTaskField('active_invoices'), isFalse);
      expect(isTaskField('logged_expenses'), isFalse);
    });

    test('key round-trips through tryParse / toJson', () {
      const c = DashboardCardConfig(
        field: 'logged_tasks',
        period: CardPeriod.previous,
        calculate: CardCalc.avg,
        format: CardFormat.time,
      );
      expect(c.key, 'logged_tasks|previous|avg|time');
      expect(c.toJson(), c.key);
      final parsed = DashboardCardConfig.tryParse(c.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.key, c.key);
      expect(parsed == c, isTrue);
    });

    test('non-task field can never decode as time → coerced to money', () {
      final parsed = DashboardCardConfig.tryParse(
        'active_invoices|current|sum|time',
      );
      expect(parsed, isNotNull);
      expect(parsed!.format, CardFormat.money);
      expect(parsed.key, 'active_invoices|current|sum|money');
    });

    test('malformed / unknown inputs return null', () {
      expect(DashboardCardConfig.tryParse(null), isNull);
      expect(DashboardCardConfig.tryParse(42), isNull);
      expect(DashboardCardConfig.tryParse('a|b|c'), isNull); // wrong arity
      expect(
        DashboardCardConfig.tryParse('not_a_field|current|sum|money'),
        isNull,
      );
      expect(
        DashboardCardConfig.tryParse('active_invoices|bogus|sum|money'),
        isNull,
      );
    });

    test('equality + hashCode are key-based (dedupe works)', () {
      const a = DashboardCardConfig(
        field: 'active_invoices',
        period: CardPeriod.current,
        calculate: CardCalc.sum,
        format: CardFormat.money,
      );
      const b = DashboardCardConfig(
        field: 'active_invoices',
        period: CardPeriod.current,
        calculate: CardCalc.sum,
        format: CardFormat.money,
      );
      expect(a == b, isTrue);
      final deduped = <DashboardCardConfig>{};
      deduped.add(a);
      deduped.add(b);
      expect(deduped.length, 1);
    });
  });
}
