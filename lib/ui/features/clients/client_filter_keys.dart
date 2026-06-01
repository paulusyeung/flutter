import 'dart:async';

import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/custom_field_filter_key.dart';
import 'package:admin/ui/core/list/search/date_range_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/membership_filter_key.dart';

// `IsFilterKey` is re-exported via `filter_keys_common.dart` (above) so
// every entity list (clients, products, …) can register the same instance
// and callers reaching for it via the clients filter-keys file keep
// working without import churn.
export 'package:admin/ui/core/list/search/filter_keys_common.dart'
    show IsFilterKey;

// `CustomFieldFilterKey` moved to core so every entity list can register
// it. Re-exported so existing importers of this file (incl. tests) keep
// resolving the symbol unchanged.
export 'package:admin/ui/core/list/search/custom_field_filter_key.dart'
    show CustomFieldFilterKey;

// ────────────────────────────────────────────────────────────────────
// Server-side behavior of the `/api/v1/clients` filter params, as of the
// v5 filter PR (`invoiceninja/invoiceninja#11970`). Earlier "silently
// ignored" notes were measured against the pre-v5 demo API (May 2026) and
// no longer apply — the PR added column-backed support for most of them.
// The docs page `https://invoiceninja.github.io/docs/api-reference/
// get-clients` is aspirational — defer to what's described here.
//
// Honored (param narrows the result set; FilterKey is available):
//   `filter`               → cross-field substring (case-insensitive)
//                            across `name`, `number`, and the primary
//                            contact's email. This is the param the
//                            plain-text search box already targets via
//                            `vm.search` → `repo.ensurePageLoaded(search:)`
//                            → `filter=` in `api_client.dart`. No
//                            dedicated FilterKey — duplicating it as a
//                            dropdown entry would mirror the free-text
//                            path 1:1.
//   `name`                 → SQL LIKE %value%. Substring match.
//                            `*` is a literal char, so the doc-example
//                            `name=Bob*` returns 0 rows. `NameFilterKey`.
//   `number`               → **exact match** (case-insensitive server
//                            side). No substring, no wildcards.
//                            `NumberFilterKey` is **available** as an
//                            exact-match key — the chip renders
//                            `= "value"` so the shape is honest, and the
//                            local watch mirrors it with an exact
//                            `clients.number` predicate (note: the local
//                            predicate is case-sensitive — a known minor
//                            divergence from the server collation).
//   `id_number`            → **exact match** (substring does NOT work —
//                            only full-string equality returns rows).
//                            `IdNumberFilterKey` is **available**:
//                            free-text `filter=` does NOT cover id_number
//                            (name + number + contact email only), so
//                            this is the sole way to filter by tax/ID.
//                            Multi-select is local-only (server `id_number`
//                            is exact-single — a 2+ value CSV matches
//                            nothing server-side).
//   `country_id`, `industry_id`, `size_id`, `classification`,
//   `vat_number`, `group_settings_id`, `assigned_user_ids`,
//   `custom_value1..4`
//                          → honored as of the v5 PR. CSV `whereIn` on
//                            ids; `vat_number` / `custom_value*` are
//                            substring LIKE. Each is mirrored locally on
//                            the denormalized `clients` v55 columns (see
//                            `clients_table.dart` / `client_dao.dart` /
//                            `billing_extra_filters.dart`) so the watch
//                            narrows in lockstep with the server fetch.
//                            Corresponding FilterKeys are **available**
//                            (`custom_value*` only when the slot label
//                            is configured).
//   `balance=value:gt`     → filters by value (gt > lt < gte ≥ lte ≤
//                            eq = ne ≠ all honored). `between` is NOT
//                            recognized (`balance=lo,hi:between` → 0).
//                            The PREFIX form `op:value` is the wrong
//                            shape — server falls back to "any non-zero
//                            balance" regardless of value. Don't write it.
//   `created_at`,          → honored as a PLAIN value (server applies
//   `updated_at`             `>=`; an operator suffix like `:gt` is
//                            swallowed). Plus `updated_between` (closed
//                            window on `updated_at`) and the unified
//                            3-part `date_range`. `Created`/`Updated`
//                            FilterKeys available. Lifecycle is the
//                            `status` param (handled by
//                            `stateQueryParams`), not `client_status`.
//
// Still silently ignored — these FilterKeys opt out of the suggestion
// menu via `isAvailable => false`:
//   `email`                → exact match on the full address
//                            (case-insensitive; `email=zzemlak` → 0,
//                            `email=zzemlak@example.net` → 1).
//                            `EmailFilterKey` is wired but hidden —
//                            free-text `filter=` already substring-
//                            matches the contact email.
//   `currency_id`,         → live in company/client *settings JSON*, not
//   `language_id`            queryable columns, so the server can't
//                            filter on them. `Currency`/`Language`
//                            FilterKeys stay hidden.
//   no-effect params:      `state`, `city`, `postal_code`, `phone`,
//                            `archived`, `client_status` — no dedicated
//                            FilterKey.
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
  required GroupSettingRepository groups,
  required UserRepository users,
  required String companyId,
  String? Function(String id)? nameForGroupId,
  String? Function(String id)? nameForAssignedId,
}) {
  return <FilterKey>[
    const IsFilterKey(),
    const NameFilterKey(),
    const EmailFilterKey(),
    const NumberFilterKey(),
    const BalanceFilterKey(),
    for (var i = 1; i <= 4; i++)
      CustomFieldFilterKey(
        columnIndex: i,
        // Reads `company.customFields['client$i']` and parses the
        // `Label|presets` shape (see `CompanyCustomFields.customFieldLabel`).
        // Empty when the slot is unconfigured — `CustomFieldFilterKey` then
        // self-hides via `isAvailable`.
        configuredLabel: company?.customFieldLabel('client$i') ?? '',
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
    const UpdatedRangeFilterKey(),
    GroupFilterKey(
      groups: groups,
      companyId: companyId,
      nameForGroupId: nameForGroupId,
    ),
    AssignedFilterKey(
      users: users,
      companyId: companyId,
      nameForAssignedId: nameForAssignedId,
    ),
  ];
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
  IconData get icon => Icons.public;

  @override
  String displayValueFor(String rawValue) =>
      statics.country(rawValue)?.name ?? rawValue;

  // Server supports `country_id` (CSV whereIn) as of the v5 filter PR.
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

  /// Free-text key-mode lookup. `startsWith` on the country name, plus
  /// exact (case-insensitive) match on `iso2`/`iso3` so the user typing
  /// `us` lands on United States even though "United" is the name's
  /// prefix. Sorted alphabetically inside the per-key cap so popular
  /// short prefixes (`un` → United …) emit a stable order.
  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches =
        statics.countries.values
            .where(
              (c) =>
                  c.name.toLowerCase().startsWith(q) ||
                  c.iso2.toLowerCase() == q ||
                  c.iso3.toLowerCase() == q,
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return [
      for (final c in matches.take(kQuickValueLimitPerKey))
        FilterValueSuggestion(
          rawValue: c.id,
          displayLabel: c.name,
          secondaryLabel: c.iso2,
        ),
    ];
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

/// `group:foo` — multi-valued, repo-backed (bundled `group_settings`).
/// Server supports CSV `group_settings_id` as of the v5 filter PR; the
/// local `ClientDao` mirrors it on the denormalized column. Mirrors the
/// `ExpenseCategoryFilterKey` repo-backed pattern.
class GroupFilterKey extends MembershipFilterKey {
  GroupFilterKey({
    required this.groups,
    required this.companyId,
    this.nameForGroupId,
  });

  final GroupSettingRepository groups;
  final String companyId;

  /// Synchronous `group_settings_id → name` lookup supplied by the
  /// wrapper (mirrors [ClientFilterKey.nameForClientId]). A fresh key
  /// instance is built on every rebuild, so resolving the chip name
  /// from a per-instance stream cache showed the raw id until a later
  /// rebuild; the wrapper-owned map is already populated. Null → id.
  final String? Function(String id)? nameForGroupId;

  @override
  String get id => 'group';

  @override
  String get serverKey => 'group_settings_id';

  @override
  bool get checkboxMultiSelect => true;

  @override
  String displayLabel(BuildContext context) => context.tr('group');

  @override
  IconData get icon => Icons.workspaces_outline;

  @override
  String displayValueFor(String rawValue) {
    final resolved = nameForGroupId?.call(rawValue);
    return (resolved != null && resolved.isNotEmpty) ? resolved : rawValue;
  }

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return groups.watchAll(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((g) => g.name.toLowerCase().contains(q));
      return [
        for (final g in filtered)
          FilterValueSuggestion(
            rawValue: g.id,
            displayLabel: g.name.isEmpty ? g.id : g.name,
          ),
      ];
    });
  }
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
  IconData get icon => Icons.business_outlined;

  @override
  String displayValueFor(String rawValue) =>
      statics.industry(rawValue)?.name ?? rawValue;

  // Server supports `industry_id` (CSV whereIn) as of the v5 filter PR.
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

  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches =
        statics.industries.values
            .where((i) => i.name.toLowerCase().startsWith(q))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return [
      for (final i in matches.take(kQuickValueLimitPerKey))
        FilterValueSuggestion(rawValue: i.id, displayLabel: i.name),
    ];
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

  // Server supports `size_id` (CSV whereIn) as of the v5 filter PR.
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

  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches =
        statics.sizes.values
            .where((s) => s.name.toLowerCase().startsWith(q))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return [
      for (final s in matches.take(kQuickValueLimitPerKey))
        FilterValueSuggestion(rawValue: s.id, displayLabel: s.name),
    ];
  }
}

