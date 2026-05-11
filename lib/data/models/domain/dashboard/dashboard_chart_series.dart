import 'package:decimal/decimal.dart';

import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/models/value/money.dart';

/// Time-series data returned by `POST /api/v1/charts/chart_summary_v2`.
///
/// Server response shape (unwrapped):
/// ```
/// {
///   "start_date": "2026-04-01",
///   "end_date":   "2026-04-30",
///   "currencies": { "1": "USD ..." },
///   "1": {
///     "invoices":    [ { total, date, currency }, ... ],
///     "payments":    [ ... ],
///     "outstanding": [ ... ],
///     "expenses":    [ ... ]
///   },
///   "2": { ... }
/// }
/// ```
class DashboardChartSeries {
  const DashboardChartSeries({
    required this.startDate,
    required this.endDate,
    required this.byCurrency,
  });

  final Date? startDate;
  final Date? endDate;
  final Map<String, DashboardCurrencyChart> byCurrency;

  bool get isEmpty => byCurrency.isEmpty;

  static DashboardChartSeries fromJson(Map<String, dynamic> json) {
    final start = Date.tryParse(json['start_date']?.toString());
    final end = Date.tryParse(json['end_date']?.toString());
    final byCurrency = <String, DashboardCurrencyChart>{};
    for (final entry in json.entries) {
      if (entry.key == 'start_date' ||
          entry.key == 'end_date' ||
          entry.key == 'currencies') {
        continue;
      }
      final v = entry.value;
      if (v is Map<String, dynamic>) {
        byCurrency[entry.key] = DashboardCurrencyChart.fromJson(v);
      } else if (v is Map) {
        byCurrency[entry.key] = DashboardCurrencyChart.fromJson(
          v.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    }
    return DashboardChartSeries(
      startDate: start,
      endDate: end,
      byCurrency: byCurrency,
    );
  }
}

class DashboardCurrencyChart {
  const DashboardCurrencyChart({
    required this.invoices,
    required this.payments,
    required this.outstanding,
    required this.expenses,
  });

  final List<DashboardChartPoint> invoices;
  final List<DashboardChartPoint> payments;
  final List<DashboardChartPoint> outstanding;
  final List<DashboardChartPoint> expenses;

  static DashboardCurrencyChart fromJson(Map<String, dynamic> json) =>
      DashboardCurrencyChart(
        invoices: _points(json['invoices']),
        payments: _points(json['payments']),
        outstanding: _points(json['outstanding']),
        expenses: _points(json['expenses']),
      );

  static List<DashboardChartPoint> _points(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Object>()
        .map((p) {
          if (p is Map<String, dynamic>) {
            return DashboardChartPoint.fromJson(p);
          }
          if (p is Map) {
            return DashboardChartPoint.fromJson(
              p.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return null;
        })
        .whereType<DashboardChartPoint>()
        .toList(growable: false);
  }
}

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.date,
    required this.total,
    required this.currency,
  });

  /// May be null when the server returns an unparseable date — callers skip
  /// these points rather than rendering a 1970 epoch tick.
  final Date? date;
  final Decimal total;
  final String currency;

  static DashboardChartPoint fromJson(Map<String, dynamic> json) =>
      DashboardChartPoint(
        date: Date.tryParse(json['date']?.toString()),
        total: parseMoney(json['total']),
        currency: (json['currency'] ?? '').toString(),
      );
}
