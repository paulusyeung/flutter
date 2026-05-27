import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/formatter_scope.dart';

/// Read-only summary of the four reminder timestamps on an invoice
/// (`reminder1Sent` / `reminder2Sent` / `reminder3Sent` / `reminderLastSent`).
/// Renders nothing when all four are null — keeps the activity tab quiet
/// for invoices that haven't fired a reminder yet.
///
/// Per-invoice reminder *schedule* configuration is a company-level
/// setting; this widget only surfaces what's already fired. The Activity
/// tab also shows individual sent events via the activities feed when
/// that lands in a follow-up.
class InvoiceRemindersSummary extends StatelessWidget {
  const InvoiceRemindersSummary({super.key, required this.invoice});

  final Invoice invoice;

  bool get _hasAny =>
      invoice.reminder1Sent != null ||
      invoice.reminder2Sent != null ||
      invoice.reminder3Sent != null ||
      invoice.reminderLastSent != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    final tokens = context.inTheme;
    final rows = <Widget>[];
    void addRow(String labelKey, Date? date) {
      if (date == null) return;
      rows.add(_RemindRow(labelKey: labelKey, date: date));
    }

    addRow('reminder1_sent', invoice.reminder1Sent);
    addRow('reminder2_sent', invoice.reminder2Sent);
    addRow('reminder3_sent', invoice.reminder3Sent);
    addRow('reminder_last_sent', invoice.reminderLastSent);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
        color: tokens.surface,
      ),
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('reminders'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.ink3,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

class _RemindRow extends StatelessWidget {
  const _RemindRow({required this.labelKey, required this.date});

  final String labelKey;
  final Date date;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final formatter = FormatterScope.maybeOf(context);
    final dateText = formatter?.date(date.toIso()) ?? date.toIso();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.notifications_outlined, size: 14, color: tokens.ink3),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.tr(labelKey),
              style: TextStyle(color: tokens.ink, fontSize: 13),
            ),
          ),
          Text(
            dateText,
            style: TextStyle(color: tokens.ink3, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
