import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// State holder for Settings → Expense Settings. Mixes top-level `company.*`
/// expense toggles (mark_paid, should_be_invoiced, convert_expense_currency,
/// invoice_expense_documents, notify_vendor_when_paid, the mailbox block,
/// and the expense-tax pair) with the cascade
/// `company.settings.defaultExpensePaymentTypeId` field. All lifecycle plumbing
/// (load/watch/dirty/reset/save and the override-binding machinery) lives on
/// [SettingsDraftViewModel] — same one-line subclass pattern as
/// `TaskSettingsViewModel` / `ProductSettingsViewModel`.
class ExpenseSettingsViewModel extends SettingsDraftViewModel {
  ExpenseSettingsViewModel({required super.repo, required super.companyId});
}
