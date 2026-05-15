import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

List<FilterKey> buildCreditFilterKeys({
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
