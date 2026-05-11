import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

/// Single source of truth for the settings sidebar layout and the in-app
/// settings search. `SettingsListSidebar` reads `kSettingsSections` to render
/// its tiles; `searchSettings` walks `kSettingsSearchCatalog` to surface
/// individual fields.
///
/// When you add or rename a user-facing field on a settings screen, append
/// the field's localization key to the matching section in
/// `kSettingsSearchCatalog` so the field shows up in search.
class SettingsSectionDef {
  const SettingsSectionDef({
    required this.slug,
    required this.titleKey,
    required this.icon,
    required this.route,
    required this.isBasic,
  });

  /// Stable identifier; matches the leading path segment after `/settings/`.
  final String slug;

  /// Localization key for the section's display name. Usually equals `slug`,
  /// but some routes intentionally diverge (e.g. slug `users` is displayed as
  /// "User Management").
  final String titleKey;

  final IconData icon;
  final String route;
  final bool isBasic;
}

const kSettingsSections = <SettingsSectionDef>[
  // Basic
  SettingsSectionDef(
    slug: 'company_details',
    titleKey: 'company_details',
    icon: Icons.business_outlined,
    route: '/settings/company_details',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'user_details',
    titleKey: 'user_details',
    icon: Icons.person_outline,
    route: '/settings/user_details',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'localization',
    titleKey: 'localization',
    icon: Icons.language_outlined,
    route: '/settings/localization',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'online_payments',
    titleKey: 'online_payments',
    icon: Icons.payments_outlined,
    route: '/settings/online_payments',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'tax_settings',
    titleKey: 'tax_settings',
    icon: Icons.percent_outlined,
    route: '/settings/tax_settings',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'product_settings',
    titleKey: 'product_settings',
    icon: Icons.inventory_2_outlined,
    route: '/settings/product_settings',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'task_settings',
    titleKey: 'task_settings',
    icon: Icons.task_alt_outlined,
    route: '/settings/task_settings',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'expense_settings',
    titleKey: 'expense_settings',
    icon: Icons.receipt_long_outlined,
    route: '/settings/expense_settings',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'workflow_settings',
    titleKey: 'workflow_settings',
    icon: Icons.account_tree_outlined,
    route: '/settings/workflow_settings',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'account_management',
    titleKey: 'account_management',
    icon: Icons.manage_accounts_outlined,
    route: '/settings/account_management',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'backup_restore',
    titleKey: 'backup_restore',
    icon: Icons.backup_outlined,
    route: '/settings/backup_restore',
    isBasic: true,
  ),
  SettingsSectionDef(
    slug: 'import_export',
    titleKey: 'import_export',
    icon: Icons.import_export_outlined,
    route: '/settings/import_export',
    isBasic: true,
  ),
  // Advanced
  SettingsSectionDef(
    slug: 'invoice_design',
    titleKey: 'invoice_design',
    icon: Icons.design_services_outlined,
    route: '/settings/invoice_design',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'custom_fields',
    titleKey: 'custom_fields',
    icon: Icons.edit_note_outlined,
    route: '/settings/custom_fields',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'generated_numbers',
    titleKey: 'generated_numbers',
    icon: Icons.format_list_numbered,
    route: '/settings/generated_numbers',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'client_portal',
    titleKey: 'client_portal',
    icon: Icons.web_outlined,
    route: '/settings/client_portal',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'e_invoice',
    titleKey: 'e_invoice',
    icon: Icons.electric_bolt_outlined,
    route: '/settings/e_invoice',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'email_settings',
    titleKey: 'email_settings',
    icon: Icons.mail_outline,
    route: '/settings/email_settings',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'templates_and_reminders',
    titleKey: 'templates_and_reminders',
    icon: Icons.notifications_outlined,
    route: '/settings/templates_and_reminders',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'bank_accounts',
    titleKey: 'bank_accounts',
    icon: Icons.account_balance_outlined,
    route: '/settings/bank_accounts',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'group_settings',
    titleKey: 'group_settings',
    icon: Icons.group_work_outlined,
    route: '/settings/group_settings',
    isBasic: false,
  ),
  // Slug intentionally diverges from titleKey: the route is `subscriptions`
  // but the user-facing label is "Payment Links".
  SettingsSectionDef(
    slug: 'subscriptions',
    titleKey: 'payment_links',
    icon: Icons.link_outlined,
    route: '/settings/subscriptions',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'schedules',
    titleKey: 'schedules',
    icon: Icons.schedule_outlined,
    route: '/settings/schedules',
    isBasic: false,
  ),
  // Slug intentionally diverges from titleKey: the route is `users` but the
  // user-facing label is "User Management".
  SettingsSectionDef(
    slug: 'users',
    titleKey: 'user_management',
    icon: Icons.supervised_user_circle_outlined,
    route: '/settings/users',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'system_logs',
    titleKey: 'system_logs',
    icon: Icons.terminal_outlined,
    route: '/settings/system_logs',
    isBasic: false,
  ),
  SettingsSectionDef(
    slug: 'integrations',
    titleKey: 'integrations',
    icon: Icons.extension_outlined,
    route: '/settings/integrations',
    isBasic: false,
  ),
];

