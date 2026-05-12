import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/membership_filter_key.dart';

// ────────────────────────────────────────────────────────────────────
// Server-side behavior of the `/api/v1/clients` filter params, measured
// against `demo.invoiceninja.com` (v2 admin API, May 2026). The docs
// page `https://invoiceninja.github.io/docs/api-reference/get-clients`
// is aspirational on operator syntax — defer to what's measured here.
//
// String fields
//   `name`                 → SQL LIKE %value%. Substring match.
//                            `*` is a literal char, so the doc-example
//                            `name=Bob*` returns 0 rows.
//   `number`, `id_number`  → exact match only.
//   `vat_number`,          → silently ignored. The server returns the
//   `custom_value1..4`       full list regardless of value. Filter chips
//                            apply locally but don't narrow results.
//                            Treat as non-functional pending a server
//                            fix; track separately.
//   `classification`       → not separately probed, assumed silently
//                            ignored. Treat as suspect.
//
// Numeric / date operator fields — **SUFFIX syntax `value:op`**
//   `balance=value:gt`     → ✅ filters by value (gt > lt < gte ≥ lte ≤
//                            eq = ne ≠ all honored). `between` is NOT
//                            recognized (`balance=lo,hi:between` → 0).
//   `balance=op:value`     → ❌ legacy/wrong shape — server falls back
//                            to "any non-zero balance" regardless of
//                            value. Don't write this format.
//   `created_at`,          → silently ignored regardless of operator/
//   `updated_at`             syntax (gt, lt, gte, lte, suffix, prefix —
//                            all return full list). Keys here write the
//                            correct suffix shape so they're ready for
//                            the day the server adds support, but the
//                            chip is currently cosmetic.
// ────────────────────────────────────────────────────────────────────

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
    const NameFilterKey(),
    const BalanceFilterKey(),
    for (var i = 1; i <= 4; i++)
      CustomFieldFilterKey(
        columnIndex: i,
        // Custom-field labels are stored as `Label|preset1,preset2,...` — we
        // only care about the label half for chip / suggestion rendering.
        configuredLabel: _labelOf(customLabels['client$i']),
      ),
    CountryFilterKey(statics: statics),
    IndustryFilterKey(statics: statics),
    SizeFilterKey(statics: statics),
    CurrencyFilterKey(statics: statics),
    LanguageFilterKey(statics: statics),
    const ClassificationFilterKey(),
    const VatFilterKey(),
    const IdNumberFilterKey(),
    const CreatedFilterKey(),
    const UpdatedFilterKey(),
    const GroupFilterKey(),
    const AssignedFilterKey(),
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

  /// Multi-valued so users can filter to a union like `{archived, deleted}`.
  /// `vm.setStates` accepts an arbitrary `Set<EntityState>` and the
  /// server-side `client_status` param is comma-joined.
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
    // `client_status` param treat it as "no restriction" (show all rows).
    // Removing the last chip drops the dimension entirely; the user sees
    // archived + deleted alongside active.
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

/// `custom1:foo` / `custom2:bar` — multi-valued, hidden when the company
/// hasn't configured a label. Suggestions stream from
/// [GenericListViewModel.watchDistinctCustomValues].
///
/// Server status: the `custom_value1..4` query params are silently
/// ignored by the v2 API as of May 2026 — the chip applies locally
/// but the row count is unchanged. Surface stays in place pending a
/// server fix.
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

  // Hidden until the company configures a label for this custom column.
  // A workspace that doesn't use custom fields shouldn't see four
  // placeholder keys cluttering the filter menu — they have nothing to
  // pick. Once a label is configured, the key appears and
  // `watchDistinctCustomValues` populates the suggestion list.
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
    // Don't paint an orphan chip when the company has un-configured this
    // custom column — the chip would show with an empty `displayKey`.
    // Symmetric with `isAvailable` already gating the menu visibility;
    // the chip data is retained in `vm.customFilters` and re-paints if
    // the label is restored.
    if (configuredLabel.isEmpty) return const [];
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
/// for US); the chip renders the country name. Paste-friendly: accepts
/// ISO codes alongside numeric ids.
class CountryFilterKey extends MembershipFilterKey {
  CountryFilterKey({required this.statics});

  final StaticsRepository statics;

  @override
  String get id => 'country';

  @override
  String get serverKey => 'country_id';

  @override
  String displayLabel(BuildContext context) => context.tr('country');

  @override
  String displayValueFor(String rawValue) =>
      statics.country(rawValue)?.name ?? rawValue;

