import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/enabled_modules.dart';
import 'package:admin/data/services/live_design_service.dart';
import 'package:admin/data/static/pdf_catalogs.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/invoice_design_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/bodies/general_settings_body.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/bodies/pdf_variable_list_body.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/widgets/invoice_design_preview_pane.dart';
import 'package:admin/ui/features/settings/widgets/cascade_tabbed_settings_shell.dart';
import 'package:admin/ui/features/settings/widgets/plan_gate_banner.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Invoice Design settings page — cascade-aware tabbed shell. Tab list is
/// computed at build time from:
///   * `company.enabledModules` (vendor / purchase order / task / credit /
///     quote drive detail-tab presence).
///   * `vm.settings.syncInvoiceQuoteColumns` — Quote Product Columns tab is
///     hidden when the flag is true (shared columns).
///   * [SettingsLevelController.level] — at non-company scope, only the
///     General Settings tab renders (mirrors React's `useTabs.ts:35-50`).
class InvoiceDesignShell extends StatelessWidget {
  const InvoiceDesignShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/invoice_design` URL (resolves to the General tab).
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
        return _buildShell(context, company);
      },
    );
  }

  Widget _buildShell(BuildContext context, Company company) {
    // `context.read` (not `watch`): `_SettingsLevelKeyed` in
    // `settings_routes.dart` already re-mounts the entire subtree when the
    // active scope / target id flips, so `build()` reruns from scratch on
    // every level change. The cascade scaffold inside
    // `SettingsCompanyScopedHost` is the canonical watcher; double-watching
    // here was redundant.
    final level = context.read<SettingsLevelController>();
    final modules = company.enabledModules;
    bool isOn(EnabledModule m) => isModuleEnabled(modules, m);
    final syncColumns = company.settings.syncInvoiceQuoteColumns ?? true;
    final isCompanyScope = level.isCompany;

    // Persistent live PDF preview, shared across every tab (hoisted out of
    // the General tab so it survives tab switches). `companyId` is guaranteed
    // non-null here — `build()` returns early otherwise.
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    final Widget? sidePane = companyId == null || companyId.isEmpty
        ? null
        : InvoiceDesignPreviewPane(companyId: companyId);
    final Widget Function(BuildContext)? sidePaneFullScreenBuilder =
        companyId == null || companyId.isEmpty
        ? null
        : (ctx) => InvoiceDesignPreviewScreen(
            host: ctx.read<SettingsDraftHost>(),
            level: ctx.read<SettingsLevelController>(),
            service: LiveDesignService(ctx.read<Services>().apiClient),
            companyId: companyId,
          );

    final tabs = <TabbedSettingsTab>[
      TabbedSettingsTab(
        slug: '',
        labelKey: 'general_settings',
        body: const GeneralSettingsBody(),
      ),
      if (isCompanyScope) ...[
        TabbedSettingsTab(
          slug: PdfVariableSection.clientDetails,
          labelKey: 'client_details',
          body: const PdfVariableListBody(
            sectionKey: PdfVariableSection.clientDetails,
          ),
        ),
        TabbedSettingsTab(
          slug: PdfVariableSection.companyDetails,
          labelKey: 'company_details',
          body: const PdfVariableListBody(
            sectionKey: PdfVariableSection.companyDetails,
          ),
        ),
        TabbedSettingsTab(
          slug: PdfVariableSection.companyAddress,
          labelKey: 'company_address',
          body: const PdfVariableListBody(
            sectionKey: PdfVariableSection.companyAddress,
          ),
        ),
        if (isOn(EnabledModule.invoices))
          TabbedSettingsTab(
            slug: PdfVariableSection.invoiceDetails,
            labelKey: 'invoice_details',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.invoiceDetails,
            ),
          ),
        if (isOn(EnabledModule.quotes))
          TabbedSettingsTab(
            slug: PdfVariableSection.quoteDetails,
            labelKey: 'quote_details',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.quoteDetails,
            ),
          ),
        if (isOn(EnabledModule.credits))
          TabbedSettingsTab(
            slug: PdfVariableSection.creditDetails,
            labelKey: 'credit_details',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.creditDetails,
            ),
          ),
        if (isOn(EnabledModule.vendors))
          TabbedSettingsTab(
            slug: PdfVariableSection.vendorDetails,
            labelKey: 'vendor_details',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.vendorDetails,
            ),
          ),
        if (isOn(EnabledModule.purchaseOrders))
          TabbedSettingsTab(
            slug: PdfVariableSection.purchaseOrderDetails,
            labelKey: 'purchase_order_details',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.purchaseOrderDetails,
            ),
          ),
        TabbedSettingsTab(
          slug: PdfVariableSection.productColumns,
          labelKey: syncColumns ? 'product_columns' : 'invoice_product_columns',
          body: const PdfVariableListBody(
            sectionKey: PdfVariableSection.productColumns,
          ),
        ),
        if (!syncColumns)
          TabbedSettingsTab(
            slug: PdfVariableSection.productQuoteColumns,
            labelKey: 'quote_product_columns',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.productQuoteColumns,
            ),
          ),
        if (isOn(EnabledModule.tasks))
          TabbedSettingsTab(
            slug: PdfVariableSection.taskColumns,
            labelKey: 'task_columns',
            body: const PdfVariableListBody(
              sectionKey: PdfVariableSection.taskColumns,
            ),
          ),
        TabbedSettingsTab(
          slug: PdfVariableSection.totalColumns,
          labelKey: 'total_fields',
          // Server-side wire key is `total_columns` even though the UI label
          // reads "Total Fields" — see admin-portal `constants.dart:972`.
          body: const PdfVariableListBody(
            sectionKey: PdfVariableSection.totalColumns,
          ),
        ),
        // Custom Designs is no longer a tab — it's reached from the
        // "Custom Designs" entry on the General tab (and its own URL
        // `/settings/invoice_design/custom_designs`).
      ],
    ];

    // Cascade tabbed shell requires >=2 tabs. At company scope this is always
    // true (General + at least Client/Company/Company Address); at client
    // scope we only have General, so substitute the single-tab cascade
    // scaffold instead.
    if (tabs.length < 2) {
      return CascadeTabbedSettingsShell(
        titleKey: 'invoice_design',
        basePath: '/settings/invoice_design',
        initialTab: initialTab,
        companyVmFactory: ({required repo, required companyId}) =>
            InvoiceDesignViewModel(repo: repo, companyId: companyId),
        banner: const PlanGateBanner(style: PlanGateStyle.stripe),
        sidePane: sidePane,
        sidePaneFullScreenBuilder: sidePaneFullScreenBuilder,
        tabs: [
          ...tabs,
          // Hidden filler so the shell's `length >= 2` invariant holds at
          // client scope. Marked `contributesToSave: false` so the save bar
          // doesn't fire for it.
          TabbedSettingsTab(
            slug: '_filler',
            labelKey: 'general_settings',
            contributesToSave: false,
            body: const SizedBox.shrink(),
          ),
        ],
      );
    }

    return CascadeTabbedSettingsShell(
      titleKey: 'invoice_design',
      basePath: '/settings/invoice_design',
      initialTab: initialTab,
      companyVmFactory: ({required repo, required companyId}) =>
          InvoiceDesignViewModel(repo: repo, companyId: companyId),
      banner: const PlanGateBanner(style: PlanGateStyle.stripe),
      sidePane: sidePane,
      sidePaneFullScreenBuilder: sidePaneFullScreenBuilder,
      tabs: tabs,
    );
  }
}
