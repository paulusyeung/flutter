import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Generated Numbers settings page.
///
/// Pure subclass of [SettingsDraftViewModel] — every field binding goes
/// through `settingsBindingOf(apiKey)` (see
/// `settings_field_bindings.dart`), so the VM itself carries no
/// generated-numbers-specific state. The client-scoped path swaps in
/// [ClientSettingsDraftViewModel] via [CascadeTabbedSettingsShell] under
/// the same [SettingsDraftHost] surface.
class GeneratedNumbersViewModel extends SettingsDraftViewModel {
  GeneratedNumbersViewModel({required super.repo, required super.companyId});
}
