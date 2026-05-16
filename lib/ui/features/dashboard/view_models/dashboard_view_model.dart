import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/dao/nav_state_dao.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_chart_series.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';

final _log = Logger('DashboardViewModel');

/// Drives the Dashboard screen. Owns:
///   * The current [DashboardFilter] (range, currency, drafts, chart window).
///   * A per-section [AsyncSection] for totals (current + previous), chart,
///     activities, and each list card.
///   * Subscriptions to Drift watch streams; resubscribes filter-keyed ones
///     (totals + chart) when the filter changes.
///   * Refresh kickoff on construction / explicit `refresh()`.
///   * Persistence of filter + legend toggles into `nav_state` using the
///     project's `{companyId: {<feature>: {...}}}` envelope.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required this.repo,
    required this.companyId,
    required this.navStateDao,
    required this.statics,
    Duration persistDebounce = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) : _persistDebounce = persistDebounce,
       _now = now ?? DateTime.now {
    unawaited(_init());
  }

  final DashboardRepository repo;
  final String companyId;
  final NavStateDao navStateDao;
  final StaticsRepository statics;
  final Duration _persistDebounce;
  final DateTime Function() _now;

  DashboardFilter _filter = DashboardFilter.defaults();
  DashboardFilter get filter => _filter;

  AsyncSection<DashboardTotals> totals = const AsyncSection.idle();
  AsyncSection<DashboardTotals> totalsPrevious = const AsyncSection.idle();
  AsyncSection<DashboardChartSeries> chart = const AsyncSection.idle();
  AsyncSection<List<DashboardActivity>> activities = const AsyncSection.idle();
  AsyncSection<List<DashboardInvoiceRow>> pastDue = const AsyncSection.idle();
  AsyncSection<List<DashboardInvoiceRow>> upcomingInvoices =
      const AsyncSection.idle();
  AsyncSection<List<DashboardPaymentRow>> recentPayments =
      const AsyncSection.idle();
  AsyncSection<List<DashboardQuoteRow>> expiredQuotes =
      const AsyncSection.idle();
  AsyncSection<List<DashboardQuoteRow>> upcomingQuotes =
      const AsyncSection.idle();
  AsyncSection<List<DashboardRecurringInvoiceRow>> upcomingRecurring =
      const AsyncSection.idle();

  /// Which chart series the legend has enabled. Default = invoices only,
  /// matching the v2 hero chart's "Revenue" framing.
  Set<ChartSeriesId> visibleChartSeries = const {ChartSeriesId.invoices};

  /// Wall-clock of the most recent successful refresh — drives the
  /// "Updated N ago" freshness label.
  DateTime? lastRefreshed;
  bool isAnyRefreshing = false;
  Object? globalError;

  final _subs = <String, StreamSubscription<dynamic>>{};
  Timer? _persistTimer;
  bool _hydrated = false;

  /// Currencies offered by the dropdown. Reads from `totals.byCurrency` when
  /// available; falls back to the full statics list during cold-start so the
  /// dropdown is never empty.
  Map<String, String> get availableCurrencies {
    final fromTotals = totals.data?.currencies;
    if (fromTotals != null && fromTotals.isNotEmpty) return fromTotals;
    return {
      for (final entry in statics.currencies.entries)
        entry.key: entry.value.name,
    };
  }

  // ─── Public actions ──────────────────────────────────────────────────

  Future<void> setFilter(DashboardFilter next) async {
    if (next == _filter) return;
    final wasFilterKeyedChange =
        next.filterHash() != _filter.filterHash() ||
        next.includeDrafts != _filter.includeDrafts;
    _filter = next;
    notifyListeners();
    _schedulePersist();
    _resubscribeFilterKeyed();
    if (wasFilterKeyedChange) {
      await _refreshFilterKeyed();
    }
  }

  Future<void> setCurrency(int currencyId) =>
      setFilter(_filter.copyWith(currencyId: currencyId));

  Future<void> setIncludeDrafts(bool value) =>
      setFilter(_filter.copyWith(includeDrafts: value));

  Future<void> setDateRange(DashboardDateRange range) =>
      setFilter(_filter.copyWith(range: range));

  void toggleChartSeries(ChartSeriesId id) {
    final next = Set<ChartSeriesId>.from(visibleChartSeries);
    if (!next.remove(id)) next.add(id);
    if (next.isEmpty) return; // never leave the chart empty
    visibleChartSeries = next;
    notifyListeners();
    _schedulePersist();
  }

  /// Full refetch: every kind, parallel under the repo's concurrency cap.
  Future<void> refresh() async {
    isAnyRefreshing = true;
    globalError = null;
    notifyListeners();
    try {
      final errors = await repo.refreshAll(companyId, _filter);
      if (errors.isNotEmpty) {
        // Streams will emit the latest cached value (possibly null/stale);
        // mark the failing sections as error so the per-card retry surfaces.
        _foldPerSectionErrors(errors);
      } else {
        lastRefreshed = _now();
      }
    } catch (e, st) {
      _log.warning('Dashboard refresh failed', e, st);
      globalError = e;
    } finally {
      isAnyRefreshing = false;
      notifyListeners();
    }
  }

  /// Per-section retry (used by ErrorView's retry button).
  Future<void> retry(String kind) async {
    isAnyRefreshing = true;
    notifyListeners();
    try {
      switch (kind) {
        case DashboardKind.totalsCurrent:
        case DashboardKind.totalsPrevious:
          await repo.refreshTotals(companyId, _filter);
        case DashboardKind.chart:
          await repo.refreshChart(companyId, _filter);
        case DashboardKind.activities:
          await repo.refreshActivities(companyId);
        case DashboardKind.pastDue:
          await repo.refreshPastDue(companyId);
        case DashboardKind.upcomingInvoices:
          await repo.refreshUpcomingInvoices(companyId);
        case DashboardKind.recentPayments:
          await repo.refreshRecentPayments(companyId);
        case DashboardKind.expiredQuotes:
          await repo.refreshExpiredQuotes(companyId);
        case DashboardKind.upcomingQuotes:
          await repo.refreshUpcomingQuotes(companyId);
        case DashboardKind.upcomingRecurring:
          await repo.refreshUpcomingRecurring(companyId);
      }
      _setSectionError(kind, null);
    } catch (e) {
      _setSectionError(kind, e);
    } finally {
      isAnyRefreshing = false;
      notifyListeners();
    }
  }

  // ─── Init / streams ───────────────────────────────────────────────────

  Future<void> _init() async {
    await _hydrate();
    _subscribeAll();
    await refresh();
  }

  void _subscribeAll() {
    _resubscribeFilterKeyed();
    _subscribe(
      DashboardKind.activities,
      repo.watchActivities(companyId),
      (d) => activities = activities.withData(d),
    );
    _subscribe(
      DashboardKind.pastDue,
      repo.watchPastDue(companyId),
      (d) => pastDue = pastDue.withData(d),
    );
    _subscribe(
      DashboardKind.upcomingInvoices,
      repo.watchUpcomingInvoices(companyId),
      (d) => upcomingInvoices = upcomingInvoices.withData(d),
    );
    _subscribe(
      DashboardKind.recentPayments,
      repo.watchRecentPayments(companyId),
      (d) => recentPayments = recentPayments.withData(d),
    );
    _subscribe(
      DashboardKind.expiredQuotes,
      repo.watchExpiredQuotes(companyId),
      (d) => expiredQuotes = expiredQuotes.withData(d),
    );
    _subscribe(
      DashboardKind.upcomingQuotes,
      repo.watchUpcomingQuotes(companyId),
      (d) => upcomingQuotes = upcomingQuotes.withData(d),
    );
    _subscribe(
      DashboardKind.upcomingRecurring,
      repo.watchUpcomingRecurring(companyId),
      (d) => upcomingRecurring = upcomingRecurring.withData(d),
    );
  }

  void _resubscribeFilterKeyed() {
    _subscribe(
      DashboardKind.totalsCurrent,
      repo.watchTotals(companyId, _filter),
      (d) {
        totals = totals.withData(d);
      },
    );
    _subscribe(
      DashboardKind.totalsPrevious,
      repo.watchTotals(companyId, _filter, previousPeriod: true),
      (d) {
        totalsPrevious = totalsPrevious.withData(d);
      },
    );
    _subscribe(DashboardKind.chart, repo.watchChart(companyId, _filter), (d) {
      chart = chart.withData(d);
    });
  }

  void _subscribe<T>(String key, Stream<T> stream, void Function(T) onData) {
    _subs[key]?.cancel();
    _subs[key] = stream.listen(
      (value) {
        onData(value);
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        _log.warning('Dashboard stream error [$key]', e, st);
      },
    );
  }

  Future<void> _refreshFilterKeyed() async {
    isAnyRefreshing = true;
    notifyListeners();
    try {
      await Future.wait<void>([
        repo.refreshTotals(companyId, _filter).catchError((Object e) {
          _setSectionError(DashboardKind.totalsCurrent, e);
        }),
        repo.refreshChart(companyId, _filter).catchError((Object e) {
          _setSectionError(DashboardKind.chart, e);
        }),
      ]);
    } finally {
      isAnyRefreshing = false;
      notifyListeners();
    }
  }

  void _foldPerSectionErrors(Map<String, Object> errors) {
    errors.forEach(_setSectionError);
  }

  void _setSectionError(String kind, Object? err) {
    switch (kind) {
      case DashboardKind.totalsCurrent:
        totals = err == null
            ? totals.withData(totals.data)
            : AsyncSection.error(err, data: totals.data);
      case DashboardKind.totalsPrevious:
        totalsPrevious = err == null
            ? totalsPrevious.withData(totalsPrevious.data)
            : AsyncSection.error(err, data: totalsPrevious.data);
      case DashboardKind.chart:
        chart = err == null
            ? chart.withData(chart.data)
            : AsyncSection.error(err, data: chart.data);
      case DashboardKind.activities:
        activities = err == null
            ? activities.withData(activities.data)
            : AsyncSection.error(err, data: activities.data);
      case DashboardKind.pastDue:
        pastDue = err == null
            ? pastDue.withData(pastDue.data)
            : AsyncSection.error(err, data: pastDue.data);
      case DashboardKind.upcomingInvoices:
        upcomingInvoices = err == null
            ? upcomingInvoices.withData(upcomingInvoices.data)
            : AsyncSection.error(err, data: upcomingInvoices.data);
      case DashboardKind.recentPayments:
        recentPayments = err == null
            ? recentPayments.withData(recentPayments.data)
            : AsyncSection.error(err, data: recentPayments.data);
      case DashboardKind.expiredQuotes:
        expiredQuotes = err == null
            ? expiredQuotes.withData(expiredQuotes.data)
            : AsyncSection.error(err, data: expiredQuotes.data);
      case DashboardKind.upcomingQuotes:
        upcomingQuotes = err == null
            ? upcomingQuotes.withData(upcomingQuotes.data)
            : AsyncSection.error(err, data: upcomingQuotes.data);
      case DashboardKind.upcomingRecurring:
        upcomingRecurring = err == null
            ? upcomingRecurring.withData(upcomingRecurring.data)
            : AsyncSection.error(err, data: upcomingRecurring.data);
    }
  }

  // ─── nav_state persistence ────────────────────────────────────────────

  Future<void> _hydrate() async {
    try {
      final row = await navStateDao.current();
      final raw = row?.filtersJson;
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final company = decoded[companyId];
      if (company is! Map) return;
      final dash = company['dashboard'];
      if (dash is! Map) return;

      final loadedFilter = DashboardFilter.tryFromJson(dash['filter']);
      if (loadedFilter != null) _filter = loadedFilter;

      final series = dash['chartSeries'];
      if (series is List) {
        final next = <ChartSeriesId>{};
        for (final s in series) {
          for (final id in ChartSeriesId.values) {
            if (id.name == s) next.add(id);
          }
        }
        if (next.isNotEmpty) visibleChartSeries = next;
      }
    } catch (e, st) {
      _log.warning('Failed to hydrate dashboard nav_state', e, st);
    } finally {
      _hydrated = true;
    }
  }

  void _schedulePersist() {
    if (!_hydrated) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persist);
  }

  Future<void> _persist() async {
    try {
      final row = await navStateDao.current();
      final existing = row?.filtersJson;
      Map<String, dynamic> doc;
      if (existing == null || existing.isEmpty) {
        doc = <String, dynamic>{};
      } else {
        final decoded = jsonDecode(existing);
        doc = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      }
      final companyDoc = doc[companyId];
      final companyMap = companyDoc is Map<String, dynamic>
          ? Map<String, dynamic>.from(companyDoc)
          : <String, dynamic>{};
      companyMap['dashboard'] = {
        'filter': _filter.toJson(),
        'chartSeries': visibleChartSeries.map((s) => s.name).toList(),
      };
      doc[companyId] = companyMap;
      await navStateDao.saveFilters(
        filtersJson: jsonEncode(doc),
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      _log.warning('Failed to persist dashboard nav_state', e, st);
    }
  }

  /// Tracks `dispose()` so async refresh work that returns after the VM
  /// has been torn down skips its trailing `notifyListeners()` (which
  /// would throw `was used after being disposed` in debug). The dashboard
  /// fires several long-running fetches at construction time, so this
  /// race shows up routinely under tests.
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _persistTimer?.cancel();
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// Series ids that the chart card can toggle via legend chips.
enum ChartSeriesId { invoices, payments, outstanding, expenses }
