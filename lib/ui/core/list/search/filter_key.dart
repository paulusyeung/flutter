import 'package:flutter/widgets.dart';

import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// One filterable dimension of an entity list — `is`, `custom1`, `country`,
/// and so on. Each `FilterKey` knows how to render itself in the suggestion
/// menu, where its values live on the [GenericListViewModel], and how to
/// apply / remove them.
///
/// Add a new dimension by writing a subclass and adding it to the entity's
/// registry (`client_filter_keys.dart`). Everything else — the search field,
/// the chip rendering, the suggestion menu, persistence — is generic.
///
/// `FilterKey` is intentionally non-generic. The concrete keys only touch
/// the `GenericListViewModel` base API (`states`, `customFilters`,
/// `extraFilters`, `setStates`, `setCustomFilter`, `setExtraFilter`,
/// `watchDistinctCustomValues`); none of them need the entity type. Keeping
/// the VM typed as `GenericListViewModel<dynamic>` lets a single registry
/// of keys serve every entity without phantom generic parameters.
abstract class FilterKey {
  const FilterKey();

  /// Canonical id the user types after the `:` separator (`is`, `custom1`,
  /// `country`). Stable across locales. Lowercase ASCII.
  String get id;

  /// Display label shown in the chip + suggestion menu. Resolved at render
  /// time so it follows the active locale + company settings (the configured
  /// "Region" label for `custom1`, the localized "Status" for `is`).
  String displayLabel(BuildContext context);

  /// Extra ids the user can type to pick this key (`is` accepts `status` as
  /// an alias and vice versa). Powers paste compatibility for Sentry-style
  /// queries.
  Iterable<String> get aliases => const [];

  /// Coarse value type — drives the chip rendering and the type label in
  /// the suggestion list. v1 uses [FilterValueType.enumeration] for status
  /// and [FilterValueType.string] for everything else.
  FilterValueType get valueType;

  /// When true, only one value may be applied at a time — selecting a new
  /// value replaces the old one rather than appending. Enums with a small
  /// fixed set typically opt in (`status`, `assigned`) to keep the chip
  /// compact and to enable [cycleValue].
  bool get singleValue => false;

  /// When true, the value picker renders an explicit checkbox per row and
  /// splits the row's hit-target: tapping the **label** selects only that
  /// value and closes the menu (quick single pick / replace), tapping the
  /// **checkbox** toggles the value into the multi-selection and keeps the
  /// menu open. Opt-in — only the status / state keys set this; every other
  /// key keeps the default toggle-and-close picker.
  bool get checkboxMultiSelect => false;

