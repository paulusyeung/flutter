import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Single-row tile used by every dashboard list card (Past Due, Upcoming
/// Invoices, Recent Payments, Quotes, Recurring). Layout:
///
/// ```
///   INV-2041  ·  Bauhaus Atelier            $4,200.00
///                                            <status>
/// ```
///
/// Trailing block stacks amount + status, right-aligned. Mobile collapses
/// nothing — at <600px the chart card already stacks, so this row stays
/// horizontal.
class DashboardListRowTile extends StatelessWidget {
  const DashboardListRowTile({
    super.key,
    required this.number,
    required this.subtitle,
    required this.amountText,
    this.trailingChip,
    this.dim = false,
    this.onTap,
  });

  final String number;
  final String subtitle; // typically client name
  final String amountText;
  final Widget? trailingChip; // StatusBadge or similar
  /// When true, the row paints disabled affordances — no ripple, mouse arrow
  /// cursor — to telegraph "this destination isn't live yet."
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final core = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.ink,
                    fontFamilyFallback: const ['Menlo', 'Consolas'],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: InSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.ink,
                  fontFamilyFallback: const ['Menlo', 'Consolas'],
                ),
              ),
              if (trailingChip != null) ...[
                const SizedBox(height: 4),
                trailingChip!,
              ],
            ],
          ),
        ],
      ),
    );

    if (dim || onTap == null) {
      return MouseRegion(cursor: SystemMouseCursors.basic, child: core);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(InRadii.r1),
      onTap: onTap,
      child: core,
    );
  }
}
