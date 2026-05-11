import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/account_management_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/danger_zone_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/enabled_modules_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/integrations_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/overview_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/referral_program_screen.dart';
import 'package:admin/ui/features/settings/views/basic/account_management/security_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/backup_restore_screen.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/restore_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';
import 'package:admin/ui/features/settings/views/basic/expense_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/import_export_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/custom_labels_screen.dart';
import 'package:admin/ui/features/settings/views/basic/localization/localization_screen.dart';
import 'package:admin/ui/features/settings/views/basic/online_payments_screen.dart';
import 'package:admin/ui/features/settings/views/basic/product_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/task_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/tax_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/accent_color_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/connect_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/notifications_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/password_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/preferences_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/two_factor_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/user_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings_screen.dart';
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
import 'package:admin/ui/features/settings/views/advanced/group_settings_screen.dart';
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
      child: builder(context, state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
        if (wide) return child;
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOut))
              .animate(animation),
          child: child,
        );
      },
    ),
    routes: routes,
  );
}

/// All sub-routes under `/settings`. Mounted by `router.dart` as the `routes:`
/// list of the `/settings` `GoRoute`. URL slugs match the React app (e.g.
/// `subscriptions` for Payment Links, `users` for User Management).
final List<RouteBase> settingsRoutes = [
  // ── Basic ─────────────────────────────────────────────────────────────
  _settingsRoute(
    path: 'company_details',
    builder: (_, _) => const CompanyDetailsScreen(),
    routes: [
      _settingsRoute(
        path: 'address',
        builder: (_, _) => const CompanyDetailsAddressScreen(),
      ),
      _settingsRoute(
        path: 'logo',
        builder: (_, _) => const CompanyDetailsLogoScreen(),
      ),
      _settingsRoute(
        path: 'defaults',
        builder: (_, _) => const CompanyDetailsDefaultsScreen(),
      ),
      _settingsRoute(
        path: 'documents',
        builder: (_, _) => const CompanyDetailsDocumentsScreen(),
      ),
      _settingsRoute(
        path: 'custom_fields',
        builder: (_, _) => const CompanyDetailsCustomFieldsScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'user_details',
    builder: (_, _) => const UserDetailsScreen(),
    routes: [
      _settingsRoute(
        path: 'password',
        builder: (_, _) => const UserDetailsPasswordScreen(),
      ),
      _settingsRoute(
        path: 'connect',
        builder: (_, _) => const UserDetailsConnectScreen(),
      ),
      _settingsRoute(
        path: 'enable_two_factor',
        builder: (_, _) => const UserDetailsTwoFactorScreen(),
      ),
      _settingsRoute(
        path: 'accent_color',
        builder: (_, _) => const UserDetailsAccentColorScreen(),
      ),
      _settingsRoute(
        path: 'notifications',
        builder: (_, _) => const UserDetailsNotificationsScreen(),
      ),
      _settingsRoute(
        path: 'custom_fields',
        builder: (_, _) => const UserDetailsCustomFieldsScreen(),
      ),
      _settingsRoute(
        path: 'preferences',
        builder: (_, _) => const UserDetailsPreferencesScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'localization',
    builder: (_, _) => const LocalizationScreen(),
    routes: [
      _settingsRoute(
        path: 'custom_labels',
        builder: (_, _) => const LocalizationCustomLabelsScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'online_payments',
    builder: (_, _) => const OnlinePaymentsScreen(),
  ),
  _settingsRoute(path: 'tax_settings', builder: (_, _) => const TaxSettingsScreen()),
  _settingsRoute(
    path: 'product_settings',
    builder: (_, _) => const ProductSettingsScreen(),
  ),
  _settingsRoute(path: 'task_settings', builder: (_, _) => const TaskSettingsScreen()),
  _settingsRoute(
    path: 'expense_settings',
    builder: (_, _) => const ExpenseSettingsScreen(),
  ),
  _settingsRoute(
    path: 'workflow_settings',
    builder: (_, _) => const WorkflowSettingsScreen(),
  ),
  _settingsRoute(
    path: 'account_management',
    builder: (_, _) => const AccountManagementScreen(),
    routes: [
      _settingsRoute(
        path: 'overview',
        builder: (_, _) => const AccountManagementOverviewScreen(),
      ),
      _settingsRoute(
        path: 'enabled_modules',
        builder: (_, _) => const AccountManagementEnabledModulesScreen(),
      ),
      _settingsRoute(
        path: 'integrations',
        builder: (_, _) => const AccountManagementIntegrationsScreen(),
      ),
      _settingsRoute(
        path: 'security_settings',
        builder: (_, _) => const AccountManagementSecuritySettingsScreen(),
      ),
      _settingsRoute(
        path: 'referral_program',
        builder: (_, _) => const AccountManagementReferralProgramScreen(),
      ),
      _settingsRoute(
        path: 'danger_zone',
        builder: (_, _) => const AccountManagementDangerZoneScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'backup_restore',
    builder: (_, _) => const BackupRestoreScreen(),
    routes: [
      _settingsRoute(
        path: 'restore',
        builder: (_, _) => const BackupRestoreRestoreScreen(),
      ),
    ],
  ),
  _settingsRoute(path: 'import_export', builder: (_, _) => const ImportExportScreen()),

  // ── Advanced ──────────────────────────────────────────────────────────
  _settingsRoute(
    path: 'invoice_design',
    builder: (_, _) => const InvoiceDesignScreen(),
    routes: [
      _settingsRoute(
        path: 'custom_designs',
        builder: (_, _) => const InvoiceDesignCustomDesignsScreen(),
      ),
      _settingsRoute(
        path: 'client_details',
        builder: (_, _) => const InvoiceDesignClientDetailsScreen(),
      ),
      _settingsRoute(
        path: 'company_details',
        builder: (_, _) => const InvoiceDesignCompanyDetailsScreen(),
      ),
      _settingsRoute(
        path: 'company_address',
        builder: (_, _) => const InvoiceDesignCompanyAddressScreen(),
      ),
      _settingsRoute(
        path: 'invoice_details',
        builder: (_, _) => const InvoiceDesignInvoiceDetailsScreen(),
      ),
      _settingsRoute(
        path: 'quote_details',
        builder: (_, _) => const InvoiceDesignQuoteDetailsScreen(),
      ),
      _settingsRoute(
        path: 'credit_details',
        builder: (_, _) => const InvoiceDesignCreditDetailsScreen(),
      ),
      _settingsRoute(
        path: 'vendor_details',
        builder: (_, _) => const InvoiceDesignVendorDetailsScreen(),
      ),
      _settingsRoute(
        path: 'purchase_order_details',
        builder: (_, _) => const InvoiceDesignPurchaseOrderDetailsScreen(),
      ),
      _settingsRoute(
        path: 'product_columns',
        builder: (_, _) => const InvoiceDesignProductColumnsScreen(),
      ),
      _settingsRoute(
        path: 'quote_product_columns',
        builder: (_, _) => const InvoiceDesignQuoteProductColumnsScreen(),
      ),
      _settingsRoute(
        path: 'task_columns',
        builder: (_, _) => const InvoiceDesignTaskColumnsScreen(),
      ),
      _settingsRoute(
        path: 'total_fields',
        builder: (_, _) => const InvoiceDesignTotalFieldsScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'custom_fields',
    builder: (_, _) => const CustomFieldsScreen(),
    routes: [
      _settingsRoute(
        path: 'company',
        builder: (_, _) => const CustomFieldsCompanyScreen(),
      ),
      _settingsRoute(
        path: 'clients',
        builder: (_, _) => const CustomFieldsClientsScreen(),
      ),
      _settingsRoute(
        path: 'products',
        builder: (_, _) => const CustomFieldsProductsScreen(),
      ),
      _settingsRoute(
        path: 'invoices',
        builder: (_, _) => const CustomFieldsInvoicesScreen(),
      ),
      _settingsRoute(
        path: 'payments',
        builder: (_, _) => const CustomFieldsPaymentsScreen(),
      ),
      _settingsRoute(
        path: 'projects',
        builder: (_, _) => const CustomFieldsProjectsScreen(),
      ),
      _settingsRoute(
        path: 'tasks',
        builder: (_, _) => const CustomFieldsTasksScreen(),
      ),
      _settingsRoute(
        path: 'vendors',
        builder: (_, _) => const CustomFieldsVendorsScreen(),
      ),
      _settingsRoute(
        path: 'expenses',
        builder: (_, _) => const CustomFieldsExpensesScreen(),
      ),
      _settingsRoute(
        path: 'users',
        builder: (_, _) => const CustomFieldsUsersScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'generated_numbers',
    builder: (_, _) => const GeneratedNumbersScreen(),
    routes: [
      _settingsRoute(
        path: 'clients',
        builder: (_, _) => const GeneratedNumbersClientsScreen(),
      ),
      _settingsRoute(
        path: 'invoices',
        builder: (_, _) => const GeneratedNumbersInvoicesScreen(),
      ),
      _settingsRoute(
        path: 'recurring_invoices',
        builder: (_, _) => const GeneratedNumbersRecurringInvoicesScreen(),
      ),
      _settingsRoute(
        path: 'payments',
        builder: (_, _) => const GeneratedNumbersPaymentsScreen(),
      ),
      _settingsRoute(
        path: 'quotes',
        builder: (_, _) => const GeneratedNumbersQuotesScreen(),
      ),
      _settingsRoute(
        path: 'credits',
        builder: (_, _) => const GeneratedNumbersCreditsScreen(),
      ),
      _settingsRoute(
        path: 'projects',
        builder: (_, _) => const GeneratedNumbersProjectsScreen(),
      ),
      _settingsRoute(
        path: 'tasks',
        builder: (_, _) => const GeneratedNumbersTasksScreen(),
      ),
      _settingsRoute(
        path: 'vendors',
        builder: (_, _) => const GeneratedNumbersVendorsScreen(),
      ),
      _settingsRoute(
        path: 'purchase_orders',
        builder: (_, _) => const GeneratedNumbersPurchaseOrdersScreen(),
      ),
      _settingsRoute(
        path: 'expenses',
        builder: (_, _) => const GeneratedNumbersExpensesScreen(),
      ),
      _settingsRoute(
        path: 'recurring_expenses',
        builder: (_, _) => const GeneratedNumbersRecurringExpensesScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'client_portal',
    builder: (_, _) => const ClientPortalScreen(),
    routes: [
      _settingsRoute(
        path: 'authorization',
        builder: (_, _) => const ClientPortalAuthorizationScreen(),
      ),
      _settingsRoute(
        path: 'registration',
        builder: (_, _) => const ClientPortalRegistrationScreen(),
      ),
      _settingsRoute(
        path: 'messages',
        builder: (_, _) => const ClientPortalMessagesScreen(),
      ),
      _settingsRoute(
        path: 'customize',
        builder: (_, _) => const ClientPortalCustomizeScreen(),
      ),
    ],
  ),
  _settingsRoute(path: 'e_invoice', builder: (_, _) => const EInvoiceScreen()),
  _settingsRoute(
    path: 'email_settings',
    builder: (_, _) => const EmailSettingsScreen(),
  ),
  _settingsRoute(
    path: 'templates_and_reminders',
    builder: (_, _) => const TemplatesRemindersScreen(),
  ),
  _settingsRoute(
    path: 'bank_accounts',
    builder: (_, _) => const BankAccountsScreen(),
    routes: [
      _settingsRoute(
        path: 'transaction_rules',
        builder: (_, _) => const BankAccountsTransactionRulesScreen(),
      ),
    ],
  ),
  _settingsRoute(
    path: 'group_settings',
    builder: (_, _) => const GroupSettingsScreen(),
  ),
  _settingsRoute(path: 'subscriptions', builder: (_, _) => const PaymentLinksScreen()),
  _settingsRoute(path: 'schedules', builder: (_, _) => const SchedulesScreen()),
  _settingsRoute(path: 'users', builder: (_, _) => const UserManagementScreen()),
  _settingsRoute(path: 'system_logs', builder: (_, _) => const SystemLogsScreen()),
  _settingsRoute(
    path: 'integrations',
    builder: (_, _) => const IntegrationsScreen(),
    routes: [
      _settingsRoute(
        path: 'api_tokens',
        builder: (_, _) => const IntegrationsApiTokensScreen(),
      ),
      _settingsRoute(
        path: 'api_webhooks',
        builder: (_, _) => const IntegrationsApiWebhooksScreen(),
      ),
      _settingsRoute(
        path: 'analytics',
        builder: (_, _) => const IntegrationsAnalyticsScreen(),
      ),
    ],
  ),
];
