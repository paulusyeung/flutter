import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Inline chip rendering one [FilterToken] inside the token search field.
///
/// Visual: `<key>` `<value>` `×` — key muted, value bold, close button
/// trailing. Matches the Sentry screenshot.
///
/// Interaction:
///   * Tap the chip body — calls [onTap]. When [onTap] is `cycleValue`,
///     each tap advances to the next value (status: active→archived→deleted);
///     when it opens a popover instead, the popover targets this widget.
///   * Tap the `×` — calls [onRemove].
///   * Backspace / Delete while focused — calls [onRemove].
///   * Screen reader announces a single semantic phrase covering the full
///     interaction model so a11y users don't have to discover each button.
class FilterTokenChip extends StatelessWidget {
  const FilterTokenChip({
    required this.token,
    required this.onTap,
    required this.onRemove,
    this.canCycle = false,
    super.key,
  });

  final FilterToken token;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  /// True when [onTap] cycles the value (vs opens a popover). Only affects
  /// the accessibility label, not the visual; the wide / narrow callers
  /// already know which behavior they wired up.
  final bool canCycle;

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
    final hint = canCycle
        ? context.tr('tap_to_change_value')
        : context.tr('tap_to_edit');

    return Semantics(
      button: true,
      label:
          '${context.tr('filter_label_prefix')}: '
          '${token.displayKey} ${token.displayValue}. '
          '$hint. ${context.tr('backspace_to_remove')}.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.border),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(token.displayKey.toLowerCase(), style: keyStyle),
                const SizedBox(width: 4),
                Text(token.displayValue, style: valueStyle),
                const SizedBox(width: 2),
                IconButton(
                  tooltip: context.tr('clear_filter'),
                  iconSize: 14,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 22,
                    minWidth: 22,
                  ),
                  onPressed: onRemove,
                  icon: Icon(Icons.close, color: tokens.ink3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
