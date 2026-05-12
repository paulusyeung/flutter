import 'package:flutter/widgets.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Per-key cap on the synchronous `quickValueSuggestions` lookup powering
/// the key-mode picker's cross-key value matches. Mirrors the constant in
/// `client_filter_keys.dart` — kept private here so each filter key file
/// owns its own pacing.
const int _kQuickValueLimitPerKey = 3;

/// `is:active` / `is:archived` / `is:deleted` — multi-valued, default
/// `{active}`. Entity-agnostic: operates on [GenericListViewModel.states]
/// only, so every entity list can register the same instance.
class IsFilterKey extends FilterKey {
  const IsFilterKey();

  @override
  String get id => 'is';

  @override
  Iterable<String> get aliases => const ['status'];

  @override
  String displayLabel(BuildContext context) => context.tr('status');

  @override
  FilterValueType get valueType => FilterValueType.enumeration;

  /// Multi-valued so users can filter to a union like `{archived, deleted}`.
  /// `vm.setStates` accepts an arbitrary `Set<EntityState>` and the
  /// server-side status param is comma-joined.
  @override
  bool get singleValue => false;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      vm.states.length == 1 && vm.states.contains(EntityState.active);

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    // Always emit a chip when a state filter is set. `vm.states` is never
    // empty — the base VM normalises `{}` back to `{active}` — so a status
    // chip is always visible. Matches Sentry, where `is:unresolved` shows
    // as a chip on a fresh load instead of being implicit.
    return [
      for (final s in EntityState.values)
        if (vm.states.contains(s))
          FilterToken(
            keyId: id,
            displayKey: displayLabel(context),
            rawValue: s.serverName,
            displayValue: context.tr(s.labelKey),
          ),
    ];
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final all = [
      for (final s in EntityState.values)
        FilterValueSuggestion(
          rawValue: s.serverName,
          displayLabel: context.tr(s.labelKey),
        ),
    ];
    final filtered = q.isEmpty
        ? all
        : all
              .where(
                (s) =>
                    s.displayLabel.toLowerCase().contains(q) ||
                    s.rawValue.toLowerCase().contains(q),
              )
              .toList();
    return Stream.value(filtered);
  }

  /// Free-text key-mode lookup. Tighter than [watchValueSuggestions]
  /// (`startsWith` not `contains`) because the user hasn't committed to
  /// the Status dimension — a stray substring match like `act` against
  /// `inactive` (hypothetical future state) would be noise, not a clue.
  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <FilterValueSuggestion>[];
    for (final s in EntityState.values) {
      if (out.length >= _kQuickValueLimitPerKey) break;
      final label = context.tr(s.labelKey).toLowerCase();
      if (label.startsWith(q) || s.serverName.startsWith(q)) {
        out.add(
          FilterValueSuggestion(
            rawValue: s.serverName,
            displayLabel: context.tr(s.labelKey),
          ),
        );
      }
    }
    return out;
  }

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final state = _stateOf(rawValue);
    if (state == null) return Future.value();
    // Always union. From `{active}` + Archived → `{active, archived}` (two
    // chips). The user removes individual chips with `×` if they want to
    // narrow. Sentry / Linear style: each click adds, never replaces.
    return vm.setStates({...vm.states, state});
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final state = _stateOf(rawValue);
    if (state == null) return Future.value();
    final next = Set<EntityState>.from(vm.states)..remove(state);
    // Empty set is allowed — both the watch query and the server-side
    // status param treat it as "no restriction" (show all rows). Removing
    // the last chip drops the dimension entirely.
    return vm.setStates(next);
  }

  // `cycleValue` is intentionally NOT overridden — users found the silent
  // chip-tap value change surprising. Tapping the chip falls through to
  // `TokenSearchField._onChipTap`'s "open value picker" branch instead,
  // which lets the user pick the new value intentionally.

  EntityState? _stateOf(String raw) {
    for (final s in EntityState.values) {
      if (s.serverName == raw || s.name == raw) return s;
    }
    return null;
  }
}
