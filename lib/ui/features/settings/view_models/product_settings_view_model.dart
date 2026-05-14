import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// VM for Settings → Product Settings. Pure subclass of [SettingsDraftViewModel];
/// the base owns dirty tracking, save, reset, and the company-level `updateCompany`
/// path. All product fields live on `company.*` (top-level), so the screen edits
/// via `vm.updateCompany((c) => c.copyWith(...))` and never touches
/// `vm.updateSettings`.
class ProductSettingsViewModel extends SettingsDraftViewModel {
  ProductSettingsViewModel({required super.repo, required super.companyId});
}
