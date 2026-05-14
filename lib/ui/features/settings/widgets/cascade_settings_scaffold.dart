import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
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
/// Handles VM lifecycle (`load`, `dispose`), survives the in-app company
/// switch (the [authSession] listener rebuilds the VM against the new
/// company), and hands the result to [SettingsPageScaffold] which owns the
/// AppBar / Save button / dirty guard / FormSaveScope chrome.
///
/// Scope-change reactivity (banner close → `controller.reset()`) is handled
/// upstream by the `_SettingsLevelKeyed` wrapper in `settings_routes.dart`,
/// which remounts this whole widget on level/targetId change. The scaffold
/// itself only needs to handle the company-switch within a stable level.
///
/// **Use this for cascade-aware screens only** (Localization, Online
/// Payments, Tax Settings, Email Settings, …). Pages that edit top-level
/// `Company` fields (Company Details — `size_id`, `industry_id`, custom
/// fields) compose `SettingsPageScaffold` directly with a company-only VM,
/// because the client scope wouldn't apply.
class CascadeSettingsScaffold extends StatefulWidget {
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
  State<CascadeSettingsScaffold> createState() =>
      _CascadeSettingsScaffoldState();
}

class _CascadeSettingsScaffoldState extends State<CascadeSettingsScaffold> {
  late final Services _services;
  late SettingsDraftHost _vm;
  String _currentCompanyId = '';

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _currentCompanyId = _services.auth.session.value?.currentCompanyId ?? '';
    _vm = _buildVm();
    unawaited(_vm.load());
    _services.auth.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    super.dispose();
  }

  SettingsDraftHost _buildVm() {
    final scope = _services.settingsLevel;
    final clientId = scope.targetId;
    if (scope.level == SettingsLevel.client && clientId != null) {
      return ClientSettingsDraftViewModel(
        repo: _services.clients,
        db: _services.db,
        companyId: _currentCompanyId,
        clientId: clientId,
      );
    }
    return widget.companyVmFactory(
      repo: _services.company,
      companyId: _currentCompanyId,
    );
  }

  /// Replace the in-progress VM when the user switches companies. The old
  /// draft is discarded on purpose — it belongs to the previous tenant and
  /// would be invalid against the new one's id (matches Company Details
  /// shell's behavior). Discard-on-dirty is the company picker's
  /// responsibility — by the time this listener fires, `confirmIfDirty`
  /// has already gated the switch.
  void _onSessionChanged() {
    final next = _services.auth.session.value?.currentCompanyId ?? '';
    if (next == _currentCompanyId) return;
    setState(() {
      _vm.dispose();
      _currentCompanyId = next;
      _vm = _buildVm();
      unawaited(_vm.load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold<SettingsDraftHost>(
      titleKey: widget.titleKey,
      viewModel: _vm,
      bottom: widget.bottom,
      extraActions: widget.extraActions,
      body: widget.body,
    );
  }
}
