import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// State holder for Settings → Task Settings. Mixes top-level `company.*`
/// edits (auto_start_tasks, invoice_task_*, lock, documents, …) with
/// cascade `company.settings.*` edits (default_task_rate, rounding,
/// client portal tasks). All lifecycle (load/watch/dirty/reset/save and
/// the override-binding plumbing) lives on [SettingsDraftViewModel]; this
/// is the same one-line subclass pattern as `CompanyDetailsViewModel` /
/// `ProductSettingsViewModel`.
class TaskSettingsViewModel extends SettingsDraftViewModel {
  TaskSettingsViewModel({required super.repo, required super.companyId});
}