/// `assigned:foo` — multi-valued, repo-backed (users arrive via
/// `/refresh`). `serverKey` is the **plural** `assigned_user_ids` — the
/// backend's column-guarded CSV base method (and what the local
/// `ClientRepository` parser reads). Same repo-backed pattern as
/// `GroupFilterKey`.
class AssignedFilterKey extends MembershipFilterKey {
  AssignedFilterKey({
    required this.users,
    required this.companyId,
    this.nameForAssignedId,
  });

  final UserRepository users;
  final String companyId;

  /// Synchronous `assigned_user_ids → display name` lookup supplied by
  /// the wrapper — same rationale as [GroupFilterKey.nameForGroupId]
  /// (per-rebuild key instances must not depend on a private stream
  /// cache for the chip name). Null → id.
  final String? Function(String id)? nameForAssignedId;

  @override
  String get id => 'assigned';

  @override
  String get serverKey => 'assigned_user_ids';

  @override
  bool get checkboxMultiSelect => true;

  @override
  String displayLabel(BuildContext context) => context.tr('assigned_to');

  @override
  IconData get icon => Icons.person_outline;

  @override
  String displayValueFor(String rawValue) {
    final resolved = nameForAssignedId?.call(rawValue);
    return (resolved != null && resolved.isNotEmpty) ? resolved : rawValue;
  }

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return users.watchAllForPicker(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((u) => u.displayName.toLowerCase().contains(q));
      return [
        for (final u in filtered)
          FilterValueSuggestion(
            rawValue: u.id,
            displayLabel: u.displayName.isEmpty ? u.id : u.displayName,
          ),
      ];
    });
  }
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
  IconData get icon => Icons.badge_outlined;

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

  // Same trailing-`*` strip as the chip's displayValue — see the
  // upgrade note above. Editing a `foo*` legacy value pre-fills `foo`;
  // re-submit then rewrites the wire format without the asterisk.
  @override
  String? editableValueText(String rawValue) => rawValue.endsWith('*')
      ? rawValue.substring(0, rawValue.length - 1)
      : rawValue;
}

