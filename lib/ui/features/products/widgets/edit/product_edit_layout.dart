import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_details_section.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_inventory_section.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_taxes_section.dart';

/// Lays out the product edit cards (Details, Inventory, Taxes, Custom
/// Fields) using the same `1fr` main + fixed-width sidebar pattern as
/// `ClientEditLayout`.
///
/// - ≥1100 px: two columns. Left (`Expanded`) holds Details + Inventory +
///   Taxes; right (`_sidebarWidth` 360 px) holds Custom Fields.
/// - <1100 px: single scrolling column with all cards stacked.
class ProductEditLayout extends StatelessWidget {
  const ProductEditLayout({super.key, required this.vm});

  final ProductEditViewModel vm;

  static const double _twoColumnBreakpoint = 1100;
  static const double _sidebarWidth = 360;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= _twoColumnBreakpoint;
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: twoCol ? _wide(context) : _narrow(context),
        );
      },
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductEditDetailsSection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ProductEditInventorySection(vm: vm),
              SizedBox(height: InSpacing.md(context)),
              ProductEditTaxesSection(vm: vm),
            ],
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        SizedBox(
          width: _sidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_customFieldsSection(context)],
          ),
        ),
      ],
    );
  }

  Widget _customFieldsSection(BuildContext context) {
    final services = context.read<Services>();
    return EntityCustomFieldsSection(
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
      cardTitle: context.tr('custom_fields'),
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductEditDetailsSection(vm: vm),
        SizedBox(height: InSpacing.md(context)),
        ProductEditInventorySection(vm: vm),
        SizedBox(height: InSpacing.md(context)),
        ProductEditTaxesSection(vm: vm),
        SizedBox(height: InSpacing.md(context)),
        _customFieldsSection(context),
      ],
    );
  }
}
