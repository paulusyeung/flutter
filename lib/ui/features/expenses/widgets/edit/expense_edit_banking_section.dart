import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';

/// Banking section — bank_id + transaction_id + transaction_reference. The
/// full Bank Transactions editor is postponed, so when an expense is linked
/// to one of those rows we surface ids as read-only context instead of
/// trying to render a picker for an entity the app doesn't ship yet.
class ExpenseEditBankingSection extends StatelessWidget {
  const ExpenseEditBankingSection({super.key, required this.vm});
  final ExpenseEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final linked =
        vm.draft.bankId.isNotEmpty || vm.draft.transactionId.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EntityEditField(
          label: context.tr('bank_id'),
          initial: vm.draft.bankId,
          onChanged: vm.setBankId,
          readOnly: linked,
        ),
        EntityEditField(
          label: context.tr('transaction_id'),
          initial: vm.draft.transactionId,
          onChanged: vm.setTransactionId,
          readOnly: linked,
        ),
        EntityEditField(
          label: context.tr('transaction_reference'),
          initial: vm.draft.transactionReference,
          onChanged: vm.setTransactionReference,
        ),
      ],
    );
  }
}
