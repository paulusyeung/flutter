import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/localization_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/localization/custom_labels_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_screen.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/statics_warmer.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Localization settings page. At **company** scope it's two tabs (Settings,
/// Custom Labels) hosted by the cascade-aware [CascadeTabbedSettingsShell];
/// both tabs bind to `company.settings.*` so the shell picks the right VM and
/// the field bodies stay scope-agnostic.
///
/// At **group / client** scope the Custom Labels tab is hidden — it's
/// company-only, matching the React app (`useLocalizationTabs.ts`) and
/// admin-portal (which drops the tab bar when filtered). We render the lone
/// Settings body through the non-tabbed [CascadeSettingsScaffold] instead of a
/// stray one-tab bar — same per-scope VM selection, no shared-shell changes.
/// Precedent: `workflow_settings_shell.dart` (single-module → single body).
///
/// On fresh logins that land here before the first `/api/v1/statics` fetch
/// finishes, the Settings tab's Currency / Language / Timezone / Date Format
/// pickers would render empty — the warmer fires a no-force ensureLoaded()
/// so the cached payload (or a quick refresh) populates them.
class LocalizationShell extends StatelessWidget {
  const LocalizationShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/localization` URL (defaults to the Settings tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    // `context.read` (not `watch`): `_SettingsLevelKeyed` (settings_routes.dart)
    // remounts this whole subtree on every level/target flip, so the scope is
    // fixed for this mount. Mirrors `invoice_design_shell.dart`.
    final isCompanyScope = context.read<SettingsLevelController>().isCompany;

    return StaticsWarmer(
      child: isCompanyScope
          ? CascadeTabbedSettingsShell(
              titleKey: 'localization',
              basePath: '/settings/localization',
              initialTab: initialTab,
              companyVmFactory: ({required repo, required companyId}) =>
                  LocalizationViewModel(repo: repo, companyId: companyId),
              tabs: const [
                TabbedSettingsTab(
                  slug: '',
                  labelKey: 'settings',
                  body: LocalizationSettingsBody(),
                ),
                TabbedSettingsTab(
                  slug: 'custom_labels',
                  labelKey: 'custom_labels',
                  body: LocalizationCustomLabelsBody(),
                ),
              ],
            )
          // Group / client scope: Custom Labels is company-only — drop the tab
          // bar and render just the Settings body.
          : CascadeSettingsScaffold(
              titleKey: 'localization',
              companyVmFactory: ({required repo, required companyId}) =>
                  LocalizationViewModel(repo: repo, companyId: companyId),
              body: const LocalizationSettingsBody(),
            ),
    );
  }
}
