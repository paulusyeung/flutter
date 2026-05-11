import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
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
      title: 'Upcoming invoices',
      section: section,
      footerLabel: 'All invoices',
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.calendar_today_outlined,
      emptyTitle: 'No invoices due soon',
      rowBuilder: (context, row) {
        final dueText = row.dueDate != null
            ? 'Due ${row.dueDate!.toIso()}'
            : 'No due date';
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle: '${row.clientName} · $dueText',
          amountText: formatter.money(
            row.balance,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          trailingChip: StatusBadge(
            tone: StatusBadge.toneForInvoiceStatus(row.statusId),
            label: _statusLabel(row.statusId),
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }

  String _statusLabel(int statusId) {
    switch (statusId) {
      case 4:
        return 'Paid';
      case 3:
        return 'Partial';
      case 2:
        return 'Sent';
      default:
        return 'Draft';
    }
  }
}
