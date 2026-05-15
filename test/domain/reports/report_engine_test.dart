import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/domain/reports/report_engine.dart';

void main() {
  group('ReportEngine.compute', () {
    const engine = ReportEngine();
    Decimal d(String s) => Decimal.parse(s);

    ReportPreview previewWith({
      List<List<ReportCell>> rows = const [],
      List<ReportColumn> columns = const [],
    }) {
      return ReportPreview(
        columns: columns,
        rows: [for (final cells in rows) ReportRow(cells: cells)],
      );
    }

    final clientCol = const ReportColumn(
      identifier: 'client.name',
      displayLabel: 'Client',
      type: ReportColumnType.string,
    );
    final amountCol = const ReportColumn(
      identifier: 'invoice.amount',
      displayLabel: 'Amount',
      type: ReportColumnType.money,
    );
    final dateCol = const ReportColumn(
      identifier: 'invoice.date',
      displayLabel: 'Date',
      type: ReportColumnType.date,
    );

    test('returns empty view for an empty preview', () {
      final view = engine.compute(
        preview: ReportPreview.empty,
        ui: const ReportUiState(),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(view.rows, isEmpty);
      expect(view.groups, isEmpty);
    });

    test('sorts strings ascending by default, descending on flip', () {
      final preview = previewWith(
        columns: [clientCol],
        rows: [
          [ReportStringCell(value: 'Charlie')],
          [ReportStringCell(value: 'alpha')],
          [ReportStringCell(value: 'Bravo')],
        ],
      );
      final asc = engine.compute(
        preview: preview,
        ui: const ReportUiState(sortField: 'client.name'),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(
        asc.rows.map((r) => (r.cells.first as ReportStringCell).value),
        ['alpha', 'Bravo', 'Charlie'],
      );
      final desc = engine.compute(
        preview: preview,
        ui: const ReportUiState(
          sortField: 'client.name',
          sortAscending: false,
        ),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(
        desc.rows.map((r) => (r.cells.first as ReportStringCell).value),
        ['Charlie', 'Bravo', 'alpha'],
      );
    });

    test('sorts numbers using Decimal comparison, not string', () {
      final preview = previewWith(
        columns: [amountCol],
        rows: [
          [ReportNumberCell(value: d('100.00'), isMoney: true)],
          [ReportNumberCell(value: d('20.00'), isMoney: true)],
          [ReportNumberCell(value: d('3.00'), isMoney: true)],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(sortField: 'invoice.amount'),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      final amounts = view.rows
          .map((r) => (r.cells.first as ReportNumberCell).value)
          .toList();
      expect(amounts, [d('3.00'), d('20.00'), d('100.00')]);
    });

    test('column substring filter applies (case-insensitive)', () {
      final preview = previewWith(
        columns: [clientCol],
        rows: [
          [
            ReportStringCell(value: 'ACME Corp', displayValue: 'ACME Corp')
          ],
          [
            ReportStringCell(
              value: 'Foo Industries',
              displayValue: 'Foo Industries',
            )
          ],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(columnFilters: {'client.name': 'acme'}),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(view.rows, hasLength(1));
      expect(
        (view.rows.first.cells.first as ReportStringCell).value,
        'ACME Corp',
      );
    });

    test('numeric range filter applies (lower-upper)', () {
      final preview = previewWith(
        columns: [amountCol],
        rows: [
          [ReportNumberCell(value: d('50'), isMoney: true)],
          [ReportNumberCell(value: d('150'), isMoney: true)],
          [ReportNumberCell(value: d('500'), isMoney: true)],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(columnFilters: {'invoice.amount': '100-400'}),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(view.rows, hasLength(1));
      expect(
        (view.rows.first.cells.first as ReportNumberCell).value,
        d('150'),
      );
    });

    test('groups by string column and counts members', () {
      final preview = previewWith(
        columns: [clientCol, amountCol],
        rows: [
          [
            ReportStringCell(value: 'ACME'),
            ReportNumberCell(value: d('100'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportStringCell(value: 'ACME'),
            ReportNumberCell(value: d('200'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportStringCell(value: 'Foo'),
            ReportNumberCell(value: d('50'), isMoney: true, currencyId: '1'),
          ],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(group: 'client.name'),
        exchangeRates: {'1': Decimal.one},
        companyCurrencyId: '1',
      );
      expect(view.rows, isEmpty);
      expect(view.groups.map((g) => g.key), ['ACME', 'Foo']);
      expect(view.groups.first.count, 2);
      expect(
        view.groups.first.numericTotals['invoice.amount']!['1'],
        d('300'),
      );
    });

    test('subgroup=month buckets dates correctly', () {
      final preview = previewWith(
        columns: [dateCol, amountCol],
        rows: [
          [
            ReportDateCell(value: Date.tryParse('2026-04-10')!),
            ReportNumberCell(value: d('10'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportDateCell(value: Date.tryParse('2026-04-25')!),
            ReportNumberCell(value: d('15'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportDateCell(value: Date.tryParse('2026-05-02')!),
            ReportNumberCell(value: d('20'), isMoney: true, currencyId: '1'),
          ],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(
          group: 'invoice.date',
          subgroup: ReportSubgroup.month,
        ),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(view.groups.map((g) => g.key), ['2026-04-01', '2026-05-01']);
      expect(view.groups.first.count, 2);
    });

    test('drill-down filters to selectedGroup and composes with column filters',
        () {
      final preview = previewWith(
        columns: [clientCol, amountCol],
        rows: [
          [
            ReportStringCell(value: 'ACME', displayValue: 'ACME'),
            ReportNumberCell(value: d('100'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportStringCell(value: 'ACME', displayValue: 'ACME'),
            ReportNumberCell(value: d('500'), isMoney: true, currencyId: '1'),
          ],
          [
            ReportStringCell(value: 'Foo', displayValue: 'Foo'),
            ReportNumberCell(value: d('200'), isMoney: true, currencyId: '1'),
          ],
        ],
      );
      // Drilled into ACME with no extra column filter — see 2 rows.
      final drilled = engine.compute(
        preview: preview,
        ui: const ReportUiState(
          group: 'client.name',
          selectedGroup: 'ACME',
        ),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(drilled.rows, hasLength(2));
      expect(drilled.groups, isEmpty);
      // Drilled in AND a column filter on amount — composes.
      final composed = engine.compute(
        preview: preview,
        ui: const ReportUiState(
          group: 'client.name',
          selectedGroup: 'ACME',
          columnFilters: {'invoice.amount': '0-200'},
        ),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(composed.rows, hasLength(1));
      expect(
        (composed.rows.first.cells.first as ReportStringCell).value,
        'ACME',
      );
    });

    test('per-currency totals bucket by currencyId', () {
      final preview = previewWith(
        columns: [amountCol],
        rows: [
          [ReportNumberCell(value: d('100'), isMoney: true, currencyId: '1')],
          [ReportNumberCell(value: d('200'), isMoney: true, currencyId: '1')],
          [ReportNumberCell(value: d('50'), isMoney: true, currencyId: '3')],
        ],
      );
      final view = engine.compute(
        preview: preview,
        ui: const ReportUiState(),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      final perCur = view.grandTotalsByCurrency['invoice.amount']!;
      expect(perCur['1'], d('300'));
      expect(perCur['3'], d('50'));
      expect(view.rowCountByCurrency['1'], 2);
      expect(view.rowCountByCurrency['3'], 1);
    });

    test(
        'converted totals require non-empty exchange rates AND a company currency',
        () {
      final preview = previewWith(
        columns: [amountCol],
        rows: [
          [ReportNumberCell(value: d('100'), isMoney: true, currencyId: '1')],
          [ReportNumberCell(value: d('100'), isMoney: true, currencyId: '3')],
        ],
      );
      // Cold launch — no rates yet → converted totals stay null.
      final cold = engine.compute(
        preview: preview,
        ui: const ReportUiState(convertCurrency: true),
        exchangeRates: const {},
        companyCurrencyId: '1',
      );
      expect(cold.convertedGrandTotals, isNull);
      expect(cold.exchangeRatesAvailable, isFalse);
      // Rates present → convert.
      final warm = engine.compute(
        preview: preview,
        ui: const ReportUiState(convertCurrency: true),
        exchangeRates: {'1': Decimal.one, '3': d('0.5')},
        companyCurrencyId: '1',
      );
      expect(warm.exchangeRatesAvailable, isTrue);
      // 100 USD stays 100; 100 EUR at rate 0.5 -> 200 USD; total 300.
      expect(warm.convertedGrandTotals!['invoice.amount'], d('300'));
    });
  });

  group('ReportUiState value equality', () {
    test('identical-field instances compare equal and share hashCode', () {
      final a = ReportUiState(
        visibleColumnIds: {'client.name', 'invoice.amount'},
        columnFilters: const {'client.name': 'acme', 'invoice.amount': '100-500'},
        sortField: 'invoice.amount',
        sortAscending: false,
        group: 'client.country',
        subgroup: ReportSubgroup.month,
        selectedGroup: 'USA',
        convertCurrency: true,
      );
      // Different set/map identities, same contents.
      final b = ReportUiState(
        visibleColumnIds: {'invoice.amount', 'client.name'},
        columnFilters: const {'invoice.amount': '100-500', 'client.name': 'acme'},
        sortField: 'invoice.amount',
        sortAscending: false,
        group: 'client.country',
        subgroup: ReportSubgroup.month,
        selectedGroup: 'USA',
        convertCurrency: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('any field difference flips equality and hashCode', () {
      const base = ReportUiState(sortField: 'a', group: 'b');
      const sortDiff = ReportUiState(sortField: 'a2', group: 'b');
      const groupDiff = ReportUiState(sortField: 'a', group: 'b2');
      expect(base == sortDiff, isFalse);
      expect(base.hashCode == sortDiff.hashCode, isFalse);
      expect(base == groupDiff, isFalse);
      expect(base.hashCode == groupDiff.hashCode, isFalse);
    });
  });
}
