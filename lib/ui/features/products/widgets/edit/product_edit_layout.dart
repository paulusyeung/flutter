import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/ui/features/products/widgets/edit/product_edit_custom_fields_section.dart';
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
          padding: const EdgeInsets.all(InSpacing.lg),
          child: twoCol ? _wide() : _narrow(),
        );
      },
    );
  }

  Widget _wide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductEditDetailsSection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ProductEditInventorySection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ProductEditTaxesSection(vm: vm),
            ],
          ),
        ),
        const SizedBox(width: InSpacing.md),
        SizedBox(
          width: _sidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ProductEditCustomFieldsSection(vm: vm)],
          ),
        ),
      ],
    );
  }

  Widget _narrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductEditDetailsSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProductEditInventorySection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProductEditTaxesSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProductEditCustomFieldsSection(vm: vm),
      ],
    );
  }
}