  // Always available in the key menu even before statics finish loading;
  // the value list will repopulate as soon as `statics.countries` arrives.
  // Hiding the key entirely during the first frame after login was making
  // country invisible whenever the user clicked through fast.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

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
    final resolved = _resolveId(rawValue);
    if (resolved == null) return Future.value();
    return unionMembership(vm, serverKey, resolved);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) =>
      removeMembership(vm, serverKey, _resolveId(rawValue) ?? rawValue);

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
class GroupFilterKey extends MembershipFilterKey {
  const GroupFilterKey();

  @override
  String get id => 'group';

  @override
  String get serverKey => 'group_settings_id';

  @override
  String displayLabel(BuildContext context) => context.tr('group');

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;
}

/// `industry:foo` — multi-valued, statics-backed. Raw value is the
/// Invoice Ninja numeric industry id; chip renders the localized name.
class IndustryFilterKey extends MembershipFilterKey {
  IndustryFilterKey({required this.statics});

  final StaticsRepository statics;

  @override
  String get id => 'industry';

  @override
  String get serverKey => 'industry_id';

  @override
  String displayLabel(BuildContext context) => context.tr('industry');

  @override
  String displayValueFor(String rawValue) =>
      statics.industry(rawValue)?.name ?? rawValue;

  // Always discoverable in the key menu, even before statics arrive — the
  // value list repopulates as soon as `statics.industries` is loaded.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final all = statics.industries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final filtered = q.isEmpty
        ? all.take(50)
        : all.where((i) => i.name.toLowerCase().contains(q));
    return Stream.value([
      for (final i in filtered)
        FilterValueSuggestion(rawValue: i.id, displayLabel: i.name),
    ]);
  }
}

/// `size:foo` — multi-valued, statics-backed. Raw value is the numeric
/// size id; chip renders the localized company-size label.
class SizeFilterKey extends MembershipFilterKey {
  SizeFilterKey({required this.statics});

  final StaticsRepository statics;

  @override
  String get id => 'size';

  @override
  String get serverKey => 'size_id';

  @override
  String displayLabel(BuildContext context) => context.tr('size');

  @override
  String displayValueFor(String rawValue) =>
      statics.size(rawValue)?.name ?? rawValue;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final all = statics.sizes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final filtered = q.isEmpty
        ? all.take(50)
        : all.where((s) => s.name.toLowerCase().contains(q));
    return Stream.value([
      for (final s in filtered)
        FilterValueSuggestion(rawValue: s.id, displayLabel: s.name),
    ]);
  }
}

/// `assigned:foo` — stub for the assigned-user filter. We don't have a
/// User entity in the rebuild yet, so the suggestion list is empty and
/// the key opts out of the menu via `isAvailable=false`. Same wiring
/// pattern as `GroupFilterKey` — flip `isAvailable` to true once Users
/// is wired.
class AssignedFilterKey extends MembershipFilterKey {
  const AssignedFilterKey();

  @override
  String get id => 'assigned';

  @override
  String get serverKey => 'assigned_user_id';

  @override
  String displayLabel(BuildContext context) => context.tr('assigned_to');

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;
}

// ────────────────────────────────────────────────────────────────────
// Typed-value keys: the user types text, the key wraps it into a wire
// format (wildcard, comparison operator, date prefix). Single-value;
// typing a new value REPLACES the old (wildcards/operators don't
// compose into a CSV the server would understand). Removal goes
// through `removeValue` on the chip's wire-format `rawValue`.
// ────────────────────────────────────────────────────────────────────

/// `name:tes` → server `name=tes` (implicit SQL LIKE %tes%). The docs
/// claim `Bob*` is the wildcard form, but live probing shows `*` is a
/// literal char on the server — see the file-header comment. Chip
/// renders the truthful form `contains "tes"`.
class NameFilterKey extends FilterKey {
  const NameFilterKey();

  static const String _serverKey = 'name';

  @override
  String get id => 'name';

  @override
  String displayLabel(BuildContext context) => context.tr('name');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('name_filter_hint');

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final wire in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: wire,
          // Strip a trailing `*` left over from an older app version's
          // persisted state so upgraded users don't see `contains "foo*"`.
          // The next `addValue` rewrites the wire format without it.
          displayValue:
              '${context.tr('contains')} '
              '"${wire.endsWith('*') ? wire.substring(0, wire.length - 1) : wire}"',
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
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return Future.value();
    // Server does substring matching natively (LIKE %value%); appending
    // `*` would make the filter look for a literal asterisk and return
    // 0 rows. Single-value: replaces any prior name filter.
    return writeSingleExtraFilter(vm, _serverKey, trimmed);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }
}

