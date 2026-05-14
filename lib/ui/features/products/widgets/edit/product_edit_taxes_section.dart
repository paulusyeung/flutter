import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/products/view_models/product_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Tax category, product image URL, and the configurable tax-rate slots.
/// `productImage` always renders; `tax_id` (tax category) always renders;
/// the three `tax_name`/`tax_rate` slot pairs are gated on
/// `company.settings.enabled_item_tax_rates` (0=none, 1=one slot, 2=two,
/// 3=three) — matches React `ProductForm.tsx`.
///
/// Today the tax name/rate inputs are freeform (label text + decimal). When
/// the tax_rates entity lands in Flutter, swap these for a TaxRateSelector
/// (search the company's tax_rates list, with "create on the fly").
class ProductEditTaxesSection extends StatelessWidget {
  const ProductEditTaxesSection({super.key, required this.vm});

  final ProductEditViewModel vm;

  /// Six standard product tax category codes — fixed enum that maps to the
  /// localized labels. The wire value is the string `'1'`..`'6'`.
  static const _taxCategoryOptions = [
    ('1', 'physical_goods'),
    ('2', 'services'),
    ('3', 'digital_products'),
    ('4', 'shipping'),
    ('5', 'tax_exempt'),
    ('6', 'reduced_tax'),
  ];

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, snap) {
        final enabledSlots = snap.data?.enabledItemTaxRates ?? 0;
        return DashboardCardShell(
          title: context.tr('taxes'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              EntityEditField(
                label: context.tr('product_image'),
                initial: vm.draft.productImage,
                onChanged: vm.setProductImage,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: context.tr('tax_category'),
                  ),
                  initialValue:
                      _taxCategoryOptions.any((o) => o.$1 == vm.draft.taxId)
                      ? vm.draft.taxId
                      : null,
                  items: [
                    for (final (id, key) in _taxCategoryOptions)
                      DropdownMenuItem(value: id, child: Text(context.tr(key))),
                  ],
                  onChanged: (v) => vm.setTaxId(v ?? ''),
                ),
              ),
              if (enabledSlots >= 1)
                _TaxRow(
                  nameLabel: context.tr('tax_name'),
                  rateLabel: context.tr('tax_rate'),
                  nameValue: vm.draft.taxName1,
                  rateValue: vm.draft.taxRate1,
                  onNameChanged: vm.setTaxName1,
                  onRateChanged: vm.setTaxRate1,
                ),
              if (enabledSlots >= 2)
                _TaxRow(
                  nameLabel: context.tr('tax_name'),
                  rateLabel: context.tr('tax_rate'),
                  nameValue: vm.draft.taxName2,
                  rateValue: vm.draft.taxRate2,
                  onNameChanged: vm.setTaxName2,
                  onRateChanged: vm.setTaxRate2,
                ),
              if (enabledSlots >= 3)
                _TaxRow(
                  nameLabel: context.tr('tax_name'),
                  rateLabel: context.tr('tax_rate'),
                  nameValue: vm.draft.taxName3,
                  rateValue: vm.draft.taxRate3,
                  onNameChanged: vm.setTaxName3,
                  onRateChanged: vm.setTaxRate3,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TaxRow extends StatelessWidget {
  const _TaxRow({
    required this.nameLabel,
    required this.rateLabel,
    required this.nameValue,
    required this.rateValue,
    required this.onNameChanged,
    required this.onRateChanged,
  });

  final String nameLabel;
  final String rateLabel;
  final String nameValue;
  final Decimal rateValue;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onRateChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: EntityEditField(
            label: nameLabel,
            initial: nameValue,
            onChanged: onNameChanged,
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: EntityEditField(
            label: rateLabel,
            initial: decimalInputText(rateValue),
            onChanged: onRateChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}
