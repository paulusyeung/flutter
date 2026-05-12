import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Inline chip rendering one [FilterToken] inside the token search field.
///
/// Visual: `<key>` `<value>` `×` — key muted, value bold, close button
/// trailing. Matches the Sentry screenshot.
///
/// The trailing `×` is always its own interactive node ([onRemove]).
/// The chip BODY is interactive when [onTap] is supplied (default for
/// the editable variant via [TokenSearchField]) and inert when null
/// (and always inert in the [FilterTokenChip.readOnly] variant).
///
/// Two prior iterations explicitly rejected body-tap, both for the
/// same reason: a chip tap surprised users by opening "value mode"
/// when they expected the key picker. The current revival is gated
/// by a visible affordance (the cursor turns into a pointer over the
/// body) and the input shows `<keyAlias>:` immediately — making it
/// obvious you're editing the chip, not adding a new filter.
class FilterTokenChip extends StatelessWidget {
  const FilterTokenChip({
    required this.token,
    required this.onRemove,
    this.onTap,
    super.key,
  }) : readOnly = false;

  /// Compact, non-interactive variant. Used by the narrow-mode summary row
  /// in [TokenSearchField] where the field is just a tap target — the chip
  /// should describe the filter visually without an own close affordance.
  const FilterTokenChip.readOnly({required this.token, super.key})
    : onRemove = _noop,
      onTap = null,
      readOnly = true;

  final FilterToken token;
  final VoidCallback onRemove;

  /// Fired when the user clicks the body (everything except the
  /// trailing `×` button). Null = body stays inert.
  final VoidCallback? onTap;

  final bool readOnly;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final keyStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.ink3,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: tokens.ink,
      fontWeight: FontWeight.w600,
    );

    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(token.displayKey.toLowerCase(), style: keyStyle),
        const SizedBox(width: 4),
        Text(token.displayValue, style: valueStyle),
      ],
    );

    // The body (key + value labels) becomes a tap target when `onTap` is
    // supplied. The trailing `×` IconButton sits OUTSIDE this region so
    // its own gesture detector always wins for the close action — tap
    // priority is by widget bounds, not by ancestor.
    final tappableBody = onTap != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: body,
            ),
          )
        : body;

    return Semantics(
      // Without onTap, the chip is described as static text + a separate
      // `×` button. With onTap, it announces as a button — screen readers
      // get "<key> <value>, button" so the user knows it's actionable.
      button: onTap != null,
      label:
          '${context.tr('filter_label_prefix')}: '
          '${token.displayKey} ${token.displayValue}',
      child: Container(
        decoration: BoxDecoration(
          color: readOnly ? tokens.surface : tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.border),
        ),
        padding: readOnly
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
            : const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tappableBody,
            if (!readOnly) ...[
              const SizedBox(width: 2),
              IconButton(
                tooltip: context.tr('clear_filter'),
                iconSize: 14,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                // 24×24 hit slop — under that, iOS HIG reports the button
                // as below the minimum touch target. The icon stays at 14
                // px for visual density.
                constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
                onPressed: onRemove,
                icon: Icon(Icons.close, color: tokens.ink3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
