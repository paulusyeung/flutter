import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the Payment Links list's search
/// field. PaymentLinks carry no entity-specific dimension on the
/// server — the name + purchase_page substring search covers it.
/// Active / archived / deleted toggles via `IsFilterKey`.
List<FilterKey> buildPaymentLinkFilterKeys() => const <FilterKey>[
  IsFilterKey(),
];
