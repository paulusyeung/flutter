import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';

/// Wraps the generic [EntityCustomFieldsSection] in a [DashboardCardShell] so
/// it sits alongside the Details/Inventory/Taxes cards in the right column
/// of the two-column edit layout. When the company hasn't configured any
/// `productN` custom-field labels the inner section collapses to
/// `SizedBox.shrink()` — in that case we hide the whole card too.
class ProductEditCustomFieldsSection extends StatelessWidget {
  const ProductEditCustomFieldsSection({super.key, required this.vm});

  final ProductEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyStream = services.company.watchCompany(vm.companyId);
    return StreamBuilder(
      stream: companyStream,
      builder: (context, snap) {
        final company = snap.data;
        final hasAny =
            company != null &&
            [
              1,
              2,
              3,
              4,
            ].any((i) => company.customFieldLabel('product$i').isNotEmpty);
        if (!hasAny) return const SizedBox.shrink();
        return DashboardCardShell(
          title: context.tr('custom_fields'),
          child: EntityCustomFieldsSection(
            keyPrefix: 'product',
            companyStream: companyStream,
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
        );
      },
    );
  }
}
