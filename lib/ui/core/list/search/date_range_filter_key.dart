import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// `date_range` — a closed window on the entity's `date` column. As of the
/// v5 filter PR the canonical server contract is **3-part**
/// `"<column>,<start>,<end>"` (column defaults to `date`); this key always
/// emits `"date,<start>,<end>"`. Legacy 2-part values still parse (the
/// backend honours them for a deprecation cycle and a pre-upgrade persisted
/// `nav_state`/saved view may still hold one) — display, validation and
/// `parseDateRangeFilter` read the **last two** comma-parts, so 2-part and
/// 3-part both resolve correctly.
///
/// Single-value, set programmatically (e.g. a dashboard KPI deep-link) or
/// via the date-range picker; rendered as one removable chip. No free-text
/// value suggestions.
class DateRangeFilterKey extends FilterKey {
  const DateRangeFilterKey();

  static const String _serverKey = 'date_range';

  @override
  String get id => 'date_range';

  @override
  String displayLabel(BuildContext context) => context.tr('date_range');

  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  /// Valid when the last two comma-parts (start, end) are non-empty —
  /// tolerant of canonical `date,start,end` and legacy `start,end`.
  @override
  bool isValidValue(String rawValue) {
    final p = rawValue.split(',');
    return p.length >= 2 &&
        p[p.length - 2].trim().isNotEmpty &&
        p[p.length - 1].trim().isNotEmpty;
  }

  /// Canonical `date,<start>,<end>`. The picker hands us a 2-part
  /// `start,end`; an already-canonical 3-part value is normalized too.
  static String _canonical(String rawValue) {
    final p = rawValue.split(',');
    if (p.length < 2) return rawValue;
    final start = p[p.length - 2].trim();
    final end = p[p.length - 1].trim();
    return 'date,$start,$end';
  }

  static String _displayFor(String rawValue) {
    final p = rawValue.split(',');
    if (p.length >= 2) return '${p[p.length - 2]} – ${p[p.length - 1]}';
    return rawValue;
  }

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final v in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: v,
          displayValue: _displayFor(v),
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
    if (!isValidValue(rawValue)) return Future.value();
    return writeSingleExtraFilter(vm, _serverKey, _canonical(rawValue));
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) =>
      writeSingleExtraFilter(vm, _serverKey, null);

  @override
  Future<void> selectExclusive(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String rawValue,
  ) => addValue(vm, rawValue);

  @override
  Future<void> clear(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) => writeSingleExtraFilter(vm, _serverKey, null);
}

/// `updated_between` — a closed window on `updated_at`. Distinct from
/// [DateRangeFilterKey]: the backend `QueryFilters::updated_between` is the
/// **2-part** `"<start>,<end>"` contract (it was not folded into the 3-part
/// `date_range` standardisation), so this key emits exactly `start,end`.
///
/// Single-value, free-text/programmatic entry (same mechanism as the
/// existing single-date `UpdatedFilterKey` — `FilterValueType.date`, no
/// suggestions). Only registered where the local watch mirrors it
/// (`ClientDao.watchPage` `updatedFrom`/`updatedTo` via
/// `parseUpdatedBetweenFilter`); other entities can adopt it once their
/// DAO grows the same predicate.
class UpdatedRangeFilterKey extends FilterKey {
  const UpdatedRangeFilterKey();

  static const String _serverKey = 'updated_between';

  @override
  String get id => 'updated_between';

  @override
  String displayLabel(BuildContext context) => context.tr('updated_between');

  // Value is a `start,end` pair (not a single date), so — like the sibling
  // `DateRangeFilterKey` — this is a string type, not `FilterValueType.date`
  // (which the suggestion menu labels as a single-date field).
  @override
  FilterValueType get valueType => FilterValueType.string;

  @override
  bool get singleValue => true;

  @override
  bool isAvailable(GenericListViewModel<dynamic> vm) => true;

  /// `start,end` — at least 2 parts, both non-empty.
  @override
  bool isValidValue(String rawValue) {
    final p = rawValue.split(',');
    return p.length >= 2 &&
        p[0].trim().isNotEmpty &&
        p[1].trim().isNotEmpty;
  }

  /// Normalize to exactly `start,end` (drop any extra parts / whitespace).
  static String _normalize(String rawValue) {
    final p = rawValue.split(',');
    if (p.length < 2) return rawValue;
    return '${p[0].trim()},${p[1].trim()}';
  }

  static String _displayFor(String rawValue) {
    final p = rawValue.split(',');
    if (p.length >= 2) return '${p[0].trim()} – ${p[1].trim()}';
    return rawValue;
  }

  @override
  bool isAtDefault(GenericListViewModel<dynamic> vm) =>
      (vm.extraFilters[_serverKey] ?? const <String>{}).isEmpty;

  @override
  String? hintForValueMode(BuildContext context) =>
      context.tr('updated_between_hint');

  @override
  Iterable<FilterToken> tokensFrom(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) {
    final values = vm.extraFilters[_serverKey] ?? const <String>{};
    return [
      for (final v in values)
        FilterToken(
          keyId: id,
          displayKey: displayLabel(context),
          rawValue: v,
          displayValue: _displayFor(v),
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
    if (!isValidValue(rawValue)) return Future.value();
    return writeSingleExtraFilter(vm, _serverKey, _normalize(rawValue));
  }

  @override
  Future<void> removeValue(GenericListViewModel<dynamic> vm, String rawValue) =>
      writeSingleExtraFilter(vm, _serverKey, null);

  @override
  Future<void> selectExclusive(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String rawValue,
  ) => addValue(vm, rawValue);

  @override
  Future<void> clear(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
  ) => writeSingleExtraFilter(vm, _serverKey, null);
}
