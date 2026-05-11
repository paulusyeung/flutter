import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Build the filter keys exposed in the clients list's search field. The
/// list is the source of truth for which `key:value` tokens autocomplete
/// against this entity — adding a new dimension is one new subclass + one
/// `..add(...)` line below.
///
/// [company] is the current workspace's company snapshot. Used to resolve
/// the configured custom-field labels (`client1: "Region"`). May be null
/// during the first frame after login while the company is still loading;
/// `CustomFieldFilterKey` falls back to the generic `Custom :index` label.
///
/// [statics] is the shared statics cache — `CountryFilterKey` reads its
/// suggestion list from `statics.countries`.
List<FilterKey> buildClientFilterKeys({
  required Company? company,
  required StaticsRepository statics,
}) {
  final customLabels = company?.customFields ?? const <String, String>{};
  return <FilterKey>[
    const IsFilterKey(),
    for (var i = 1; i <= 4; i++)
      CustomFieldFilterKey(
        columnIndex: i,
        // Custom-field labels are stored as `Label|preset1,preset2,...` — we
        // only care about the label half for chip / suggestion rendering.
        configuredLabel: _labelOf(customLabels['client$i']),
      ),
    CountryFilterKey(statics: statics),
    const GroupFilterKey(),
  ];
}

String _labelOf(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final pipe = raw.indexOf('|');
  return pipe == -1 ? raw : raw.substring(0, pipe);
}

/// `is:active` / `is:archived` / `is:deleted` — single-valued, cycle on tap.
///
/// Backed by [GenericListViewModel.states]; default set `{active}`. Renders
/// no chip at the default so a fresh load is clean.
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

  @override
  bool get singleValue => true;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      vm.states.length == 1 && vm.states.contains(EntityState.active);

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    if (isAtDefault(vm)) return const [];
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

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final state = _stateOf(rawValue);
    if (state == null) return Future.value();
    // Single-valued: replace, don't accumulate.
    return vm.setStates({state});
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final state = _stateOf(rawValue);
    if (state == null) return Future.value();
    final next = Set<EntityState>.from(vm.states)..remove(state);
    // Removing the only chip snaps back to the default `{active}` — the
    // chip disappears via `isAtDefault`.
    return vm.setStates(next.isEmpty ? const {EntityState.active} : next);
  }

  @override
  Future<void> Function()? cycleValue(GenericListViewModel<dynamic> vm) {
    return () {
      // active → archived → deleted → active (back to default, chip hides).
      const order = [
        EntityState.active,
        EntityState.archived,
        EntityState.deleted,
      ];
      final current = vm.states.length == 1 ? vm.states.first : order.first;
      final next = order[(order.indexOf(current) + 1) % order.length];
      return vm.setStates({next});
    };
  }

  EntityState? _stateOf(String raw) {
    for (final s in EntityState.values) {
      if (s.serverName == raw || s.name == raw) return s;
    }
    return null;
  }
}

/// `custom1:foo` / `custom2:bar` — multi-valued, hidden when the company
/// hasn't configured a label. Suggestions stream from
/// [GenericListViewModel.watchDistinctCustomValues].
class CustomFieldFilterKey extends FilterKey {
  const CustomFieldFilterKey({
    required this.columnIndex,
    required this.configuredLabel,
  }) : assert(columnIndex >= 1 && columnIndex <= 4);

  final int columnIndex;

  /// Label the company configured for this column (`Region`, `Project`,
  /// …). Empty when unset — the key is then hidden from autocomplete.
  final String configuredLabel;

  @override
  String get id => 'custom$columnIndex';

