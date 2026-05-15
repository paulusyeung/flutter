import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/purchase_orders/view_models/purchase_order_list_view_model.dart';
import 'package:admin/ui/features/purchase_orders/widgets/purchase_order_filter_keys.dart';

class PurchaseOrderTokenSearchField extends StatelessWidget {
  const PurchaseOrderTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final PurchaseOrderListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildPurchaseOrderFilterKeys(),
      wide: wide,
      hintKey: 'search_purchase_orders_or_filter_hint',
    );
  }
}
