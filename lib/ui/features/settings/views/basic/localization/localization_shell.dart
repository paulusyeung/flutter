import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/features/settings/view_models/localization_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/localization/custom_labels_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_screen.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Localization settings page — two tabs (Settings, Custom Labels) hosted by
/// the cascade-aware [CascadeTabbedSettingsShell]. Both tabs bind to
/// `company.settings.*` so the shell picks the right VM per scope (company
/// vs. client) and the field bodies stay scope-agnostic.
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
    return _StaticsWarmer(
      child: CascadeTabbedSettingsShell(
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
      ),
    );
  }
}

class _StaticsWarmer extends StatefulWidget {
  const _StaticsWarmer({required this.child});

  final Widget child;

  @override
  State<_StaticsWarmer> createState() => _StaticsWarmerState();
}

class _StaticsWarmerState extends State<_StaticsWarmer> {
  @override
  void initState() {
    super.initState();
    // All localization maps come from the same /api/v1/statics payload, so
    // any single map's emptiness is a reliable "not loaded yet" proxy.
    final statics = context.read<Services>().statics;
    if (statics.currencies.isEmpty) {
      statics.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
