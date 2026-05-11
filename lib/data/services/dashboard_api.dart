import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/services/api_client.dart';

/// Thin service for the read-only dashboard endpoints. Does **not** extend
/// `BaseEntityApi` — these aren't CRUD resources, there's no keyset cursor,
/// and the responses don't fit the standard list/item envelope shape.
///
/// Every method returns the **unwrapped** server payload (the inner `data`
/// object/array), so the dashboard repo can cache and decode it without
/// re-stripping the envelope. Network exceptions, 401 single-flight, and
/// version negotiation all flow through `ApiClient`.
class DashboardApi {
  DashboardApi(this.client);

  final ApiClient client;

  /// `POST /api/v1/charts/totals_v2`. Returns the totals map keyed by
  /// currency-id (plus a `currencies` id→label map).
  ///
  /// When [previousPeriod] is true, both dates are shifted back by the
  /// window length so the ViewModel can compute period-over-period deltas.
  Future<Object?> fetchTotals(
    DashboardFilter filter, {
    bool previousPeriod = false,
  }) async {
    final body = _periodBody(filter, previousPeriod: previousPeriod);
    final raw = await client.postJson(
      '/api/v1/charts/totals_v2',
      body: body,
      query: {'include_drafts': filter.includeDrafts.toString()},
      readOnly: true,
    );
    return _unwrap(raw);
  }

  /// `POST /api/v1/charts/chart_summary_v2`. Returns the time-series payload
  /// (start/end dates + per-currency arrays of {date, total, currency}).
  Future<Object?> fetchChartSummary(DashboardFilter filter) async {
    final body = _periodBody(filter);
    final raw = await client.postJson(
      '/api/v1/charts/chart_summary_v2',
      body: body,
      query: {'include_drafts': filter.includeDrafts.toString()},
      readOnly: true,
    );
    return _unwrap(raw);
  }

  /// `GET /api/v1/activities?reactv2`. Returns a list of activity objects.
  Future<Object?> fetchActivities() async {
    final raw = await client.getOneWithQuery(
      '/api/v1/activities',
      query: const {'reactv2': ''},
    );
    return _unwrap(raw);
  }

  Future<Object?> fetchPastDueInvoices() =>
      _fetchList('/api/v1/invoices', const {
        'include': 'client.group_settings',
        'overdue': 'true',
        'without_deleted_clients': 'true',
        'per_page': '50',
        'page': '1',
        'sort': 'due_date|asc',
      });

  Future<Object?> fetchUpcomingInvoices() =>
      _fetchList('/api/v1/invoices', const {
        'include': 'client.group_settings',
        'without_deleted_clients': 'true',
        'per_page': '50',
        'page': '1',
        'sort': 'due_date|asc',
      });

  Future<Object?> fetchRecentPayments() => _fetchList(
    '/api/v1/payments',
    const {'include': 'client', 'per_page': '50', 'page': '1'},
  );

  Future<Object?> fetchExpiredQuotes() => _fetchList('/api/v1/quotes', const {
    'include': 'client',
    'client_status': 'expired',
    'without_deleted_clients': 'true',
    'per_page': '50',
    'page': '1',
    'sort': 'id|desc',
  });

  Future<Object?> fetchUpcomingQuotes() => _fetchList('/api/v1/quotes', const {
    'include': 'client',
    'without_deleted_clients': 'true',
    'per_page': '50',
    'page': '1',
  });

  Future<Object?> fetchUpcomingRecurringInvoices() =>
      _fetchList('/api/v1/recurring_invoices', const {
        'include': 'client',
        'without_deleted_clients': 'true',
        'per_page': '50',
        'page': '1',
      });

  // ---------------------------------------------------------------------------

  Future<Object?> _fetchList(String path, Map<String, String> query) async {
    final raw = await client.getOneWithQuery(path, query: query);
    return _unwrap(raw);
  }

  Map<String, dynamic> _periodBody(
    DashboardFilter filter, {
    bool previousPeriod = false,
  }) {
    final (start, end) = filter.resolveDates();
    var startDate = start;
    var endDate = end;
    if (previousPeriod) {
      final days = _windowDays(start, end);
      startDate = _shiftBack(start, days);
      endDate = _shiftBack(end, days);
    }
    return {
      'start_date': startDate.toIso(),
      'end_date': endDate.toIso(),
      'date_range': previousPeriod
          ? 'custom'
          : _serverDateRangeName(filter.range),
    };
  }

  int _windowDays(Date start, Date end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final days = e.difference(s).inDays + 1;
    return days <= 0 ? 1 : days;
  }

  Date _shiftBack(Date date, int days) {
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: days));
    return Date(dt.year, dt.month, dt.day);
  }

  /// Map a [DashboardDateRange] to the server's `date_range` string. Server
  /// accepts presets (`this_month`, etc.) or `custom`.
  String _serverDateRangeName(DashboardDateRange range) {
    if (range is DashboardPresetRange) return range.preset.serverName;
    return 'custom';
  }

  /// Unwrap the standard `{data: ...}` envelope. Pass-through if the server
  /// returns an unwrapped payload (e.g. some endpoints).
  Object? _unwrap(Object? raw) {
    if (raw is Map && raw['data'] != null) return raw['data'];
    return raw;
  }
}
