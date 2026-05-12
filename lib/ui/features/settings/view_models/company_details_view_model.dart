import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// State holder shared across all 6 tabs of the Company Details page.
///
/// Pure subclass of [SettingsDraftViewModel] — the lifecycle (load, watch,
/// dirty, reset, save), the override path, and the field-error plumbing
/// all live on the base. Adding a new settings page follows the same
/// one-line pattern with a different class name.
class CompanyDetailsViewModel extends SettingsDraftViewModel {
  CompanyDetailsViewModel({required super.repo, required super.companyId});
}
