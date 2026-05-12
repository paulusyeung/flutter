import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';

/// Pick the `DashboardCurrencyTotals` to display from a `DashboardTotals`
/// response. When [key] is null we render the first currency in the map —
/// `KpiRow` separately surfaces a "mixed currencies" warning when the
/// response spans multiple incompatible codes.
DashboardCurrencyTotals? selectCurrencyTotals(
  DashboardTotals? totals,
  String? key,
) {
  if (totals == null || totals.isEmpty) return null;
  if (key != null) return totals.byCurrency[key];
  return totals.byCurrency.values.first;
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
