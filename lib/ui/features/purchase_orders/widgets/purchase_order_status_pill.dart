import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/purchase_order_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact status badge for the purchase order list + detail screens.
/// Mirrors the invoice / quote / credit status pill shape; color mapping
/// reflects the PO lifecycle: draft → sent → accepted (green) →
/// received (green) → cancelled (red).
class PurchaseOrderStatusPill extends StatelessWidget {
  const PurchaseOrderStatusPill({
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
    final name = context.tr(purchaseOrderStatusLabelKey(statusId));
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
    case '4': // received
    case '3': // accepted
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case '5': // cancelled
      return (fg: tokens.overdue, bg: tokens.overdueSoft);
    case '2': // sent
    case '-1': // viewed (computed)
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '1': // draft
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
