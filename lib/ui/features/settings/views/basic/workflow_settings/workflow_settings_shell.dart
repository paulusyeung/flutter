import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/ui/features/settings/view_models/workflow_settings_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_invoices_body.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_quotes_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Workflow Settings page — Invoices + Quotes tabs hosted by the
/// cascade-aware [CascadeTabbedSettingsShell]. Both tabs bind to
/// `company.settings.*` so the shell picks the right VM per scope (company
/// vs. client) and the field bodies stay scope-agnostic.
///
/// Two of the eight fields (`stop_on_unpaid_recurring` on the Invoices tab,
/// `use_quote_terms_on_conversion` on the Quotes tab) live at top-level
/// `company.*` rather than `company.settings.*`, so they only render at
/// company scope. The body widgets gate them on
/// [SettingsLevelController.isCompany].
///
/// Per-tab module gating mirrors [GeneratedNumbersShell] /
/// `InvoiceDesignShell`: the tab list is computed at build time from
/// `company.enabledModules` so a deep link to `/settings/workflow_settings`
/// with one module off doesn't show that tab. The whole section is already
/// hidden from the sidebar when both modules are off (via
/// `SettingsSectionDef.enabledBy`); the fall-back below only guards a
/// hand-typed URL / an unhydrated (`0`) mask on cold start.
class WorkflowSettingsShell extends StatelessWidget {
  const WorkflowSettingsShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/workflow_settings` URL (defaults to the first visible tab).
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
        final modules = company.enabledModules;
        final invoicesOn = isModuleEnabled(modules, EnabledModule.invoices);
        final quotesOn = isModuleEnabled(modules, EnabledModule.quotes);

        // First visible tab takes slug '' so the bare
        // `/settings/workflow_settings` route always resolves to a real tab.
        final tabs = <TabbedSettingsTab>[
          if (invoicesOn)
            const TabbedSettingsTab(
              slug: '',
              labelKey: 'invoices',
              body: WorkflowSettingsInvoicesBody(),
            ),
          if (quotesOn)
            TabbedSettingsTab(
              slug: invoicesOn ? 'quotes' : '',
              labelKey: 'quotes',
              body: const WorkflowSettingsQuotesBody(),
            ),
        ];

        // Both modules off — only reachable via a hand-typed URL (the
        // sidebar/search already hide the section) or an unhydrated `0`
        // mask on cold start. Fall back to the full set rather than an
        // empty shell (consistent with the mask-0 fail-open policy).
        final resolved = tabs.isEmpty
            ? const [
                TabbedSettingsTab(
                  slug: '',
                  labelKey: 'invoices',
                  body: WorkflowSettingsInvoicesBody(),
                ),
                TabbedSettingsTab(
                  slug: 'quotes',
                  labelKey: 'quotes',
                  body: WorkflowSettingsQuotesBody(),
                ),
              ]
            : tabs;

        return CascadeTabbedSettingsShell(
          titleKey: 'workflow_settings',
          basePath: '/settings/workflow_settings',
          initialTab: initialTab,
          companyVmFactory: ({required repo, required companyId}) =>
              WorkflowSettingsViewModel(repo: repo, companyId: companyId),
          tabs: resolved,
        );
      },
    );
  }
}
