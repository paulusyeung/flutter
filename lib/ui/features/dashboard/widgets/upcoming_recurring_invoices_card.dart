import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';

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
      rowBuilder: (context, row) {
        final next = row.nextSendDate != null
            ? context.tr('next_on', {'date': row.nextSendDate!.toIso()})
            : context.tr('no_schedule_set');
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle: '${row.clientName} · $next',
          amountText: formatter.money(
            row.amount,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }
}
