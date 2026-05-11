import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

/// "Needs your attention" — full-width past-due card. Same generic list shape,
/// just an explicit override of title + footer copy per the v2 mockup.
class NeedsYourAttentionCard extends StatelessWidget {
  const NeedsYourAttentionCard({
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
      title: 'Needs your attention',
      section: section,
      footerLabel: 'All invoices',
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.check_circle_outline,
      emptyTitle: 'All caught up',
      emptySubtitle: 'Nothing overdue.',
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
          trailingChip: StatusBadge(tone: StatusTone.overdue, label: 'Overdue'),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }
}
