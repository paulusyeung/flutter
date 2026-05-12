import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_controller.dart';
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
///
/// [controller] is the shared keyboard-navigation state: the menu publishes
/// each row's action so [TokenSearchField]'s arrow-key handler can drive
/// the highlight + commit Enter.
class FilterSuggestionMenu extends StatelessWidget {
  const FilterSuggestionMenu({
    required this.vm,
    required this.keys,
    required this.parse,
    required this.controller,
    required this.onSelectKey,
    required this.onSelectValue,
    required this.onCommitFreeText,
    this.maxHeight = 320,
    super.key,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> keys;
  final FilterInputParse parse;
  final FilterSuggestionController controller;
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
                controller: controller,
                onSelectKey: onSelectKey,
                onCommitFreeText: onCommitFreeText,
              )
            : _ValueList(
                vm: vm,
                filterKey: parse.matchedKey!,
                query: parse.query,
                controller: controller,
                onSelectValue: onSelectValue,
              ),
      ),
    );
  }
}

/// Schedule a row-publish on the next frame. Calling [publishRows]
/// synchronously during build is unsafe because it fires `notifyListeners`
/// which would re-trigger any widgets listening to the controller mid-build.
void _scheduleRowPublish(
  FilterSuggestionController controller,
  List<VoidCallback> actions,
) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    controller.publishRows(actions);
  });
}

class _KeyList extends StatelessWidget {
  const _KeyList({
    required this.vm,
    required this.keys,
    required this.query,
    required this.controller,
    required this.onSelectKey,
    required this.onCommitFreeText,
  });

  final GenericListViewModel<dynamic> vm;
  final List<FilterKey> keys;
  final String query;
  final FilterSuggestionController controller;
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

    // Build the rows and the parallel action list in display order. The
    // action list is what the field's keyboard handler invokes on Enter.
    final rows = <Widget>[];
    final actions = <VoidCallback>[];

    if (query.isNotEmpty) {
      final idx = actions.length;
      actions.add(() => onCommitFreeText(query));
      rows.add(
        _Highlightable(
          controller: controller,
          index: idx,
          child: _SearchForRow(query: query, onTap: actions[idx]),
        ),
      );
    }
    if (query.isNotEmpty && filtered.isNotEmpty) {
      rows.add(
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
      );
    }
    for (final k in filtered) {
      final idx = actions.length;
      actions.add(() => onSelectKey(k));
      rows.add(
        _Highlightable(
          controller: controller,
          index: idx,
          child: _KeyRow(filterKey: k, onTap: actions[idx]),
        ),
      );
    }
    if (filtered.isEmpty && query.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr('no_filters_available'),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
          ),
        ),
      );
    }

    _scheduleRowPublish(controller, actions);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: rows,
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
    // GestureDetector + MouseRegion instead of InkWell so the tap recognizer
    // doesn't lose the gesture arena to the surrounding ListView's scroll
    // recognizer on macOS (sub-pixel mouse motion between down and up was
    // canceling clicks even though the hover state worked). Keyboard Enter
    // routes through `FilterSuggestionController.commit()` directly and
    // never relied on this widget's recognizer.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
    // See `_SearchForRow` for the GestureDetector rationale.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  filterKey.displayLabel(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink,
                  ),
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
    required this.controller,
    required this.onSelectValue,
  });

  final GenericListViewModel<dynamic> vm;
  final FilterKey filterKey;
  final String query;
  final FilterSuggestionController controller;
  final void Function(FilterKey key, FilterValueSuggestion value) onSelectValue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    // Snapshot of which raw values are currently applied for this key.
    // Drives the leading check icon and the toggle (vs. add) decision per
    // row. Computed once per build so we don't iterate tokens N times.
    final applied = <String>{
      for (final t in filterKey.tokensFrom(vm, context)) t.rawValue,
    };
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
                _scheduleRowPublish(controller, const []);
                // Typed-value keys (name, balance, created, …) opt-in to
                // a key-specific hint via `hintForValueMode` — falls back
                // to the generic "No matches" copy for pick-list keys.
                final hint =
                    filterKey.hintForValueMode(context) ??
                    context.tr('no_values_match');
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink3,
                    ),
                  ),
                );
              }
              // Every value click funnels through `onSelectValue` —
              // the field (or the entry sheet) is the source of truth
              // for the add/remove dispatch + dismiss decision. The
              // menu just renders rows; the ✓ icon below shows current
              // applied state for the user's reference.
              final actions = [
                for (final v in values) () => onSelectValue(filterKey, v),
              ];
              _scheduleRowPublish(controller, actions);
              return ListView.builder(
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, i) {
                  final v = values[i];
                  final isApplied = applied.contains(v.rawValue);
                  return _Highlightable(
                    controller: controller,
                    index: i,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        // See `_SearchForRow` for the rationale.
                        behavior: HitTestBehavior.opaque,
                        onTap: actions[i],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Fixed-width leading slot keeps row labels
                              // aligned regardless of which rows are applied.
                              SizedBox(
                                width: 20,
                                child: isApplied
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: tokens.accent,
                                      )
                                    : null,
                              ),
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

/// Wraps a row in a tint when the controller's selected index equals
/// [index]. Listening only to the controller keeps the row rebuild cheap
/// (no full menu rebuild on highlight changes).
class _Highlightable extends StatelessWidget {
  const _Highlightable({
    required this.controller,
    required this.index,
    required this.child,
  });

  final FilterSuggestionController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.selectedIndex == index;
        return Container(
          color: selected ? tokens.surfaceAlt : Colors.transparent,
          child: child,
        );
      },
    );
  }
}
