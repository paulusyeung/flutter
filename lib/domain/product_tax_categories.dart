/// Canonical product tax-category catalog — wire id → localization key.
///
/// Single source of truth, mirrored from the server's
/// `Product::PRODUCT_TYPE_*` constants (`app/Models/Product.php`) and React's
/// `useTaxCategories()` (`src/components/tax-rates/TaxCategorySelector.tsx`).
/// The server contract is the string id (`'1'`..`'9'`); the value is a
/// localization key resolved via `context.tr(...)`.
///
/// `Map` literal order is insertion order in Dart, so iterating
/// `.entries` yields `1`→`9` for dropdowns / pickers. Every consumer
/// (the set-tax-category dialog, the edit-form dropdown, the list column,
/// the detail card) reads from this map — do not re-declare a local copy.
/// `product_tax_category_catalog_test` guards that all ids resolve to a
/// real `en.json` key.
const Map<String, String> kProductTaxCategories = <String, String>{
  '1': 'physical_goods',
  '2': 'services',
  '3': 'digital_products',
  '4': 'shipping',
  '5': 'tax_exempt',
  '6': 'reduced_tax',
  '7': 'override_tax',
  '8': 'zero_rated',
  '9': 'reverse_tax',
};
