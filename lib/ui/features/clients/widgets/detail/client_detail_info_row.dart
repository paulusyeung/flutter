import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// One row inside a detail card: a small ink3 label above the value.
/// Matches the React reference at `react/src/pages/clients/show/Details.tsx`
/// — small caps-ish label, full ink value below, full-width.
class ClientDetailInfoRow extends StatelessWidget {
  const ClientDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
  });

  final String label;
  final String value;

  /// Renders the value with tabular figures so money columns align.
  final bool monospace;

  /// Override the default value color (used by the Standing card to dim
  /// zero amounts).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.ink3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? tokens.ink,
              fontFeatures: monospace
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
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
