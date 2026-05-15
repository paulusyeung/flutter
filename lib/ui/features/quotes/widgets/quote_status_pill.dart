import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/quote_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact status badge for the quotes list + detail screens. Mirrors the
/// invoice status pill shape; color mapping is quote-specific ("approved"
/// → green and "expired" → overdue).
class QuoteStatusPill extends StatelessWidget {
  const QuoteStatusPill({
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
    final name = context.tr(quoteStatusLabelKey(statusId));
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
    case '3': // approved
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case '4': // converted
    case '2': // sent
    case '-2': // viewed (computed)
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '-1': // expired (computed)
      return (fg: tokens.overdue, bg: tokens.overdueSoft);
    case '1': // draft
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
