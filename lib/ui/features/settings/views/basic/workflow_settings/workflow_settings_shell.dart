import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/ui/features/settings/view_models/workflow_settings_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_invoices_body.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_quotes_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';
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
/// `company.enabledModules`. Three cases:
///   * both modules on → two tabs via [CascadeTabbedSettingsShell];
///   * exactly one on → that single body via the non-tabbed
///     [CascadeSettingsScaffold] (the tabbed shell requires `>= 2` tabs, and a
///     lone tab bar reads as broken);
///   * both off → only reachable by a hand-typed URL (the sidebar and search
///     hide the section via `SettingsSectionDef.enabledBy`), so fall back to
///     the full two-tab set rather than an empty shell.
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

        // Both modules off — only reachable via a hand-typed URL (the sidebar
        // and search already hide the whole section when neither module is on).
        // Fall back to the full two-tab set rather than an empty shell.
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

        // Exactly one module on → a single tab. CascadeTabbedSettingsShell
        // asserts `tabs.length >= 2` (and renders a stray one-tab bar in
        // release), so drop the tab bar: render the lone body through the
        // non-tabbed cascade scaffold. It does the same per-scope (company vs.
        // client) VM selection, so the cascade-override behavior is unchanged.
        if (resolved.length == 1) {
          return CascadeSettingsScaffold(
            titleKey: 'workflow_settings',
            companyVmFactory: ({required repo, required companyId}) =>
                WorkflowSettingsViewModel(repo: repo, companyId: companyId),
            body: resolved.single.body,
          );
        }

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
