import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/entity_table.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

class UpcomingQuotesCard extends StatelessWidget {
  const UpcomingQuotesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onQuoteTap,
    required this.onClientTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardQuoteRow>> section;
  final Formatter formatter;
  final void Function(DashboardQuoteRow) onQuoteTap;
  final void Function(DashboardQuoteRow) onClientTap;
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
      bodyBuilder: (context, rows) => _quoteTable(
        context: context,
        rows: rows,
        formatter: formatter,
        onQuoteTap: onQuoteTap,
        onClientTap: onClientTap,
        expired: false,
      ),
    );
  }
}

class ExpiredQuotesCard extends StatelessWidget {
  const ExpiredQuotesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onQuoteTap,
    required this.onClientTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardQuoteRow>> section;
  final Formatter formatter;
  final void Function(DashboardQuoteRow) onQuoteTap;
  final void Function(DashboardQuoteRow) onClientTap;
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
      bodyBuilder: (context, rows) => _quoteTable(
        context: context,
        rows: rows,
        formatter: formatter,
        onQuoteTap: onQuoteTap,
        onClientTap: onClientTap,
        expired: true,
      ),
    );
  }
}

/// Shared quote-row table used by both upcoming and expired variants. The
/// `expired` flag forces an overdue-tone "Expired" badge in the status cell
/// and swaps the 4th column from "Date" to "Valid until".
Widget _quoteTable({
  required BuildContext context,
  required List<DashboardQuoteRow> rows,
  required Formatter formatter,
  required void Function(DashboardQuoteRow) onQuoteTap,
  required void Function(DashboardQuoteRow) onClientTap,
  required bool expired,
}) {
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
    cellAlignments: const {4: Alignment.centerRight, 5: Alignment.centerRight},
    headers: [
      context.tr('quote'),
      context.tr('client'),
      context.tr('status'),
      expired ? context.tr('valid_until') : context.tr('date'),
      context.tr('amount'),
      '',
    ],
    rows: [
      for (final row in rows)
        _quoteRow(
          context: context,
          tokens: tokens,
          row: row,
          formatter: formatter,
          onQuoteTap: onQuoteTap,
          onClientTap: onClientTap,
          expired: expired,
        ),
    ],
  );
}

DashboardEntityTableRow _quoteRow({
  required BuildContext context,
  required InTheme tokens,
  required DashboardQuoteRow row,
  required Formatter formatter,
  required void Function(DashboardQuoteRow) onQuoteTap,
  required void Function(DashboardQuoteRow) onClientTap,
  required bool expired,
}) {
  final tone = StatusBadge.toneForQuoteStatus(row.statusId, expired: expired);
  final statusLabel = expired
      ? context.tr('expired')
      : _quoteStatusLabel(context, row.statusId);

  final dateSource = expired ? row.validUntil : row.date;
  final dateText = dateSource != null
      ? formatter.date(dateSource.toIso())
      : '—';

  final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
  final amountText = formatter.money(row.amount, clientCurrencyId: currencyKey);

  void quoteTap() => onQuoteTap(row);
  void clientTap() => onClientTap(row);

  return DashboardEntityTableRow(
    cellTaps: [quoteTap, clientTap, quoteTap, quoteTap, quoteTap, quoteTap],
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
      StatusBadge(tone: tone, label: statusLabel),
      Text(
        dateText,
        style: TextStyle(
          fontSize: 12.5,
          color: expired ? tokens.overdue : tokens.ink2,
        ),
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

String _quoteStatusLabel(BuildContext context, int statusId) {
  switch (statusId) {
    case 4:
      return context.tr('approved');
    case 5:
      return context.tr('converted');
    case 3:
      return context.tr('partial');
    case 2:
      return context.tr('sent');
    case 1:
    default:
      return context.tr('draft');
  }
}
