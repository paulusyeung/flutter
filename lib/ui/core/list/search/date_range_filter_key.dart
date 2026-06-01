import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// `updated_between` — a closed window on `updated_at`. The backend
/// `QueryFilters::updated_between` is the **2-part** `"<start>,<end>"`
/// contract, so this key emits exactly `start,end`.
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

  // Value is a `start,end` pair (not a single date), so this is a string
  // type, not `FilterValueType.date` (which the suggestion menu labels as
  // a single-date field).
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
    return p.length >= 2 && p[0].trim().isNotEmpty && p[1].trim().isNotEmpty;
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
  Future<void> clear(GenericListViewModel<dynamic> vm, BuildContext context) =>
      writeSingleExtraFilter(vm, _serverKey, null);
}
