import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/l10n/localization.dart';

/// Compact "● Status name" pill for bank-transaction `status_id` (1
/// Unmatched / 2 Matched / 3 Converted). Mirrors the visual vocabulary
/// of `ExpenseStatusPill` so the list rows agree across feature areas.
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
    final color = _colorFor(statusId, tokens);
    final labelKey = _labelKeyFor(statusId);
    final name = labelKey == null ? statusId : context.tr(labelKey);
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

  Color _colorFor(String id, InTheme tokens) {
    switch (id) {
      case kTransactionStatusUnmatched:
        return tokens.draft;
      case kTransactionStatusMatched:
        return tokens.partial;
      case kTransactionStatusConverted:
        return tokens.paid;
      default:
        return tokens.ink3;
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
