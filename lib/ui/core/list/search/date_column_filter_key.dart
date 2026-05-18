import 'package:flutter/widgets.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// Generic comparable filter on a single date column (`date`,
/// `due_date`, …) for the billing-doc lists. All wire encode/decode,
/// the comparator vocabulary, relative-preset values and the segmented
/// chip come from [ComparableFilterKey]; this class only declares the
/// id / server param / label.
///
/// Server: routed through `QueryFilters`-style `comparableDate()` on the
/// entity's filter class — canonical prefix `op:value`, `whereDate`
/// calendar-day semantics, a bare date still applying `>=`.
class DateColumnFilterKey extends FilterKey with ComparableFilterKey {
  const DateColumnFilterKey({
    required this.id,
    required this.serverKey,
    required String labelKey,
  }) : _labelKey = labelKey;

  @override
  final String id;

  @override
  final String serverKey;

  final String _labelKey;

  @override
  String displayLabel(BuildContext context) => context.tr(_labelKey);

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
