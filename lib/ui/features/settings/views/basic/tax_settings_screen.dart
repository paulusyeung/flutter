import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/view_models/tax_settings_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/tax_settings_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';

/// Settings → Tax Settings. Cascade-aware (company / group / client) — the
/// scaffold swaps to the shared `ClientSettingsDraftViewModel` at non-company
/// scope; per-page customization lives in [TaxSettingsViewModel] (a one-line
/// subclass of `SettingsDraftViewModel`).
class TaxSettingsScreen extends StatelessWidget {
  const TaxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CascadeSettingsScaffold(
      titleKey: 'tax_settings',
      companyVmFactory: ({required repo, required companyId}) =>
          TaxSettingsViewModel(repo: repo, companyId: companyId),
      body: const TaxSettingsBody(),
    );
  }
}