/// `email:foo@bar.com` → server `email=foo@bar.com`. Server's `email=`
/// is **exact match on the full address** (case-insensitive); it does
/// NOT substring-match — `email=foo` returns 0 rows even when there's
/// a contact `foo@bar.com`. Free-text typing (`vm.search` → `filter=`)
/// already substring-matches contact emails cross-field, which is what
/// users actually want, so this key is hidden from the dropdown.
class EmailFilterKey extends FilterKey {
  const EmailFilterKey();

  static const String _serverKey = 'email';

  @override
  String get id => 'email';

  @override
  String displayLabel(BuildContext context) => context.tr('email');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  // Server `email=` is full-address exact match only — useless UX for
  // free-typed values. Free-text `filter=` already substring-matches
  // contact emails. Flip back to `true` if the server ever adds
  // substring support to the dedicated param.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('email_filter_hint');

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
          displayValue: '${context.tr('contains')} "$wire"',
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
    return writeSingleExtraFilter(vm, _serverKey, trimmed);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }

  @override
  String? editableValueText(String rawValue) => rawValue;
}

/// `number:1234` → server `number=1234` (exact match — no substring,
/// no wildcards). Chip renders as `= "1234"` to be honest about the
/// match shape. Hidden from the dropdown because users typing partial
/// numbers expect substring; free-text `filter=` already covers that
/// (substring on name + number + contact email).
class NumberFilterKey extends FilterKey {
  const NumberFilterKey();

  static const String _serverKey = 'number';

  @override
  String get id => 'number';

  @override
  String displayLabel(BuildContext context) => context.tr('number');

  @override
  IconData get icon => Icons.tag;

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  // Server `number=` is an exact match (no substring / wildcards). The
  // chip renders `= "value"` so the match shape is honest, and the local
  // watch mirrors it with an exact predicate — so the key stays available.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('number_filter_hint');

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
          displayValue: '= "$wire"',
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
    return writeSingleExtraFilter(vm, _serverKey, trimmed);
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) {
    return writeSingleExtraFilter(vm, _serverKey, null);
  }

  @override
  String? editableValueText(String rawValue) => rawValue;
}

