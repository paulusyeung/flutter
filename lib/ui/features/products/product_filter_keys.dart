import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/is_filter_key.dart';

/// Build the filter keys exposed in the products list's search field.
///
/// Products use a much smaller filter surface than clients today — there's
/// no custom-fields/country/industry equivalent on the server, and free-text
/// search already covers `product_key`/`notes` substring lookup via the
/// generic `vm.setSearch` path. Status is the one cross-cutting dimension
/// users expect, so we register [IsFilterKey] and call it done.
///
/// Add a product-specific dimension by writing a `FilterKey` subclass that
/// writes to `vm.extraFilters` (or its own VM slot) and appending it to the
/// list returned here.
List<FilterKey> buildProductFilterKeys() => const <FilterKey>[IsFilterKey()];
