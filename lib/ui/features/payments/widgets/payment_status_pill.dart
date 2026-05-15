import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/payment_status.dart';
import 'package:admin/l10n/localization.dart';

/// Compact "● Status name" pill — colored dot + status name. Used inside
/// the payments list tile, detail header, and KPI strip.
class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({
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
    final color = kPaymentStatusColors[statusId] ?? tokens.ink3;
    final labelKey = kPaymentStatusLabels[statusId];
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
