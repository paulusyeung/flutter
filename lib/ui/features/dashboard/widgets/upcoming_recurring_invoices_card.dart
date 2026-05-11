import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/entity_table.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';

class UpcomingRecurringInvoicesCard extends StatelessWidget {
  const UpcomingRecurringInvoicesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardRecurringInvoiceRow>> section;
  final Formatter formatter;
  final void Function(DashboardRecurringInvoiceRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardRecurringInvoiceRow>(
      title: context.tr('upcoming_recurring_invoices'),
      section: section,
      footerLabel: context.tr('all_recurring_invoices'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.replay_outlined,
      emptyTitle: context.tr('no_upcoming_recurring_invoices'),
      bodyBuilder: (context, rows) => _table(context, rows),
    );
  }

  Widget _table(BuildContext context, List<DashboardRecurringInvoiceRow> rows) {
    final tokens = context.inTheme;
    return DashboardEntityTable(
      compact: true,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(2),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: FixedColumnWidth(32),
      },
      cellAlignments: const {
        3: Alignment.centerRight,
        4: Alignment.centerRight,
      },
      headers: [
        context.tr('invoice'),
        context.tr('client'),
        context.tr('next'),
        context.tr('amount'),
        '',
      ],
      rows: [
        for (final row in rows) _row(context, tokens, row),
      ],
    );
  }

  DashboardEntityTableRow _row(
    BuildContext context,
    InTheme tokens,
    DashboardRecurringInvoiceRow row,
  ) {
    final nextText = row.nextSendDate != null
        ? formatter.date(row.nextSendDate!.toIso())
        : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(row.amount, clientCurrencyId: currencyKey);

    return DashboardEntityTableRow(
      onTap: () => onRowTap(row),
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
        Text(
          nextText,
          style: TextStyle(fontSize: 12.5, color: tokens.ink2),
        ),
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
}
