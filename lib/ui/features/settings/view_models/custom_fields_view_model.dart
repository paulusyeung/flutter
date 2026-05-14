import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// State holder for the Custom Fields screen — every tab in the
/// [CustomFieldsShell] binds to one instance, scoped to the active company.
///
/// Pure subclass of [SettingsDraftViewModel] — the lifecycle (load, watch,
/// dirty, reset, save), the override path, and the field-error plumbing all
/// live on the base. Mirrors the one-line pattern used for
/// [CompanyDetailsViewModel].
class CustomFieldsViewModel extends SettingsDraftViewModel {
  CustomFieldsViewModel({required super.repo, required super.companyId});
}
