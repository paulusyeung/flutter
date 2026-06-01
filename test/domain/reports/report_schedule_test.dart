import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_schedule_seed.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/reports/report_schedule.dart';

ReportScheduleSeed _seed({
  String id = 'invoice',
  ReportPayload payload = const ReportPayload(),
  List<String> reportKeys = const ['number', 'amount'],
  String? groupBy,
}) => ReportScheduleSeed(
  reportIdentifier: id,
  payload: payload,
  reportKeys: reportKeys,
  groupBy: groupBy,
);

void main() {
  final now = DateTime.utc(2026, 5, 19, 14, 30);

  test('maps identifier/template/columns/flags faithfully', () {
    final s = reportEmailSchedule(
      _seed(id: 'profitloss', reportKeys: ['a', 'b'], groupBy: 'client'),
      now: now,
    );
    expect(s.template, kScheduleTemplateEmailReport);
    expect(s.parameters['report_name'], 'profitloss');
    expect(s.parameters['report_keys'], ['a', 'b']);
    expect(s.parameters['group_by'], 'client');
    expect(s.parameters['send_email'], true);
    expect(s.name, 'profitloss'); // default = identifier when no name
    expect(s.nextRun, Date(2026, 5, 19)); // injected `now`, date-only
    expect(s.frequencyId, '5'); // monthly default (Schedule.empty)
  });

  test('explicit name overrides the identifier default', () {
    final s = reportEmailSchedule(_seed(), now: now, name: 'My report');
    expect(s.name, 'My report');
  });

  group('date-range alias (React DATE_RANGES_ALIASES parity)', () {
    test('last7 → last7_days, last30 → last30_days', () {
      expect(
        reportEmailSchedule(
          _seed(
            payload: const ReportPayload(datePreset: ReportDatePreset.last7),
          ),
        ).parameters['date_range'],
        'last7_days',
      );
      expect(
        reportEmailSchedule(
          _seed(
            payload: const ReportPayload(datePreset: ReportDatePreset.last30),
          ),
        ).parameters['date_range'],
        'last30_days',
      );
    });

    test('other presets pass through verbatim', () {
      expect(
        reportEmailSchedule(
          _seed(
            payload: const ReportPayload(datePreset: ReportDatePreset.allTime),
          ),
        ).parameters['date_range'],
        'all',
      );
      expect(
        reportEmailSchedule(
          _seed(
            payload: const ReportPayload(
              datePreset: ReportDatePreset.thisMonth,
            ),
          ),
        ).parameters['date_range'],
        'this_month',
      );
      expect(
        reportEmailSchedule(
          _seed(
            payload: const ReportPayload(datePreset: ReportDatePreset.last90),
          ),
        ).parameters['date_range'],
        'last90',
      );
    });

    test('custom range carries start/end ISO', () {
      final s = reportEmailSchedule(
        _seed(
          payload: ReportPayload(
            datePreset: ReportDatePreset.custom,
            startDate: Date(2026, 1, 1),
            endDate: Date(2026, 3, 31),
          ),
        ),
      );
      expect(s.parameters['date_range'], 'custom');
      expect(s.parameters['start_date'], '2026-01-01');
      expect(s.parameters['end_date'], '2026-03-31');
    });
  });

  test('CSV filters: clients → list, others verbatim string', () {
    final s = reportEmailSchedule(
      _seed(
        payload: const ReportPayload(
          clientId: 'c1',
          clients: 'c2, c3 ,',
          vendors: 'v1,v2',
          projects: 'p1',
          categories: 'cat1',
          status: 'paid',
          productKey: 'SKU1',
          templateId: 't1',
        ),
      ),
    );
    expect(s.parameters['client_id'], 'c1');
    expect(s.parameters['clients'], ['c2', 'c3']); // trimmed, empties dropped
    expect(s.parameters['vendors'], 'v1,v2');
    expect(s.parameters['projects'], 'p1');
    expect(s.parameters['categories'], 'cat1');
    expect(s.parameters['status'], 'paid');
    expect(s.parameters['product_key'], 'SKU1');
    expect(s.parameters['template_id'], 't1');
  });

  test('empty clients CSV → empty list', () {
    final s = reportEmailSchedule(_seed());
    expect(s.parameters['clients'], const <String>[]);
  });

  test('bool flags copied from payload', () {
    final s = reportEmailSchedule(
      _seed(
        payload: const ReportPayload(
          isIncomeBilled: true,
          isExpenseBilled: true,
          includeTax: true,
          includeDeleted: true,
          documentEmailAttachment: true,
          pdfEmailAttachment: true,
        ),
      ),
    );
    expect(s.parameters['is_income_billed'], true);
    expect(s.parameters['is_expense_billed'], true);
    expect(s.parameters['include_tax'], true);
    expect(s.parameters['include_deleted'], true);
    expect(s.parameters['document_email_attachment'], true);
    expect(s.parameters['pdf_email_attachment'], true);
  });
}
