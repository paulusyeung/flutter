import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/models/domain/report_definition.dart';
import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/reports_api.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/domain/reports/report_engine.dart';
import 'package:admin/domain/reports/report_registry.dart';

final _log = Logger('ReportsViewModel');

enum ReportRunStatus { idle, loading, ready, error }

class ReportRunState {
  const ReportRunState({
    required this.status,
    this.preview,
    this.error,
  });

  factory ReportRunState.idle() =>
      const ReportRunState(status: ReportRunStatus.idle);

  /// Loading. Carries the [previousPreview] forward so [cancelRun] can
  /// restore it without an additional VM field — the table stays visible
  /// while the user reruns, and a cancel reverts to what was on screen.
  factory ReportRunState.loading({ReportPreview? previousPreview}) =>
      ReportRunState(
        status: ReportRunStatus.loading,
        preview: previousPreview,
      );
  factory ReportRunState.ready(ReportPreview preview) =>
      ReportRunState(status: ReportRunStatus.ready, preview: preview);
  factory ReportRunState.error(ReportError error, {ReportPreview? lastGood}) =>
      ReportRunState(
        status: ReportRunStatus.error,
        preview: lastGood,
        error: error,
      );

  final ReportRunStatus status;

  /// The last successful preview. Stays populated through Cancel and error
  /// states so the table doesn't blank out during a failed Run.
  final ReportPreview? preview;

  final ReportError? error;

  bool get isLoading => status == ReportRunStatus.loading;
  bool get hasPreview => preview != null && preview!.rows.isNotEmpty;
}

