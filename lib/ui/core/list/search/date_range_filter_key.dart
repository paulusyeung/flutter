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
