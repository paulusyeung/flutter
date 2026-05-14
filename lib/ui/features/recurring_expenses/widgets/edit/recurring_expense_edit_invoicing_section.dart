import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_edit_view_model.dart';

/// `should_be_invoiced` + `invoice_documents` toggles. Mirrors
/// `ExpenseEditInvoicingSection`.
class RecurringExpenseEditInvoicingSection extends StatelessWidget {
  const RecurringExpenseEditInvoicingSection({super.key, required this.vm});
  final RecurringExpenseEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      title: context.tr('invoicing'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('should_be_invoiced')),
            value: vm.draft.shouldBeInvoiced,
            onChanged: vm.setShouldBeInvoiced,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('invoice_documents')),
            value: vm.draft.invoiceDocuments,
            onChanged: vm.setInvoiceDocuments,
          ),
        ],
      ),
    );
  }
}
