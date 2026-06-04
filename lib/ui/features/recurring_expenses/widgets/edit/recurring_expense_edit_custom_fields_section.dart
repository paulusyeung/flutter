import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_edit_view_model.dart';

/// Custom value 1–4 fields — type-aware and gated by the company's configured
/// labels. Recurring expenses reuse the **expense** custom fields
/// (`expense1..4`), matching the legacy alias `recurring_expense* → expense*`.
class RecurringExpenseEditCustomFieldsSection extends StatelessWidget {
  const RecurringExpenseEditCustomFieldsSection({super.key, required this.vm});
  final RecurringExpenseEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return EntityCustomFieldsSection(
      keyPrefix: 'expense',
      companyStream: services.company.watchCompany(vm.companyId),
      formatter: services.formatterIfReady(vm.companyId),
      wrapInCard: false,
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
    );
  }
}
