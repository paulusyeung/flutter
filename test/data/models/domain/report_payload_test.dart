import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/value/date.dart';

void main() {
  group('ReportPayload.toJson', () {
    test('emits date_range wire key and drops empty optionals', () {
      final json = const ReportPayload(
        datePreset: ReportDatePreset.thisYear,
      ).toJson(reportIdentifier: 'clients');
      expect(json['date_range'], 'this_year');
      expect(json.containsKey('start_date'), isFalse);
      expect(json.containsKey('clients'), isFalse);
    });

    test('date_range uses React reports short-form tokens, not long form', () {
      // The reports endpoint expects `all`/`last7`/… (React reports `ranges`),
      // NOT the dashboard/scheduler `all_time`/`last7_days` form. Stricter
      // servers return an empty report for the long form. Regression guard.
      String wireFor(ReportDatePreset p) =>
          const ReportPayload()
                  .copyWith(datePreset: p)
                  .toJson(reportIdentifier: 'clients')['date_range']
              as String;

      expect(wireFor(ReportDatePreset.allTime), 'all');
      expect(wireFor(ReportDatePreset.last7), 'last7');
      expect(wireFor(ReportDatePreset.last30), 'last30');
      expect(wireFor(ReportDatePreset.last90), 'last90');
      expect(wireFor(ReportDatePreset.last365), 'last365');
      // Unchanged forms (already matched React).
      expect(wireFor(ReportDatePreset.thisMonth), 'this_month');
      expect(wireFor(ReportDatePreset.lastQuarter), 'last_quarter');
      expect(wireFor(ReportDatePreset.thisYear), 'this_year');
    });

    test('default payload date_range is all-time (short form)', () {
      final json = const ReportPayload().toJson(reportIdentifier: 'clients');
      expect(json['date_range'], 'all');
    });

    test('serializes start/end as ISO date strings when set', () {
      final json = ReportPayload(
        datePreset: ReportDatePreset.custom,
        startDate: Date(2026, 1, 1),
        endDate: Date(2026, 12, 31),
      ).toJson(reportIdentifier: 'clients');
      expect(json['date_range'], 'custom');
      expect(json['start_date'], '2026-01-01');
      expect(json['end_date'], '2026-12-31');
    });

    test('CSV multi-select fields pass through as strings', () {
      final json = const ReportPayload(
        clients: 'abc,def,ghi',
        vendors: 'jkl,mno',
      ).toJson(reportIdentifier: 'expense');
      expect(json['clients'], 'abc,def,ghi');
      expect(json['vendors'], 'jkl,mno');
    });

    test('product_sales coerces empty client_id to literal null', () {
      final json = const ReportPayload(
        clientId: null,
      ).toJson(reportIdentifier: 'product_sales');
      expect(json.containsKey('client_id'), isTrue);
      expect(json['client_id'], isNull);
    });

    test('product_sales preserves a non-empty client_id verbatim', () {
      final json = const ReportPayload(
        clientId: 'abc',
      ).toJson(reportIdentifier: 'product_sales');
      expect(json['client_id'], 'abc');
    });

    test('other reports drop an empty client_id entirely', () {
      final json = const ReportPayload(
        clientId: null,
      ).toJson(reportIdentifier: 'clients');
      expect(json.containsKey('client_id'), isFalse);
    });

    test('boolean flags only appear when true', () {
      final flagged = const ReportPayload(
        includeDeleted: true,
        includeTax: true,
        isExpenseBilled: true,
        isIncomeBilled: true,
      ).toJson(reportIdentifier: 'profitloss');
      expect(flagged['include_deleted'], true);
      expect(flagged['include_tax'], true);
      expect(flagged['is_expense_billed'], true);
      expect(flagged['is_income_billed'], true);
      final empty = const ReportPayload().toJson(
        reportIdentifier: 'profitloss',
      );
      expect(empty.containsKey('include_deleted'), isFalse);
      expect(empty.containsKey('is_expense_billed'), isFalse);
    });

    test('report_keys + group_by passed through when set', () {
      final json = const ReportPayload().toJson(
        reportIdentifier: 'clients',
        reportKeys: ['client.name', 'client.balance'],
        groupBy: 'client.country',
      );
      expect(json['report_keys'], ['client.name', 'client.balance']);
      expect(json['group_by'], 'client.country');
    });

    test('send_email only emits when sendEmail flag is on', () {
      final json = const ReportPayload(
        sendEmail: true,
      ).toJson(reportIdentifier: 'clients');
      expect(json['send_email'], true);
      final off = const ReportPayload().toJson(reportIdentifier: 'clients');
      expect(off.containsKey('send_email'), isFalse);
    });
  });

  group('ReportPayload equality', () {
    test('two equal-shape payloads compare equal (for isParamDirty)', () {
      const a = ReportPayload(
        datePreset: ReportDatePreset.thisMonth,
        clients: 'x,y',
        includeDeleted: true,
      );
      const b = ReportPayload(
        datePreset: ReportDatePreset.thisMonth,
        clients: 'x,y',
        includeDeleted: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
