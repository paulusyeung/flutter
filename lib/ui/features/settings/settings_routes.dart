import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/account_management_shell.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/quickbooks_screen.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/backup_restore_shell.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_shell.dart';
import 'package:admin/ui/features/settings/views/basic/expense_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/device_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/import_export_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_shell.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_detail_screen.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_edit_screen.dart';
import 'package:admin/ui/features/gateways/views/company_gateway_list_screen.dart';
import 'package:admin/ui/features/settings/views/basic/online_payments_screen.dart';
import 'package:admin/ui/features/settings/views/basic/product_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/task_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/tax_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/user_details_shell.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_shell.dart';
import 'package:admin/ui/features/bank_accounts/views/bank_account_edit_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/bank_accounts/bank_accounts_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/bank_accounts/transaction_rules_screen.dart';
import 'package:admin/ui/features/transaction_rules/views/transaction_rule_edit_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/client_portal_shell.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/custom_fields_shell.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/email_settings_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/generated_numbers_shell.dart';
import 'package:admin/ui/features/settings/views/advanced/group_settings_edit_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/group_settings_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/payment_terms_edit_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/payment_terms_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/task_statuses_edit_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/task_statuses_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/integrations/analytics_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/integrations/api_tokens_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/integrations/api_webhooks_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/integrations/integrations_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/invoice_design_shell.dart';
import 'package:admin/ui/features/settings/views/advanced/schedules_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/system_logs_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/user_management_screen.dart';

/// Wraps a settings route's child in a [KeyedSubtree] whose key encodes the
/// current `(level, targetId)` from [SettingsLevelController]. When the
/// scope flips (e.g. the scope banner's close button calls
/// `controller.reset()`), the key changes and the inner screen remounts
/// — its `initState` then rebuilds the view-model against the new level.
///
/// Without this, screens that capture the scope once in `initState`
/// (every settings screen today) would keep saving to the previous scope
/// after the level changed. With this wrapper, the route stays at the
/// same URL while the content swaps, so closing the banner keeps the
/// user on the same sub-page.
class _SettingsLevelKeyed extends StatelessWidget {
  const _SettingsLevelKeyed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SettingsLevelController>();
    return KeyedSubtree(
      key: ValueKey('${ctrl.level.name}:${ctrl.targetId ?? ''}'),
      child: child,
    );
  }
}

/// Drop-in replacement for `GoRoute(builder: ...)` that swaps the default
/// `MaterialPage` slide for a viewport-aware transition:
///   * **wide** (≥ `Breakpoints.wide`): no transition — the persistent left
///     sidebar makes navigation feel like content replacement, not a push.
///   * **narrow**: standard right-to-left slide so the stack-style narrow nav
///     still feels right.
/// `MediaQuery` can't be read in `pageBuilder` (no `BuildContext` is mounted
/// yet), so the size check happens inside `transitionsBuilder`.
GoRoute _settingsRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  List<RouteBase> routes = const [],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: _SettingsLevelKeyed(child: builder(context, state)),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
        if (wide) return child;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
          child: child,
        );
      },
    ),
    routes: routes,
  );
}

/// One-line shorthand for the dominant pattern: a leaf settings route with no
/// children. Equivalent to `_settingsRoute(path: path, builder: (_, _) =>
/// child())` — the closure is required so the widget can stay `const` at the
/// call site without forcing every entry to spell out the typed lambda.
GoRoute _leaf(String path, Widget Function() child) =>
    _settingsRoute(path: path, builder: (_, _) => child());

