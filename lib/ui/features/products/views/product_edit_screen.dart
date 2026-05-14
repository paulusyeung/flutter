import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_layout.dart';

/// Edit + Create form for a Product. See `EntityEditScreenScaffold` for the
/// shared chrome (loading state, dead-outbox 422 recovery, post-save
/// cleanup).
class ProductEditScreen extends StatelessWidget {
  const ProductEditScreen({this.existingId, super.key});

  final String? existingId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Product, ProductEditViewModel>(
      existingId: existingId,
      entityTypeName: 'product',
      fetchExisting: (ctx, services, companyId, id) =>
          services.products.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) => ProductEditViewModel(
        repo: services.products,
        companyId: companyId,
        existing: existing,
      ),
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_product') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_product')
          : (vm.draft.productKey.isNotEmpty
                ? '${ctx.tr('edit')} · ${vm.draft.productKey}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => ProductEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (p) => p.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/products/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
