import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/quote_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact status pill for the quotes list + detail screens. Mirrors the
/// invoice status pill shape; color mapping is quote-specific (no "paid"
/// → green; instead "approved" → green and "expired" → overdue).
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
    final color = _colorForStatus(tokens, statusId);
    final name = context.tr(quoteStatusLabelKey(statusId));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
          ),
        ),
      ],
    );
  }
}

Color _colorForStatus(InTheme tokens, String id) {
  switch (id) {
    case '3': // approved
      return tokens.paid;
    case '4': // converted
      return tokens.sent;
    case '2': // sent
      return tokens.sent;
    case '-1': // expired (computed)
      return tokens.overdue;
    case '-2': // viewed (computed)
      return tokens.sent;
    case '1': // draft
    default:
      return tokens.draft;
  }
}