/// `balance:1000` → server `balance=1000:gt` (suffix-syntax operator).
/// `balance:1000:lt` → server `balance=1000:lt`. Chip renders as `> 1000`
/// or `< 1000`. The value menu exposes both operators via the picker
/// declared in `supportedOps`.
class BalanceFilterKey extends FilterKey {
  const BalanceFilterKey();

  static const String _serverKey = 'balance';

  @override
  String get id => 'balance';

  @override
  String displayLabel(BuildContext context) => context.tr('balance');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  @override
  List<FilterOp> get supportedOps => const [FilterOp.gt, FilterOp.lt];

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('balance_filter_hint');

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final wire in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: wire,
          displayValue: _displayFor(wire),
        ),
    ];
  }

  /// Renders the chip text for any persisted wire format.
  ///
  /// New suffix form:    `1000:gt` → `> 1000`, `1000:lt` → `< 1000`.
  /// Legacy prefix form: `gt:1000` → `> 1000` (server never actually
  ///                     compared the value with this shape; next
  ///                     `addValue` rewrites the wire correctly).
  String _displayFor(String wire) {
    if (wire.endsWith(':gt')) {
      return '> ${wire.substring(0, wire.length - 3)}';
    }
    if (wire.endsWith(':lt')) {
      return '< ${wire.substring(0, wire.length - 3)}';
    }
    if (wire.startsWith('gt:')) return '> ${wire.substring(3)}';
    if (wire.startsWith('lt:')) return '< ${wire.substring(3)}';
    return wire;
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) => Stream.value(const []);

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final (value, op) = _parseValueWithOp(rawValue);
    if (value.isEmpty) return Future.value();
    // Suffix wire format `value:op`. The PREFIX form `op:value` was the
    // earlier code's shape and is silently ignored by the server (returns
    // any-non-zero-balance regardless of threshold) — see the file-header
    // comment for the server-side findings.
    return writeSingleExtraFilter(vm, _serverKey, '$value:${op.name}');
  }

  /// Accepts any of these user-typed or pre-built forms; all collapse to
  /// the suffix wire `value:op` that the server expects.
  ///
  ///   `1000`       → (`1000`, gt)   — bare number defaults to greater-than
  ///   `1000:gt`    → (`1000`, gt)   — explicit suffix form (wire-shape)
  ///   `1000:lt`    → (`1000`, lt)   — explicit suffix form
  ///   `>1000`      → (`1000`, gt)   — pick-op-first input prefix
  ///   `<1000`      → (`1000`, lt)   — pick-op-first input prefix
  (String, FilterOp) _parseValueWithOp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith(':gt')) {
      return (trimmed.substring(0, trimmed.length - 3).trim(), FilterOp.gt);
    }
    if (trimmed.endsWith(':lt')) {
      return (trimmed.substring(0, trimmed.length - 3).trim(), FilterOp.lt);
    }
    if (trimmed.startsWith('>')) {
      return (trimmed.substring(1).trim(), FilterOp.gt);
    }
    if (trimmed.startsWith('<')) {
      return (trimmed.substring(1).trim(), FilterOp.lt);
    }
    return (trimmed, FilterOp.gt);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }

  /// Reject inputs that parse to an empty value — e.g. picking the `>`
  /// operator (input becomes `balance:>`) and pressing Enter before
  /// typing a number. Without this guard, `addValue('>')` short-circuits
  /// on empty trimmed value and the user sees Enter silently dropped.
  @override
  bool isValidValue(String rawValue) {
    final (value, _) = _parseValueWithOp(rawValue);
    return value.isNotEmpty;
  }
}

/// `created:2026-01-01` → server `created_at=2026-01-01:gt` (after
/// the given date). v1 ships "after" only.
///
/// Server status: the v2 API silently ignores `created_at` filters
/// regardless of operator/syntax (probed against demo.invoiceninja.com,
/// May 2026). The wire format here uses the same correct suffix syntax
/// as `BalanceFilterKey` so the chip is correct for the day the server
/// adds support. Until then, applying this filter has no visible effect
/// on the row count. (TODO: server-side bug.)
class CreatedFilterKey extends FilterKey {
  const CreatedFilterKey();

  static const String _serverKey = 'created_at';

  @override
  String get id => 'created';

  @override
  String displayLabel(BuildContext context) => context.tr('created');

  @override
  FilterValueType get valueType => FilterValueType.date;

