import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_totals.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/dashboard_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/activity_card.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/dashboard/widgets/chart_card.dart';
import 'package:admin/ui/features/dashboard/widgets/freshness_label.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_sparkline.dart';
import 'package:admin/ui/features/dashboard/widgets/mobile/dashboard_mobile_rows.dart';

/// Mobile (<600 px) dashboard body. The header follows `patterns.jsx:375-441`
/// — eyebrow → dark hero KPI → 4 quick-action tiles → compact past-due table
/// — and is then followed by the same sections desktop renders (revenue
/// chart, activity feed, upcoming invoices, recent payments, upcoming /
/// expired quotes, upcoming recurring invoices), each laid out as a single-
/// column stack of mobile-friendly rows rather than the desktop multi-column
/// tables which overflow on phone widths.
class MobileDashboardBody extends StatelessWidget {
  const MobileDashboardBody({
    super.key,
    required this.vm,
    required this.formatter,
    required this.companyName,
    required this.onPastDueInvoiceTap,
    required this.onAllInvoices,
    required this.onNewInvoice,
    required this.onAddClient,
    required this.onLogExpense,
    required this.onReports,
    required this.onOutstandingTap,
    required this.onOverdueTap,
    required this.onPaidTap,
    required this.onActivityTap,
    required this.onAllActivities,
    required this.onUpcomingInvoiceTap,
    required this.onPaymentTap,
    required this.onAllPayments,
    required this.onQuoteTap,
    required this.onAllQuotes,
    required this.onRecurringTap,
    required this.onAllRecurring,
  });

