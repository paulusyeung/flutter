import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Compact "● Status name" badge for bank-transaction `status_id` (1
/// Unmatched / 2 Matched / 3 Converted). Mirrors the visual vocabulary
/// of [ExpenseStatusPill] so the list rows agree across feature areas.
class TransactionStatusPill extends StatelessWidget {
  const TransactionStatusPill({
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
    final colors = _colorsFor(statusId, tokens);
    final labelKey = _labelKeyFor(statusId);
    final name = labelKey == null ? statusId : context.tr(labelKey);
    return StatusPill(
      label: name,
      fgColor: colors.fg,
      bgColor: colors.bg,
      dotSize: dotSize,
      textStyle: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
    );
  }

  ({Color fg, Color bg}) _colorsFor(String id, InTheme tokens) {
    switch (id) {
      case kTransactionStatusUnmatched:
        return (fg: tokens.draft, bg: tokens.draftSoft);
      case kTransactionStatusMatched:
        return (fg: tokens.partial, bg: tokens.partialSoft);
      case kTransactionStatusConverted:
        return (fg: tokens.paid, bg: tokens.paidSoft);
      default:
        return (fg: tokens.ink3, bg: tokens.draftSoft);
    }
  }

  String? _labelKeyFor(String id) {
    switch (id) {
      case kTransactionStatusUnmatched:
        return 'unmatched';
      case kTransactionStatusMatched:
        return 'matched';
      case kTransactionStatusConverted:
        return 'converted';
      default:
        return null;
    }
  }
}
