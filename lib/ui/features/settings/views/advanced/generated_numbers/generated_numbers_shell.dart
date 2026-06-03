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

  Widget _buildShell(BuildContext context, Company company, String companyId) {
    final modules = company.enabledModules;
    bool isOn(EnabledModule m) => isModuleEnabled(modules, m);

    // Every per-entity tab shares slug == labelKey == titleKey and threads the
    // active `company` (for the custom-field chip gating) plus a stable
    // ValueKey so a tab-list change can't alias the body's pattern controller.
    TabbedSettingsTab entityTab({
      required String slug,
      required String patternKey,
      required String counterKey,
      bool showClientTokens = false,
      bool showVendorTokens = false,
    }) {
      return TabbedSettingsTab(
        slug: slug,
        labelKey: slug,
        body: GeneratedNumbersEntityBody(
          key: ValueKey(patternKey),
          company: company,
          patternKey: patternKey,
          counterKey: counterKey,
          titleKey: slug,
          showClientTokens: showClientTokens,
          showVendorTokens: showVendorTokens,
        ),
      );
    }

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
      entityTab(
        slug: 'clients',
        patternKey: 'client_number_pattern',
        counterKey: 'client_number_counter',
      ),
      if (isOn(EnabledModule.invoices))
        entityTab(
          slug: 'invoices',
          patternKey: 'invoice_number_pattern',
          counterKey: 'invoice_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.recurringInvoices))
        entityTab(
          slug: 'recurring_invoices',
          patternKey: 'recurring_invoice_number_pattern',
          counterKey: 'recurring_invoice_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.invoices))
        entityTab(
          slug: 'payments',
          patternKey: 'payment_number_pattern',
          counterKey: 'payment_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.quotes))
        entityTab(
          slug: 'quotes',
          patternKey: 'quote_number_pattern',
          counterKey: 'quote_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.credits))
        entityTab(
          slug: 'credits',
          patternKey: 'credit_number_pattern',
          counterKey: 'credit_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.projects))
        entityTab(
          slug: 'projects',
          patternKey: 'project_number_pattern',
          counterKey: 'project_number_counter',
          showClientTokens: true,
        ),
      if (isOn(EnabledModule.tasks))
        entityTab(
          slug: 'tasks',
          patternKey: 'task_number_pattern',
          counterKey: 'task_number_counter',
        ),
      if (isOn(EnabledModule.vendors))
        entityTab(
          slug: 'vendors',
          patternKey: 'vendor_number_pattern',
          counterKey: 'vendor_number_counter',
        ),
      if (isOn(EnabledModule.purchaseOrders))
        entityTab(
          slug: 'purchase_orders',
          patternKey: 'purchase_order_number_pattern',
          counterKey: 'purchase_order_number_counter',
          showVendorTokens: true,
        ),
      if (isOn(EnabledModule.expenses))
        entityTab(
          slug: 'expenses',
          patternKey: 'expense_number_pattern',
          counterKey: 'expense_number_counter',
          showVendorTokens: true,
        ),
      if (isOn(EnabledModule.recurringExpenses))
        entityTab(
          slug: 'recurring_expenses',
          patternKey: 'recurring_expense_number_pattern',
          counterKey: 'recurring_expense_number_counter',
          showVendorTokens: true,
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
