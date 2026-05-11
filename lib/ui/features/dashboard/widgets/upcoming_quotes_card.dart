import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/list_row_tile.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

class UpcomingQuotesCard extends StatelessWidget {
  const UpcomingQuotesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardQuoteRow>> section;
  final Formatter formatter;
  final void Function(DashboardQuoteRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardQuoteRow>(
      title: 'Upcoming quotes',
      section: section,
      footerLabel: 'All quotes',
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.description_outlined,
      emptyTitle: 'No upcoming quotes',
      rowBuilder: (context, row) {
        final dateText = row.date != null ? row.date!.toIso() : '';
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle:
              '${row.clientName}${dateText.isEmpty ? '' : ' · $dateText'}',
          amountText: formatter.money(
            row.amount,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          trailingChip: StatusBadge(
            tone: StatusBadge.toneForQuoteStatus(row.statusId),
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
        return 'Approved';
      case 5:
        return 'Converted';
      case 3:
        return 'Partial';
      case 2:
        return 'Sent';
      default:
        return 'Draft';
    }
  }
}

class ExpiredQuotesCard extends StatelessWidget {
  const ExpiredQuotesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardQuoteRow>> section;
  final Formatter formatter;
  final void Function(DashboardQuoteRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardQuoteRow>(
      title: 'Expired quotes',
      section: section,
      footerLabel: 'All quotes',
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: 'No expired quotes',
      rowBuilder: (context, row) {
        final dateText = row.validUntil != null
            ? 'Expired ${row.validUntil!.toIso()}'
            : (row.date != null ? row.date!.toIso() : '');
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle:
              '${row.clientName}${dateText.isEmpty ? '' : ' · $dateText'}',
          amountText: formatter.money(
            row.amount,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          trailingChip: const StatusBadge(
            tone: StatusTone.overdue,
            label: 'Expired',
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }
}
