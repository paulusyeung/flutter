import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/dashboard_cache_dao.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/dashboard_api.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target DashboardRepository's behavioral contracts:
///   * refresh fans out, writes cache rows, and watch streams emit decoded
///     domain models from those rows
///   * per-kind errors don't kill peer refreshes
///   * `null` is emitted before the first cache row exists
///   * `clearForCompany` wipes the company's cache
///
/// They do NOT exercise the http layer — a fake DashboardApi feeds canned
/// responses.

/// Minimal ApiClient stand-in so we can satisfy [DashboardApi]'s `final
/// ApiClient client` field. The fake never calls it — it's just there because
/// the type requires it.
final ApiClient _dummyClient = ApiClient(
  credentials: ValueNotifier<ApiCredentials?>(
    const ApiCredentials(baseUrl: 'https://test', token: 't'),
  ),
  passwordCache: PasswordCache(),
  onUnauthorized: () async {},
);

class _FakeDashboardApi extends DashboardApi {
  _FakeDashboardApi() : super(_dummyClient);

  final Map<String, Object?> _totalsCurrent = {};
  final Map<String, Object?> _totalsPrevious = {};
  Object? chartSummary;
  Object? activities;
  Object? pastDue;
  Object? upcomingInvoices;
  Object? recentPayments;
  Object? expiredQuotes;
  Object? upcomingQuotes;
  Object? upcomingRecurring;

  /// Per-method failure injection. Throws when set.
  Map<String, Object> failures = {};

  Future<Object?> _maybe(String key, Object? value) {
    final fail = failures[key];
    if (fail != null) return Future.error(fail);
    return Future.value(value);
  }

  @override
  Future<Object?> fetchTotals(
    DashboardFilter filter, {
    bool previousPeriod = false,
  }) {
    final key = previousPeriod ? 'totals_previous' : 'totals_current';
    final value = previousPeriod
        ? _totalsPrevious[filter.filterHash()]
        : _totalsCurrent[filter.filterHash()];
    return _maybe(key, value);
  }

  @override
  Future<Object?> fetchChartSummary(DashboardFilter filter) =>
      _maybe('chart', chartSummary);

  @override
  Future<Object?> fetchActivities() => _maybe('activities', activities);

  @override
  Future<Object?> fetchPastDueInvoices() => _maybe('past_due', pastDue);

  @override
  Future<Object?> fetchUpcomingInvoices() =>
      _maybe('upcoming_invoices', upcomingInvoices);

  @override
  Future<Object?> fetchRecentPayments() =>
      _maybe('recent_payments', recentPayments);

  @override
  Future<Object?> fetchExpiredQuotes() =>
      _maybe('expired_quotes', expiredQuotes);

  @override
  Future<Object?> fetchUpcomingQuotes() =>
      _maybe('upcoming_quotes', upcomingQuotes);

  @override
  Future<Object?> fetchUpcomingRecurringInvoices() =>
      _maybe('upcoming_recurring', upcomingRecurring);
}

void main() {
  late AppDatabase db;
  late _FakeDashboardApi api;
  late DashboardRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = _FakeDashboardApi();
    repo = DashboardRepository(db: db, api: api, now: () => 1000);
  });

  tearDown(() async {
    await db.close();
  });

  group('refresh + watch round-trip', () {
    test('watchTotals emits null until refresh writes a cache row', () async {
      final filter = DashboardFilter.defaults();
      // Seed the response: a single-currency totals map.
      api._totalsCurrent[filter.filterHash()] = {
        'currencies': {'1': 'USD'},
        '1': {
          'revenue': {'paid_to_date': '100.50', 'code': 'USD'},
          'expenses': {'amount': '0', 'code': 'USD'},
          'invoices': {'invoiced_amount': '0', 'code': 'USD'},
          'outstanding': {
            'outstanding_count': 3,
            'amount': '250.00',
            'code': 'USD',
          },
        },
      };
      api._totalsPrevious[filter.filterHash()] =
          api._totalsCurrent[filter.filterHash()];

      final stream = repo.watchTotals('co_a', filter);
      final values = <dynamic>[];
      final sub = stream.listen(values.add);

      // Settle the initial subscription.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last, isNull);

      await repo.refreshTotals('co_a', filter);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last, isNotNull);
      expect(values.last!.byCurrency.length, 1);
      expect(values.last!.byCurrency['1']!.outstandingCount, 3);

      await sub.cancel();
    });

    test('refreshAll fans out and records per-kind failures', () async {
      final filter = DashboardFilter.defaults();
      api._totalsCurrent[filter.filterHash()] = {
        'currencies': <String, dynamic>{},
      };
      api._totalsPrevious[filter.filterHash()] = {
        'currencies': <String, dynamic>{},
      };
      api.chartSummary = {'start_date': '2026-05-01', 'end_date': '2026-05-31'};
      api.activities = <dynamic>[];
      api.pastDue = <dynamic>[];
      api.upcomingInvoices = <dynamic>[];
      api.recentPayments = <dynamic>[];
      api.expiredQuotes = <dynamic>[];
      api.upcomingQuotes = <dynamic>[];
      api.upcomingRecurring = <dynamic>[];

      // Inject a failure on one kind.
      api.failures['chart'] = StateError('boom');

      final errors = await repo.refreshAll('co_a', filter);
      expect(errors.containsKey(DashboardKind.chart), isTrue);
      // Other kinds still completed successfully — verified by reading the DAO.
      final pastDueRow = await db.dashboardCacheDao.read(
        companyId: 'co_a',
        kind: DashboardKind.pastDue,
        filterHash: kDashboardListFilterHash,
      );
      expect(pastDueRow, isNotNull);
    });

    test('clearForCompany wipes only that company\'s cache', () async {
      final filter = DashboardFilter.defaults();
      api.pastDue = <dynamic>[];
      api._totalsCurrent[filter.filterHash()] = {
        'currencies': <String, dynamic>{},
      };
      api._totalsPrevious[filter.filterHash()] = {
        'currencies': <String, dynamic>{},
      };

      await repo.refreshPastDue('co_a');
      await repo.refreshPastDue('co_b');

      await repo.clearForCompany('co_a');

      final a = await db.dashboardCacheDao.read(
        companyId: 'co_a',
        kind: DashboardKind.pastDue,
        filterHash: kDashboardListFilterHash,
      );
      final b = await db.dashboardCacheDao.read(
        companyId: 'co_b',
        kind: DashboardKind.pastDue,
        filterHash: kDashboardListFilterHash,
      );
      expect(a, isNull);
      expect(b, isNotNull);
    });

    test('AppDatabase.wipe() clears dashboard_cache', () async {
      api.pastDue = <dynamic>[];
      await repo.refreshPastDue('co_a');
      expect(
        await db.dashboardCacheDao.read(
          companyId: 'co_a',
          kind: DashboardKind.pastDue,
          filterHash: kDashboardListFilterHash,
        ),
        isNotNull,
      );
      await db.wipe();
      expect(
        await db.dashboardCacheDao.read(
          companyId: 'co_a',
          kind: DashboardKind.pastDue,
          filterHash: kDashboardListFilterHash,
        ),
        isNull,
      );
    });
  });
}
