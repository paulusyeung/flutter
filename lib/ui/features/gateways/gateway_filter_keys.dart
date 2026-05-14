import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the company-gateways list's search field.
///
/// Phase 1 surfaces only the state filter (`is:archived`, `is:active`).
/// Future filters (per-provider, supports-card-X, etc.) would be added as
/// `FilterKey` subclasses writing to `vm.extraFilters`.
List<FilterKey> buildCompanyGatewayFilterKeys() => const <FilterKey>[
  IsFilterKey(),
];
