import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the payments list's search field.
///
/// `client_id` was confirmed working server-side in the May 2026 audit
/// (`client_id=<id>` → narrows). The "has unapplied funds" toggle is a
/// dedicated bool on the ViewModel, not a search token.
List<FilterKey> buildPaymentFilterKeys({
  required ClientRepository clients,
  required String companyId,
}) => <FilterKey>[
  const IsFilterKey(),
  ClientFilterKey(clients: clients, companyId: companyId),
];
