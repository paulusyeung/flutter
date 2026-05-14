import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/expense_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact "● Status name" pill — colored dot + status name. Used inside
/// the expenses list tile, the detail header, and anywhere else a raw
/// `expense.calculatedStatusId` would otherwise leak into the UI.
///
/// Colors come from [kExpenseStatusColors]; labels resolve via
/// [kExpenseStatusLabels] + the active locale's translations.
class ExpenseStatusPill extends StatelessWidget {
  const ExpenseStatusPill({
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
    final color = kExpenseStatusColors[statusId] ?? tokens.ink3;
    final labelKey = kExpenseStatusLabels[statusId];
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
}
