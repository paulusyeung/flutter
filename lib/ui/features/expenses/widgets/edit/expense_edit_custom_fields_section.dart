import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';

/// Custom value 1–4 fields. Labels come from the company-level
/// `custom_fields` JSON in a follow-up — for now we surface the generic
/// `custom_valueN` translation key so the form's discoverable.
class ExpenseEditCustomFieldsSection extends StatelessWidget {
  const ExpenseEditCustomFieldsSection({super.key, required this.vm});
  final ExpenseEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EntityEditField(
          label: context.tr('custom_value1'),
          initial: vm.draft.customValue1,
          onChanged: vm.setCustomValue1,
        ),
        EntityEditField(
          label: context.tr('custom_value2'),
          initial: vm.draft.customValue2,
          onChanged: vm.setCustomValue2,
        ),
        EntityEditField(
          label: context.tr('custom_value3'),
          initial: vm.draft.customValue3,
          onChanged: vm.setCustomValue3,
        ),
        EntityEditField(
          label: context.tr('custom_value4'),
          initial: vm.draft.customValue4,
          onChanged: vm.setCustomValue4,
        ),
      ],
    );
  }
}