/// Route pair for a tabbed settings shell — registers `/settings/<path>` and
/// `/settings/<path>/:tab(<slugs>)` against a single [CustomTransitionPage]
/// builder so both routes resolve to the same Navigator Page. The constant
/// [ValueKey] keyed by [pageKey] is what keeps the shell's Element (its
/// `TabController`, draft VM, in-progress swipe) alive across the two paths;
/// without it, clicking a tab from the bare URL would remount the shell.
///
/// Pairs with [TabbedSettingsShell] in
/// `lib/ui/features/settings/widgets/tabbed_settings_shell.dart` — the shell
/// reads `:tab` off the route, the route trusts the shell to keep
/// [TabController] aligned. Both halves are required.
List<RouteBase> tabbedSettingsRoutePair({
  required String path,
  required String pageKey,
  required List<String> tabSlugs,
  required Widget Function(String? initialTab) shellBuilder,
}) {
  CustomTransitionPage<void> pageBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return CustomTransitionPage<void>(
      key: ValueKey(pageKey),
      child: _SettingsLevelKeyed(
        child: shellBuilder(state.pathParameters['tab']),
      ),
      transitionsBuilder: (context, animation, _, child) {
        final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
        if (wide) return child;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
          child: child,
        );
      },
    );
  }

  return [
    GoRoute(path: path, pageBuilder: pageBuilder),
    GoRoute(
      path: '$path/:tab(${tabSlugs.join('|')})',
      pageBuilder: pageBuilder,
    ),
  ];
}

