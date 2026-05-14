import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Workflow Settings page.
///
/// Pure subclass of [SettingsDraftViewModel] — every workflow toggle lives
/// under `company.settings.*` (cascade-aware) except the two company-only
/// rows (`stop_on_unpaid_recurring`, `use_quote_terms_on_conversion`), which
/// the page edits via [SettingsDraftHost.updateCompany]. The client-scoped
/// path uses [ClientSettingsDraftViewModel] instead, exposed under the same
/// [SettingsDraftHost] surface so the page's tab bodies stay scope-agnostic.
class WorkflowSettingsViewModel extends SettingsDraftViewModel {
  WorkflowSettingsViewModel({required super.repo, required super.companyId});
}
