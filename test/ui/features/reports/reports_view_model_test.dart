import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/reports_api.dart';
import 'package:admin/data/services/statics_service.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';

class _Trigger {
  final Completer<void> _gate = Completer<void>();
  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  Future<void> get future => _gate.future;
}

/// Repository fake — drives runReport's behavior step-by-step via Triggers
/// so the test can interleave concurrent calls deterministically.
class _FakeRepo implements ReportsRepository {
  final List<_Trigger> _gates = [];
  final List<Object> _outcomes = [];

  /// Queue a "this call waits on [gate] then returns [preview]".
  void queue(_Trigger gate, ReportPreview preview) {
    _gates.add(gate);
    _outcomes.add(preview);
  }

  /// Queue a "this call waits on [gate] then throws [error]".
  void queueError(_Trigger gate, Object error) {
    _gates.add(gate);
    _outcomes.add(error);
  }

  int callCount = 0;

  @override
  Future<ReportPreview> runPreview({
    required String reportIdentifier,
    required String endpoint,
    required ReportPayload payload,
    List<String> reportKeys = const [],
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    final i = callCount++;
    await _gates[i].future;
    if (isCancelled?.call() == true) {
      throw const ReportError(kind: ReportErrorKind.cancelled);
    }
    final out = _outcomes[i];
    if (out is ReportPreview) return out;
    throw out;
  }

  @override
  Future<ReportPreview> continuePreview({
    required String hash,
    int maxRetries = ReportsApi.defaultPreviewRetries,
    Duration pollInterval = ReportsApi.defaultPollInterval,
    ReportPollingCancellation? isCancelled,
  }) async {
    throw UnimplementedError();
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late StaticsRepository statics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    statics = StaticsRepository(
      db: db,
      service: _NullStaticsService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  ReportPreview previewOf(String marker) => ReportPreview(
        columns: const [],
        rows: [
          ReportRow(cells: [ReportStringCell(value: marker, displayValue: marker)]),
        ],
      );

  test('isParamDirty flips on payload change and clears after a successful run',
      () async {
    final repo = _FakeRepo();
    final firstGate = _Trigger()..release();
    repo.queue(firstGate, previewOf('a'));
    final vm = ReportsViewModel(repo: repo, statics: statics);

    // Edit the date preset → dirty without a run.
    vm.setPayload(vm.payload.copyWith(datePreset: ReportDatePreset.lastMonth));
    expect(vm.isParamDirty, isTrue);

    await vm.runReport();
    expect(vm.run.status, ReportRunStatus.ready);
    expect(vm.isParamDirty, isFalse);

    vm.setPayload(vm.payload.copyWith(datePreset: ReportDatePreset.thisYear));
    expect(vm.isParamDirty, isTrue);
  });

  test('concurrent Runs: only the latest result lands; older futures no-op',
      () async {
    final repo = _FakeRepo();
    final g1 = _Trigger();
    final g2 = _Trigger();
    repo.queue(g1, previewOf('first'));
    repo.queue(g2, previewOf('second'));
    final vm = ReportsViewModel(repo: repo, statics: statics);

    final f1 = vm.runReport();
    final f2 = vm.runReport();
    // Release the *second* call first — that's the one whose epoch matches.
    g2.release();
    await f2;
    // Release the first call — its epoch is stale, must not overwrite.
    g1.release();
    await f1;
    expect(vm.run.status, ReportRunStatus.ready);
    expect(
      (vm.run.preview!.rows.first.cells.first as ReportStringCell).value,
      'second',
    );
  });

  test('cancelRun bumps epoch and restores previous preview', () async {
    final repo = _FakeRepo();
    final firstGate = _Trigger()..release();
    repo.queue(firstGate, previewOf('a'));
    final secondGate = _Trigger();
    repo.queue(secondGate, previewOf('b'));
    final vm = ReportsViewModel(repo: repo, statics: statics);

    await vm.runReport();
    expect(vm.run.status, ReportRunStatus.ready);

    final pending = vm.runReport();
    expect(vm.run.isLoading, isTrue);
    vm.cancelRun();
    expect(vm.run.status, ReportRunStatus.ready);
    expect(
      (vm.run.preview!.rows.first.cells.first as ReportStringCell).value,
      'a',
    );
    secondGate.release();
    await pending;
    // The first preview is still what the user sees — the stranded second
    // run did not overwrite.
    expect(
      (vm.run.preview!.rows.first.cells.first as ReportStringCell).value,
      'a',
    );
  });

  group('chartColumn', () {
    test('setChartColumn updates the getter and notifies listeners',
        () async {
      final repo = _FakeRepo();
      final vm = ReportsViewModel(repo: repo, statics: statics);
      var notified = 0;
      vm.addListener(() => notified++);

      expect(vm.chartColumn, isNull);
      vm.setChartColumn('invoice.amount');
      expect(vm.chartColumn, 'invoice.amount');
      expect(notified, 1);

      // Same value is a no-op — no second notification.
      vm.setChartColumn('invoice.amount');
      expect(notified, 1);

      // Null clears.
      vm.setChartColumn(null);
      expect(vm.chartColumn, isNull);
      expect(notified, 2);
    });

    test('setReport clears chartColumn (new report\'s columns are unrelated)',
        () async {
      final repo = _FakeRepo();
      final vm = ReportsViewModel(repo: repo, statics: statics);
      vm.setChartColumn('invoice.amount');
      expect(vm.chartColumn, 'invoice.amount');

      // Switch to any other registered report — the identifier just needs
      // to differ; we don't run it, only assert the reset behavior.
      final otherId = vm.reportIdentifier == 'invoice' ? 'payment' : 'invoice';
      vm.setReport(otherId);
      expect(vm.chartColumn, isNull);
    });

    test('resetEverything clears chartColumn', () async {
      final repo = _FakeRepo();
      final vm = ReportsViewModel(repo: repo, statics: statics);
      vm.setChartColumn('invoice.amount');
      vm.resetEverything();
      expect(vm.chartColumn, isNull);
    });

    test('numericChartColumns returns only money + number types from preview',
        () async {
      final repo = _FakeRepo();
      final firstGate = _Trigger()..release();
      repo.queue(
        firstGate,
        const ReportPreview(
          columns: [
            ReportColumn(
              identifier: 'invoice.client',
              displayLabel: 'Client',
              type: ReportColumnType.string,
            ),
            ReportColumn(
              identifier: 'invoice.amount',
              displayLabel: 'Amount',
              type: ReportColumnType.money,
            ),
            ReportColumn(
              identifier: 'invoice.count',
              displayLabel: 'Count',
              type: ReportColumnType.number,
            ),
            ReportColumn(
              identifier: 'invoice.created_at',
              displayLabel: 'Created',
              type: ReportColumnType.dateTime,
            ),
          ],
          rows: [],
        ),
      );
      final vm = ReportsViewModel(repo: repo, statics: statics);
      // Before a Run lands → no preview → empty list.
      expect(vm.numericChartColumns(), isEmpty);

      await vm.runReport();
      final ids = vm
          .numericChartColumns()
          .map((c) => c.identifier)
          .toList();
      expect(ids, ['invoice.amount', 'invoice.count']);
    });
  });

  test('dispose strands in-flight futures cleanly', () async {
    final repo = _FakeRepo();
    final gate = _Trigger();
    repo.queue(gate, previewOf('a'));
    final vm = ReportsViewModel(repo: repo, statics: statics);

    final pending = vm.runReport();
    vm.dispose();
    gate.release();
    // Must complete without throwing or calling notifyListeners after
    // dispose — pending should resolve via the disposed check.
    await pending;
  });
}

class _NullStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch(
      {bool includeStatic = true, bool? includeData}) async =>
      const <String, dynamic>{};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
