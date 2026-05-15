import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact "● Status name" badge — colored dot + status name on a tinted
/// rounded-rect background. Used inside the invoices list tile, the
/// detail header, the wide-table status column, and anywhere else a raw
/// status id would otherwise leak into the UI.
///
/// Color tokens come from the design system (`paid` + `paidSoft`,
/// `partial` + `partialSoft`, `overdue` + `overdueSoft`, `sent` +
/// `sentSoft`, `draft` + `draftSoft`) so light/dark modes pick the right
/// palette automatically. Labels resolve via [invoiceStatusLabelKey] +
/// the active locale's translations.
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
    final colors = _colorsForStatus(tokens, statusId);
    final name = context.tr(invoiceStatusLabelKey(statusId));
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
    case '4': // paid
      return (fg: tokens.paid, bg: tokens.paidSoft);
    case '3': // partial
      return (fg: tokens.partial, bg: tokens.partialSoft);
    case '2': // sent
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '5': // cancelled
    case '6': // reversed
      return (fg: tokens.ink3, bg: tokens.draftSoft);
    case '-1': // past due
    case '-2': // unpaid
      return (fg: tokens.overdue, bg: tokens.overdueSoft);
    case '-3': // viewed
      return (fg: tokens.sent, bg: tokens.sentSoft);
    case '1': // draft
    default:
      return (fg: tokens.draft, bg: tokens.draftSoft);
  }
}
