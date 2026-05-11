import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
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
      title: context.tr('upcoming_quotes'),
      section: section,
      footerLabel: context.tr('all_quotes'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.description_outlined,
      emptyTitle: context.tr('no_upcoming_quotes'),
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
      4 => 'approved',
      5 => 'converted',
      3 => 'partial',
      2 => 'sent',
      _ => 'draft',
    };
    return context.tr(key);
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
      title: context.tr('expired_quotes'),
      section: section,
      footerLabel: context.tr('all_quotes'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.event_busy_outlined,
      emptyTitle: context.tr('no_expired_quotes'),
      rowBuilder: (context, row) {
        final dateText = row.validUntil != null
            ? context.tr('expired_on', {'date': row.validUntil!.toIso()})
            : (row.date != null ? row.date!.toIso() : '');
        return DashboardListRowTile(
          number: row.number.isEmpty ? '—' : row.number,
          subtitle:
              '${row.clientName}${dateText.isEmpty ? '' : ' · $dateText'}',
          amountText: formatter.money(
            row.amount,
            clientCurrencyId: row.currencyId.isEmpty ? null : row.currencyId,
          ),
          trailingChip: StatusBadge(
            tone: StatusTone.overdue,
            label: context.tr('expired'),
          ),
          dim: true,
          onTap: () => onRowTap(row),
        );
      },
    );
  }
}
