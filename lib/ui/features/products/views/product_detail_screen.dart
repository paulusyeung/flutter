import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/products/view_models/product_detail_view_model.dart';
import 'package:admin/ui/features/products/widgets/detail/product_detail_cards.dart';
import 'package:admin/ui/features/products/widgets/detail/product_detail_header.dart';
import 'package:admin/ui/features/products/widgets/product_actions.dart';

/// Read-only Product detail screen.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with FormatterHostMixin {
  late final ProductDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = ProductDetailViewModel.bound(
      _services.products.watch(companyId: _companyId, id: widget.id),
    );
    loadFormatter(_services, _companyId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Product>(
      vm: _vm,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: context.tr('product_not_found'),
      actionsForItem: (context, p) => EntityDetailActionsRow<ProductAction>(
        items: ProductActions.itemsFor(
          context,
          p,
          (a) => ProductActions.dispatch(context, _services, _companyId, p, a),
        ),
      ),
      bodyBuilder: (context, p) => SingleChildScrollView(
        padding: const EdgeInsets.all(InSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductDetailHeader(product: p, formatter: formatter),
            const SizedBox(height: InSpacing.xl),
            ProductDetailCards(product: p, formatter: formatter),
          ],
        ),
      ),
    );
  }
}
