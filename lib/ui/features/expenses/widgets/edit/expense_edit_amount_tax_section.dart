import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Amount + tax rows + the two inclusive/calculate-by-amount toggles.
///
/// Tax-tier rows track the company's `enabled_expense_tax_rates` setting.
/// We render `enabled` rows by default; an "Add tax" button overflows into
/// the higher tiers if an individual expense needs more than the company's
/// default. Matches the UX spec § Tax-tier rows track the company setting.
class ExpenseEditAmountTaxSection extends StatefulWidget {
  const ExpenseEditAmountTaxSection({super.key, required this.vm});
  final ExpenseEditViewModel vm;

  @override
  State<ExpenseEditAmountTaxSection> createState() =>
      _ExpenseEditAmountTaxSectionState();
}

class _ExpenseEditAmountTaxSectionState
    extends State<ExpenseEditAmountTaxSection> {
  /// `null` until the first frame after the company stream emits — we
  /// adopt the larger of the company's enabled count and the draft's
  /// populated-rows count. After that the user can add more via the "Add
  /// tax" button.
  int? _visibleTaxRows;

  int _draftPopulated(Expense e) {
    if (e.taxName3.isNotEmpty || e.taxRate3 != Decimal.zero) return 3;
    if (e.taxName2.isNotEmpty || e.taxRate2 != Decimal.zero) return 2;
    if (e.taxName1.isNotEmpty || e.taxRate1 != Decimal.zero) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, snapshot) {
        final companyEnabled =
            (snapshot.data?.enabledExpenseTaxRates ?? 0).clamp(0, 3);
        final draftPopulated = _draftPopulated(vm.draft);
        // Lock in the initial visible count on first build; user-added
        // rows survive subsequent rebuilds.
        _visibleTaxRows ??=
            companyEnabled > draftPopulated ? companyEnabled : draftPopulated;
        final visible = _visibleTaxRows!;
        final canAdd = visible < 3;
        return _build(context, vm, visible, canAdd);
      },
    );
  }

  Widget _build(
    BuildContext context,
    ExpenseEditViewModel vm,
    int visible,
    bool canAdd,
  ) {
    return DashboardCardShell(
      title: context.tr('amount'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EntityEditField(
            label: context.tr('amount'),
            initial: decimalInputText(vm.draft.amount),
            onChanged: vm.setAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: vm.fieldErrorFor('amount'),
          ),
          if (visible >= 1)
            _TaxRow(
              index: 1,
              nameInitial: vm.draft.taxName1,
              rateInitial: vm.draft.taxRate1,
              onNameChanged: vm.setTaxName1,
              onRateChanged: vm.setTaxRate1,
            ),
          if (visible >= 2)
            _TaxRow(
              index: 2,
              nameInitial: vm.draft.taxName2,
              rateInitial: vm.draft.taxRate2,
              onNameChanged: vm.setTaxName2,
              onRateChanged: vm.setTaxRate2,
            ),
          if (visible >= 3)
            _TaxRow(
              index: 3,
              nameInitial: vm.draft.taxName3,
              rateInitial: vm.draft.taxRate3,
              onNameChanged: vm.setTaxName3,
              onRateChanged: vm.setTaxRate3,
            ),
          if (canAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _visibleTaxRows = (_visibleTaxRows ?? visible) + 1,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('add_tax')),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: InSpacing.sm),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('inclusive_taxes')),
              value: vm.draft.usesInclusiveTaxes,
              onChanged: vm.setUsesInclusiveTaxes,
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('calculate_tax_by_amount')),
            value: vm.draft.calculateTaxByAmount,
            onChanged: vm.setCalculateTaxByAmount,
          ),
        ],
      ),
    );
  }
}

class _TaxRow extends StatelessWidget {
  const _TaxRow({
    required this.index,
    required this.nameInitial,
    required this.rateInitial,
    required this.onNameChanged,
    required this.onRateChanged,
  });

  final int index;
  final String nameInitial;
  final Decimal rateInitial;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onRateChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: EntityEditField(
              label: context.tr('tax_name$index'),
              initial: nameInitial,
              onChanged: onNameChanged,
            ),
          ),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            flex: 2,
            child: EntityEditField(
              label: context.tr('tax_rate$index'),
              initial: decimalInputText(rateInitial),
              onChanged: onRateChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
