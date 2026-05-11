import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';

class RecentPaymentsCard extends StatelessWidget {
  const RecentPaymentsCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardPaymentRow>> section;
  final Formatter formatter;
  final void Function(DashboardPaymentRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardPaymentRow>(
      title: 'Recent payments',
      section: section,
      footerLabel: 'All payments',
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.payments_outlined,
      emptyTitle: 'No payments yet',
      rowBuilder: (context, row) {
        final dateText = row.date != null ? row.date!.toIso() : '';
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle:
              '${row.clientName}${dateText.isEmpty ? '' : ' · $dateText'}',
          amountText: formatter.money(
            row.amount,
            currencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }
}
