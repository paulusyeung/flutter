import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/recurring_invoice_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_bounce_overlay.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact status badge for recurring invoice list + detail screens.
/// Lifecycle: Draft → Active → Paused → Completed. Pending (computed,
/// future next_send_date) shares the Active color.
class RecurringInvoiceStatusPill extends StatelessWidget {
  const RecurringInvoiceStatusPill({
    super.key,
    required this.statusId,
    this.dotSize = 8,
    this.textStyle,
    this.hasBounce = false,
  });

  final String statusId;
  final double dotSize;
  final TextStyle? textStyle;

  /// Overlays a red alert badge when an invitation bounced/errored
  /// (`recurringInvoice.hasBouncedInvitation`).
  final bool hasBounce;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final colors = _colorsForStatus(tokens, statusId);
    final name = context.tr(recurringInvoiceStatusLabelKey(statusId));
    return StatusBounceOverlay(
      hasBounce: hasBounce,
      child: StatusPill(
        label: name,
        fgColor: colors.fg,
        bgColor: colors.bg,
        dotSize: dotSize,
        textStyle: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
      ),
    );
  }
}

({Color fg, Color bg}) _colorsForStatus(InTheme tokens, String id) {
  switch (id) {
    case '4': // completed
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case '3': // paused
      return (fg: tokens.partial, bg: tokens.partialSoft);
    case '2': // active
    case '-1': // pending (computed)
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '1': // draft
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