  final DashboardViewModel vm;
  final Formatter formatter;
  final String companyName;
  final void Function(DashboardInvoiceRow) onPastDueInvoiceTap;
  final VoidCallback onAllInvoices;
  final VoidCallback onNewInvoice;
  final VoidCallback onAddClient;
  final VoidCallback onLogExpense;
  final VoidCallback onReports;
  final VoidCallback onOutstandingTap;
  final VoidCallback onOverdueTap;
  final VoidCallback onPaidTap;
  final void Function(DashboardActivity) onActivityTap;
  final VoidCallback onAllActivities;
  final void Function(DashboardInvoiceRow) onUpcomingInvoiceTap;
  final void Function(DashboardPaymentRow) onPaymentTap;
  final VoidCallback onAllPayments;
  final void Function(DashboardQuoteRow) onQuoteTap;
  final VoidCallback onAllQuotes;
  final void Function(DashboardRecurringInvoiceRow) onRecurringTap;
  final VoidCallback onAllRecurring;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      children: [
        _eyebrow(context, tokens),
        const SizedBox(height: 8),
        _heroKpi(context, tokens),
        const SizedBox(height: 14),
        _quickActions(context, tokens),
        const SizedBox(height: 14),
        _needsAttentionCard(context, tokens),
        const SizedBox(height: 14),
        ChartCard(vm: vm, formatter: formatter),
        const SizedBox(height: 14),
        ActivityCard(
          section: vm.activities,
          onViewAll: onAllActivities,
          onRetry: () => vm.retry(DashboardKind.activities),
          onActivityTap: onActivityTap,
        ),
        const SizedBox(height: 14),
        _upcomingInvoicesCard(context, tokens),
        const SizedBox(height: 14),
        _recentPaymentsCard(context, tokens),
        const SizedBox(height: 14),
        _upcomingQuotesCard(context, tokens),
        const SizedBox(height: 14),
        _expiredQuotesCard(context, tokens),
        const SizedBox(height: 14),
        _upcomingRecurringCard(context, tokens),
        const SizedBox(height: InSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: FreshnessLabel(
            lastRefreshed: vm.lastRefreshed,
            isRefreshing: vm.isAnyRefreshing,
            onRefresh: vm.refresh,
          ),
        ),
        const SizedBox(height: InSpacing.lg),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Eyebrow

  Widget _eyebrow(BuildContext context, InTheme tokens) {
    return Text(
      '${companyName.toUpperCase()} · ${context.tr('dashboard').toUpperCase()}',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: tokens.ink3,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero KPI — dark surface, Outstanding number + sparkline, 2 sub-KPIs.

  Widget _heroKpi(BuildContext context, InTheme tokens) {
    final currencyKey = vm.filter.currencyId == kDashboardCurrencyAll
        ? null
        : vm.filter.currencyId.toString();
    final current = _select(vm.totals.data, currencyKey);
    final previous = _select(vm.totalsPrevious.data, currencyKey);

    final outstanding = current?.outstandingAmount ?? Decimal.zero;
    final outstandingText = formatter.money(outstanding);
    final outstandingDelta = _percent(
      current?.outstandingAmount,
      previous?.outstandingAmount,
    );

    final overdueCount = current?.outstandingCount ?? 0;
    final overdueAmountText = formatter.money(outstanding);

    final paidText = formatter.money(
      current?.revenuePaidToDate ?? Decimal.zero,
    );

    final whiteMuted = Colors.white.withValues(alpha: 0.55);
    final whiteSurface = Colors.white.withValues(alpha: 0.08);
    final heroRadius = BorderRadius.circular(InRadii.r3);

    return Material(
      color: tokens.ink,
      borderRadius: heroRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOutstandingTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('outstanding'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: whiteMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          outstandingText,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            fontFamilyFallback: ['Menlo', 'Consolas'],
                          ),
                        ),
                        if (outstandingDelta != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                outstandingDelta >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 11,
                                color: tokens.accentLime,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${outstandingDelta >= 0 ? '+' : ''}${outstandingDelta.toStringAsFixed(1)}% ${context.tr('this_month').toLowerCase()}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.accentLime,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  KpiSparkline(
                    values: const [12, 16, 11, 14, 18, 22, 20, 26, 24, 30],
                    color: tokens.accentLime,
                    width: 80,
                    height: 40,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _subKpi(
                      label: context.tr('overdue'),
                      value: '$overdueAmountText · $overdueCount',
                      bg: whiteSurface,
                      labelColor: whiteMuted,
                      onTap: onOverdueTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _subKpi(
                      label: context.tr('paid_this_month'),
                      value: paidText,
                      bg: whiteSurface,
                      labelColor: whiteMuted,
                      onTap: onPaidTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subKpi({
    required String label,
    required String value,
    required Color bg,
    required Color labelColor,
    VoidCallback? onTap,
  }) {
    final radius = BorderRadius.circular(10);
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamilyFallback: ['Menlo', 'Consolas'],
            ),
          ),
        ],
      ),
    );
    return Material(
      color: bg,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? inner
          : InkWell(onTap: onTap, borderRadius: radius, child: inner),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick-actions grid — 4 tiles in a row.

  Widget _quickActions(BuildContext context, InTheme tokens) {
    final actions = [
      _QuickAction(
        label: context.tr('new_invoice'),
        icon: Icons.add,
        iconColor: tokens.accent,
        onTap: onNewInvoice,
      ),
      _QuickAction(
        label: context.tr('new_client'),
        icon: Icons.person_add_alt_outlined,
        iconColor: tokens.ink2,
        onTap: onAddClient,
      ),
      _QuickAction(
        label: context.tr('new_expense'),
        icon: Icons.receipt_long_outlined,
        iconColor: tokens.ink2,
        onTap: onLogExpense,
      ),
      _QuickAction(
        label: context.tr('reports'),
        icon: Icons.insert_chart_outlined,
        iconColor: tokens.ink2,
        onTap: onReports,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _quickActionTile(tokens, actions[i])),
          ],
        ],
      ),
    );
  }

  Widget _quickActionTile(InTheme tokens, _QuickAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(InRadii.r2),
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(InRadii.r2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 15, color: action.iconColor),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: tokens.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Needs-attention card — 3 rows max on mobile.

  Widget _needsAttentionCard(BuildContext context, InTheme tokens) {
    final section = vm.pastDue;
    final hasRows = section.hasData && (section.data?.isNotEmpty ?? false);
    final rows = hasRows
        ? section.data!.take(3).toList(growable: false)
        : const <DashboardInvoiceRow>[];
    final today = Date.today();
    return DashboardCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('needs_your_attention'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                if (hasRows)
                  GestureDetector(
                    onTap: onAllInvoices,
                    child: Text(
                      context.tr('all_invoices'),
                      style: TextStyle(fontSize: 11.5, color: tokens.ink3),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: tokens.border),
          if (hasRows)
            for (var i = 0; i < rows.length; i++) ...[
              MobileInvoiceRow(
                row: rows[i],
                formatter: formatter,
                today: today,
                onTap: () => onPastDueInvoiceTap(rows[i]),
                alwaysOverdue: true,
              ),
              if (i < rows.length - 1)
                Divider(height: 1, thickness: 1, color: tokens.border),
            ]
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              child: Text(
                context.tr('all_caught_up'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: tokens.ink3),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // List-card sections — single-column stacked rows that mirror the data each
  // desktop card shows, but in a layout that fits on a phone width.

  Widget _upcomingInvoicesCard(BuildContext context, InTheme tokens) {
    final today = Date.today();
    return _mobileListCard<DashboardInvoiceRow>(
      context: context,
      tokens: tokens,
      title: context.tr('upcoming_invoices'),
      allLabel: context.tr('all_invoices'),
      onAllTap: onAllInvoices,
      section: vm.upcomingInvoices,
      emptyMessage: context.tr('no_invoices_due_soon'),
      rowBuilder: (row) => MobileInvoiceRow(
        row: row,
        formatter: formatter,
        today: today,
        onTap: () => onUpcomingInvoiceTap(row),
      ),
    );
  }

  Widget _recentPaymentsCard(BuildContext context, InTheme tokens) {
    return _mobileListCard<DashboardPaymentRow>(
      context: context,
      tokens: tokens,
      title: context.tr('recent_payments'),
      allLabel: context.tr('all_payments'),
      onAllTap: onAllPayments,
      section: vm.recentPayments,
      emptyMessage: context.tr('no_payments_yet'),
      rowBuilder: (row) => MobilePaymentRow(
        row: row,
        formatter: formatter,
        onTap: () => onPaymentTap(row),
      ),
    );
  }

  Widget _upcomingQuotesCard(BuildContext context, InTheme tokens) {
    return _mobileListCard<DashboardQuoteRow>(
      context: context,
      tokens: tokens,
      title: context.tr('upcoming_quotes'),
      allLabel: context.tr('all_quotes'),
      onAllTap: onAllQuotes,
      section: vm.upcomingQuotes,
      emptyMessage: context.tr('no_upcoming_quotes'),
      rowBuilder: (row) => MobileQuoteRow(
        row: row,
        formatter: formatter,
        expired: false,
        onTap: () => onQuoteTap(row),
      ),
    );
  }

  Widget _expiredQuotesCard(BuildContext context, InTheme tokens) {
    return _mobileListCard<DashboardQuoteRow>(
      context: context,
      tokens: tokens,
      title: context.tr('expired_quotes'),
      allLabel: context.tr('all_quotes'),
      onAllTap: onAllQuotes,
      section: vm.expiredQuotes,
      emptyMessage: context.tr('no_expired_quotes'),
      rowBuilder: (row) => MobileQuoteRow(
        row: row,
        formatter: formatter,
        expired: true,
        onTap: () => onQuoteTap(row),
      ),
    );
  }

  Widget _upcomingRecurringCard(BuildContext context, InTheme tokens) {
    return _mobileListCard<DashboardRecurringInvoiceRow>(
      context: context,
      tokens: tokens,
      title: context.tr('upcoming_recurring_invoices'),
      allLabel: context.tr('all_recurring_invoices'),
      onAllTap: onAllRecurring,
      section: vm.upcomingRecurring,
      emptyMessage: context.tr('no_upcoming_recurring_invoices'),
      rowBuilder: (row) => MobileRecurringInvoiceRow(
        row: row,
        formatter: formatter,
        onTap: () => onRecurringTap(row),
      ),
    );
  }

  // Shared shell for the stacked list cards: header (title + optional "view
  // all" link) → divider → up to [max] rows separated by dividers, or a
  // centered empty message. Matches the pattern of `_needsAttentionCard`.
  Widget _mobileListCard<T>({
    required BuildContext context,
    required InTheme tokens,
    required String title,
    required String allLabel,
    required VoidCallback onAllTap,
    required AsyncSection<List<T>> section,
    required String emptyMessage,
    required Widget Function(T) rowBuilder,
    int max = 5,
  }) {
    final hasRows = section.hasData && (section.data?.isNotEmpty ?? false);
    final List<T> rows = hasRows
        ? section.data!.take(max).toList(growable: false)
        : <T>[];
    return DashboardCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                if (hasRows)
                  GestureDetector(
                    onTap: onAllTap,
                    child: Text(
                      allLabel,
                      style: TextStyle(fontSize: 11.5, color: tokens.ink3),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: tokens.border),
          if (hasRows)
            for (var i = 0; i < rows.length; i++) ...[
              rowBuilder(rows[i]),
              if (i < rows.length - 1)
                Divider(height: 1, thickness: 1, color: tokens.border),
            ]
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: tokens.ink3),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers shared with `KpiRow` — keep both in sync if the math changes.

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

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
}
