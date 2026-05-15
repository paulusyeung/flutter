import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/services/reports_api.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/domain/reports/report_engine.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';
import 'package:admin/ui/features/reports/widgets/reports_chart_card.dart';
import 'package:admin/utils/formatting.dart';

import '../../../../_localization_helper.dart';

/// Returns the supplied preview on the first Run. The chart-card tests
/// need `vm.run.preview` populated so `numericChartColumns()` reads the
/// chart-eligible columns from the same place the production VM does.
class _SeededRepo implements ReportsRepository {
  _SeededRepo(this._preview);
  final ReportPreview _preview;

  @override
  Future<ReportPreview> runPreview({
    required String reportIdentifier,
    required String endpoint,
    required ReportPayload payload,
    List<String> reportKeys = const [],
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async =>
      _preview;

  @override
  Future<ReportPreview> continuePreview({
    required String hash,
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async =>
      _preview;

  @override
  Future<void> sendEmail({
    required String reportIdentifier,
    required String endpoint,
    required ReportPayload payload,
    List<String> reportKeys = const [],
    String? groupBy,
  }) async {}

  @override
  ReportsApi get api => throw UnsupportedError('not used by tests');
}

class _NullStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch({
    bool includeStatic = true,
    bool? includeData,
  }) async =>
      const <String, dynamic>{};

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

const _clientCol = ReportColumn(
  identifier: 'invoice.client',
  displayLabel: 'Client',
  type: ReportColumnType.string,
);
const _amountCol = ReportColumn(
  identifier: 'invoice.amount',
  displayLabel: 'Amount',
  type: ReportColumnType.money,
);
const _countCol = ReportColumn(
  identifier: 'invoice.count',
  displayLabel: 'Count',
  type: ReportColumnType.number,
);

ReportView _viewWith({
  required List<GroupTotals> groups,
  List<ReportColumn> visibleColumns = const [_clientCol, _amountCol, _countCol],
}) {
  return ReportView(
    visibleColumns: visibleColumns,
    rows: const [],
    groups: groups,
    grandTotalsByCurrency: const {},
    convertedGrandTotals: null,
    rowCountByCurrency: const {},
    totalRowCount: groups.fold<int>(0, (a, g) => a + g.count),
    exchangeRatesAvailable: false,
    cellIndexByColumn: const {},
  );
}

GroupTotals _group(
  String key,
  Map<String, Map<String, Decimal>> totals, {
  int rowCount = 1,
}) {
  return GroupTotals(
    key: key,
    rows: [
      for (var i = 0; i < rowCount; i++) const ReportRow(cells: []),
    ],
    numericTotals: totals,
  );
}

/// Build a VM seeded with the supplied preview. Runs an in-memory repo
/// once so `vm.run.preview` is populated, then sets the active group
/// (callers always group by `invoice.client` in these tests).
Future<ReportsViewModel> _seedVm(
  WidgetTester tester,
  ReportPreview preview, {
  String activeGroupId = 'invoice.client',
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final statics = StaticsRepository(db: db, service: _NullStaticsService());
  final vm = ReportsViewModel(repo: _SeededRepo(preview), statics: statics);
  await vm.runReport();
  vm.setGroup(activeGroupId);
  return vm;
}

Formatter _testFormatter() => Formatter(
      settings: CompanyFormatSettings.fallback,
      currencies: const {},
      countries: const {},
      dateFormats: const {},
    );

Future<void> _pump(
  WidgetTester tester, {
  required ReportsViewModel vm,
  required ReportView view,
  Formatter? formatter,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: ChangeNotifierProvider<ReportsViewModel>.value(
        value: vm,
        child: Scaffold(
          body: ReportsChartCard(view: view, formatter: formatter),
        ),
      ),
    ),
  );
  // Initial paint, then the post-frame auto-pick callback fires + the
  // VM's notifyListeners rebuilds the card.
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders a bar chart with one bar per group, '
      'sorted by value descending', (tester) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol, _countCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {'1': Decimal.fromInt(50)},
      }),
      _group('Beta', {
        'invoice.amount': {'1': Decimal.fromInt(200)},
      }),
      _group('Gamma', {
        'invoice.amount': {'1': Decimal.fromInt(120)},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    expect(find.byType(BarChart), findsOneWidget);
    // Auto-pick fired → chartColumn is the first numeric column (amount).
    expect(vm.chartColumn, 'invoice.amount');

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final groups = chart.data.barGroups;
    expect(groups.length, 3);
    // Bars sorted descending: Beta (200), Gamma (120), Acme (50).
    expect(groups[0].barRods.first.toY, 200);
    expect(groups[1].barRods.first.toY, 120);
    expect(groups[2].barRods.first.toY, 50);
  });

  testWidgets('empty-state hint renders when all bars are zero', (
    tester,
  ) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {'1': Decimal.zero},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    expect(find.byType(BarChart), findsNothing);
    expect(
      find.text('No numeric values to chart — pick a different column.'),
      findsOneWidget,
    );
  });

  testWidgets('close button calls setChartVisible(false)', (tester) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {'1': Decimal.fromInt(10)},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    expect(vm.chartVisible, isTrue);
    await tester.tap(find.byTooltip('Hide chart'));
    await tester.pump();
    expect(vm.chartVisible, isFalse);
  });

  testWidgets('currency picker hidden when only one currency is present',
      (tester) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {'1': Decimal.fromInt(10)},
      }),
      _group('Beta', {
        'invoice.amount': {'1': Decimal.fromInt(20)},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    // Only one numeric column AND one currency → no dropdowns at all.
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(
      find.textContaining('Switch above to see other currencies'),
      findsNothing,
    );
  });

  testWidgets('currency picker + mixed-currency hint appear with '
      'multi-currency data', (tester) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {
          '1': Decimal.fromInt(10),
          '2': Decimal.fromInt(50),
        },
      }),
      _group('Beta', {
        'invoice.amount': {'1': Decimal.fromInt(20)},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    // Currency dropdown visible.
    expect(find.byType(DropdownButton<String>), findsWidgets);
    // Mixed-currency hint shown until the user picks one explicitly.
    expect(
      find.textContaining('Switch above to see other currencies'),
      findsOneWidget,
    );
  });

  testWidgets('column picker shows only numeric columns (string columns '
      'are filtered out)', (tester) async {
    final vm = await _seedVm(
      tester,
      const ReportPreview(
        columns: [_clientCol, _amountCol, _countCol],
        rows: [],
      ),
    );

    final view = _viewWith(groups: [
      _group('Acme', {
        'invoice.amount': {'1': Decimal.fromInt(10)},
        'invoice.count': {'1': Decimal.fromInt(2)},
      }),
    ]);
    await _pump(tester, vm: vm, view: view, formatter: _testFormatter());

    // Two numeric columns → picker exists. Open it and verify the menu
    // shows only numeric column labels. The card title also says
    // "Client" (the group column's label), so scope the assertion to
    // `DropdownMenuItem<String>` to look at picker contents only.
    final picker = find.byType(DropdownButton<String>).first;
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.text('Amount'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.text('Count'),
      ),
      findsWidgets,
    );
    // String column never appears as a menu item.
    expect(
      find.descendant(
        of: find.byType(DropdownMenuItem<String>),
        matching: find.text('Client'),
      ),
      findsNothing,
    );
  });
}
