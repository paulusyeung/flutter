import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Direction-of-good for the [DeltaChip]: which way a positive delta is good.
/// Revenue/Paid: up. Outstanding/Overdue/Expenses: down. Avg days to pay: down.
enum GoodDirection { up, down }

/// Compact "+18.4% vs prior" pill with an up/down arrow. The color resolves
/// from the sign × [goodDirection]:
///   - matches direction-of-good → paid color (positive vibe)
///   - opposes direction-of-good → overdue color (negative vibe)
///   - zero → ink3 (neutral)
class DeltaChip extends StatelessWidget {
  const DeltaChip({
    super.key,
    required this.percent,
    required this.goodDirection,
    this.suffix,
  });

  /// Signed percent. Positive = `up`, negative = `down`.
  final double? percent;

  final GoodDirection goodDirection;

  /// Optional trailing text (e.g. "vs prior"). Renders in `ink3`.
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final p = percent;
    if (p == null) {
      return Text(
        suffix == null ? '—' : '— $suffix',
        style: TextStyle(fontSize: 11.5, color: tokens.ink3),
      );
    }
    final isZero = p.abs() < 0.05;
    final dir = p < 0 ? GoodDirection.down : GoodDirection.up;
    final Color color;
    if (isZero) {
      color = tokens.ink3;
    } else {
      color = dir == goodDirection ? tokens.paid : tokens.overdue;
    }
    final arrow = dir == GoodDirection.up
        ? Icons.arrow_drop_up
        : Icons.arrow_drop_down;
    final formatted = '${p > 0 ? '+' : ''}${p.toStringAsFixed(1)}%';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isZero) Icon(arrow, size: 14, color: color),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 4),
          Text(suffix!, style: TextStyle(fontSize: 11.5, color: tokens.ink3)),
        ],
      ],
    );
  }
}
