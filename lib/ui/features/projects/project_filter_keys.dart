import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the projects list's search field.
///
/// `client_id` was confirmed working server-side in the May 2026 audit.
/// Other dimensions (`assigned_user_id`, `due_date` range) wait on
/// backend support.
List<FilterKey> buildProjectFilterKeys({
  required ClientRepository clients,
  required String companyId,
  String? Function(String id)? nameForClientId,
}) => <FilterKey>[
  const IsFilterKey(),
  ClientFilterKey(
    clients: clients,
    companyId: companyId,
    nameForClientId: nameForClientId,
  ),
];
