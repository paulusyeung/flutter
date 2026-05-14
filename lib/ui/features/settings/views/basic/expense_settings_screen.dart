import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/expense_settings_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Searchable label keys rendered by this screen. Aggregated into
/// `kSettingsSearchCatalog['expense_settings']` so the in-app search surfaces
/// these fields. `search_catalog_consistency_test` verifies every key here
/// appears as a `context.tr('…')` reference in this file.
const kExpenseSettingsSearchKeys = <String>[
  'should_be_invoiced',
  'mark_paid',
  'default_payment_type',
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
/// Style: `SettingsCompanyScopedHost` + `SettingsPageScaffold` (the Task
/// Settings hybrid pattern) per CLAUDE.md § Settings screens — using
/// `CascadeSettingsScaffold` here would silently drop the top-level
/// `vm.updateCompany(...)` writes at non-company scope.
class ExpenseSettingsScreen extends StatelessWidget {
  const ExpenseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsCompanyScopedHost<ExpenseSettingsViewModel>(
      create: (companyId) {
        final vm = ExpenseSettingsViewModel(
          repo: services.company,
          companyId: companyId,
        );
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) => SettingsPageScaffold<ExpenseSettingsViewModel>(
        titleKey: 'expense_settings',
        viewModel: vm,
        body: const _ExpenseSettingsBody(),
      ),
    );
  }
}

