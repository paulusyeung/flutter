import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/account_management_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/danger_zone_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/enabled_modules_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/integrations_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/overview_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/referral_program_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/security_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/backup_restore_screen.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/restore_screen.dart';
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
import 'package:admin/ui/features/settings/views/advanced/bank_accounts/bank_accounts_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/bank_accounts/transaction_rules_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/authorization_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/client_portal_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/customize_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/messages_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/client_portal/registration_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/clients_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/company_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/expenses_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/invoices_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/payments_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/products_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/projects_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/tasks_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/users_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/vendors_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/email_settings_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/clients_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/credits_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/expenses_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/generated_numbers_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/invoices_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/payments_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/projects_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/purchase_orders_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/quotes_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/recurring_expenses_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/recurring_invoices_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/tasks_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/vendors_screen.dart';
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
import 'package:admin/ui/features/settings/views/advanced/invoice_design/client_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/company_address_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/credit_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/custom_designs_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/invoice_design_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/invoice_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/product_columns_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/purchase_order_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/quote_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/quote_product_columns_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/task_columns_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/total_fields_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/vendor_details_screen.dart';
import 'package:admin/ui/features/settings/views/advanced/payment_links_screen.dart';
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
/// list of the `/settings` `GoRoute`. URL slugs match the React app (e.g.
/// `subscriptions` for Payment Links, `users` for User Management).
final List<RouteBase> settingsRoutes = [
  // ── Basic ─────────────────────────────────────────────────────────────
  // Company Details is one shell with 6 tabs in a TabBarView. The bare URL
  // and the per-tab URL share a page key (see `tabbedSettingsRoutePair`) so
  // they resolve to a single, persistent Navigator Page — clicking a tab
  // from the bare URL doesn't remount the shell.
  ...tabbedSettingsRoutePair(
    path: 'company_details',
    pageKey: 'company_details_shell',
    tabSlugs: const [
      'address',
      'logo',
      'defaults',
      'documents',
      'custom_fields',
    ],
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
  _settingsRoute(
    path: 'account_management',
    builder: (_, _) => const AccountManagementScreen(),
    routes: [
      _leaf('overview', () => const AccountManagementOverviewScreen()),
      _leaf(
        'enabled_modules',
        () => const AccountManagementEnabledModulesScreen(),
      ),
      _leaf('integrations', () => const AccountManagementIntegrationsScreen()),
      _leaf(
        'security_settings',
        () => const AccountManagementSecuritySettingsScreen(),
      ),
      _leaf(
        'referral_program',
        () => const AccountManagementReferralProgramScreen(),
      ),
      _leaf('danger_zone', () => const AccountManagementDangerZoneScreen()),
    ],
  ),
  _settingsRoute(
    path: 'backup_restore',
    builder: (_, _) => const BackupRestoreScreen(),
    routes: [_leaf('restore', () => const BackupRestoreRestoreScreen())],
  ),
  _leaf('import_export', () => const ImportExportScreen()),
  _leaf('device_settings', () => const DeviceSettingsScreen()),

  // ── Advanced ──────────────────────────────────────────────────────────
  _settingsRoute(
    path: 'invoice_design',
    builder: (_, _) => const InvoiceDesignScreen(),
    routes: [
      _leaf('custom_designs', () => const InvoiceDesignCustomDesignsScreen()),
      _leaf('client_details', () => const InvoiceDesignClientDetailsScreen()),
      _leaf('company_details', () => const InvoiceDesignCompanyDetailsScreen()),
      _leaf('company_address', () => const InvoiceDesignCompanyAddressScreen()),
      _leaf('invoice_details', () => const InvoiceDesignInvoiceDetailsScreen()),
      _leaf('quote_details', () => const InvoiceDesignQuoteDetailsScreen()),
      _leaf('credit_details', () => const InvoiceDesignCreditDetailsScreen()),
      _leaf('vendor_details', () => const InvoiceDesignVendorDetailsScreen()),
      _leaf(
        'purchase_order_details',
        () => const InvoiceDesignPurchaseOrderDetailsScreen(),
      ),
      _leaf('product_columns', () => const InvoiceDesignProductColumnsScreen()),
      _leaf(
        'quote_product_columns',
        () => const InvoiceDesignQuoteProductColumnsScreen(),
      ),
      _leaf('task_columns', () => const InvoiceDesignTaskColumnsScreen()),
      _leaf('total_fields', () => const InvoiceDesignTotalFieldsScreen()),
    ],
  ),
  _settingsRoute(
    path: 'custom_fields',
    builder: (_, _) => const CustomFieldsScreen(),
    routes: [
      _leaf('company', () => const CustomFieldsCompanyScreen()),
      _leaf('clients', () => const CustomFieldsClientsScreen()),
      _leaf('products', () => const CustomFieldsProductsScreen()),
      _leaf('invoices', () => const CustomFieldsInvoicesScreen()),
      _leaf('payments', () => const CustomFieldsPaymentsScreen()),
      _leaf('projects', () => const CustomFieldsProjectsScreen()),
      _leaf('tasks', () => const CustomFieldsTasksScreen()),
      _leaf('vendors', () => const CustomFieldsVendorsScreen()),
      _leaf('expenses', () => const CustomFieldsExpensesScreen()),
      _leaf('users', () => const CustomFieldsUsersScreen()),
    ],
  ),
  _settingsRoute(
    path: 'generated_numbers',
    builder: (_, _) => const GeneratedNumbersScreen(),
    routes: [
      _leaf('clients', () => const GeneratedNumbersClientsScreen()),
      _leaf('invoices', () => const GeneratedNumbersInvoicesScreen()),
      _leaf(
        'recurring_invoices',
        () => const GeneratedNumbersRecurringInvoicesScreen(),
      ),
      _leaf('payments', () => const GeneratedNumbersPaymentsScreen()),
      _leaf('quotes', () => const GeneratedNumbersQuotesScreen()),
      _leaf('credits', () => const GeneratedNumbersCreditsScreen()),
      _leaf('projects', () => const GeneratedNumbersProjectsScreen()),
      _leaf('tasks', () => const GeneratedNumbersTasksScreen()),
      _leaf('vendors', () => const GeneratedNumbersVendorsScreen()),
      _leaf(
        'purchase_orders',
        () => const GeneratedNumbersPurchaseOrdersScreen(),
      ),
      _leaf('expenses', () => const GeneratedNumbersExpensesScreen()),
      _leaf(
        'recurring_expenses',
        () => const GeneratedNumbersRecurringExpensesScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'client_portal',
    builder: (_, _) => const ClientPortalScreen(),
    routes: [
      _leaf('authorization', () => const ClientPortalAuthorizationScreen()),
      _leaf('registration', () => const ClientPortalRegistrationScreen()),
      _leaf('messages', () => const ClientPortalMessagesScreen()),
      _leaf('customize', () => const ClientPortalCustomizeScreen()),
    ],
  ),
  _leaf('e_invoice', () => const EInvoiceScreen()),
  _leaf('email_settings', () => const EmailSettingsScreen()),
  _leaf('templates_and_reminders', () => const TemplatesRemindersScreen()),
  _settingsRoute(
    path: 'bank_accounts',
    builder: (_, _) => const BankAccountsScreen(),
    routes: [
      _leaf(
        'transaction_rules',
        () => const BankAccountsTransactionRulesScreen(),
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
  _leaf('subscriptions', () => const PaymentLinksScreen()),
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
