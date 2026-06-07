import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/dashboard/widgets/entity_table.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';

/// Tabular renderer for dashboard invoice rows. Used by "Needs your
/// attention" and "Upcoming invoices". Mirrors the `InvoiceTable` pattern in
/// `docs/design/v2/screens.jsx:357-390`: `Invoice | Client | Status | Due |
/// Amount | ⋮`.
class DashboardInvoiceTable extends StatelessWidget {
  const DashboardInvoiceTable({
    super.key,
    required this.rows,
    required this.formatter,
    required this.onInvoiceTap,
    required this.onClientTap,
    this.compact = true,
    this.alwaysOverdue = false,
  });

  final List<DashboardInvoiceRow> rows;
  final Formatter formatter;

  /// Fired when the invoice number, status, due date, amount, or trailing
  /// menu cell is tapped — i.e. anything that names the invoice itself.
  final void Function(DashboardInvoiceRow) onInvoiceTap;

  /// Fired only when the client name cell is tapped — routes to that client.
  final void Function(DashboardInvoiceRow) onClientTap;

  final bool compact;

  /// When true, every row paints as overdue regardless of `dueDate` — used by
  /// the "Needs your attention" card, which is already filtered to past-due.
  /// When false, overdue is derived from `dueDate < today` + status.
  final bool alwaysOverdue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final today = Date.today();

    return DashboardEntityTable(
      compact: compact,
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
        context.tr('invoice'),
        context.tr('client'),
        context.tr('status'),
        context.tr('due'),
        context.tr('amount'),
        '',
      ],
      rows: [for (final row in rows) _row(context, tokens, today, row)],
    );
  }

  DashboardEntityTableRow _row(
    BuildContext context,
    InTheme tokens,
    Date today,
    DashboardInvoiceRow row,
  ) {
    final overdue =
        alwaysOverdue ||
        (row.statusId != 4 &&
            row.dueDate != null &&
            row.dueDate!.compareTo(today) < 0);
    final daysOverdue = (overdue && row.dueDate != null)
        ? today.differenceInDays(row.dueDate!)
        : null;

    final tone = StatusBadge.toneForInvoiceStatus(
      row.statusId,
      overdue: overdue,
    );
    final statusLabel = overdue && daysOverdue != null && daysOverdue > 0
        ? '${context.tr('overdue')} · ${daysOverdue}d'
        : StatusBadge.invoiceStatusLabel(
            context,
            row.statusId,
            overdue: overdue,
          );

    final dueText = row.dueDate != null
        ? formatter.date(row.dueDate!.toIso())
        : '—';

    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(
      row.balance,
      clientCurrencyId: currencyKey,
    );
    final isPartial = row.statusId == 3;
    final paidAmount = row.amount - row.balance;
    final partialPaidText = isPartial && paidAmount > Decimal.zero
        ? '${formatter.money(paidAmount, clientCurrencyId: currencyKey)} ${context.tr('paid').toLowerCase()}'
        : null;

    void invoiceTap() => onInvoiceTap(row);
    void clientTap() => onClientTap(row);

    return DashboardEntityTableRow(
      cellTaps: [
        invoiceTap,
        clientTap,
        invoiceTap,
        invoiceTap,
        invoiceTap,
        invoiceTap,
      ],
      cells: [
        LinkText(
          label: row.number.isEmpty ? '—' : row.number,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
        LinkText(
          label: row.clientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        StatusBadge(tone: tone, label: statusLabel),
        Text(
          dueText,
          style: TextStyle(
            fontSize: 12.5,
            color: overdue ? tokens.overdue : tokens.ink2,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountText,
              style: moneyTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.ink,
              ),
            ),
            if (partialPaidText != null)
              Text(
                partialPaidText,
                style: moneyTextStyle(fontSize: 10.5, color: tokens.partial),
              ),
          ],
        ),
        Icon(Icons.more_vert, size: 16, color: tokens.ink3),
      ],
    );
  }
}
