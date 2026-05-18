import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/ui/core/list/search/client_filter_key.dart';
import 'package:admin/ui/core/list/search/custom_field_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

List<FilterKey> buildRecurringInvoiceFilterKeys({
  required ClientRepository clients,
  required String companyId,
  Company? company,
  String? Function(String id)? nameForClientId,
}) => <FilterKey>[
  const IsFilterKey(),
  ClientFilterKey(
    clients: clients,
    companyId: companyId,
    nameForClientId: nameForClientId,
  ),
  // Recurring invoices share Invoice Ninja's `invoice1..4` custom-fields.
  for (var i = 1; i <= 4; i++)
    CustomFieldFilterKey(
      columnIndex: i,
      configuredLabel: company?.customFieldLabel('invoice$i') ?? '',
    ),
];