/// State holder for the Reports screen. Pure `ChangeNotifier` — owns the
/// payload (server-side filter inputs that drive a refetch), the result, and
/// all local manipulation state (sort / column filters / group / column
/// visibility — none of which refetch).
///
/// `FormatterHostMixin` is a `State<T>` mixin (lib/ui/core/widgets/
/// formatter_host_mixin.dart) and cannot apply here — the screen's State
/// mixes it in and passes the formatter to [buildView] / export helpers.
class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({
    required this.repo,
    required this.statics,
    String initialReport = kDefaultReportIdentifier,
  })  : _reportIdentifier = initialReport,
        _payload = const ReportPayload();

  final ReportsRepository repo;
  final StaticsRepository statics;

  // ─── Payload (server-side) ───
  String _reportIdentifier;
  String get reportIdentifier => _reportIdentifier;
  ReportDefinition get definition => reportDefinitionFor(_reportIdentifier);

  ReportPayload _payload;
  ReportPayload get payload => _payload;

  /// Snapshot of [payload] at the moment of the last successful run.
  /// `isParamDirty` compares against this — column toggles, sort, group,
  /// and column filters are NOT in here so changing them doesn't bump
  /// dirty (they're local-render concerns).
  ReportPayload? _lastRunPayload;
  bool get isParamDirty => _payload != _lastRunPayload;

  // ─── Result ───
  ReportRunState _run = ReportRunState.idle();
  ReportRunState get run => _run;

  String? _activePollingHash; // for "Keep waiting?" continuation

  // ─── Local-only UI state ───
  Set<String> _visibleColumnIds = const {};
  Set<String> get visibleColumnIds => _visibleColumnIds;

  Map<String, String> _columnFilters = const {};
  Map<String, String> get columnFilters => _columnFilters;

  bool _columnFiltersVisible = false;
  bool get columnFiltersVisible => _columnFiltersVisible;

  bool _chartVisible = true;
  bool get chartVisible => _chartVisible;

  String? _sortField;
  bool _sortAscending = true;
  String? get sortField => _sortField;
  bool get sortAscending => _sortAscending;

  String? _group;
  String? get group => _group;
  ReportSubgroup? _subgroup;
  ReportSubgroup? get subgroup => _subgroup;
  String? _selectedGroup;
  String? get selectedGroup => _selectedGroup;

  /// Identifier of the numeric column the chart card aggregates per group.
  /// Null when no group is active or before the chart card auto-picks the
  /// first numeric column from the active preview. Cleared on `setReport`
  /// (a new report's column set is unrelated) and `resetEverything`.
  String? _chartColumn;
  String? get chartColumn => _chartColumn;

  /// Numeric columns (money + plain number) from the active preview that
  /// the chart card's column picker can offer. Returns `[]` before a
  /// preview is loaded. Reads from `preview.columns`, not
  /// `_visibleColumnIds`, so hiding a column from the table doesn't blank
  /// the chart.
  List<ReportColumn> numericChartColumns() {
    final preview = _run.preview;
    if (preview == null) return const [];
    return preview.columns
        .where(
          (c) =>
              c.type == ReportColumnType.money ||
              c.type == ReportColumnType.number,
        )
        .toList(growable: false);
  }

  /// Active filter count for the toolbar badge. Excludes `date_range`
  /// and `date_key` (they have their own toolbar surface) and matches
  /// against the report's `defaultFilterValues`.
  int get activeFilterCount {
    final defaults = definition.defaultFilterValues;
    String defaultStr(String key) => defaults[key]?.toString() ?? '';
    bool defaultBool(String key) => defaults[key] == true;
    var n = 0;
    for (final f in definition.filterFields) {
      bool changed;
      switch (f) {
        case ReportFilterField.dateRange:
        case ReportFilterField.dateColumn:
          continue;
        case ReportFilterField.status:
          changed = (_payload.status ?? '') != defaultStr('status');
        case ReportFilterField.clientsMulti:
          changed = (_payload.clients ?? '') != defaultStr('clients');
        case ReportFilterField.clientSingle:
          changed = (_payload.clientId ?? '') != defaultStr('client_id');
        case ReportFilterField.vendorsMulti:
          changed = (_payload.vendors ?? '') != defaultStr('vendors');
        case ReportFilterField.projectsMulti:
          changed = (_payload.projects ?? '') != defaultStr('projects');
        case ReportFilterField.categoriesMulti:
          changed = (_payload.categories ?? '') != defaultStr('categories');
        case ReportFilterField.activityType:
          changed = (_payload.activityTypeId ?? '') !=
              defaultStr('activity_type_id');
        case ReportFilterField.productKey:
          changed = (_payload.productKey ?? '') != defaultStr('product_key');
        case ReportFilterField.template:
          changed = (_payload.templateId ?? '') != defaultStr('template');
        case ReportFilterField.documentEmailAttachment:
          changed = _payload.documentEmailAttachment !=
              defaultBool('document_email_attachment');
        case ReportFilterField.pdfEmailAttachment:
          changed = _payload.pdfEmailAttachment !=
              defaultBool('pdf_email_attachment');
        case ReportFilterField.includeDeleted:
          changed =
              _payload.includeDeleted != defaultBool('include_deleted');
        case ReportFilterField.includeTax:
          changed = _payload.includeTax != defaultBool('include_tax');
        case ReportFilterField.isExpenseBilled:
          changed =
              _payload.isExpenseBilled != defaultBool('is_expense_billed');
        case ReportFilterField.isIncomeBilled:
          changed =
              _payload.isIncomeBilled != defaultBool('is_income_billed');
      }
      if (changed) n++;
    }
    return n;
  }

  // ─── Concurrency ───
  int _runEpoch = 0;
  bool _disposed = false;

  /// Used by the polling layer to bail out on cancel / dispose. Captures
  /// the epoch at the moment the run started so a fresh run (which bumps
  /// the epoch) immediately strands the old poll.
  ReportPollingCancellation _cancellationFor(int epoch) =>
      () => _disposed || _runEpoch != epoch;

  // ─── Engine memoization ───
  final _engine = const ReportEngine();
  // Memo key: (preview identity, ui-state hash, exchange-rates epoch).
  // statics.currencies is rebuilt on company switch / refresh; we use its
  // identityHashCode as a cheap epoch proxy.
  int? _memoKey;
  ReportView? _memoView;

  /// Compute the view from the current preview + UI state. Memoized so the
  /// table widget can call this on every rebuild without recomputing.
  ///
  /// Caller supplies the [companyCurrencyId] and [convertCurrency] flag
  /// (typically from the active company's `CompanyFormatSettings` + a
  /// pending settings model). Phase 1 ships with `convertCurrency: false`
  /// so the engine path is wired but defaulted off; flipping it on per
  /// company is a Phase-2 concern.
  ReportView buildView({
    String? companyCurrencyId,
    bool convertCurrency = false,
    Map<String, Decimal>? exchangeRatesOverride,
  }) {
    final preview = _run.preview ?? ReportPreview.empty;
    final rates = exchangeRatesOverride ??
        {
          for (final entry in statics.currencies.entries)
            entry.key: entry.value.exchangeRate,
        };
    final ratesEpoch = identityHashCode(statics.currencies);
    final ui = ReportUiState(
      visibleColumnIds: _visibleColumnIds,
      columnFilters: _columnFilters,
      sortField: _sortField,
      sortAscending: _sortAscending,
      group: _group,
      subgroup: _subgroup,
      selectedGroup: _selectedGroup,
      convertCurrency: convertCurrency,
    );
    final key = Object.hash(
      identityHashCode(preview),
      ui.hashCode,
      ratesEpoch,
      companyCurrencyId,
      convertCurrency,
    );
    if (_memoKey == key && _memoView != null) return _memoView!;
    _memoView = _engine.compute(
      preview: preview,
      ui: ui,
      exchangeRates: rates,
      companyCurrencyId: companyCurrencyId,
    );
    _memoKey = key;
    return _memoView!;
  }

  void _invalidateMemo() {
    _memoKey = null;
    _memoView = null;
  }

  // ─── Mutations ───

  void setReport(String identifier) {
    if (identifier == _reportIdentifier) return;
    _reportIdentifier = identifier;
    // Reset payload-side state to defaults for the new report, but keep the
    // local-only state (visible columns) cleared so the new report's
    // server-returned columns are all initially visible.
    _payload = const ReportPayload();
    _visibleColumnIds = const {};
    _columnFilters = const {};
    _sortField = null;
    _group = null;
    _subgroup = null;
    _selectedGroup = null;
    _chartColumn = null;
    _run = ReportRunState.idle();
    _invalidateMemo();
    notifyListeners();
  }

  void setPayload(ReportPayload payload) {
    if (payload == _payload) return;
    _payload = payload;
    notifyListeners();
  }

  void setVisibleColumns(Set<String> ids) {
    _visibleColumnIds = Set.unmodifiable(ids);
    _invalidateMemo();
    notifyListeners();
  }

  void setColumnFilter(String columnId, String value) {
    final next = Map<String, String>.from(_columnFilters);
    if (value.isEmpty) {
      next.remove(columnId);
    } else {
      next[columnId] = value;
    }
    _columnFilters = Map.unmodifiable(next);
    _invalidateMemo();
    notifyListeners();
  }

  void clearColumnFilter(String columnId) => setColumnFilter(columnId, '');

  void toggleColumnFiltersVisible() {
    _columnFiltersVisible = !_columnFiltersVisible;
    notifyListeners();
  }

  void setChartVisible(bool value) {
    if (_chartVisible == value) return;
    _chartVisible = value;
    notifyListeners();
  }

  /// Pick the column the chart card aggregates by. Null clears. Does NOT
  /// invalidate the engine memo — `chartColumn` doesn't feed into the
  /// engine compute; the chart card reads from the same `ReportView` the
  /// table renders.
  void setChartColumn(String? id) {
    if (_chartColumn == id) return;
    _chartColumn = id;
    notifyListeners();
  }

  /// Click a column header to (re)sort. First click → ascending; second
  /// click on the same column → descending; subsequent clicks toggle.
  void toggleSort(String columnId) {
    if (_sortField == columnId) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = columnId;
      _sortAscending = true;
    }
    _invalidateMemo();
    notifyListeners();
  }

  void setGroup(String? columnId, {ReportSubgroup? subgroup}) {
    _group = columnId;
    _subgroup = columnId == null ? null : (subgroup ?? _subgroup);
    _selectedGroup = null;
    _invalidateMemo();
    notifyListeners();
  }

  void setSubgroup(ReportSubgroup? sg) {
    _subgroup = sg;
    _invalidateMemo();
    notifyListeners();
  }

  void setSelectedGroup(String? key) {
    _selectedGroup = key;
    _invalidateMemo();
    notifyListeners();
  }

  /// Reset payload filter values (not date range / date column / columns /
  /// sort / group). Keeps the loaded preview so the user doesn't have to
  /// re-Run just to clear filters.
  void resetFilters() {
    final defaults = definition.defaultFilterValues;
    _payload = ReportPayload(
      datePreset: _payload.datePreset,
      startDate: _payload.startDate,
      endDate: _payload.endDate,
      dateKey: _payload.dateKey,
      clientId: defaults['client_id']?.toString(),
      clients: defaults['clients']?.toString(),
      vendors: defaults['vendors']?.toString(),
      categories: defaults['categories']?.toString(),
      projects: defaults['projects']?.toString(),
      status: defaults['status']?.toString(),
      activityTypeId: defaults['activity_type_id']?.toString(),
      productKey: defaults['product_key']?.toString(),
      templateId: defaults['template']?.toString(),
      documentEmailAttachment: defaults['document_email_attachment'] == true,
      pdfEmailAttachment: defaults['pdf_email_attachment'] == true,
      includeDeleted: defaults['include_deleted'] == true,
      includeTax: defaults['include_tax'] == true,
      isExpenseBilled: defaults['is_expense_billed'] == true,
      isIncomeBilled: defaults['is_income_billed'] == true,
    );
    notifyListeners();
  }

  /// Reset everything except the report identifier — payload, columns,
  /// sort, group, chart. The loaded preview stays so the user can recover
  /// by re-Running.
  void resetEverything() {
    _payload = const ReportPayload();
    _visibleColumnIds = const {};
    _columnFilters = const {};
    _sortField = null;
    _sortAscending = true;
    _group = null;
    _subgroup = null;
    _selectedGroup = null;
    _chartColumn = null;
    _chartVisible = true;
    _invalidateMemo();
    notifyListeners();
  }

  // ─── Server actions ───

  Future<void> runReport() async {
    final epoch = ++_runEpoch;
    final lastGood = _run.preview;
    _run = ReportRunState.loading(previousPreview: lastGood);
    _activePollingHash = null;
    notifyListeners();

    try {
      final preview = await repo.runPreview(
        reportIdentifier: _reportIdentifier,
        endpoint: definition.endpoint,
        payload: _payload,
        reportKeys: _visibleColumnIds.toList(),
        isCancelled: _cancellationFor(epoch),
      );
      if (_disposed || epoch != _runEpoch) return;
      _lastRunPayload = _payload;
      _run = ReportRunState.ready(preview);
      _activePollingHash = null;
      // First Run on this report: default visible columns to the server's
      // returned set so the column picker has a baseline.
      if (_visibleColumnIds.isEmpty) {
        _visibleColumnIds =
            preview.columns.map((c) => c.identifier).toSet();
      }
      _invalidateMemo();
      notifyListeners();
    } on ReportError catch (e) {
      if (_disposed || epoch != _runEpoch) return;
      if (e.kind == ReportErrorKind.cancelled) {
        // Cancelled: restore previous preview if any, else go back to idle.
        _run = lastGood == null
            ? ReportRunState.idle()
            : ReportRunState.ready(lastGood);
        notifyListeners();
        return;
      }
      _activePollingHash = e.pollingHash;
      _run = ReportRunState.error(e, lastGood: lastGood);
      notifyListeners();
    } catch (e, st) {
      if (_disposed || epoch != _runEpoch) return;
      _log.warning('Unhandled report run failure', e, st);
      _run = ReportRunState.error(
        const ReportError(kind: ReportErrorKind.unknown),
        lastGood: lastGood,
      );
      notifyListeners();
    }
  }

  /// Re-poll the in-flight hash for another budget. Only valid when the
  /// last error was a timeout; the repository surfaces a `pollingHash` on
  /// that error specifically so we can pick up where we left off.
  Future<void> keepWaiting() async {
    final hash = _activePollingHash;
    if (hash == null) return;
    final epoch = ++_runEpoch;
    final lastGood = _run.preview;
    _run = ReportRunState.loading(previousPreview: lastGood);
    notifyListeners();
    try {
      final preview = await repo.continuePreview(
        hash: hash,
        isCancelled: _cancellationFor(epoch),
      );
      if (_disposed || epoch != _runEpoch) return;
      _lastRunPayload = _payload;
      _run = ReportRunState.ready(preview);
      _activePollingHash = null;
      _invalidateMemo();
      notifyListeners();
    } on ReportError catch (e) {
      if (_disposed || epoch != _runEpoch) return;
      _activePollingHash = e.pollingHash;
      _run = ReportRunState.error(e, lastGood: lastGood);
      notifyListeners();
    }
  }

  /// Bump the epoch (stranding the in-flight future) and restore the
  /// previous preview if one existed. Caller surfaces a "Run cancelled"
  /// snackbar.
  void cancelRun() {
    if (!_run.isLoading) return;
    _runEpoch++;
    final lastGood = _run.preview;
    _run = lastGood == null
        ? ReportRunState.idle()
        : ReportRunState.ready(lastGood);
    notifyListeners();
  }

  /// Email-flow: POSTs `send_email: true` and returns. Email is independent
  /// of the preview/Run state — failures don't taint `_run` (the on-screen
  /// table doesn't owe the user an error there). Callers surface their own
  /// snackbar via the rethrown [ReportError].
  Future<void> sendEmail() async {
    await repo.sendEmail(
      reportIdentifier: _reportIdentifier,
      endpoint: definition.endpoint,
      payload: _payload,
      reportKeys: _visibleColumnIds.toList(),
      groupBy: _group,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _runEpoch++;
    super.dispose();
  }
}
