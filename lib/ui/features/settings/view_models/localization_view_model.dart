import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Localization settings page.
///
/// Pure subclass of [SettingsDraftViewModel] — the lifecycle (load, watch,
/// dirty, reset, save), the override path, and the field-error plumbing
/// all live on the base. The client-scoped path uses
/// [ClientSettingsDraftViewModel] instead, exposed under the same
/// [SettingsDraftHost] surface so the page's body is scope-agnostic.
class LocalizationViewModel extends SettingsDraftViewModel {
  LocalizationViewModel({required super.repo, required super.companyId});
}