/// All sub-routes under `/settings`. Mounted by `router.dart` as the `routes:`
/// list of the `/settings` `GoRoute`. URL slugs are user-facing (e.g.
/// `payment_links`, `users` for User Management).
final List<RouteBase> settingsRoutes = [
  // ── Basic ─────────────────────────────────────────────────────────────
  // Company Details is one shell with 6 tabs in a TabBarView. The bare URL
  // and the per-tab URL share a page key (see `tabbedSettingsRoutePair`) so
  // they resolve to a single, persistent Navigator Page — clicking a tab
  // from the bare URL doesn't remount the shell.
  ...tabbedSettingsRoutePair(
    path: 'company_details',
    pageKey: 'company_details_shell',
    tabSlugs: const ['address', 'logo', 'defaults', 'documents'],
    shellBuilder: (initialTab) => CompanyDetailsShell(initialTab: initialTab),
  ),
  ...tabbedSettingsRoutePair(
    path: 'user_details',
    pageKey: 'user_details_shell',
    tabSlugs: const [
      'password',
      'connect',
      'enable_two_factor',
      'notifications',
      'preferences',
    ],
    shellBuilder: (initialTab) => UserDetailsShell(initialTab: initialTab),
  ),
  // Localization is one shell with two tabs (Settings, Custom Labels), shared
  // page key so the bare URL and `/custom_labels` resolve to the same
  // Navigator Page — keeps the cascade VM + TabController alive across the
  // two paths.
  ...tabbedSettingsRoutePair(
    path: 'localization',
    pageKey: 'localization_shell',
    tabSlugs: const ['custom_labels'],
    shellBuilder: (initialTab) => LocalizationShell(initialTab: initialTab),
  ),
  // Online Payments is one shell with three tabs (General / Defaults /
  // Emails) on narrow widths, and a single stacked page on wide. The bare URL
  // and `/defaults` + `/emails` share a page key (see `tabbedSettingsRoutePair`)
  // so they resolve to the same Navigator Page — clicking a tab from the bare
  // URL doesn't remount the shell.
  ...tabbedSettingsRoutePair(
    path: 'online_payments',
    pageKey: 'online_payments_shell',
    tabSlugs: const ['defaults', 'emails'],
    shellBuilder: (initialTab) => OnlinePaymentsScreen(initialTab: initialTab),
  ),
  _settingsRoute(
    path: 'company_gateways',
    builder: (_, _) => const CompanyGatewayListScreen(),
    routes: [
      _leaf('new', () => const CompanyGatewayEditScreen()),
      _settingsRoute(
        path: ':id',
        builder: (_, state) =>
            CompanyGatewayDetailScreen(id: state.pathParameters['id']!),
        routes: [
          _settingsRoute(
            path: 'edit',
            builder: (_, state) => CompanyGatewayEditScreen(
              existingId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
    ],
  ),
  _leaf('tax_settings', () => const TaxSettingsScreen()),
  _leaf('product_settings', () => const ProductSettingsScreen()),
  _leaf('task_settings', () => const TaskSettingsScreen()),
  _leaf('expense_settings', () => const ExpenseSettingsScreen()),
  // Workflow Settings is one shell with two tabs (Invoices / Quotes), shared
  // page key so the bare URL and `/quotes` resolve to the same Navigator Page
  // — keeps the cascade VM + TabController alive across the two paths.
  ...tabbedSettingsRoutePair(
    path: 'workflow_settings',
    pageKey: 'workflow_settings_shell',
    tabSlugs: const ['quotes'],
    shellBuilder: (initialTab) =>
        WorkflowSettingsShell(initialTab: initialTab),
  ),
  // Account Management is one shell with seven URL-driven tabs (Plan default,
  // Overview / Enabled Modules / Integrations / Security Settings / Referral
  // Program / Danger Zone). Shared page key keeps the TabController + each
  // tab's local state alive across navigations. The QuickBooks sub-page lives
  // outside the shell (focused OAuth-style flow without competing nav chrome).
  ...tabbedSettingsRoutePair(
    path: 'account_management',
    pageKey: 'account_management_shell',
    tabSlugs: const [
      'overview',
      'enabled_modules',
      'integrations',
      'security_settings',
      'referral_program',
      'danger_zone',
    ],
    shellBuilder: (initialTab) =>
        AccountManagementShell(initialTab: initialTab),
  ),
  _leaf(
    'account_management/integrations/quickbooks',
    () => const QuickbooksScreen(),
  ),
  // Backup | Restore is a single shell with two URL-driven tabs. Bare URL
  // resolves to the Backup tab; `/restore` to the Restore tab. Shared page
  // key (see `tabbedSettingsRoutePair`) keeps the shell's TabController + the
  // Restore tab's in-progress upload state alive across the two paths.
  ...tabbedSettingsRoutePair(
    path: 'backup_restore',
    pageKey: 'backup_restore_shell',
    tabSlugs: const ['restore'],
    shellBuilder: (initialTab) => BackupRestoreShell(initialTab: initialTab),
  ),
  _leaf('import_export', () => const ImportExportScreen()),
  _leaf('device_settings', () => const DeviceSettingsScreen()),

  // ── Advanced ──────────────────────────────────────────────────────────
  // Invoice Design is one shell with a tab per PDF-variable section + a
  // General Settings tab + Custom Designs. Shared page key so the bare URL
  // and each `/<slug>` resolve to the same Navigator Page — keeps the
  // cascade VM + TabController alive across tab clicks.
  ...tabbedSettingsRoutePair(
    path: 'invoice_design',
    pageKey: 'invoice_design_shell',
    tabSlugs: const [
      'client_details',
      'company_details',
      'company_address',
      'invoice_details',
      'quote_details',
      'credit_details',
      'vendor_details',
      'purchase_order_details',
      'product_columns',
      'product_quote_columns',
      'task_columns',
      'total_columns',
      'custom_designs',
    ],
    shellBuilder: (initialTab) =>
        InvoiceDesignShell(initialTab: initialTab),
  ),
  // Custom Fields is one shell with N module-gated tabs (Company / Clients /
  // Products / Invoices / Payments / Projects / Tasks / Vendors / Expenses /
  // Users). The bare URL and per-tab URL share a page key (see
  // `tabbedSettingsRoutePair`) so flipping tabs doesn't remount the shell —
  // the dynamic-tabs custom shell still derives `:tab` off the route, so the
  // pair helper here just registers both URLs against one Navigator page.
  // Module-disabled slugs (e.g. `tasks` when the Tasks module is off) stay
  // in `tabSlugs` so deep links resolve; the shell falls back to the first
  // visible tab in that case.
  ...tabbedSettingsRoutePair(
    path: 'custom_fields',
    pageKey: 'custom_fields_shell',
    tabSlugs: const [
      'clients',
      'products',
      'invoices',
      'payments',
      'projects',
      'tasks',
      'vendors',
      'expenses',
      'users',
    ],
    shellBuilder: (initialTab) => CustomFieldsShell(initialTab: initialTab),
  ),
  // Generated Numbers is a tabbed cascade shell — the parent and per-tab
  // URLs share a page key (see `tabbedSettingsRoutePair`) so flipping tabs
  // doesn't remount the shell or its draft VM. Module-disabled slugs (e.g.
  // `tasks` when the Tasks module is off) stay in `tabSlugs` so deep links
  // resolve; the shell falls back to the first visible tab.
  ...tabbedSettingsRoutePair(
    path: 'generated_numbers',
    pageKey: 'generated_numbers_shell',
    tabSlugs: const [
      'clients',
      'invoices',
      'recurring_invoices',
      'payments',
      'quotes',
      'credits',
      'projects',
      'tasks',
      'vendors',
      'purchase_orders',
      'expenses',
      'recurring_expenses',
    ],
    shellBuilder: (initialTab) =>
        GeneratedNumbersShell(initialTab: initialTab),
  ),
  ...tabbedSettingsRoutePair(
    path: 'client_portal',
    pageKey: 'client_portal',
    tabSlugs: const ['authorization', 'registration', 'messages', 'customize'],
    shellBuilder: (initialTab) => ClientPortalShell(initialTab: initialTab),
  ),
  _leaf('e_invoice', () => const EInvoiceScreen()),
  _leaf('email_settings', () => const EmailSettingsScreen()),
  _leaf('templates_and_reminders', () => const TemplatesRemindersScreen()),
  _settingsRoute(
    path: 'bank_accounts',
    builder: (_, _) => const BankAccountsScreen(),
    routes: [
      _leaf('new', () => const BankAccountEditScreen()),
      _settingsRoute(
        path: 'transaction_rules',
        builder: (_, _) => const BankAccountsTransactionRulesScreen(),
        routes: [
          _leaf('new', () => const TransactionRuleEditScreen()),
          _settingsRoute(
            path: ':id',
            builder: (_, state) => TransactionRuleEditScreen(
              existingId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      _settingsRoute(
        path: ':id',
        builder: (_, state) => BankAccountEditScreen(
          existingId: state.pathParameters['id'],
        ),
      ),
    ],
  ),
  _settingsRoute(
    path: 'group_settings',
    builder: (_, _) => const GroupSettingsScreen(),
    routes: [
      _leaf('new', () => const GroupSettingsEditScreen()),
      _settingsRoute(
        path: ':id',
        builder: (_, state) =>
            GroupSettingsEditScreen(existingId: state.pathParameters['id']),
      ),
    ],
  ),
  _settingsRoute(
    path: 'task_statuses',
    builder: (_, _) => const TaskStatusesScreen(),
    routes: [
      _leaf('new', () => const TaskStatusesEditScreen()),
      _settingsRoute(
        path: ':id',
        builder: (_, state) =>
            TaskStatusesEditScreen(existingId: state.pathParameters['id']),
      ),
    ],
  ),
  _settingsRoute(
    path: 'payment_terms',
    builder: (_, _) => const PaymentTermsScreen(),
    routes: [
      _leaf('new', () => const PaymentTermsEditScreen()),
      _settingsRoute(
        path: ':id',
        builder: (_, state) =>
            PaymentTermsEditScreen(existingId: state.pathParameters['id']),
      ),
    ],
  ),
  // Payment Links — fully entity-managed via `kWiredEntityModules`. The
  // entity registry installs `/settings/payment_links[/new|/:id|/:id/edit]`
  // automatically; no `_leaf(...)` placeholder needed.
  _leaf('schedules', () => const SchedulesScreen()),
  _leaf('users', () => const UserManagementScreen()),
  _leaf('system_logs', () => const SystemLogsScreen()),
  _settingsRoute(
    path: 'integrations',
    builder: (_, _) => const IntegrationsScreen(),
    routes: [
      _leaf('api_tokens', () => const IntegrationsApiTokensScreen()),
      _leaf('api_webhooks', () => const IntegrationsApiWebhooksScreen()),
      _leaf('analytics', () => const IntegrationsAnalyticsScreen()),
    ],
  ),
];
