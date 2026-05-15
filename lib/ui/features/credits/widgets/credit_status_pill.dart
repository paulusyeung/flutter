import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/credit_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact status pill for the credits list + detail screens. Mirrors the
/// invoice / quote status pill shape; color mapping reflects credits'
/// lifecycle (no "paid" — applied is the terminal state and is green).
class CreditStatusPill extends StatelessWidget {
  const CreditStatusPill({
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
    final name = context.tr(creditStatusLabelKey(statusId));
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
    case '4': // applied
      return tokens.paid;
    case '3': // partial
      return tokens.partial;
    case '2': // sent
      return tokens.sent;
    case '-2': // viewed (computed)
      return tokens.sent;
    case '1': // draft
    default:
      return tokens.draft;
  }
}
