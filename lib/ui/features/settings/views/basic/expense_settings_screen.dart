import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/expense_settings_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/plain_radio_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_switch_tile.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';

/// Searchable label keys rendered by this screen. Aggregated into
/// `kSettingsSearchCatalog['expense_settings']` so the in-app search surfaces
/// these fields. `search_catalog_consistency_test` verifies every key here
/// appears as a `context.tr('…')` reference in this file.
const kExpenseSettingsSearchKeys = <String>[
  'should_be_invoiced',
  'mark_paid',
  'default_expense_payment_type',
  'convert_currency',
  'add_documents_to_invoice',
  'notify_vendor_when_paid',
  'expense_mailbox_active',
  'expense_mailbox',
  'inbound_mailbox_allow_company_users',
  'inbound_mailbox_allow_vendors',
  'inbound_mailbox_allow_clients',
  'inbound_mailbox_whitelist',
  'inbound_mailbox_blacklist',
  'inbound_mailbox_allow_unknown',
  'enter_taxes',
  'inclusive_taxes',
  'configure_categories',
];

/// Settings → Expense Settings. Mixes top-level `company.*` expense toggles
/// (`mark_expenses_*`, `notify_vendor_when_paid`, the inbound mailbox block,
/// the expense-tax pair) with the cascade
/// `settings.defaultExpensePaymentTypeId` picker.
///
/// Style: `CascadeSettingsScaffold` (like Task Settings / Localization) so
/// the one cascade field (`default_expense_payment_type_id`) writes to the
/// right entity at every scope. The top-level `company.*` toggles render
/// only inside `if (isCompanyScope)` via `host.draft` / `host.updateCompany`,
/// which resolve to the company VM at company scope (where alone they show).
class ExpenseSettingsScreen extends StatelessWidget {
  const ExpenseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CascadeSettingsScaffold(
      titleKey: 'expense_settings',
      companyVmFactory: ({required repo, required companyId}) =>
          ExpenseSettingsViewModel(repo: repo, companyId: companyId),
      body: const _ExpenseSettingsBody(),
    );
  }
}

class _ExpenseSettingsBody extends StatelessWidget {
  const _ExpenseSettingsBody();

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();
    // Company draft: non-null at company scope (the scaffold gates the body on
    // `draftReady` = draft != null), null at client/group scope where only the
    // cascade picker shows. Top-level sections guard on `draft != null`, which
    // promotes `draft` to non-null inside.
    final draft = host.draft;

