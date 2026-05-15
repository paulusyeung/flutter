import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the expenses list's search field.
///
/// `client_id` was confirmed working server-side in the May 2026 audit
/// (`vendor_id` / `category_id` / `project_id` are silently ignored —
/// tracked in BACKEND.md). Adding vendor / category pickers waits on
/// backend support.
List<FilterKey> buildExpenseFilterKeys({
  required ClientRepository clients,
  required String companyId,
}) => <FilterKey>[
  const IsFilterKey(),
  ClientFilterKey(clients: clients, companyId: companyId),
];
