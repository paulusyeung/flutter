import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the expense-categories list's search
/// field. Categories carry no entity-specific dimension on the server —
/// `name` substring search covers the only field users care about. The
/// active/archived/deleted toggle goes through `IsFilterKey`.
List<FilterKey> buildExpenseCategoryFilterKeys() => const <FilterKey>[
  IsFilterKey(),
];
