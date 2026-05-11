import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Inline chip rendering one [FilterToken] inside the token search field.
///
/// Visual: `<key>` `<value>` `×` — key muted, value bold, close button
/// trailing. Matches the Sentry screenshot.
///
/// The chip body itself is inert: the only interactive element is the
/// trailing `×` button which fires [onRemove]. To change a chip's value
/// the user removes it and re-adds via the search field's autocomplete
/// (`FilterSuggestionMenu`). Making the body inert avoided two bad UX
/// states the codebase went through:
///   1. tap-to-cycle silently changing the chip's value, and
///   2. tap-to-open-popover hijacking the search field into value mode
///      when the user expected the full key picker for adding a new
///      filter.
///
/// Screen readers announce the chip as static text plus a separate
/// "Remove filter" button — no "tap to edit" misdirection.
class FilterTokenChip extends StatelessWidget {
  const FilterTokenChip({
    required this.token,
    required this.onRemove,
    super.key,
  });

  final FilterToken token;
  final VoidCallback onRemove;

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

    return Semantics(
      // The chip itself isn't a button — the only interactive element is
      // the trailing × IconButton (already a separate Semantics node).
      // Announce the chip as text so screen readers describe the filter
      // and the user can navigate to the close button by itself.
      label:
          '${context.tr('filter_label_prefix')}: '
          '${token.displayKey} ${token.displayValue}',
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
              constraints: const BoxConstraints(minHeight: 22, minWidth: 22),
              onPressed: onRemove,
              icon: Icon(Icons.close, color: tokens.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
