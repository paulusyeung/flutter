import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// `date_range` — a closed window on the entity's `date` column. Server-
/// backed via the base `QueryFilters::date_range`, which expects a
/// **2-part** value `"<start>,<end>"` and applies
/// `whereBetween('date', [start, end])`. Inherited by invoices, quotes,
/// credits, etc. (the entities whose table has a `date` column and don't
/// override `date_range`).
///
/// Distinct from `PaymentFilters::date_range`, which overrides the base to
/// a **3-part** `"<label>,<start>,<end>"` shape — payments use the separate
/// `PaymentDateRangeFilterKey`. (The cross-entity arity inconsistency is a
/// tracked backend ask in `BACKEND.md`; standardizing it server-side would
/// let these two keys merge.)
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

  /// `start,end` — at least 2 parts, both non-empty.
  @override
  bool isValidValue(String rawValue) {
    final parts = rawValue.split(',');
    return parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
  }

  static String _displayFor(String rawValue) {
    final parts = rawValue.split(',');
    if (parts.length >= 2) return '${parts[0]} – ${parts[1]}';
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
    return writeSingleExtraFilter(vm, _serverKey, rawValue.trim());
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
