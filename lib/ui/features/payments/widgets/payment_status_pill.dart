import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/payment_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact "● Status name" badge — colored dot + status name on a tinted
/// rounded-rect background. Used inside the payments list tile, detail
/// header, KPI strip, and the wide-table status column.
///
/// Maps payment statuses onto the shared design tokens so light/dark
/// palettes resolve automatically (completed → paid, failed/refunded →
/// overdue, partially-refunded/unapplied-partial → partial,
/// pending/cancelled → draft, unapplied → sent).
class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({
    super.key,
    required this.statusId,
    this.dotSize = 8,
    this.textStyle,
  });

  final String statusId;
  final double dotSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final colors = _colorsForStatus(tokens, statusId);
    final labelKey = kPaymentStatusLabels[statusId];
    final name = labelKey == null ? statusId : context.tr(labelKey);
    return StatusPill(
      label: name,
      fgColor: colors.fg,
      bgColor: colors.bg,
      dotSize: dotSize,
      textStyle: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
    );
  }
}

({Color fg, Color bg}) _colorsForStatus(InTheme tokens, String id) {
  switch (id) {
    case kPaymentStatusCompleted:
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case kPaymentStatusFailed:
    case kPaymentStatusRefunded:
      return (fg: tokens.overdue, bg: tokens.overdueSoft);
    case kPaymentStatusPartiallyRefunded:
    case kPaymentStatusPartiallyUnapplied:
      return (fg: tokens.partial, bg: tokens.partialSoft);
    case kPaymentStatusUnapplied:
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case kPaymentStatusPending:
    case kPaymentStatusCancelled:
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
