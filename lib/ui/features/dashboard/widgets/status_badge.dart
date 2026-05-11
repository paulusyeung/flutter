import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Status pill rendered next to invoices / quotes / payments.
///
/// The overdue variant inlines `" · 3d"` inside the same pill so we don't end
/// up with two adjacent chips fighting for attention.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.tone, required this.label});

  final StatusTone tone;
  final String label;

  /// Invoice status_id → tone. Status IDs from `EntityStatus` in
  /// admin-portal (`lib/data/models/static/invoice_status_model.dart`).
  static StatusTone toneForInvoiceStatus(int statusId, {bool overdue = false}) {
    if (overdue) return StatusTone.overdue;
    switch (statusId) {
      case 4:
        return StatusTone.paid;
      case 3:
        return StatusTone.partial;
      case 2:
        return StatusTone.sent;
      case 1:
      default:
        return StatusTone.draft;
    }
  }

  static StatusTone toneForQuoteStatus(int statusId, {bool expired = false}) {
    if (expired) return StatusTone.overdue;
    switch (statusId) {
      case 4:
      case 5:
        return StatusTone.paid;
      case 3:
        return StatusTone.partial;
      case 2:
        return StatusTone.sent;
      case 1:
      default:
        return StatusTone.draft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (bg, fg) = _resolve(tokens, tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  (Color bg, Color fg) _resolve(InTheme t, StatusTone tone) {
    switch (tone) {
      case StatusTone.paid:
        return (t.paidSoft, t.paid);
      case StatusTone.overdue:
        return (t.overdueSoft, t.overdue);
      case StatusTone.draft:
        return (t.draftSoft, t.draft);
      case StatusTone.sent:
        return (t.sentSoft, t.sent);
      case StatusTone.partial:
        return (t.partialSoft, t.partial);
    }
  }
}

enum StatusTone { paid, overdue, draft, sent, partial }