  /// Currently-applied tokens for this key, derived from VM state. Empty
  /// when the key is at its default and no chip should appear.
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  );

  /// Streamed value suggestions for the autocomplete. `query` is the text
  /// after `<id-or-alias>:`. Implementations filter a static list or
  /// project from a live DAO stream.
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  );

  /// Synchronous lookup used by the key-mode picker to surface cross-key
  /// value matches when the user types free text without a `<key>:` prefix —
  /// e.g. typing `act` surfaces a `Status: Active` row so picking it applies
  /// `status:active` directly.
  ///
  /// Distinct from [watchValueSuggestions] because we need same-frame
  /// results per keystroke: a `StreamBuilder` per key per keystroke flickers
  /// the first frame as `Stream.value` emits asynchronously on the
  /// microtask queue. The five statics-backed keys and `IsFilterKey`
  /// already build their suggestion list synchronously inside
  /// `watchValueSuggestions`, so the override is a thin extract.
  ///
  /// Default returns empty so typed-input keys (`name`, `balance`, …)
  /// and flat-membership keys (`vat`, `id_number`, `classification`)
  /// contribute nothing — they have no enumerable value set.
  ///
  /// Implementations should use case-insensitive `startsWith` against
  /// display labels (and ISO codes for country/currency) and cap the
  /// returned list per key — the menu applies its own total cap on top.
  List<FilterValueSuggestion> quickValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) => const [];

  /// Apply a value. Implementations write through to the relevant VM slot
  /// ([GenericListViewModel.setStates], [GenericListViewModel.setCustomFilter],
  /// [GenericListViewModel.setExtraFilter]).
  Future<void> addValue(GenericListViewModel<dynamic> vm, String rawValue);

  /// Remove a specific value. No-op if the value wasn't applied.
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue);

  /// Replace every currently-applied value for this key with [rawValue]
  /// alone. Drives the "tap the row label = pick only this" half of the
  /// [checkboxMultiSelect] split action. The generic default removes each
  /// applied token then adds [rawValue] — correct but fires one VM reload
  /// per removal; keys that can express the replace as a single VM write
  /// (`setStates` / `setExtraFilter`) override this for one reload.
  Future<void> selectExclusive(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String rawValue,
  ) {
    // Snapshot the applied raw values synchronously (uses [context]) before
    // any await, so the BuildContext never crosses an async gap.
    final applied = [for (final t in tokensFrom(vm, context)) t.rawValue];
    Future<void> run() async {
      for (final raw in applied) {
        await removeValue(vm, raw);
      }
      await addValue(vm, rawValue);
    }

    return run();
  }

  /// Remove every currently-applied value for this key. Drives the `×` on
  /// an aggregate multi-value chip. The generic default snapshots the
  /// applied raw values synchronously (before any await — no BuildContext
  /// across an async gap) then loops [removeValue]; correct but fires one
  /// VM reload per value. Keys that can express the clear as a single VM
  /// write (`setStates` / `setExtraFilter`) override this for one reload.
  Future<void> clear(GenericListViewModel<dynamic> vm, BuildContext context) {
    final applied = [for (final t in tokensFrom(vm, context)) t.rawValue];
    Future<void> run() async {
      for (final raw in applied) {
        await removeValue(vm, raw);
      }
    }

    return run();
  }

  /// User-typeable form of [rawValue] for chip-tap-to-edit. Returns null
  /// when the key shouldn't pre-fill its value — membership keys whose
  /// raw value is an opaque id (`country:840`), enum keys whose value
  /// belongs in the picker. Typed-input keys override to return the form
  /// the user originally typed; [addValue] must accept what's returned
  /// here so Enter on the pre-fill produces the same wire format.
  String? editableValueText(String rawValue) => null;

  /// For [singleValue] enum keys with a small enumeration, advance to the
  /// next value. Returning `null` (the default) disables the chip's
  /// tap-to-cycle path — keys without an obvious "next" should just open
  /// the popover.
  Future<void> Function()? cycleValue(GenericListViewModel<dynamic> vm) => null;

  /// True when this key has no chip to render (e.g. `is` with only
  /// `{active}`). The search field uses this to suppress noise on a fresh
  /// load: a user who hasn't filtered shouldn't see a default chip.
  bool isAtDefault(GenericListViewModel<dynamic> vm);

  /// True when this key should appear in the suggestion menu at all. Keys
  /// whose options come from a stream that may be empty (the custom-field
  /// columns, groups before the Groups entity ships) opt out so they don't
  /// surface a key with no values to pick from. Defaults to true.
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  /// Optional hint shown in the value menu when `watchValueSuggestions`
  /// emits an empty list. For typed-value keys (`name`, `balance`,
  /// `created`, …) the value menu has nothing to pick — the user types
  /// the value directly and presses Enter. Returning a localized hint
  /// here replaces the default "No matches" copy with something
  /// actionable like "Type a name (starts with)". Default null leaves
  /// the menu's existing fallback in place.
  String? hintForValueMode(BuildContext context) => null;

  /// Operators this key exposes when the user has typed a value. Default
  /// empty → no operator picker (value menu falls back to suggestions
  /// or the `hintForValueMode` text). Keys that opt in must also accept
  /// the wire format `<value>:<op.name>` from `addValue` — see
  /// `BalanceFilterKey` for the reference implementation.
  List<FilterOp> get supportedOps => const [];

  /// Pre-flight validation for a user-typed value before Enter commits
  /// it through [addValue]. Default accepts anything.
  ///
  /// Keys can reject inputs that would silently produce no chip — e.g.
  /// `BalanceFilterKey` rejects bare operator symbols (`>`, `<`,
  /// `:gt`, `:lt`) with no numeric value, so Enter on `balance:>`
  /// keeps the overlay open instead of dropping the input on the floor.
  ///
  /// Return `true` to accept; `false` to reject and keep the input.
  bool isValidValue(String rawValue) => true;
}

/// Helper for typed-input keys whose `addValue` stores a single
/// wire-formatted value (substring text, `value:gt` / `value:lt`,
/// `value:eq`, …). Writes a one-element set; passing null/empty clears
/// the filter entirely. Shared across every entity that has at least
/// one single-value typed-input key.
Future<void> writeSingleExtraFilter(
  GenericListViewModel<dynamic> vm,
  String serverKey,
  String? wireValue,
) {
  if (wireValue == null || wireValue.isEmpty) {
    return vm.setExtraFilter(serverKey: serverKey, values: const {});
  }
  return vm.setExtraFilter(serverKey: serverKey, values: {wireValue});
}

/// Comparison operators a [FilterKey] can expose in its value menu.
///
/// Wire format: the Invoice Ninja v2 API uses **suffix** syntax
/// `param=value:op` (e.g. `balance=1000:gt`, `balance=1000:lt`).
/// The PREFIX form `param=op:value` is silently treated as
/// "any non-empty filter" — the actual value isn't compared. See
/// `client_filter_keys.dart` for the empirical findings.
enum FilterOp {
  /// Greater than. `balance=1000:gt`.
  gt,

  /// Less than. `balance=1000:lt`.
  lt,
}