  @override
  bool get singleValue => true;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('created_filter_hint');

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final wire in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: wire,
          displayValue: '${context.tr('after')} ${_stripOp(wire)}',
        ),
    ];
  }

  /// Trim either the new suffix form (`2026-01-01:gt`) or the legacy
  /// prefix form (`gt:2026-01-01`) down to the bare date so the chip
  /// reads as "after 2026-01-01" either way.
  static String _stripOp(String wire) {
    if (wire.endsWith(':gt')) return wire.substring(0, wire.length - 3);
    if (wire.endsWith(':lt')) return wire.substring(0, wire.length - 3);
    if (wire.startsWith('gt:')) return wire.substring(3);
    if (wire.startsWith('lt:')) return wire.substring(3);
    return wire;
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) => Stream.value(const []);

  @override
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return Future.value();
    // Suffix wire format `yyyy-MM-dd:gt`. The PREFIX form `gt:yyyy-MM-dd`
    // is the broken shape the older code used — see the file-header
    // comment. Date format follows `yyyy-MM-dd` per
    // lib/utils/formatting.dart conventions.
    return writeSingleExtraFilter(vm, _serverKey, '$trimmed:gt');
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }
}

/// `updated:2026-01-01` → server `updated_at=2026-01-01:gt`. Same
/// shape as [CreatedFilterKey]; same server-ignored caveat applies.
class UpdatedFilterKey extends FilterKey {
  const UpdatedFilterKey();

  static const String _serverKey = 'updated_at';

  @override
  String get id => 'updated';

  @override
  String displayLabel(BuildContext context) => context.tr('updated');

  @override
  FilterValueType get valueType => FilterValueType.date;

  @override
  bool get singleValue => true;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('updated_filter_hint');

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final wire in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: wire,
          displayValue:
              '${context.tr('after')} ${CreatedFilterKey._stripOp(wire)}',
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
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return Future.value();
    // Suffix wire format — see `BalanceFilterKey` for why.
    return writeSingleExtraFilter(vm, _serverKey, '$trimmed:gt');
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }
}

// ────────────────────────────────────────────────────────────────────
// Flat-match membership keys. The server filter param name is the same
// snake_case the v2 API accepts. Each is multi-value (CSV).
//
// Server status (probed against demo.invoiceninja.com, May 2026):
//   - `id_number` → works for exact match only.
//   - `vat_number`, `classification` → silently ignored by the server.
//     The chip applies locally but the list isn't narrowed. Surface
//     stays in place pending a server-side fix; track separately.
// ────────────────────────────────────────────────────────────────────

class VatFilterKey extends MembershipFilterKey {
  const VatFilterKey();

  @override
  String get id => 'vat';

  @override
  String get serverKey => 'vat_number';

  @override
  String displayLabel(BuildContext context) => context.tr('vat_number');

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('vat_filter_hint');
}

class IdNumberFilterKey extends MembershipFilterKey {
  const IdNumberFilterKey();

  @override
  String get id => 'id_number';

  @override
  String get serverKey => 'id_number';

  @override
  String displayLabel(BuildContext context) => context.tr('id_number');

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('id_number_filter_hint');
}

class ClassificationFilterKey extends MembershipFilterKey {
  const ClassificationFilterKey();

  @override
  String get id => 'classification';

  @override
  String get serverKey => 'classification';

  @override
  String displayLabel(BuildContext context) => context.tr('classification');

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('classification_filter_hint');
}

// ────────────────────────────────────────────────────────────────────
// Statics-backed membership keys: same shape as CountryFilterKey but
// pulling from statics.currencies / statics.languages.
// ────────────────────────────────────────────────────────────────────

class CurrencyFilterKey extends MembershipFilterKey {
  CurrencyFilterKey({required this.statics});

  final StaticsRepository statics;

  @override
  String get id => 'currency';

  @override
  String get serverKey => 'currency_id';

  @override
  String displayLabel(BuildContext context) => context.tr('currency');

  @override
  String displayValueFor(String rawValue) =>
      statics.currency(rawValue)?.code ?? rawValue;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final all = statics.currencies.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final filtered = q.isEmpty
        ? all.take(50)
        : all.where(
            (c) =>
                c.code.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q),
          );
    return Stream.value([
      for (final c in filtered)
        FilterValueSuggestion(
          rawValue: c.id,
          displayLabel: c.code,
          secondaryLabel: c.name,
        ),
    ]);
  }
}

class LanguageFilterKey extends MembershipFilterKey {
  LanguageFilterKey({required this.statics});

  final StaticsRepository statics;

  @override
  String get id => 'language';

  @override
  String get serverKey => 'language_id';

  @override
  String displayLabel(BuildContext context) => context.tr('language');

  @override
  String displayValueFor(String rawValue) =>
      statics.language(rawValue)?.name ?? rawValue;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final all = statics.languages.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final filtered = q.isEmpty
        ? all.take(50)
        : all.where((l) => l.name.toLowerCase().contains(q));
    return Stream.value([
      for (final l in filtered)
        FilterValueSuggestion(rawValue: l.id, displayLabel: l.name),
    ]);
  }
}
