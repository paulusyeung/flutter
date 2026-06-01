import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_layout.dart';
import 'package:admin/ui/features/products/widgets/product_actions.dart';

/// Edit + Create form for a Product. See `EntityEditScreenScaffold` for the
/// shared chrome (loading state, dead-outbox 422 recovery, post-save
/// cleanup).
class ProductEditScreen extends StatelessWidget {
  const ProductEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this product's fields (Clone action). Identity-bearing
  /// fields (id, timestamps, deleted/archived state) should already be
  /// stripped by the caller.
  final Product? cloneFrom;

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
        cloneFrom: cloneFrom,
        useCommaAsDecimalPlace: services
                .formatterIfReady(companyId)
                ?.settings
                .useCommaAsDecimalPlace ??
            false,
        sync: services.sync,
        connectivity: services.connectivity,
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
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<ProductAction>(
            leading: saveButton,
            items: filterForEditScreen(
              ProductActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: ProductActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return ProductActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as ProductAction,
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/products',
        savedId: saved.id,
      ),
    );
  }
}
