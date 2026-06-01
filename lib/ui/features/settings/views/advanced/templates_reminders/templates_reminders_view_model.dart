import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Templates & Reminders settings VM. Inherits the entire load / save /
/// dirty / cascade override machinery from [SettingsDraftViewModel] — this
/// subclass exists only as a typed identity for `Provider` lookups inside
/// the body (the `selectedTemplate` `ValueNotifier` and the
/// `PreviewController` live on the body's own State; they're rebuild-on-
/// company-switch state, not draft state, so they don't belong on the VM).
///
/// `selectedTemplate` resets to `'invoice'` on both company switch (via
/// `SettingsCompanyScopedHost` disposing this VM) and cascade-scope
/// switch (via the `_SettingsLevelKeyed` wrapper remounting the subtree).
/// Both are intentional — picker state shouldn't persist across
/// context switches.
class TemplatesRemindersViewModel extends SettingsDraftViewModel {
  TemplatesRemindersViewModel({required super.repo, required super.companyId});
}