  @override
  String displayLabel(BuildContext context) {
    if (configuredLabel.isNotEmpty) return configuredLabel;
    return context.tr('custom_column_n', {'index': columnIndex.toString()});
  }

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) =>
      configuredLabel.isNotEmpty;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.customFilters[columnIndex] ?? const <String>{}).isEmpty;

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.customFilters[columnIndex] ?? const <String>{};
    return [
      for (final v in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: v,
          displayValue: v,
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
    return vm.watchDistinctCustomValues(columnIndex).map((values) {
      final filtered = q.isEmpty
          ? values
          : values.where((v) => v.toLowerCase().contains(q)).toList();
      return [
        for (final v in filtered)
          FilterValueSuggestion(rawValue: v, displayLabel: v),
      ];
    });
  }

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final next = Set<String>.from(vm.customFilters[columnIndex] ?? const {})
      ..add(rawValue);
    return vm.setCustomFilter(columnIndex: columnIndex, values: next);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final next = Set<String>.from(vm.customFilters[columnIndex] ?? const {})
      ..remove(rawValue);
    return vm.setCustomFilter(columnIndex: columnIndex, values: next);
  }
}

/// `country:US` — multi-valued, suggestions come from the cached statics
/// bundle. Raw value is the Invoice Ninja numeric country id (e.g. `"840"`
/// for US); the chip renders the country name.
class CountryFilterKey extends FilterKey {
  CountryFilterKey({required this.statics});

  final StaticsRepository statics;

  static const String _serverKey = 'country_id';

  @override
  String get id => 'country';

  @override
  String displayLabel(BuildContext context) => context.tr('country');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) =>
      statics.countries.isNotEmpty;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final ids = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final id in ids)
        FilterToken(
          keyId: this.id,
          displayKey: displayLabel(context),
          rawValue: id,
          displayValue: statics.country(id)?.name ?? id,
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
    final all = statics.countries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final filtered = q.isEmpty
        ? all.take(50)
        : all.where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.iso2.toLowerCase() == q ||
                c.iso3.toLowerCase() == q,
          );
    return Stream.value([
      for (final c in filtered)
        FilterValueSuggestion(
          rawValue: c.id,
          displayLabel: c.name,
          secondaryLabel: c.iso2,
        ),
    ]);
  }

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    // Accept both the numeric id and the ISO code (paste-friendly).
    final resolved = _resolveId(rawValue);
    if (resolved == null) return Future.value();
    final next = Set<String>.from(vm.extraFilters[_serverKey] ?? const {})
      ..add(resolved);
    return vm.setExtraFilter(serverKey: _serverKey, values: next);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final resolved = _resolveId(rawValue) ?? rawValue;
    final next = Set<String>.from(vm.extraFilters[_serverKey] ?? const {})
      ..remove(resolved);
    return vm.setExtraFilter(serverKey: _serverKey, values: next);
  }

  String? _resolveId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (statics.country(t) != null) return t;
    final upper = t.toUpperCase();
    for (final c in statics.countries.values) {
      if (c.iso2 == upper || c.iso3 == upper) return c.id;
    }
    return null;
  }
}

/// `group:foo` — stub key. The Groups entity hasn't been registered in the
/// rebuild yet, so the suggestion list is always empty and the key opts out
/// of [isAvailable]. The wiring stays so the registry exercises a key with
/// no backing static data, and so a future PR only has to flip `isAvailable`
/// once the Groups repo lands.
class GroupFilterKey extends FilterKey {
  const GroupFilterKey();

  static const String _serverKey = 'group_settings_id';

  @override
  String get id => 'group';

  @override
  String displayLabel(BuildContext context) => context.tr('group');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final ids = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final id in ids)
        FilterToken(
          keyId: this.id,
          displayKey: displayLabel(context),
          rawValue: id,
          displayValue: id,
        ),
    ];
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) => Stream.value(const []);

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final next = Set<String>.from(vm.extraFilters[_serverKey] ?? const {})
      ..add(rawValue);
    return vm.setExtraFilter(serverKey: _serverKey, values: next);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final next = Set<String>.from(vm.extraFilters[_serverKey] ?? const {})
      ..remove(rawValue);
    return vm.setExtraFilter(serverKey: _serverKey, values: next);
  }
}
