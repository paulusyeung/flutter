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
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_detail_view_model.dart';

/// Read-only Product detail screen.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _archive(Product p) async {
    await _services.products.archive(companyId: _companyId, id: p.id);
    if (!mounted) return;
    Notify.success(context, context.tr('archived'));
  }

  Future<void> _restore(Product p) async {
    await _services.products.restore(companyId: _companyId, id: p.id);
    if (!mounted) return;
    Notify.success(context, context.tr('restored'));
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Product>(
      vm: _vm,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: context.tr('product_not_found'),
      actionsForItem: (context, p) => Row(
        children: [
          Expanded(
            child: Text(
              p.productKey.isEmpty ? '—' : p.productKey,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: context.tr('edit'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/products/${p.id}/edit'),
          ),
          if (p.archivedAt == null && !p.isDeleted)
            IconButton(
              tooltip: context.tr('archive'),
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => _archive(p),
            )
          else
            IconButton(
              tooltip: context.tr('restore'),
              icon: const Icon(Icons.unarchive_outlined),
              onPressed: () => _restore(p),
            ),
        ],
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
