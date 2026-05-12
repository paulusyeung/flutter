import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// One row inside a detail card: a small ink3 label in a fixed-width column
/// on the left, value left-aligned right next to it. Keeps values close to
/// their labels so short fields (phone, country) don't leave a big gap.
class ClientDetailInfoRow extends StatelessWidget {
  const ClientDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;

  /// Renders the value with tabular figures so money columns align.
  final bool monospace;

  /// Override the default value color (used by the Standing card to dim
  /// zero amounts).
  final Color? valueColor;

  /// When non-null the value renders as a clickable link (accent color,
  /// hover underline) that invokes [onTap].
  final VoidCallback? onTap;

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
    final Widget valueWidget = onTap == null
        ? Text(value, style: valueStyle)
        : LinkText(
            label: value,
            style: valueStyle,
            color: tokens.accent,
            onTap: onTap,
          );
    // Fixed-width label column with the value left-aligned right next to it,
    // so short values don't get pushed to the far card edge. Keeps the row
    // height savings vs the older label-above-value layout.
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

/// Hairline divider between rows in a card. Uses `tokens.border`; matches
/// the row inset of `DashboardCardShell` content.
class ClientDetailRowDivider extends StatelessWidget {
  const ClientDetailRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.inTheme.border);
  }
}

/// Stacks a list of [ClientDetailInfoRow]s with [ClientDetailRowDivider]s
/// between them, dropping any null entries (so callers can write
/// `if (foo.isEmpty) null else InfoRow(...)`).
class ClientDetailRowStack extends StatelessWidget {
  const ClientDetailRowStack({super.key, required this.children});

  final List<Widget?> children;

  @override
  Widget build(BuildContext context) {
    final rows = children.whereType<Widget>().toList(growable: false);
    if (rows.isEmpty) return const SizedBox.shrink();
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) out.add(const ClientDetailRowDivider());
      out.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: out,
    );
  }
}
