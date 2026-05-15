import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/ui/features/settings/view_models/generated_numbers_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/bodies/entity_body.dart';
import 'package:admin/ui/features/settings/views/advanced/generated_numbers/bodies/settings_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/plan_gate_banner.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Generated Numbers settings page — cascade-aware tabbed shell.
///
/// Tab list is computed at build time from `company.enabledModules`. The
/// Settings tab (global counter behavior) and Clients tab always render;
/// the other 11 entity tabs gate on their corresponding [EnabledModule]
/// (`isOn(...)`), mirroring [InvoiceDesignShell]. Module-disabled slugs
/// still resolve in `tabbedSettingsRoutePair` so deep links don't 404; the
/// shell just falls back to the first visible tab.
///
/// Pairs with `tabbedSettingsRoutePair(path: 'generated_numbers', …)` in
/// `settings_routes.dart` — the shared page key keeps the [TabController]
/// and draft VM alive across tab switches.
class GeneratedNumbersShell extends StatelessWidget {
  const GeneratedNumbersShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null on the bare
  /// `/settings/generated_numbers` URL (resolves to the Settings tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(companyId),
      builder: (context, snapshot) {
        final company = snapshot.data;
        if (company == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildShell(context, company, companyId);
      },
    );
  }

  Widget _buildShell(
    BuildContext context,
    Company company,
    String companyId,
  ) {
    final modules = company.enabledModules;
    bool isOn(EnabledModule m) => isModuleEnabled(modules, m);

    final tabs = <TabbedSettingsTab>[
      TabbedSettingsTab(
        slug: '',
        labelKey: 'settings',
        body: GeneratedNumbersSettingsBody(
          companyId: companyId,
          showRecurringPrefix: isOn(EnabledModule.recurringInvoices),
          showSharedQuoteCounter: isOn(EnabledModule.quotes),
          showSharedCreditCounter: isOn(EnabledModule.credits),
        ),
      ),
      const TabbedSettingsTab(
        slug: 'clients',
        labelKey: 'clients',
        body: GeneratedNumbersEntityBody(
          patternKey: 'client_number_pattern',
          counterKey: 'client_number_counter',
          titleKey: 'clients',
          showClientTokens: false,
          showVendorTokens: false,
        ),
      ),
      if (isOn(EnabledModule.invoices))
        const TabbedSettingsTab(
          slug: 'invoices',
          labelKey: 'invoices',
          body: GeneratedNumbersEntityBody(
            patternKey: 'invoice_number_pattern',
            counterKey: 'invoice_number_counter',
            titleKey: 'invoices',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.recurringInvoices))
        const TabbedSettingsTab(
          slug: 'recurring_invoices',
          labelKey: 'recurring_invoices',
          body: GeneratedNumbersEntityBody(
            patternKey: 'recurring_invoice_number_pattern',
            counterKey: 'recurring_invoice_number_counter',
            titleKey: 'recurring_invoices',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.invoices))
        const TabbedSettingsTab(
          slug: 'payments',
          labelKey: 'payments',
          body: GeneratedNumbersEntityBody(
            patternKey: 'payment_number_pattern',
            counterKey: 'payment_number_counter',
            titleKey: 'payments',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.quotes))
        const TabbedSettingsTab(
          slug: 'quotes',
          labelKey: 'quotes',
          body: GeneratedNumbersEntityBody(
            patternKey: 'quote_number_pattern',
            counterKey: 'quote_number_counter',
            titleKey: 'quotes',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.credits))
        const TabbedSettingsTab(
          slug: 'credits',
          labelKey: 'credits',
          body: GeneratedNumbersEntityBody(
            patternKey: 'credit_number_pattern',
            counterKey: 'credit_number_counter',
            titleKey: 'credits',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.projects))
        const TabbedSettingsTab(
          slug: 'projects',
          labelKey: 'projects',
          body: GeneratedNumbersEntityBody(
            patternKey: 'project_number_pattern',
            counterKey: 'project_number_counter',
            titleKey: 'projects',
            showClientTokens: true,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.tasks))
        const TabbedSettingsTab(
          slug: 'tasks',
          labelKey: 'tasks',
          body: GeneratedNumbersEntityBody(
            patternKey: 'task_number_pattern',
            counterKey: 'task_number_counter',
            titleKey: 'tasks',
            showClientTokens: false,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.vendors))
        const TabbedSettingsTab(
          slug: 'vendors',
          labelKey: 'vendors',
          body: GeneratedNumbersEntityBody(
            patternKey: 'vendor_number_pattern',
            counterKey: 'vendor_number_counter',
            titleKey: 'vendors',
            showClientTokens: false,
            showVendorTokens: false,
          ),
        ),
      if (isOn(EnabledModule.purchaseOrders))
        const TabbedSettingsTab(
          slug: 'purchase_orders',
          labelKey: 'purchase_orders',
          body: GeneratedNumbersEntityBody(
            patternKey: 'purchase_order_number_pattern',
            counterKey: 'purchase_order_number_counter',
            titleKey: 'purchase_orders',
            showClientTokens: false,
            showVendorTokens: true,
          ),
        ),
      if (isOn(EnabledModule.expenses))
        const TabbedSettingsTab(
          slug: 'expenses',
          labelKey: 'expenses',
          body: GeneratedNumbersEntityBody(
            patternKey: 'expense_number_pattern',
            counterKey: 'expense_number_counter',
            titleKey: 'expenses',
            showClientTokens: false,
            showVendorTokens: true,
          ),
        ),
      if (isOn(EnabledModule.recurringExpenses))
        const TabbedSettingsTab(
          slug: 'recurring_expenses',
          labelKey: 'recurring_expenses',
          body: GeneratedNumbersEntityBody(
            patternKey: 'recurring_expense_number_pattern',
            counterKey: 'recurring_expense_number_counter',
            titleKey: 'recurring_expenses',
            showClientTokens: false,
            showVendorTokens: true,
          ),
        ),
    ];

    return CascadeTabbedSettingsShell(
      titleKey: 'generated_numbers',
      basePath: '/settings/generated_numbers',
      initialTab: initialTab,
      companyVmFactory: ({required repo, required companyId}) =>
          GeneratedNumbersViewModel(repo: repo, companyId: companyId),
      banner: const PlanGateBanner(style: PlanGateStyle.stripe),
      tabs: tabs,
    );
  }
}