/// `balance:1000` → server `balance=1000:gt` (suffix-syntax operator).
/// `balance:1000:lt` → server `balance=1000:lt`. Chip renders as `> 1000`
/// or `< 1000`. The value menu exposes both operators via the picker
/// declared in `supportedOps`.
/// `balance` → server `balance=gt:5000` (canonical prefix). Chip shows
/// `> 5000` / `≥ 5000` / …; the value menu exposes all five operators.
/// Wire encode/decode (incl. legacy suffix self-heal) lives in
/// [ComparableFilterKey].
class BalanceFilterKey extends FilterKey with ComparableFilterKey {
  const BalanceFilterKey();

  @override
  String get id => 'balance';

  @override
  String get serverKey => 'balance';

  @override
  String displayLabel(BuildContext context) => context.tr('balance');

  @override
  IconData get icon => Icons.attach_money;

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  List<FilterOp> get supportedOps => const [
    FilterOp.gt,
    FilterOp.gte,
    FilterOp.lt,
    FilterOp.lte,
    FilterOp.eq,
  ];

  /// A bare `balance:1000` means "greater than 1000" (historical default).
  @override
  FilterOp get defaultOp => FilterOp.gt;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('balance_filter_hint');
}

/// `created` → server `created_at=gte:2026-01-01` (canonical prefix;
/// `whereDate` calendar-day semantics server-side). A bare/legacy plain
/// `created_at=<date>` still means "on or after" ([defaultOp] = [gte]),
/// preserving the historical server `>=`.
class CreatedFilterKey extends FilterKey with ComparableFilterKey {
  const CreatedFilterKey();

  @override
  String get id => 'created';

  @override
  String get serverKey => 'created_at';

  @override
  String displayLabel(BuildContext context) => context.tr('created');

  @override
  FilterValueType get valueType => FilterValueType.date;

  @override
  List<FilterOp> get supportedOps => const [
    FilterOp.gt,
    FilterOp.gte,
    FilterOp.lt,
    FilterOp.lte,
    FilterOp.eq,
  ];

  @override
  FilterOp get defaultOp => FilterOp.gte;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('created_filter_hint');
}

/// `updated` → server `updated_at=gte:2026-01-01`. Same shape as
/// [CreatedFilterKey].
class UpdatedFilterKey extends FilterKey with ComparableFilterKey {
  const UpdatedFilterKey();

  @override
  String get id => 'updated';

  @override
  String get serverKey => 'updated_at';

  @override
  String displayLabel(BuildContext context) => context.tr('updated');

  @override
  FilterValueType get valueType => FilterValueType.date;

  @override
  List<FilterOp> get supportedOps => const [
    FilterOp.gt,
    FilterOp.gte,
    FilterOp.lt,
    FilterOp.lte,
    FilterOp.eq,
  ];

  @override
  FilterOp get defaultOp => FilterOp.gte;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('updated_filter_hint');
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
  IconData get icon => Icons.receipt_long_outlined;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('vat_filter_hint');

  // Server supports `vat_number` (substring LIKE) as of the v5 filter PR.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;
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
  IconData get icon => Icons.pin_outlined;

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
  IconData get icon => Icons.category_outlined;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('classification_filter_hint');

  // Server supports `classification` (CSV whereIn) as of the v5 filter PR.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;
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

  // Server ignores `currency_id` as of May 2026 — flip back to `true`
  // when the v5 API adds support.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;

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

  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches =
        statics.currencies.values
            .where(
              (c) =>
                  c.code.toLowerCase().startsWith(q) ||
                  c.name.toLowerCase().startsWith(q),
            )
            .toList()
          ..sort((a, b) => a.code.compareTo(b.code));
    return [
      for (final c in matches.take(kQuickValueLimitPerKey))
        FilterValueSuggestion(
          rawValue: c.id,
          displayLabel: c.code,
          secondaryLabel: c.name,
        ),
    ];
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

  // Server ignores `language_id` as of May 2026 — flip back to `true`
  // when the v5 API adds support.
  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => false;

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

  @override
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches =
        statics.languages.values
            .where((l) => l.name.toLowerCase().startsWith(q))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return [
      for (final l in matches.take(kQuickValueLimitPerKey))
        FilterValueSuggestion(rawValue: l.id, displayLabel: l.name),
    ];
  }
}
