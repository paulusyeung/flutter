import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/entity_table.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

class RecentPaymentsCard extends StatelessWidget {
  const RecentPaymentsCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onPaymentTap,
    required this.onClientTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardPaymentRow>> section;
  final Formatter formatter;
  final void Function(DashboardPaymentRow) onPaymentTap;
  final void Function(DashboardPaymentRow) onClientTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardPaymentRow>(
      title: context.tr('recent_payments'),
      section: section,
      footerLabel: context.tr('all_payments'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.payments_outlined,
      emptyTitle: context.tr('no_payments_yet'),
      bodyBuilder: (context, rows) => _table(context, rows),
    );
  }

  Widget _table(BuildContext context, List<DashboardPaymentRow> rows) {
    final tokens = context.inTheme;
    return DashboardEntityTable(
      compact: true,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(2),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: FixedColumnWidth(32),
      },
      cellAlignments: const {
        4: Alignment.centerRight,
        5: Alignment.centerRight,
      },
      headers: [
        context.tr('payment'),
        context.tr('client'),
        context.tr('status'),
        context.tr('date'),
        context.tr('amount'),
        '',
      ],
      rows: [for (final row in rows) _row(context, tokens, row)],
    );
  }

  DashboardEntityTableRow _row(
    BuildContext context,
    InTheme tokens,
    DashboardPaymentRow row,
  ) {
    final (statusLabel, statusTone) = _paymentStatus(context, row.statusId);
    final dateText = row.date != null ? formatter.date(row.date!.toIso()) : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(row.amount, currencyId: currencyKey);

    void paymentTap() => onPaymentTap(row);
    void clientTap() => onClientTap(row);

    return DashboardEntityTableRow(
      cellTaps: [
        paymentTap,
        clientTap,
        paymentTap,
        paymentTap,
        paymentTap,
        paymentTap,
      ],
      cells: [
        Text(
          row.number.isEmpty ? '—' : row.number,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: tokens.ink,
            fontFamilyFallback: const ['Menlo', 'Consolas'],
          ),
        ),
        Text(
          row.clientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: tokens.ink),
        ),
        StatusBadge(tone: statusTone, label: statusLabel),
        Text(dateText, style: TextStyle(fontSize: 12.5, color: tokens.ink2)),
        Text(
          amountText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.ink,
            fontFamilyFallback: const ['Menlo', 'Consolas'],
          ),
        ),
        Icon(Icons.more_vert, size: 16, color: tokens.ink3),
      ],
    );
  }

  (String, StatusTone) _paymentStatus(BuildContext context, int statusId) {
    switch (statusId) {
      case 4:
        return (context.tr('completed'), StatusTone.paid);
      case 5:
        return (context.tr('partially_refunded'), StatusTone.partial);
      case 6:
        return (context.tr('refunded'), StatusTone.overdue);
      case 3:
        return (context.tr('failed'), StatusTone.overdue);
      case 2:
        return (context.tr('voided'), StatusTone.draft);
      case 1:
      default:
        return (context.tr('pending'), StatusTone.draft);
    }
  }
}
