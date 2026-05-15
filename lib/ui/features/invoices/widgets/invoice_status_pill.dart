import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact "● Status name" pill — colored dot + status name. Used inside
/// the invoices list tile, the detail header, and anywhere else a raw
/// status id would otherwise leak into the UI.
///
/// Color tokens come from the design system (`paid`, `partial`, `overdue`,
/// `sent`, `draft`) so light/dark modes pick the right palette
/// automatically. Labels resolve via [invoiceStatusLabelKey] + the active
/// locale's translations.
class InvoiceStatusPill extends StatelessWidget {
  const InvoiceStatusPill({
    super.key,
    required this.statusId,
    this.dotSize = 8,
    this.textStyle,
  });

  /// One of [InvoiceStatus.wireId] or [InvoiceStatusComputed] (`'-1'`,
  /// `'-2'`, `'-3'`) — pass the value of `invoice.calculatedStatusId`.
  final String statusId;
  final double dotSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final color = _colorForStatus(tokens, statusId);
    final name = context.tr(invoiceStatusLabelKey(statusId));
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
    case '4': // paid
      return tokens.paid;
    case '3': // partial
      return tokens.partial;
    case '2': // sent
      return tokens.sent;
    case '5': // cancelled
    case '6': // reversed
      return tokens.ink3;
    case '-1': // past due
      return tokens.overdue;
    case '-3': // viewed
      return tokens.sent;
    case '-2': // unpaid
      return tokens.overdue;
    case '1': // draft
    default:
      return tokens.draft;
  }
}
