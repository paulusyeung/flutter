import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_card.dart';

/// Builds the four-KPI row. Picks the current-currency totals out of the
/// `totals.byCurrency` map; falls back to "Mixed currencies" subcaption when
/// the selection is `All` and the response spans multiple incompatible codes.
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.vm, required this.formatter});

  final DashboardViewModel vm;
  final Formatter formatter;

  @override
  Widget build(BuildContext context) {
    final currencyKey = vm.filter.currencyId == kDashboardCurrencyAll
        ? null
        : vm.filter.currencyId.toString();
    final current = _select(vm.totals.data, currencyKey);
    final previous = _select(vm.totalsPrevious.data, currencyKey);
    final isMixed =
        currencyKey == null && (vm.totals.data?.byCurrency.length ?? 0) > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1024 ? 4 : (width >= 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: InSpacing.lg,
          mainAxisSpacing: InSpacing.lg,
          childAspectRatio: width >= 1024 ? 2.0 : 2.4,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _outstandingCard(current, previous, isMixed),
            _overdueCard(current, previous, isMixed),
            _paidThisMonthCard(current, previous, isMixed),
            _avgDaysToPayCard(current, previous, isMixed),
          ],
        );
      },
    );
  }

  KpiCard _outstandingCard(
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    final value = isMixed
        ? '—'
        : formatter.money(
            current?.outstandingAmount ?? Decimal.zero,
            currencyId: current?.code.isNotEmpty == true ? null : null,
          );
    final delta = _percent(
      current?.outstandingAmount,
      previous?.outstandingAmount,
    );
    return KpiCard(
      label: 'Outstanding',
      value: value,
      deltaPercent: delta,
      goodDirection: GoodDirection.down,
      sparklineValues: const [12, 16, 11, 14, 18, 22, 20, 26, 24, 30],
      subcaption: isMixed ? 'Mixed currencies — pick one to see totals.' : null,
      semanticsLabel:
          'Outstanding, $value${delta == null ? '' : ', ${delta > 0 ? 'up' : 'down'} ${delta.abs().toStringAsFixed(1)}% versus prior period'}',
    );
  }

  KpiCard _overdueCard(
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    final count = current?.outstandingCount ?? 0;
    final value = '$count';
    return KpiCard(
      label: 'Overdue',
      value: value,
      deltaPercent: null,
      goodDirection: GoodDirection.down,
      sparklineValues: const [4, 3, 5, 2, 4, 3, 2, 3, 3, 3],
      tone: KpiTone.overdue,
      semanticsLabel: 'Overdue, $count invoices',
    );
  }

  KpiCard _paidThisMonthCard(
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    final value = isMixed
        ? '—'
        : formatter.money(current?.revenuePaidToDate ?? Decimal.zero);
    final delta = _percent(
      current?.revenuePaidToDate,
      previous?.revenuePaidToDate,
    );
    return KpiCard(
      label: 'Paid this month',
      value: value,
      deltaPercent: delta,
      goodDirection: GoodDirection.up,
      sparklineValues: const [22, 18, 28, 24, 32, 28, 36, 38, 34, 42],
      subcaption: isMixed ? 'Mixed currencies — pick one to see totals.' : null,
      semanticsLabel:
          'Paid this month, $value${delta == null ? '' : ', ${delta > 0 ? 'up' : 'down'} ${delta.abs().toStringAsFixed(1)}% versus prior period'}',
    );
  }

  KpiCard _avgDaysToPayCard(
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    // No direct source in totals_v2; surface `—` until a future endpoint or
    // a derivation from payment dates lands.
    return const KpiCard(
      label: 'Avg. days to pay',
      value: '—',
      deltaPercent: null,
      goodDirection: GoodDirection.down,
      sparklineValues: [22, 20, 21, 18, 19, 17, 18, 17, 16, 17],
      semanticsLabel: 'Average days to pay, not enough data',
    );
  }

  /// Pick a single currency's totals. When `currencyKey` is null (filter =
  /// All), we still surface the first available currency so KPIs don't
  /// render empty — the "Mixed currencies" subcaption flags ambiguity.
  DashboardCurrencyTotals? _select(DashboardTotals? totals, String? key) {
    if (totals == null || totals.isEmpty) return null;
    if (key != null) return totals.byCurrency[key];
    return totals.byCurrency.values.first;
  }

  double? _percent(Decimal? current, Decimal? previous) {
    if (current == null || previous == null) return null;
    if (previous == Decimal.zero) return null;
    final c = current.toDouble();
    final p = previous.toDouble();
    if (p == 0) return null;
    return ((c - p) / p) * 100;
  }
}
