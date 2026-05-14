import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the Recurring Expenses list's search
/// field. The status chip strip above the list owns the 5-status filter
/// dimension — the search field here keeps to the same minimal surface
/// as Expense / Project (only `is:archived`, `is:active`).
List<FilterKey> buildRecurringExpenseFilterKeys() =>
    const <FilterKey>[IsFilterKey()];
