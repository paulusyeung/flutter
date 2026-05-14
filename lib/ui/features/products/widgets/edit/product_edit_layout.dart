import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Edit-form body for a Product. Mirrors `ClientEditLayout` — the screen
/// supplies the chrome (Save button, FormSaveScope, 422 banner) via
/// `EntityEditScreenScaffold`; this widget owns the field layout.
///
/// Today the form is a single "Details" card. When more sections land
/// (variants, image, related products) the responsive `LayoutBuilder`
/// two-column split from `ClientEditLayout` is the pattern to copy.
class ProductEditLayout extends StatelessWidget {
  const ProductEditLayout({super.key, required this.vm});

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
              initial: decimalInputText(vm.draft.price),
              onChanged: vm.setPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: vm.fieldErrorFor('price'),
            ),
            EntityEditField(
              label: context.tr('cost'),
              initial: decimalInputText(vm.draft.cost),
              onChanged: vm.setCost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              errorText: vm.fieldErrorFor('cost'),
            ),
            EntityEditField(
              label: context.tr('quantity'),
              initial: decimalInputText(vm.draft.quantity),
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
