import 'package:admin/app/services.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/group_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Resolves the right [SettingsDraftHost] for the active settings level.
///
/// Every cascade-aware settings scaffold (`CascadeSettingsScaffold`,
/// `CascadeTabbedSettingsShell`, the Online Payments shell) shares this seam:
/// at company scope it builds the page-specific company VM (via [companyVm]);
/// at group / client scope it substitutes the matching sparse-override draft
/// VM pointed at the entity whose id is on [SettingsLevelController].
///
/// Callers invoke `vm.load()` on the result themselves (kept explicit so the
/// `unawaited` is visible at each site).
SettingsDraftHost resolveCascadeDraftVm(
  Services services,
  String companyId,
  SettingsDraftHost Function() companyVm,
) {
  final scope = services.settingsLevel;
  final targetId = scope.targetId;
  if (scope.level == SettingsLevel.group && targetId != null) {
    return GroupSettingsDraftViewModel(
      repo: services.groupSettings,
      db: services.db,
      companyId: companyId,
      groupId: targetId,
    );
  }
  if (scope.level == SettingsLevel.client && targetId != null) {
    return ClientSettingsDraftViewModel(
      repo: services.clients,
      db: services.db,
      companyId: companyId,
      clientId: targetId,
    );
  }
  return companyVm();
}
