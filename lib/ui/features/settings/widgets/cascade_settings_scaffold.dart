import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Builds the page-specific company-scoped VM (e.g. `LocalizationViewModel`).
/// Invoked at [SettingsLevel.company]. The scaffold supplies the
/// [CompanyRepository] and the resolved company id.
typedef CompanySettingsVmFactory =
    SettingsDraftViewModel Function({
      required CompanyRepository repo,
      required String companyId,
    });

/// One-call scaffold for any settings page whose fields live on
/// `company.settings.*` (i.e. cascade-aware). Picks the right
/// [SettingsDraftHost] for the current [SettingsLevel]:
///
/// * `SettingsLevel.company` → invokes [companyVmFactory] with the active
///   company's [CompanyRepository] + id.
/// * `SettingsLevel.client` → builds a [ClientSettingsDraftViewModel]
///   pointed at the client whose id is on [SettingsLevelController].
///
/// Company-switch lifecycle (rebuild the VM against the new tenant) is
/// delegated to [SettingsCompanyScopedHost]. Scope-change reactivity
/// (banner close → `controller.reset()`) is handled upstream by the
/// `_SettingsLevelKeyed` wrapper in `settings_routes.dart`, which remounts
/// this whole widget on level/targetId change. The scaffold itself only
/// needs to handle the company-switch within a stable level.
///
/// **Use this for cascade-aware screens only** (Localization, Online
/// Payments, Tax Settings, Email Settings, …). Pages that edit top-level
/// `Company` fields (Company Details — `size_id`, `industry_id`, custom
/// fields) compose `SettingsPageScaffold` directly with a company-only VM,
/// because the client scope wouldn't apply.
class CascadeSettingsScaffold extends StatelessWidget {
  const CascadeSettingsScaffold({
    super.key,
    required this.titleKey,
    required this.companyVmFactory,
    required this.body,
    this.bottom,
    this.extraActions = const <Widget>[],
  });

  final String titleKey;
  final CompanySettingsVmFactory companyVmFactory;
  final Widget body;
  final PreferredSizeWidget? bottom;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsCompanyScopedHost<SettingsDraftHost>(
      create: (companyId) {
        final scope = services.settingsLevel;
        final clientId = scope.targetId;
        final SettingsDraftHost vm;
        if (scope.level == SettingsLevel.client && clientId != null) {
          vm = ClientSettingsDraftViewModel(
            repo: services.clients,
            db: services.db,
            companyId: companyId,
            clientId: clientId,
          );
        } else {
          vm = companyVmFactory(repo: services.company, companyId: companyId);
        }
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) => SettingsPageScaffold<SettingsDraftHost>(
        titleKey: titleKey,
        viewModel: vm,
        bottom: bottom,
        extraActions: extraActions,
        body: body,
      ),
    );
  }
}