class _ExpenseSettingsBody extends StatelessWidget {
  const _ExpenseSettingsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseSettingsViewModel>();
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();
    final draft = vm.draft;
    if (draft == null) return const SizedBox.shrink();

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
            if (isCompanyScope) ...[
              _ExpenseSwitch(
                label: context.tr('should_be_invoiced'),
                help: context.tr('should_be_invoiced_help'),
                value: draft.markExpensesInvoiceable,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(markExpensesInvoiceable: v),
                ),
              ),
              _ExpenseSwitch(
                label: context.tr('mark_paid'),
                help: context.tr('mark_paid_help'),
                value: draft.markExpensesPaid,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(markExpensesPaid: v)),
              ),
            ],
            // Cascade picker. At company scope it follows the old admin-portal
            // behavior: only visible when `mark_paid` is on. At non-company
            // scope it's always visible — it's the only field on this page
            // that cascades, so hiding it would leave the user nothing to
            // edit.
            if (!isCompanyScope || draft.markExpensesPaid)
              _DefaultPaymentTypePicker(host: host, services: services),
            if (isCompanyScope) ...[
              _ExpenseSwitch(
                label: context.tr('convert_currency'),
                help: context.tr('convert_expense_currency_help'),
                value: draft.convertExpenseCurrency,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(convertExpenseCurrency: v),
                ),
              ),
              _ExpenseSwitch(
                label: context.tr('add_documents_to_invoice'),
                help: context.tr('add_documents_to_invoice_help'),
                value: draft.invoiceExpenseDocuments,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(invoiceExpenseDocuments: v),
                ),
              ),
              _ExpenseSwitch(
                label: context.tr('notify_vendor_when_paid'),
                help: context.tr('notify_vendor_when_paid_help'),
                value: draft.notifyVendorWhenPaid,
                onChanged: (v) =>
                    vm.updateCompany((c) => c.copyWith(notifyVendorWhenPaid: v)),
              ),
            ],
          ],
        ),
        if (isCompanyScope && isSelfHosted)
          FormSection(
            title: context.tr('expense_mailbox_active'),
            children: [
              _ExpenseSwitch(
                label: context.tr('expense_mailbox_active'),
                help: context.tr('expense_mailbox_active_help'),
                value: draft.expenseMailboxActive,
                onChanged: (v) => vm.updateCompany(
                  (c) => c.copyWith(expenseMailboxActive: v),
                ),
              ),
              if (draft.expenseMailboxActive) ...[
                _MailboxTextField(
                  key: const ValueKey('expense_mailbox'),
                  label: context.tr('expense_mailbox'),
                  helperText: context.tr('expense_mailbox_help'),
                  value: draft.expenseMailbox,
                  onChanged: (v) =>
                      vm.updateCompany((c) => c.copyWith(expenseMailbox: v)),
                ),
                _ExpenseSwitch(
                  label: context.tr('inbound_mailbox_allow_company_users'),
                  help: context.tr('inbound_mailbox_allow_company_users_help'),
                  value: draft.inboundMailboxAllowCompanyUsers,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowCompanyUsers: v),
                  ),
                ),
                _ExpenseSwitch(
                  label: context.tr('inbound_mailbox_allow_vendors'),
                  help: context.tr('inbound_mailbox_allow_vendors_help'),
                  value: draft.inboundMailboxAllowVendors,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowVendors: v),
                  ),
                ),
                _ExpenseSwitch(
                  label: context.tr('inbound_mailbox_allow_clients'),
                  help: context.tr('inbound_mailbox_allow_clients_help'),
                  value: draft.inboundMailboxAllowClients,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowClients: v),
                  ),
                ),
                _MailboxTextField(
                  key: const ValueKey('inbound_mailbox_whitelist'),
                  label: context.tr('inbound_mailbox_whitelist'),
                  helperText: context.tr('inbound_mailbox_whitelist_help'),
                  value: draft.inboundMailboxWhitelist,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxWhitelist: v),
                  ),
                ),
                _MailboxTextField(
                  key: const ValueKey('inbound_mailbox_blacklist'),
                  label: context.tr('inbound_mailbox_blacklist'),
                  helperText: context.tr('inbound_mailbox_blacklist_help'),
                  value: draft.inboundMailboxBlacklist,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxBlacklist: v),
                  ),
                ),
                _ExpenseSwitch(
                  label: context.tr('inbound_mailbox_allow_unknown'),
                  help: context.tr('inbound_mailbox_allow_unknown_help'),
                  value: draft.inboundMailboxAllowUnknown,
                  onChanged: (v) => vm.updateCompany(
                    (c) => c.copyWith(inboundMailboxAllowUnknown: v),
                  ),
                ),
              ],
            ],
          ),
        // Old admin-portal gates the tax card on `numberOfItemTaxRates > 0`;
        // the modern equivalent on the new app is `enabledItemTaxRates`. Both
        // fields below only affect expenses that carry tax rates, so hiding
        // the card when no rates are enabled keeps the screen tidy.
        if (isCompanyScope && draft.enabledItemTaxRates > 0)
          FormSection(
            title: context.tr('tax_settings'),
            children: [
              DropdownButtonFormField<bool>(
                key: ValueKey(
                  'enter-taxes-${draft.calculateExpenseTaxByAmount}',
                ),
                initialValue: draft.calculateExpenseTaxByAmount,
                decoration: InputDecoration(
                  labelText: context.tr('enter_taxes'),
                ),
                items: [
                  DropdownMenuItem(
                    value: false,
                    child: Text(context.tr('by_rate')),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(context.tr('by_amount')),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  vm.updateCompany(
                    (c) => c.copyWith(calculateExpenseTaxByAmount: v),
                  );
                },
              ),
              _ExpenseSwitch(
                label: context.tr('inclusive_taxes'),
                help:
                    '${context.tr('exclusive')}: 100 + 10% = 100 + 10\n'
                    '${context.tr('inclusive')}: 100 + 10% = 90.91 + 9.09',
                value: draft.expenseInclusiveTaxes,
                onChanged: (v) => vm.updateCompany(
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
  const _DefaultPaymentTypePicker({
    required this.host,
    required this.services,
  });

  final SettingsDraftHost host;
  final Services services;

  @override
  Widget build(BuildContext context) {
    final paymentTypes = services.statics.paymentTypes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return OverridableSearchableDropdownField<PaymentType>(
      label: context.tr('default_payment_type'),
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

/// Top-level `company.*` switch with a help-text subtitle. Same shape as
/// `_TaskSwitch` in `task_settings_screen.dart` minus the disabled-tooltip
/// branch — none of the expense toggles need it.
class _ExpenseSwitch extends StatelessWidget {
  const _ExpenseSwitch({
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(help),
    value: value,
    onChanged: onChanged,
  );
}

/// Plain top-level `company.*` text field with controller plumbing so the
/// user can type without losing focus. Pattern mirrors `_CustomSecondsField`
/// in `task_settings_screen.dart` — controller initialized from the draft,
/// re-synced on `didUpdateWidget` (so a Discard / refresh emission rolls the
/// text back), and `onChanged` pipes straight to `vm.updateCompany(...)`.
class _MailboxTextField extends StatefulWidget {
  const _MailboxTextField({
    required Key super.key,
    required this.label,
    required this.helperText,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String helperText;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_MailboxTextField> createState() => _MailboxTextFieldState();
}

class _MailboxTextFieldState extends State<_MailboxTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_MailboxTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
      ),
      onChanged: widget.onChanged,
    );
  }
}
