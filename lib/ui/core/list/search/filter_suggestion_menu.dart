import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Parsed view of the current input text.
///
///   ""               -> key mode, prefix=null, query=""
///   "acme"           -> key mode, prefix=null, query="acme"
///   "is:"            -> value mode, prefix=IsFilterKey, query=""
///   "is:arch"        -> value mode, prefix=IsFilterKey, query="arch"
///   "unmatched:foo"  -> key mode (the prefix doesn't match a known key —
///                       fall back to free-text mode so the user sees the
///                       "Search for 'unmatched:foo'" row).
class FilterInputParse {
  const FilterInputParse({this.matchedKey, required this.query});

  /// When non-null, the menu shows value suggestions for this key. When
  /// null, the menu shows the key picker (with [query] as the free-text
  /// filter / "Search for …" target).
  final FilterKey? matchedKey;
  final String query;

  static FilterInputParse of(String input, List<FilterKey> keys) {
    final colon = input.indexOf(':');
    if (colon == -1) return FilterInputParse(query: input);
    final prefix = input.substring(0, colon).trim().toLowerCase();
    final tail = input.substring(colon + 1);
    for (final k in keys) {
      if (k.id == prefix || k.aliases.contains(prefix)) {
        return FilterInputParse(matchedKey: k, query: tail);
      }
    }
    return FilterInputParse(query: input);
  }
}

/// Overlay menu attached to the token search field. Two modes:
///   * **Key mode** (`parse.matchedKey == null`): renders a flat list of
///     every available [FilterKey], plus a "Search for `query`" row when
///     [query] is non-empty so free-text submission is an explicit choice.
///   * **Value mode** (`parse.matchedKey != null`): streams value
///     suggestions from the matched key.
///
/// Selection routes through the three callbacks rather than mutating the VM
/// directly — keeps this widget free of side effects so it can be reused by
/// the wide-mode overlay and the narrow-mode full-screen sheet.
class FilterSuggestionMenu extends StatelessWidget {
  const FilterSuggestionMenu({
    required this.vm,
    required this.keys,
    required this.parse,
    required this.onSelectKey,
    required this.onSelectValue,
    required this.onCommitFreeText,
    this.maxHeight = 320,
    super.key,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> keys;
  final FilterInputParse parse;
  final ValueChanged<FilterKey> onSelectKey;
  final void Function(FilterKey key, FilterValueSuggestion value) onSelectValue;
  final ValueChanged<String> onCommitFreeText;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(InRadii.r2),
      color: tokens.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 420),
        child: parse.matchedKey == null
            ? _KeyList(
                vm: vm,
                keys: keys,
                query: parse.query.trim(),
                onSelectKey: onSelectKey,
                onCommitFreeText: onCommitFreeText,
              )
            : _ValueList(
                vm: vm,
                filterKey: parse.matchedKey!,
                query: parse.query,
                onSelectValue: onSelectValue,
              ),
      ),
    );
  }
}

class _KeyList extends StatelessWidget {
  const _KeyList({
    required this.vm,
    required this.keys,
    required this.query,
    required this.onSelectKey,
    required this.onCommitFreeText,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> keys;
  final String query;
  final ValueChanged<FilterKey> onSelectKey;
  final ValueChanged<String> onCommitFreeText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final q = query.toLowerCase();
    final available = keys.where((k) => k.isAvailable(vm)).toList();
    final filtered = q.isEmpty
        ? available
        : available.where((k) {
            // Match by id, alias, or localized display label so a user
            // typing "stat" finds `status` (alias of `is`).
            final label = k.displayLabel(context).toLowerCase();
            return k.id.contains(q) ||
                label.contains(q) ||
                k.aliases.any((a) => a.contains(q));
          }).toList();

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        if (query.isNotEmpty)
          _SearchForRow(query: query, onTap: () => onCommitFreeText(query)),
        if (query.isNotEmpty && filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              context.tr('filters_section'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.ink3,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (final k in filtered)
          _KeyRow(filterKey: k, onTap: () => onSelectKey(k)),
        if (filtered.isEmpty && query.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.tr('no_filters_available'),
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
            ),
          ),
      ],
    );
  }
}

class _SearchForRow extends StatelessWidget {
  const _SearchForRow({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: tokens.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                  ),
                  children: [
                    TextSpan(text: '${context.tr('search_for')} '),
                    TextSpan(
                      text: '"$query"',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '↵',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.filterKey, required this.onTap});

  final FilterKey filterKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                filterKey.displayLabel(context),
                style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
              ),
            ),
            Text(
              _typeLabel(context, filterKey.valueType),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.ink3,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context, FilterValueType type) =>
      switch (type) {
        FilterValueType.enumeration => context.tr('filter_type_enum'),
        FilterValueType.string => context.tr('filter_type_string'),
        FilterValueType.date => context.tr('filter_type_date'),
      };
}

class _ValueList extends StatelessWidget {
  const _ValueList({
    required this.vm,
    required this.filterKey,
    required this.query,
    required this.onSelectValue,
  });

  final GenericListViewModel<dynamic> vm;
  final FilterKey filterKey;
  final String query;
  final void Function(FilterKey key, FilterValueSuggestion value) onSelectValue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            filterKey.displayLabel(context),
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.ink3,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: StreamBuilder<List<FilterValueSuggestion>>(
            stream: filterKey.watchValueSuggestions(vm, context, query),
            builder: (context, snapshot) {
              final values = snapshot.data ?? const <FilterValueSuggestion>[];
              if (values.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr('no_values_match'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, i) {
                  final v = values[i];
                  return InkWell(
                    onTap: () => onSelectValue(filterKey, v),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              v.displayLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.ink,
                              ),
                            ),
                          ),
                          if (v.secondaryLabel != null)
                            Text(
                              v.secondaryLabel!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.ink3,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