final Map<String, SettingsSectionDef> kSettingsSectionsBySlug = {
  for (final s in kSettingsSections) s.slug: s,
};

/// Searchable fields per section. Keys are section slugs from
/// `kSettingsSections`. Values are localization keys (the same keys you pass
/// to `context.tr(...)` when rendering the field's label).
///
/// **Keep this in sync** when you add or rename fields on a settings screen —
/// it's the only way search will surface them.
const kSettingsSearchCatalog = <String, List<String>>{
  'company_details': [
    'name',
    'id_number',
    'vat_number',
    'classification',
    'website',
    'email',
    'phone',
    'size',
    'industry',
    'address',
    'postal_code',
    'country',
    'logo',
    'defaults',
    'invoice_terms',
    'invoice_footer',
    'quote_terms',
    'quote_footer',
    'credit_terms',
    'credit_footer',
    'default_documents',
  ],
  'user_details': [
    'first_name',
    'last_name',
    'email',
    'phone',
    'password',
    'accent_color',
    'connect_google',
    'connect_gmail',
    'enable_two_factor',
    'user_logged_in_notification',
    'task_assigned_notification',
    'notifications',
  ],
  'localization': [
    'currency',
    'language',
    'timezone',
    'date_format',
    'military_time',
    'decimal_comma',
    'first_month_of_the_year',
    'rappen_rounding',
    'custom_labels',
  ],
  'online_payments': [
    'company_gateways',
    'auto_bill',
    'auto_bill_on',
    'use_available_credits',
    'admin_initiated_payments',
    'allow_over_payment',
    'allow_under_payment',
    'auto_bill_standard_invoices',
    'client_initiated_payments',
    'use_available_payments',
    'one_page_checkout',
    'payment_type',
    'payment_terms',
    'online_payment_email',
    'manual_payment_email',
    'send_emails_to',
  ],
  'tax_settings': [
    'tax_settings',
    'inclusive_taxes',
    'calculate_taxes',
    'tax_rates',
  ],
  'product_settings': [
    'track_inventory',
    'stock_notifications',
    'show_product_discount',
    'show_product_cost',
    'fill_products',
    'update_products',
    'convert_products',
  ],
  'task_settings': [
    'task_settings',
    'auto_start_tasks',
    'show_tasks_table',
    'client_portal',
    'lock_invoiced_tasks',
    'invoice_task_hours',
    'allow_billable_task_items',
    'show_task_item_description',
    'project_location',
    'round_tasks',
    'task_statuses',
  ],
  'expense_settings': [
    'should_be_invoiced',
    'mark_paid',
    'inclusive_taxes',
    'convert_currency',
    'notify_vendor_when_paid',
    'expense_categories',
  ],
  'workflow_settings': [
    'auto_email_invoice',
    'stop_on_unpaid',
    'auto_archive_paid_invoices',
    'auto_archive_cancelled_invoices',
    'lock_invoices',
    'auto_convert',
    'use_quote_terms',
  ],
  'account_management': [
    'activate_company',
    'enable_markdown',
    'include_drafts',
    'include_deleted',
    'api_tokens',
    'api_webhooks',
    'purge_data',
    'delete_company',
    'enabled_modules',
    'google_analytics',
    'matomo_id',
    'password_timeout',
    'web_session_timeout',
    'referral_program',
  ],
  'backup_restore': [
    'backup',
    'restore',
    'export',
  ],
  'import_export': [
    'import',
    'export',
  ],
  'invoice_design': [
    'invoice_design',
    'quote_design',
    'page_size',
    'font_size',
    'primary_font',
    'secondary_font',
    'primary_color',
    'secondary_color',
    'empty_columns',
    'logo_size',
    'show_paid_stamp',
    'show_shipping_address',
    'share_invoice_quote_columns',
    'invoice_embed_documents',
    'delivery_note_design',
    'statement_design',
    'payment_receipt_design',
    'payment_refund_design',
    'custom_designs',
  ],
  'custom_fields': [
    'custom_fields',
  ],
  'generated_numbers': [
    'number_padding',
    'number_counter',
    'recurring_prefix',
    'reset_counter',
    'invoice_number',
    'client_number',
    'credit_number',
    'payment_number',
  ],
  'client_portal': [
    'client_portal',
    'dashboard',
    'portal_mode',
    'subdomain',
    'domain',
    'client_document_upload',
    'vendor_document_upload',
    'accept_purchase_order_number',
    'mobile_version',
    'enable_client_profile_update',
    'client_registration',
    'enable_portal_password',
    'show_accept_invoice_terms',
    'show_accept_quote_terms',
    'require_invoice_signature',
    'require_quote_signature',
    'messages',
    'header',
    'footer',
    'custom_css',
    'custom_javascript',
  ],
  'e_invoice': [
    'e_invoice_settings',
    'merge_to_pdf',
  ],
  'email_settings': [
    'send_from_gmail',
    'email_design',
    'from_name',
    'reply_to_email',
    'reply_to_name',
    'bcc_email',
    'attach_pdf',
    'attach_documents',
    'attach_ubl',
    'email_signature',
    'microsoft',
    'postmark',
    'mailgun',
    'email_alignment',
    'show_email_footer',
    'enable_e_invoice',
  ],
  'templates_and_reminders': [
    'template',
    'send_reminders',
    'late_fees',
  ],
  'bank_accounts': [
    'bank_accounts',
    'transaction_rules',
  ],
  'group_settings': [
    'groups',
  ],
  'subscriptions': [
    'payment_links',
  ],
  'schedules': [
    'schedules',
  ],
  'users': [
    'users',
  ],
  'system_logs': [
    'system_logs',
  ],
  'integrations': [
    'api_tokens',
    'api_webhooks',
  ],
};

/// A single field match returned by [searchSettings].
class SettingsSearchHit {
  const SettingsSearchHit({required this.fieldKey, required this.section});

  /// Localization key of the matching field (e.g. `'vat_number'`).
  final String fieldKey;

  /// Section that owns the field — used to render the subtitle/icon and to
  /// navigate when the result is tapped.
  final SettingsSectionDef section;
}

/// Returns every catalog entry whose *localized* label contains [query]
/// (case-insensitive). An empty / whitespace-only query returns the full
/// flattened catalog so the search list is discoverable when the user first
/// opens it.
List<SettingsSearchHit> searchSettings(String query, Localization l10n) {
  final q = query.trim().toLowerCase();
  final hits = <SettingsSearchHit>[];
  for (final entry in kSettingsSearchCatalog.entries) {
    final section = kSettingsSectionsBySlug[entry.key];
    if (section == null) continue;
    for (final fieldKey in entry.value) {
      if (q.isEmpty || l10n.lookup(fieldKey).toLowerCase().contains(q)) {
        hits.add(SettingsSearchHit(fieldKey: fieldKey, section: section));
      }
    }
  }
  return hits;
}
