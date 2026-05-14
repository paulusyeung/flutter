import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the expenses list's search field.
///
/// Expenses launch with the same minimal filter surface as Products and
/// Projects today: only the state filter (`is:archived`, `is:active`).
/// Adding an expense-specific dimension (status chips, vendor / category
/// picker) is a `FilterKey` subclass that writes to `vm.extraFilters`.
List<FilterKey> buildExpenseFilterKeys() => const <FilterKey>[IsFilterKey()];
