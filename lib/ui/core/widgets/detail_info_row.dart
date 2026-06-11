import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/copyable_value.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// One row inside an entity detail card: a small ink3 label in a fixed-width
/// column on the left, value left-aligned right next to it. Keeps values close
/// to their labels so short fields (phone, country, price) don't leave a big
/// gap on the right edge.
///
/// Entity-agnostic — used by client, product, invoice, …  detail cards.
class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
    this.onTap,
    this.copyable = true,
    this.copyText,
  });

  final String label;
  final String value;

  /// Renders the value with tabular figures so money columns align.
  final bool monospace;

  /// Override the default value color (used to dim zero amounts).
  final Color? valueColor;

  /// When non-null the value renders as a clickable link (accent color,
  /// hover underline) that invokes [onTap].
  final VoidCallback? onTap;

  /// Whether the value gets a copy affordance (hover icon on desktop/web,
  /// tap-to-copy on mobile). On by default; set false for values that aren't
  /// worth copying — resolved enum/display names ("US Dollar", "Yes"),
  /// composites, or formatted dates.
  final bool copyable;

  /// The exact string copied when [copyable]. Defaults to [value]; override
  /// when the displayed text differs from what's useful to copy.
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: valueColor ?? tokens.ink,
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      fontFeatures: monospace ? const [FontFeature.tabularFigures()] : null,
    );
    final Widget display = onTap == null
        ? Text(value, style: valueStyle)
        : LinkText(
            label: value,
            style: valueStyle,
            color: tokens.accent,
            onTap: onTap,
          );
    // Copy affordance: hover icon (desktop/web) or tap-to-copy (mobile). A row
    // with its own onTap (e.g. a website launch) keeps tap for that action and
    // exposes copy via the hover icon / a mobile long-press instead.
    final Widget valueWidget = copyable && value.isNotEmpty
        ? CopyableValue(
            value: copyText ?? value,
            enableTapToCopy: onTap == null,
            enableLongPressToCopy: onTap != null,
            child: display,
          )
        : display;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.ink3,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: InSpacing.sm),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}

/// Hairline divider between rows in a detail card. Uses `tokens.border`;
/// matches the row inset of `DashboardCardShell` content.
class DetailRowDivider extends StatelessWidget {
  const DetailRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.inTheme.border);
  }
}

/// Stacks a list of [DetailInfoRow]s with [DetailRowDivider]s between them,
/// dropping any null entries (so callers can write
/// `if (foo.isEmpty) null else DetailInfoRow(...)`).
class DetailRowStack extends StatelessWidget {
  const DetailRowStack({super.key, required this.children});

  final List<Widget?> children;

  @override
  Widget build(BuildContext context) {
    final rows = children.whereType<Widget>().toList(growable: false);
    if (rows.isEmpty) return const SizedBox.shrink();
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) out.add(const DetailRowDivider());
      out.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: out,
    );
  }
}
