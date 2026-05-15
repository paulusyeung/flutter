import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the payments list's search field.
///
/// Launching with the same minimal filter surface as Expense: only the
/// state filter (`is:archived`, `is:active`). The "has unapplied funds"
/// chip is a dedicated bool on the ViewModel, not a search token.
List<FilterKey> buildPaymentFilterKeys() => const <FilterKey>[IsFilterKey()];
