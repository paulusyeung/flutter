import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/hover_highlight.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_sparkline.dart';

/// One KPI tile: label / value / delta / sparkline. Renders inside the shared
/// card shell shape, sized by the parent grid.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.deltaPercent,
    required this.goodDirection,
    required this.sparklineValues,
    this.tone,
    this.subcaption,
    this.semanticsLabel,
    this.onTap,
  });

  final String label;

  /// Formatted value text (e.g. `$38,420`, `17` for days).
  final String value;

  /// Signed percent change vs prior period; null = no delta available.
  final double? deltaPercent;

  final GoodDirection goodDirection;

  final List<double> sparklineValues;

  /// Optional accent override. Default = `accent`; "Overdue" passes `overdue`.
  final KpiTone? tone;

  /// Optional below-value caption ("Mixed currencies — pick one ...").
  final String? subcaption;

  final String? semanticsLabel;

  /// Optional tap target — when non-null, the card becomes a clickable link
  /// (typically to a filtered list view).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final sparkColor = tone == KpiTone.overdue ? tokens.overdue : tokens.accent;
    final radius = BorderRadius.circular(InRadii.r3);
    final clickable = onTap != null;
    final Widget inner = Padding(
      padding: const EdgeInsets.all(InSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: tokens.ink3,
                  ),
                ),
              ),
              if (clickable)
                Icon(Icons.chevron_right, size: 16, color: tokens.ink3),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              color: tokens.ink,
              fontFamilyFallback: const ['Menlo', 'Consolas'],
            ),
          ),
          if (subcaption != null) ...[
            const SizedBox(height: 2),
            Text(
              subcaption!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: tokens.ink3),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              DeltaChip(
                percent: deltaPercent,
                goodDirection: goodDirection,
                suffix: 'vs prior',
              ),
              const Spacer(),
              KpiSparkline(values: sparklineValues, color: sparkColor),
            ],
          ),
        ],
      ),
    );
    final Widget body = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: radius,
        border: Border.all(color: tokens.border),
        boxShadow: tokens.shadow1,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: HoverHighlight(
          enabled: clickable,
          borderRadius: radius,
          child: inner,
        ),
      ),
    );
    Widget result = body;
    if (clickable) {
      result = Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, borderRadius: radius, child: body),
      );
    }
    if (semanticsLabel == null) return result;
    return Semantics(
      container: true,
      label: semanticsLabel,
      button: clickable,
      child: ExcludeSemantics(child: result),
    );
  }
}

enum KpiTone { accent, overdue }
