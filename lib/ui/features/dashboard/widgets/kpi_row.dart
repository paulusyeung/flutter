import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/helpers/totals_math.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_card.dart';

/// Builds the four-KPI row. Picks the current-currency totals out of the
/// `totals.byCurrency` map; falls back to "Mixed currencies" subcaption when
/// the selection is `All` and the response spans multiple incompatible codes.
class KpiRow extends StatelessWidget {
  const KpiRow({
    super.key,
    required this.vm,
    required this.formatter,
    this.onOutstandingTap,
    this.onOverdueTap,
    this.onPaidThisMonthTap,
  });

  final DashboardViewModel vm;
  final Formatter formatter;
  final VoidCallback? onOutstandingTap;
  final VoidCallback? onOverdueTap;
  final VoidCallback? onPaidThisMonthTap;

  @override
  Widget build(BuildContext context) {
    final currencyKey = vm.filter.currencyId == kDashboardCurrencyAll
        ? null
        : vm.filter.currencyId.toString();
    final current = selectCurrencyTotals(vm.totals.data, currencyKey);
    final previous = selectCurrencyTotals(vm.totalsPrevious.data, currencyKey);
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
            _outstandingCard(context, current, previous, isMixed),
            _overdueCard(context, current, previous, isMixed),
            _paidThisMonthCard(context, current, previous, isMixed),
            _avgDaysToPayCard(context, current, previous, isMixed),
          ],
        );
      },
    );
  }

  String _kpiSemantics(
    BuildContext context, {
    required String label,
    required String value,
    required double? delta,
  }) {
    if (delta == null) {
      return context.tr('kpi_no_delta_semantic', {
        'label': label,
        'value': value,
      });
    }
    return context.tr('kpi_with_delta_semantic', {
      'label': label,
      'value': value,
      'direction': context.tr(delta > 0 ? 'delta_up' : 'delta_down'),
      'percent': delta.abs().toStringAsFixed(1),
    });
  }

  KpiCard _outstandingCard(
    BuildContext context,
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
    final delta = percentDelta(
      current?.outstandingAmount,
      previous?.outstandingAmount,
    );
    final label = context.tr('outstanding');
    return KpiCard(
      label: label,
      value: value,
      deltaPercent: delta,
      goodDirection: GoodDirection.down,
      sparklineValues: const [12, 16, 11, 14, 18, 22, 20, 26, 24, 30],
      subcaption: isMixed ? context.tr('mixed_currencies_hint') : null,
      semanticsLabel: _kpiSemantics(
        context,
        label: label,
        value: value,
        delta: delta,
      ),
      onTap: onOutstandingTap,
    );
  }

  KpiCard _overdueCard(
    BuildContext context,
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    final count = current?.outstandingCount ?? 0;
    final value = '$count';
    return KpiCard(
      label: context.tr('overdue'),
      value: value,
      deltaPercent: null,
      goodDirection: GoodDirection.down,
      sparklineValues: const [4, 3, 5, 2, 4, 3, 2, 3, 3, 3],
      tone: KpiTone.overdue,
      semanticsLabel: context.tr('overdue_count_invoices_semantic', {
        'count': count.toString(),
      }),
      onTap: onOverdueTap,
    );
  }

  KpiCard _paidThisMonthCard(
    BuildContext context,
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    final value = isMixed
        ? '—'
        : formatter.money(current?.revenuePaidToDate ?? Decimal.zero);
    final delta = percentDelta(
      current?.revenuePaidToDate,
      previous?.revenuePaidToDate,
    );
    final label = context.tr('paid_this_month');
    return KpiCard(
      label: label,
      value: value,
      deltaPercent: delta,
      goodDirection: GoodDirection.up,
      sparklineValues: const [22, 18, 28, 24, 32, 28, 36, 38, 34, 42],
      subcaption: isMixed ? context.tr('mixed_currencies_hint') : null,
      semanticsLabel: _kpiSemantics(
        context,
        label: label,
        value: value,
        delta: delta,
      ),
      onTap: onPaidThisMonthTap,
    );
  }

  KpiCard _avgDaysToPayCard(
    BuildContext context,
    DashboardCurrencyTotals? current,
    DashboardCurrencyTotals? previous,
    bool isMixed,
  ) {
    // No direct source in totals_v2; surface `—` until a future endpoint or
    // a derivation from payment dates lands.
    return KpiCard(
      label: context.tr('avg_days_to_pay'),
      value: '—',
      deltaPercent: null,
      goodDirection: GoodDirection.down,
      sparklineValues: const [22, 20, 21, 18, 19, 17, 18, 17, 16, 17],
      semanticsLabel: context.tr('avg_days_to_pay_no_data'),
    );
  }
}
