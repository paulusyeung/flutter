import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';

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
      bodyBuilder: (ctx, vm) => _ProductEditBody(vm: vm),
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

class _ProductEditBody extends StatelessWidget {
  const _ProductEditBody({required this.vm});

  final ProductEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(InSpacing.lg),
      child: DashboardCardShell(
        title: context.tr('details'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EntityEditField(
              label: context.tr('product'),
              initial: vm.draft.productKey,
              onChanged: vm.setProductKey,
              autofocus: vm.isCreate,
              errorText: vm.fieldErrorFor('product_key'),
            ),
            EntityEditField(
              label: context.tr('price'),
              initial: vm.draft.price.toString(),
              onChanged: vm.setPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: vm.fieldErrorFor('price'),
            ),
            EntityEditField(
              label: context.tr('cost'),
              initial: vm.draft.cost.toString(),
              onChanged: vm.setCost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: vm.fieldErrorFor('cost'),
            ),
            EntityEditField(
              label: context.tr('quantity'),
              initial: vm.draft.quantity.toString(),
              onChanged: vm.setQuantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: vm.fieldErrorFor('quantity'),
            ),
            EntityEditField(
              label: context.tr('notes'),
              initial: vm.draft.notes,
              onChanged: vm.setNotes,
              minLines: 2,
              maxLines: null,
            ),
            EntityCustomFieldsSection(
              keyPrefix: 'product',
              companyStream: services.company.watchCompany(vm.companyId),
              values: [
                vm.draft.customValue1,
                vm.draft.customValue2,
                vm.draft.customValue3,
                vm.draft.customValue4,
              ],
              onChanged: [
                vm.setCustomValue1,
                vm.setCustomValue2,
                vm.setCustomValue3,
                vm.setCustomValue4,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
