import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// VM for Settings → Tax Settings. Pure subclass of [SettingsDraftViewModel];
/// the base owns dirty tracking, save, reset, and the override toggle for
/// every cascadeable field rendered on the page.
class TaxSettingsViewModel extends SettingsDraftViewModel {
  TaxSettingsViewModel({required super.repo, required super.companyId});
}