    final isCompanyScope = scope.isCompany;
    final services = context.read<Services>();
    // Default `isHosted` to true so unknown sessions never accidentally
    // expose the mailbox config (which is meaningless on hosted).
    final isSelfHosted = !(services.auth.session.value?.isHosted ?? true);

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('settings'),
          children: [
            if (isCompanyScope && draft != null) ...[
              SettingsSwitchTile(
                label: context.tr('should_be_invoiced'),
                help: context.tr('should_be_invoiced_help'),
                value: draft.markExpensesInvoiceable,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(markExpensesInvoiceable: v),
                ),
              ),
              SettingsSwitchTile(
                label: context.tr('mark_paid'),
                help: context.tr('mark_paid_help'),
                value: draft.markExpensesPaid,
                onChanged: (v) =>
                    host.updateCompany((c) => c.copyWith(markExpensesPaid: v)),
              ),
            ],
            // Cascade picker. At company scope it follows the old admin-portal
            // behavior: only visible when `mark_paid` is on. At non-company
            // scope it's always visible — it's the only field on this page
            // that cascades, so hiding it would leave the user nothing to
            // edit.
            if (!isCompanyScope || (draft?.markExpensesPaid ?? false))
              _DefaultPaymentTypePicker(host: host, services: services),
            if (isCompanyScope && draft != null) ...[
              SettingsSwitchTile(
                label: context.tr('convert_currency'),
                help: context.tr('convert_expense_currency_help'),
                value: draft.convertExpenseCurrency,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(convertExpenseCurrency: v),
                ),
              ),
              SettingsSwitchTile(
                label: context.tr('add_documents_to_invoice'),
                help: context.tr('add_documents_to_invoice_help'),
                value: draft.invoiceExpenseDocuments,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(invoiceExpenseDocuments: v),
                ),
              ),
              SettingsSwitchTile(
                label: context.tr('notify_vendor_when_paid'),
                help: context.tr('notify_vendor_when_paid_help'),
                value: draft.notifyVendorWhenPaid,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(notifyVendorWhenPaid: v),
                ),
              ),
            ],
          ],
        ),
        if (isCompanyScope && isSelfHosted && draft != null)
          FormSection(
            title: context.tr('expense_mailbox_active'),
            children: [
              SettingsSwitchTile(
                label: context.tr('expense_mailbox_active'),
                help: context.tr('expense_mailbox_active_help'),
                value: draft.expenseMailboxActive,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(expenseMailboxActive: v),
                ),
              ),
              if (draft.expenseMailboxActive) ...[
                SettingsTextField(
                  key: const ValueKey('expense_mailbox'),
                  labelText: context.tr('expense_mailbox'),
                  helperText: context.tr('expense_mailbox_help'),
                  helperMaxLines: 2,
                  initialValue: draft.expenseMailbox,
                  onChanged: (v) =>
                      host.updateCompany((c) => c.copyWith(expenseMailbox: v)),
                ),
                SettingsSwitchTile(
                  label: context.tr('inbound_mailbox_allow_company_users'),
                  help: context.tr('inbound_mailbox_allow_company_users_help'),
                  value: draft.inboundMailboxAllowCompanyUsers,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowCompanyUsers: v),
                  ),
                ),
                SettingsSwitchTile(
                  label: context.tr('inbound_mailbox_allow_vendors'),
                  help: context.tr('inbound_mailbox_allow_vendors_help'),
                  value: draft.inboundMailboxAllowVendors,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowVendors: v),
                  ),
                ),
                SettingsSwitchTile(
                  label: context.tr('inbound_mailbox_allow_clients'),
                  help: context.tr('inbound_mailbox_allow_clients_help'),
                  value: draft.inboundMailboxAllowClients,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowClients: v),
                  ),
                ),
                SettingsTextField(
                  key: const ValueKey('inbound_mailbox_whitelist'),
                  labelText: context.tr('inbound_mailbox_whitelist'),
                  helperText: context.tr('inbound_mailbox_whitelist_help'),
                  helperMaxLines: 2,
                  initialValue: draft.inboundMailboxWhitelist,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxWhitelist: v),
                  ),
                ),
                SettingsTextField(
                  key: const ValueKey('inbound_mailbox_blacklist'),
                  labelText: context.tr('inbound_mailbox_blacklist'),
                  helperText: context.tr('inbound_mailbox_blacklist_help'),
                  helperMaxLines: 2,
                  initialValue: draft.inboundMailboxBlacklist,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxBlacklist: v),
                  ),
                ),
                SettingsSwitchTile(
                  label: context.tr('inbound_mailbox_allow_unknown'),
                  help: context.tr('inbound_mailbox_allow_unknown_help'),
                  value: draft.inboundMailboxAllowUnknown,
                  onChanged: (v) => host.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowUnknown: v),
                  ),
                ),
              ],
            ],
          ),
        // Render the tax section whenever we're at company scope —
        // matches the React client. Old admin-portal gated this on
        // `numberOfItemTaxRates > 0`, but `calculateExpenseTaxByAmount` and
        // `expenseInclusiveTaxes` are independently meaningful even before
        // any tax rate slots are enabled in Tax Settings.
        if (isCompanyScope && draft != null)
          FormSection(
            title: context.tr('tax_settings'),
            children: [
              PlainRadioField<bool>(
                label: context.tr('enter_taxes'),
                value: draft.calculateExpenseTaxByAmount,
                options: [
                  (value: false, label: context.tr('by_rate')),
                  (value: true, label: context.tr('by_amount')),
                ],
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(calculateExpenseTaxByAmount: v),
                ),
              ),
              SettingsSwitchTile(
                label: context.tr('inclusive_taxes'),
                // Leading newline gives the formula examples vertical room
                // under the title — matches the old admin-portal subtitle.
                help:
                    '\n${context.tr('exclusive')}: 100 + 10% = 100 + 10\n'
                    '${context.tr('inclusive')}: 100 + 10% = 90.91 + 9.09',
                value: draft.expenseInclusiveTaxes,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(expenseInclusiveTaxes: v),
                ),
              ),
            ],
          ),
        if (isCompanyScope)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/settings/expense_categories'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              icon: const Icon(Icons.category_outlined, size: 18),
              label: Text(context.tr('configure_categories')),
            ),
          ),
      ],
    );
  }
}

/// Cascade picker for `default_expense_payment_type_id`. Mirrors the call
/// site at `online_payments_defaults_body.dart:61-71` — same setting key,
/// same `PaymentType` source from `services.statics`.
class _DefaultPaymentTypePicker extends StatelessWidget {
  const _DefaultPaymentTypePicker({required this.host, required this.services});

  final SettingsDraftHost host;
  final Services services;

  @override
  Widget build(BuildContext context) {
    final paymentTypes = services.statics.paymentTypes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return OverridableSearchableDropdownField<PaymentType>(
      // `default_expense_payment_type`, not `default_payment_type` — the
      // latter is the *invoice* default that Online Payments → Defaults
      // edits with the same widget. Same-label-different-key was the
      // confusion before.
      label: context.tr('default_expense_payment_type'),
      apiKey: 'default_expense_payment_type_id',
      value: host.settings.defaultExpensePaymentTypeId,
      items: paymentTypes,
      displayString: (p) => p.name,
      idOf: (p) => p.id,
      onChanged: (v) => host.updateSettings(
        (s) => s.copyWith(defaultExpensePaymentTypeId: v),
      ),
    );
  }
}
