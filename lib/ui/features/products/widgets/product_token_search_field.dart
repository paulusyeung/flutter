import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/products/product_filter_keys.dart';
import 'package:admin/ui/features/products/view_models/product_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the products list.
///
/// Mirrors `ClientTokenSearchField` so the layout / placement code in
/// [EntityListNormalAppBar] stays entity-agnostic. Products don't have a
/// company-derived custom-field label set today, so the filter keys are
/// constant — but kept inside this wrapper for symmetry with clients.
class ProductTokenSearchField extends StatelessWidget {
  const ProductTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final ProductListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildProductFilterKeys(),
      wide: wide,
      hintKey: 'search_products_or_filter_hint',
    );
  }
}
