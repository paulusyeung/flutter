import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

class UpcomingInvoicesCard extends StatelessWidget {
  const UpcomingInvoicesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardInvoiceRow>> section;
  final Formatter formatter;
  final void Function(DashboardInvoiceRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardInvoiceRow>(
      title: context.tr('upcoming_invoices'),
      section: section,
      footerLabel: context.tr('all_invoices'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.calendar_today_outlined,
      emptyTitle: context.tr('no_invoices_due_soon'),
      rowBuilder: (context, row) {
        final dueText = row.dueDate != null
            ? context.tr('due_on', {'date': row.dueDate!.toIso()})
            : context.tr('no_due_date');
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle: '${row.clientName} · $dueText',
          amountText: formatter.money(
            row.balance,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          trailingChip: StatusBadge(
            tone: StatusBadge.toneForInvoiceStatus(row.statusId),
            label: _statusLabel(context, row.statusId),
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }

  String _statusLabel(BuildContext context, int statusId) {
    final key = switch (statusId) {
      4 => 'paid',
      3 => 'partial',
      2 => 'sent',
      _ => 'draft',
    };
    return context.tr(key);
  }
}
