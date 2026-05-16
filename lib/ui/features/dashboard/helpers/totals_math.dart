import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';

/// Pick the `DashboardCurrencyTotals` to display from a `DashboardTotals`
/// response. When [key] is null ("All currencies") we render the server's
/// `999` bucket — amounts already exchange-rate-converted to the company base
/// currency. Single-currency companies may omit `999`, so fall back to the
/// sole currency in the map.
DashboardCurrencyTotals? selectCurrencyTotals(
  DashboardTotals? totals,
  String? key,
) {
  if (totals == null || totals.isEmpty) return null;
  if (key != null) return totals.byCurrency[key];
  return totals.byCurrency[kDashboardCurrencyAll.toString()] ??
      totals.byCurrency.values.first;
}

/// Period-over-period delta as a percentage. Returns null when either side
/// is null or when the previous period is zero (division would be
/// undefined / infinite, not a real "delta").
double? percentDelta(Decimal? current, Decimal? previous) {
  if (current == null || previous == null) return null;
  if (previous == Decimal.zero) return null;
  final c = current.toDouble();
  final p = previous.toDouble();
  if (p == 0) return null;
  return ((c - p) / p) * 100;
}
