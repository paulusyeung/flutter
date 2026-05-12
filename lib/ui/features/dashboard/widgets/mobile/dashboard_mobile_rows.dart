import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/dashboard/widgets/status_badge.dart';
import 'package:admin/utils/formatting.dart';

/// Mobile-stacked row widgets shared by the mobile dashboard cards. Each row
/// follows the same anatomy:
///
///   number + status pill on the top-left
///   client name beneath
///   amount + date stacked on the right
///
/// Lifted out of `mobile_dashboard_body.dart` so the body can focus on
/// layout composition. The status-label helpers live alongside since they're
/// shared between the rows and the table-style cards on desktop.

/// Stacked invoice row. When [alwaysOverdue] is true (used by the "Needs your
/// attention" card, already filtered to past-due), every row paints as
/// overdue. Otherwise overdue is derived from `statusId != paid && dueDate <
/// today`, matching `DashboardInvoiceTable._row` on desktop.
class MobileInvoiceRow extends StatelessWidget {
  const MobileInvoiceRow({
    super.key,
    required this.row,
    required this.formatter,
    required this.today,
    required this.onTap,
    this.alwaysOverdue = false,
  });

  final DashboardInvoiceRow row;
  final Formatter formatter;
  final Date today;
  final VoidCallback onTap;
  final bool alwaysOverdue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final overdue =
        alwaysOverdue ||
        (row.statusId != 4 &&
            row.dueDate != null &&
            row.dueDate!.compareTo(today) < 0);
    final daysOverdue = (overdue && row.dueDate != null)
        ? _daysBetween(row.dueDate!, today)
        : null;
    final tone = StatusBadge.toneForInvoiceStatus(
      row.statusId,
      overdue: overdue,
    );
    final statusLabel = overdue && daysOverdue != null && daysOverdue > 0
        ? '${context.tr('overdue')} · ${daysOverdue}d'
        : invoiceStatusLabel(context, row.statusId, overdue: overdue);

    final dueText = row.dueDate != null
        ? formatter.date(row.dueDate!.toIso())
        : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(
      row.balance,
      clientCurrencyId: currencyKey,
    );

    return _RowShell(
      onTap: onTap,
      leading: _LeadingIdentity(
        number: row.number,
        clientName: row.clientName,
        statusBadge: StatusBadge(tone: tone, label: statusLabel),
      ),
      trailing: _TrailingAmountDate(
        amountText: amountText,
        dateText: dueText,
        dateColor: overdue ? tokens.overdue : tokens.ink3,
      ),
    );
  }

  int _daysBetween(Date a, Date b) {
    final aDt = DateTime(a.year, a.month, a.day);
    final bDt = DateTime(b.year, b.month, b.day);
    return bDt.difference(aDt).inDays;
  }
}

/// Stacked payment row for the "Recent payments" card.
class MobilePaymentRow extends StatelessWidget {
  const MobilePaymentRow({
    super.key,
    required this.row,
    required this.formatter,
    required this.onTap,
  });

  final DashboardPaymentRow row;
  final Formatter formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (statusLabel, statusTone) = paymentStatus(context, row.statusId);
    final dateText = row.date != null ? formatter.date(row.date!.toIso()) : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(row.amount, currencyId: currencyKey);

    return _RowShell(
      onTap: onTap,
      leading: _LeadingIdentity(
        number: row.number,
        clientName: row.clientName,
        statusBadge: StatusBadge(tone: statusTone, label: statusLabel),
      ),
      trailing: _TrailingAmountDate(
        amountText: amountText,
        dateText: dateText,
        dateColor: tokens.ink3,
      ),
    );
  }
}

/// Stacked quote row for "Upcoming / Expired quotes" cards. When [expired]
/// is true the status pill becomes "Expired" with overdue tone and the date
/// switches to `validUntil`.
class MobileQuoteRow extends StatelessWidget {
  const MobileQuoteRow({
    super.key,
    required this.row,
    required this.formatter,
    required this.onTap,
    required this.expired,
  });

  final DashboardQuoteRow row;
  final Formatter formatter;
  final VoidCallback onTap;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final tone = StatusBadge.toneForQuoteStatus(row.statusId, expired: expired);
    final statusLabel = expired
        ? context.tr('expired')
        : quoteStatusLabel(context, row.statusId);
    final dateSource = expired ? row.validUntil : row.date;
    final dateText = dateSource != null
        ? formatter.date(dateSource.toIso())
        : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(
      row.amount,
      clientCurrencyId: currencyKey,
    );

