import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Master list of settings sections — pure list, no `Scaffold`. Used as the
/// left pane on wide screens (mounted by `SettingsShell`) and as the body of
/// `SettingsScreen` on narrow screens. Reads the current go_router location
/// to highlight whichever top-level section is active.
class SettingsListSidebar extends StatelessWidget {
  const SettingsListSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final activeSlug = _activeSlug(GoRouterState.of(context).uri.path);
    return ListView(
      children: [
        _GroupHeader(context.tr('basic_settings')),
        for (final t in _basicTiles) _tile(context, t, activeSlug),
        const Divider(height: 1),
        _GroupHeader(context.tr('advanced_settings')),
        for (final t in _advancedTiles) _tile(context, t, activeSlug),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _tile(BuildContext context, _SettingsTile t, String? activeSlug) {
    final tokens = context.inTheme;
    final selected = t.slug == activeSlug;
    return ListTile(
      leading: Icon(t.icon),
      title: Text(context.tr(t.titleKey)),
      selected: selected,
      selectedTileColor: tokens.accentSoft,
      // Drives both leading icon + title color when `selected` is true.
      // Matches the SidebarNavItem active-state pattern.
      selectedColor: tokens.accentInk,
      iconColor: tokens.ink3,
      textColor: tokens.ink2,
      onTap: () => context.go(t.route),
    );
  }

  /// Extract the top-level section slug from a path like
  /// `/settings/user_details/preferences` → `user_details`. Returns null when
  /// the user is on `/settings` itself (no section selected).
  static String? _activeSlug(String path) {
    if (!path.startsWith('/settings')) return null;
    final rest = path.substring('/settings'.length);
    if (rest.isEmpty || rest == '/') return null;
    final segments = rest.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.first;
  }
}

/// Narrow-only route target for `/settings`. On wide screens the shell shows
/// `SettingsListSidebar` directly in the left pane, so this screen never gets
/// rendered — but it remains the route's `builder` so the back-button on
/// narrow lands on the list cleanly.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('settings')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: const SettingsListSidebar(),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile {
  const _SettingsTile(this.titleKey, this.icon, this.route);
  // Localization key for the tile's title. Resolve via `context.tr(titleKey)`.
  final String titleKey;
  final IconData icon;
  final String route;

  /// `user_details` from `/settings/user_details`.
  String get slug => route.replaceFirst('/settings/', '').split('/').first;
}

const _basicTiles = <_SettingsTile>[
  _SettingsTile(
    'company_details',
    Icons.business_outlined,
    '/settings/company_details',
  ),
  _SettingsTile('user_details', Icons.person_outline, '/settings/user_details'),
  _SettingsTile(
    'localization',
    Icons.language_outlined,
    '/settings/localization',
  ),
  _SettingsTile(
    'online_payments',
    Icons.payments_outlined,
    '/settings/online_payments',
  ),
  _SettingsTile(
    'tax_settings',
    Icons.percent_outlined,
    '/settings/tax_settings',
  ),
  _SettingsTile(
    'product_settings',
    Icons.inventory_2_outlined,
    '/settings/product_settings',
  ),
  _SettingsTile(
    'task_settings',
    Icons.task_alt_outlined,
    '/settings/task_settings',
  ),
  _SettingsTile(
    'expense_settings',
    Icons.receipt_long_outlined,
    '/settings/expense_settings',
  ),
  _SettingsTile(
    'workflow_settings',
    Icons.account_tree_outlined,
    '/settings/workflow_settings',
  ),
  _SettingsTile(
    'account_management',
    Icons.manage_accounts_outlined,
    '/settings/account_management',
  ),
  _SettingsTile(
    'backup_restore',
    Icons.backup_outlined,
    '/settings/backup_restore',
  ),
  _SettingsTile(
    'import_export',
    Icons.import_export_outlined,
    '/settings/import_export',
  ),
];

const _advancedTiles = <_SettingsTile>[
  _SettingsTile(
    'invoice_design',
    Icons.design_services_outlined,
    '/settings/invoice_design',
  ),
  _SettingsTile(
    'custom_fields',
    Icons.edit_note_outlined,
    '/settings/custom_fields',
  ),
  _SettingsTile(
    'generated_numbers',
    Icons.format_list_numbered,
    '/settings/generated_numbers',
  ),
  _SettingsTile('client_portal', Icons.web_outlined, '/settings/client_portal'),
  _SettingsTile(
    'e_invoice',
    Icons.electric_bolt_outlined,
    '/settings/e_invoice',
  ),
  _SettingsTile(
    'email_settings',
    Icons.mail_outline,
    '/settings/email_settings',
  ),
  _SettingsTile(
    'templates_and_reminders',
    Icons.notifications_outlined,
    '/settings/templates_and_reminders',
  ),
  _SettingsTile(
    'bank_accounts',
    Icons.account_balance_outlined,
    '/settings/bank_accounts',
  ),
  _SettingsTile(
    'group_settings',
    Icons.group_work_outlined,
    '/settings/group_settings',
  ),
  _SettingsTile(
    'payment_links',
    Icons.link_outlined,
    '/settings/subscriptions',
  ),
  _SettingsTile('schedules', Icons.schedule_outlined, '/settings/schedules'),
  _SettingsTile(
    'user_management',
    Icons.supervised_user_circle_outlined,
    '/settings/users',
  ),
  _SettingsTile(
    'system_logs',
    Icons.terminal_outlined,
    '/settings/system_logs',
  ),
  _SettingsTile(
    'integrations',
    Icons.extension_outlined,
    '/settings/integrations',
  ),
];
