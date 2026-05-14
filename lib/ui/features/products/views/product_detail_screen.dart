import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_detail_view_model.dart';
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
    _vm = ProductDetailViewModel(
      repo: _services.products,
      companyId: _companyId,
      id: widget.id,
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
      bodyBuilder: (context, p) {
        final priceFmt = NumberFormat.decimalPattern()
          ..minimumFractionDigits = 2
          ..maximumFractionDigits = 2;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(InSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductDetailHeader(product: p, formatter: formatter),
              const SizedBox(height: InSpacing.xl),
              DashboardCardShell(
                title: context.tr('details'),
                child: DetailRowStack(
                  children: [
                    DetailInfoRow(
                      label: context.tr('product'),
                      value: p.productKey.isEmpty ? '—' : p.productKey,
                    ),
                    DetailInfoRow(
                      label: context.tr('price'),
                      value: priceFmt.format(p.price.toDouble()),
                      monospace: true,
                    ),
                    DetailInfoRow(
                      label: context.tr('cost'),
                      value: priceFmt.format(p.cost.toDouble()),
                      monospace: true,
                    ),
                    DetailInfoRow(
                      label: context.tr('quantity'),
                      value: p.quantity.toString(),
                      monospace: true,
                    ),
                    if (p.notes.isNotEmpty)
                      DetailInfoRow(label: context.tr('notes'), value: p.notes),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