    return _RowShell(
      onTap: onTap,
      leading: _LeadingIdentity(
        number: row.number,
        clientName: row.clientName,
        statusBadge: StatusBadge(tone: tone, label: statusLabel),
      ),
      trailing: _TrailingAmountDate(
        amountText: amountText,
        dateText: dateText,
        dateColor: expired ? tokens.overdue : tokens.ink3,
      ),
    );
  }
}

/// Stacked recurring-invoice row for "Upcoming recurring invoices". No
/// status pill — the cadence leads the row instead.
class MobileRecurringInvoiceRow extends StatelessWidget {
  const MobileRecurringInvoiceRow({
    super.key,
    required this.row,
    required this.formatter,
    required this.onTap,
  });

  final DashboardRecurringInvoiceRow row;
  final Formatter formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final nextText = row.nextSendDate != null
        ? formatter.date(row.nextSendDate!.toIso())
        : '—';
    final currencyKey = row.currencyId.isEmpty ? null : row.currencyId;
    final amountText = formatter.money(
      row.amount,
      clientCurrencyId: currencyKey,
    );

    return _RowShell(
      onTap: onTap,
      leading: _LeadingIdentity(
        number: row.number,
        clientName: row.clientName,
        statusBadge: null,
      ),
      trailing: _TrailingAmountDate(
        amountText: amountText,
        dateText: nextText,
        dateColor: tokens.ink3,
      ),
    );
  }
}

// ── Internal shells ────────────────────────────────────────────────────

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.onTap,
    required this.leading,
    required this.trailing,
  });

  final VoidCallback onTap;
  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _LeadingIdentity extends StatelessWidget {
  const _LeadingIdentity({
    required this.number,
    required this.clientName,
    required this.statusBadge,
  });

  final String number;
  final String clientName;
  final Widget? statusBadge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final numberText = Text(
      number.isEmpty ? '—' : number,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        fontFamilyFallback: ['Menlo', 'Consolas'],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusBadge != null)
          Row(
            children: [
              Flexible(child: numberText),
              const SizedBox(width: 8),
              statusBadge!,
            ],
          )
        else
          numberText,
        const SizedBox(height: 3),
        Text(
          clientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tokens.ink,
          ),
        ),
      ],
    );
  }
}

class _TrailingAmountDate extends StatelessWidget {
  const _TrailingAmountDate({
    required this.amountText,
    required this.dateText,
    required this.dateColor,
  });

  final String amountText;
  final String dateText;
  final Color dateColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amountText,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: tokens.ink,
            fontFamilyFallback: const ['Menlo', 'Consolas'],
          ),
        ),
        const SizedBox(height: 2),
        Text(dateText, style: TextStyle(fontSize: 10.5, color: dateColor)),
      ],
    );
  }
}

// ── Status-label helpers ───────────────────────────────────────────────

/// Localized label for an invoice status id, with overdue taking precedence.
String invoiceStatusLabel(
  BuildContext context,
  int statusId, {
  required bool overdue,
}) {
  if (overdue) return context.tr('overdue');
  switch (statusId) {
    case 4:
      return context.tr('paid');
    case 3:
      return context.tr('partial');
    case 2:
      return context.tr('sent');
    case 1:
    default:
      return context.tr('draft');
  }
}

/// Resolves a payment status id to a `(localizedLabel, badgeTone)` pair.
(String, StatusTone) paymentStatus(BuildContext context, int statusId) {
  switch (statusId) {
    case 4:
      return (context.tr('completed'), StatusTone.paid);
    case 5:
      return (context.tr('partially_refunded'), StatusTone.partial);
    case 6:
      return (context.tr('refunded'), StatusTone.overdue);
    case 3:
      return (context.tr('failed'), StatusTone.overdue);
    case 2:
      return (context.tr('voided'), StatusTone.draft);
    case 1:
    default:
      return (context.tr('pending'), StatusTone.draft);
  }
}

/// Localized label for a quote status id. Expiry is layered on top by the
/// caller (it overrides the status), not resolved here.
String quoteStatusLabel(BuildContext context, int statusId) {
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
