import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/recurring_invoice_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact status pill for recurring invoice list + detail screens.
/// Lifecycle: Draft → Active → Paused → Completed. Pending (computed,
/// future next_send_date) shares the Active color.
class RecurringInvoiceStatusPill extends StatelessWidget {
  const RecurringInvoiceStatusPill({
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
    final name = context.tr(recurringInvoiceStatusLabelKey(statusId));
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
    case '4': // completed
      return tokens.paid;
    case '3': // paused
      return tokens.partial;
    case '2': // active
      return tokens.sent;
    case '-1': // pending (computed)
      return tokens.sent;
    case '1': // draft
    default:
      return tokens.draft;
  }
}
