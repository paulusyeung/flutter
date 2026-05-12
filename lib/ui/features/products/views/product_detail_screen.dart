import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/widgets/detail_info_row.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_detail_view_model.dart';
import 'package:admin/ui/features/products/widgets/detail/product_detail_actions_row.dart';
import 'package:admin/ui/features/products/widgets/detail/product_detail_header.dart';

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

  Future<void> _onAction(Product p, ProductAction action) async {
    switch (action) {
      case ProductAction.edit:
        context.go('/products/${p.id}/edit');
      case ProductAction.archive:
        await _services.products.archive(companyId: _companyId, id: p.id);
        if (!mounted) return;
        Notify.success(context, context.tr('archived'));
      case ProductAction.restore:
        await _services.products.restore(companyId: _companyId, id: p.id);
        if (!mounted) return;
        Notify.success(context, context.tr('restored'));
      case ProductAction.clone:
      case ProductAction.cloneToInvoice:
      case ProductAction.cloneToQuote:
      case ProductAction.newInvoice:
      case ProductAction.newQuote:
      case ProductAction.delete:
      case ProductAction.purge:
        // Buttons render disabled — branches kept so the enum stays
        // exhaustive and future wiring is grep-able.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Product>(
      vm: _vm,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: context.tr('product_not_found'),
      actionsForItem: (context, p) =>
          ProductDetailActionsRow(product: p, onAction: (a) => _onAction(p, a)),
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
