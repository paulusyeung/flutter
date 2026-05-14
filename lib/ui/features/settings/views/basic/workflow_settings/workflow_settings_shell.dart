import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/view_models/workflow_settings_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_invoices_body.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_quotes_body.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Workflow Settings page — two tabs (Invoices, Quotes) hosted by the
/// cascade-aware [CascadeTabbedSettingsShell]. Both tabs bind to
/// `company.settings.*` so the shell picks the right VM per scope (company
/// vs. client) and the field bodies stay scope-agnostic.
///
/// Two of the eight fields (`stop_on_unpaid_recurring` on the Invoices tab,
/// `use_quote_terms_on_conversion` on the Quotes tab) live at top-level
/// `company.*` rather than `company.settings.*`, so they only render at
/// company scope. The body widgets gate them on
/// [SettingsLevelController.isCompany].
class WorkflowSettingsShell extends StatelessWidget {
  const WorkflowSettingsShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/workflow_settings` URL (defaults to the Invoices tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return CascadeTabbedSettingsShell(
      titleKey: 'workflow_settings',
      basePath: '/settings/workflow_settings',
      initialTab: initialTab,
      companyVmFactory: ({required repo, required companyId}) =>
          WorkflowSettingsViewModel(repo: repo, companyId: companyId),
      tabs: const [
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
      ],
    );
  }
}
