import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/danger_zone_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/enabled_modules_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/integrations_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/overview_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/plan_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/referral_program_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/security_settings_screen.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Settings → Account Management. Seven URL-driven tabs:
///
/// * `/settings/account_management` → Plan (default).
/// * `/settings/account_management/overview` → Overview.
/// * `/settings/account_management/enabled_modules` → Enabled Modules.
/// * `/settings/account_management/integrations` → Integrations.
/// * `/settings/account_management/security_settings` → Security Settings.
/// * `/settings/account_management/referral_program` → Referral Program.
/// * `/settings/account_management/danger_zone` → Danger Zone.
///
/// Pairs with `tabbedSettingsRoutePair(...)` in `settings_routes.dart` — both
/// the bare URL and per-tab URL resolve to a single Navigator Page so
/// swiping a tab doesn't remount the shell.
///
/// Modeled on `BackupRestoreShell` (`widgets/backup_restore_shell.dart`):
/// no VM scaffolding because each tab fires its writes through
/// `services.company.updateCompany` independently — there is no unified Save
/// button. The `TabbedSettingsShell<V extends SettingsDraftHost>` machinery
/// would be pure overhead here.
///
/// QuickBooks lives at `/settings/account_management/integrations/quickbooks`
/// as a standalone sub-page outside this shell — the Integrations tab body
/// links to it. OAuth-style flows render better without competing tab chrome.
class AccountManagementShell extends StatefulWidget {
  const AccountManagementShell({super.key, this.initialTab});

  /// The `:tab` path-parameter from the route, or null on the bare URL
  /// (defaults to the Plan tab).
  final String? initialTab;

  @override
  State<AccountManagementShell> createState() => _AccountManagementShellState();
}

class _AccountManagementShellState extends State<AccountManagementShell>
    with SingleTickerProviderStateMixin {
  static const _basePath = '/settings/account_management';
  static const _tabs = <_TabDef>[
    _TabDef(slug: '', labelKey: 'plan'),
    _TabDef(slug: 'overview', labelKey: 'overview'),
    _TabDef(slug: 'enabled_modules', labelKey: 'enabled_modules'),
    _TabDef(slug: 'integrations', labelKey: 'integrations'),
    _TabDef(slug: 'security_settings', labelKey: 'security_settings'),
    _TabDef(slug: 'referral_program', labelKey: 'referral_program'),
    _TabDef(slug: 'danger_zone', labelKey: 'danger_zone'),
  ];

  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _indexForSlug(widget.initialTab),
    );
    _controller.addListener(_onTabSettled);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabSettled);
    _controller.dispose();
    super.dispose();
  }

  void _onTabSettled() {
    if (_controller.indexIsChanging) return;
    final tab = _tabs[_controller.index];
    final desired = tab.slug.isEmpty ? _basePath : '$_basePath/${tab.slug}';
    final current = GoRouterState.of(context).uri.path;
    if (current == desired) return;
    context.go(desired);
  }

  int _indexForSlug(String? slug) {
    if (slug == null || slug.isEmpty) return 0;
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].slug == slug) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller in sync if the URL changed externally (back button,
    // deep link, settings search). The `!=` guard prevents the controller
    // listener (which pushes URL updates) from looping back into another
    // `animateTo`.
    final currentTab = GoRouterState.of(context).pathParameters['tab'];
    final urlIndex = _indexForSlug(currentTab);
    if (urlIndex != _controller.index && !_controller.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (urlIndex != _controller.index) {
          _controller.animateTo(urlIndex);
        }
      });
    }

    final tokens = context.inTheme;
    return SettingsScreenScaffold(
      titleKey: 'account_management',
      bottom: TabBar(
        controller: _controller,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelColor: tokens.ink,
        unselectedLabelColor: tokens.ink3,
        indicatorColor: tokens.accent,
        indicatorWeight: 2,
        tabs: [
          for (final tab in _tabs) Tab(text: context.tr(tab.labelKey)),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        // Children are intentionally non-const: when external state changes
        // (e.g. session re-emits) and the shell rebuilds, fresh widget
        // instances let `Element.updateChild` walk into the subtree instead
        // of short-circuiting on identity.
        children: [
          AccountManagementPlanScreen(),
          AccountManagementOverviewScreen(),
          AccountManagementEnabledModulesScreen(),
          AccountManagementIntegrationsScreen(),
          AccountManagementSecuritySettingsScreen(),
          AccountManagementReferralProgramScreen(),
          AccountManagementDangerZoneScreen(),
        ],
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.slug, required this.labelKey});
  final String slug;
  final String labelKey;
}
