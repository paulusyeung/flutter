import 'package:go_router/go_router.dart';

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

/// All sub-routes under `/settings`. Mounted by `router.dart` as the `routes:`
/// list of the `/settings` `GoRoute`. URL slugs match the React app (e.g.
/// `subscriptions` for Payment Links, `users` for User Management).
final List<RouteBase> settingsRoutes = [
  // ── Basic ─────────────────────────────────────────────────────────────
  GoRoute(
    path: 'company_details',
    builder: (_, _) => const CompanyDetailsScreen(),
    routes: [
      GoRoute(
        path: 'address',
        builder: (_, _) => const CompanyDetailsAddressScreen(),
      ),
      GoRoute(
        path: 'logo',
        builder: (_, _) => const CompanyDetailsLogoScreen(),
      ),
      GoRoute(
        path: 'defaults',
        builder: (_, _) => const CompanyDetailsDefaultsScreen(),
      ),
      GoRoute(
        path: 'documents',
        builder: (_, _) => const CompanyDetailsDocumentsScreen(),
      ),
      GoRoute(
        path: 'custom_fields',
        builder: (_, _) => const CompanyDetailsCustomFieldsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'user_details',
    builder: (_, _) => const UserDetailsScreen(),
    routes: [
      GoRoute(
        path: 'password',
        builder: (_, _) => const UserDetailsPasswordScreen(),
      ),
      GoRoute(
        path: 'connect',
        builder: (_, _) => const UserDetailsConnectScreen(),
      ),
      GoRoute(
        path: 'enable_two_factor',
        builder: (_, _) => const UserDetailsTwoFactorScreen(),
      ),
      GoRoute(
        path: 'accent_color',
        builder: (_, _) => const UserDetailsAccentColorScreen(),
      ),
      GoRoute(
        path: 'notifications',
        builder: (_, _) => const UserDetailsNotificationsScreen(),
      ),
      GoRoute(
        path: 'custom_fields',
        builder: (_, _) => const UserDetailsCustomFieldsScreen(),
      ),
      GoRoute(
        path: 'preferences',
        builder: (_, _) => const UserDetailsPreferencesScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'localization',
    builder: (_, _) => const LocalizationScreen(),
    routes: [
      GoRoute(
        path: 'custom_labels',
        builder: (_, _) => const LocalizationCustomLabelsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'online_payments',
    builder: (_, _) => const OnlinePaymentsScreen(),
  ),
  GoRoute(path: 'tax_settings', builder: (_, _) => const TaxSettingsScreen()),
  GoRoute(
    path: 'product_settings',
    builder: (_, _) => const ProductSettingsScreen(),
  ),
  GoRoute(path: 'task_settings', builder: (_, _) => const TaskSettingsScreen()),
  GoRoute(
    path: 'expense_settings',
    builder: (_, _) => const ExpenseSettingsScreen(),
  ),
  GoRoute(
    path: 'workflow_settings',
    builder: (_, _) => const WorkflowSettingsScreen(),
  ),
  GoRoute(
    path: 'account_management',
    builder: (_, _) => const AccountManagementScreen(),
    routes: [
      GoRoute(
        path: 'overview',
        builder: (_, _) => const AccountManagementOverviewScreen(),
      ),
      GoRoute(
        path: 'enabled_modules',
        builder: (_, _) => const AccountManagementEnabledModulesScreen(),
      ),
      GoRoute(
        path: 'integrations',
        builder: (_, _) => const AccountManagementIntegrationsScreen(),
      ),
      GoRoute(
        path: 'security_settings',
        builder: (_, _) => const AccountManagementSecuritySettingsScreen(),
      ),
      GoRoute(
        path: 'referral_program',
        builder: (_, _) => const AccountManagementReferralProgramScreen(),
      ),
      GoRoute(
        path: 'danger_zone',
        builder: (_, _) => const AccountManagementDangerZoneScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'backup_restore',
    builder: (_, _) => const BackupRestoreScreen(),
    routes: [
      GoRoute(
        path: 'restore',
        builder: (_, _) => const BackupRestoreRestoreScreen(),
      ),
    ],
  ),
  GoRoute(path: 'import_export', builder: (_, _) => const ImportExportScreen()),

  // ── Advanced ──────────────────────────────────────────────────────────
  GoRoute(
    path: 'invoice_design',
    builder: (_, _) => const InvoiceDesignScreen(),
    routes: [
      GoRoute(
        path: 'custom_designs',
        builder: (_, _) => const InvoiceDesignCustomDesignsScreen(),
      ),
      GoRoute(
        path: 'client_details',
        builder: (_, _) => const InvoiceDesignClientDetailsScreen(),
      ),
      GoRoute(
        path: 'company_details',
        builder: (_, _) => const InvoiceDesignCompanyDetailsScreen(),
      ),
      GoRoute(
        path: 'company_address',
        builder: (_, _) => const InvoiceDesignCompanyAddressScreen(),
      ),
      GoRoute(
        path: 'invoice_details',
        builder: (_, _) => const InvoiceDesignInvoiceDetailsScreen(),
      ),
      GoRoute(
        path: 'quote_details',
        builder: (_, _) => const InvoiceDesignQuoteDetailsScreen(),
      ),
      GoRoute(
        path: 'credit_details',
        builder: (_, _) => const InvoiceDesignCreditDetailsScreen(),
      ),
      GoRoute(
        path: 'vendor_details',
        builder: (_, _) => const InvoiceDesignVendorDetailsScreen(),
      ),
      GoRoute(
        path: 'purchase_order_details',
        builder: (_, _) => const InvoiceDesignPurchaseOrderDetailsScreen(),
      ),
      GoRoute(
        path: 'product_columns',
        builder: (_, _) => const InvoiceDesignProductColumnsScreen(),
      ),
      GoRoute(
        path: 'quote_product_columns',
        builder: (_, _) => const InvoiceDesignQuoteProductColumnsScreen(),
      ),
      GoRoute(
        path: 'task_columns',
        builder: (_, _) => const InvoiceDesignTaskColumnsScreen(),
      ),
      GoRoute(
        path: 'total_fields',
        builder: (_, _) => const InvoiceDesignTotalFieldsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'custom_fields',
    builder: (_, _) => const CustomFieldsScreen(),
    routes: [
      GoRoute(
        path: 'company',
        builder: (_, _) => const CustomFieldsCompanyScreen(),
      ),
      GoRoute(
        path: 'clients',
        builder: (_, _) => const CustomFieldsClientsScreen(),
      ),
      GoRoute(
        path: 'products',
        builder: (_, _) => const CustomFieldsProductsScreen(),
      ),
      GoRoute(
        path: 'invoices',
        builder: (_, _) => const CustomFieldsInvoicesScreen(),
      ),
      GoRoute(
        path: 'payments',
        builder: (_, _) => const CustomFieldsPaymentsScreen(),
      ),
      GoRoute(
        path: 'projects',
        builder: (_, _) => const CustomFieldsProjectsScreen(),
      ),
      GoRoute(
        path: 'tasks',
        builder: (_, _) => const CustomFieldsTasksScreen(),
      ),
      GoRoute(
        path: 'vendors',
        builder: (_, _) => const CustomFieldsVendorsScreen(),
      ),
      GoRoute(
        path: 'expenses',
        builder: (_, _) => const CustomFieldsExpensesScreen(),
      ),
      GoRoute(
        path: 'users',
        builder: (_, _) => const CustomFieldsUsersScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'generated_numbers',
    builder: (_, _) => const GeneratedNumbersScreen(),
    routes: [
      GoRoute(
        path: 'clients',
        builder: (_, _) => const GeneratedNumbersClientsScreen(),
      ),
      GoRoute(
        path: 'invoices',
        builder: (_, _) => const GeneratedNumbersInvoicesScreen(),
      ),
      GoRoute(
        path: 'recurring_invoices',
        builder: (_, _) => const GeneratedNumbersRecurringInvoicesScreen(),
      ),
      GoRoute(
        path: 'payments',
        builder: (_, _) => const GeneratedNumbersPaymentsScreen(),
      ),
      GoRoute(
        path: 'quotes',
        builder: (_, _) => const GeneratedNumbersQuotesScreen(),
      ),
      GoRoute(
        path: 'credits',
        builder: (_, _) => const GeneratedNumbersCreditsScreen(),
      ),
      GoRoute(
        path: 'projects',
        builder: (_, _) => const GeneratedNumbersProjectsScreen(),
      ),
      GoRoute(
        path: 'tasks',
        builder: (_, _) => const GeneratedNumbersTasksScreen(),
      ),
      GoRoute(
        path: 'vendors',
        builder: (_, _) => const GeneratedNumbersVendorsScreen(),
      ),
      GoRoute(
        path: 'purchase_orders',
        builder: (_, _) => const GeneratedNumbersPurchaseOrdersScreen(),
      ),
      GoRoute(
        path: 'expenses',
        builder: (_, _) => const GeneratedNumbersExpensesScreen(),
      ),
      GoRoute(
        path: 'recurring_expenses',
        builder: (_, _) => const GeneratedNumbersRecurringExpensesScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'client_portal',
    builder: (_, _) => const ClientPortalScreen(),
    routes: [
      GoRoute(
        path: 'authorization',
        builder: (_, _) => const ClientPortalAuthorizationScreen(),
      ),
      GoRoute(
        path: 'registration',
        builder: (_, _) => const ClientPortalRegistrationScreen(),
      ),
      GoRoute(
        path: 'messages',
        builder: (_, _) => const ClientPortalMessagesScreen(),
      ),
      GoRoute(
        path: 'customize',
        builder: (_, _) => const ClientPortalCustomizeScreen(),
      ),
    ],
  ),
  GoRoute(path: 'e_invoice', builder: (_, _) => const EInvoiceScreen()),
  GoRoute(
    path: 'email_settings',
    builder: (_, _) => const EmailSettingsScreen(),
  ),
  GoRoute(
    path: 'templates_and_reminders',
    builder: (_, _) => const TemplatesRemindersScreen(),
  ),
  GoRoute(
    path: 'bank_accounts',
    builder: (_, _) => const BankAccountsScreen(),
    routes: [
      GoRoute(
        path: 'transaction_rules',
        builder: (_, _) => const BankAccountsTransactionRulesScreen(),
      ),
    ],
  ),
  GoRoute(
    path: 'group_settings',
    builder: (_, _) => const GroupSettingsScreen(),
  ),
  GoRoute(path: 'subscriptions', builder: (_, _) => const PaymentLinksScreen()),
  GoRoute(path: 'schedules', builder: (_, _) => const SchedulesScreen()),
  GoRoute(path: 'users', builder: (_, _) => const UserManagementScreen()),
  GoRoute(path: 'system_logs', builder: (_, _) => const SystemLogsScreen()),
  GoRoute(
    path: 'integrations',
    builder: (_, _) => const IntegrationsScreen(),
    routes: [
      GoRoute(
        path: 'api_tokens',
        builder: (_, _) => const IntegrationsApiTokensScreen(),
      ),
      GoRoute(
        path: 'api_webhooks',
        builder: (_, _) => const IntegrationsApiWebhooksScreen(),
      ),
      GoRoute(
        path: 'analytics',
        builder: (_, _) => const IntegrationsAnalyticsScreen(),
      ),
    ],
  ),
];
