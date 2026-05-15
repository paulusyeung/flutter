import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/services/live_design_service.dart';
import 'package:admin/data/static/google_fonts_catalog.dart';
import 'package:admin/data/static/pdf_catalogs.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/widgets/live_pdf_preview_pane.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_color_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_design_picker.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_logo_size_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Field labels surfaced by in-app search for the Invoice Design → General tab.
/// Combined with the PDF-variable tab labels in `settings_search_catalog.dart`.
const kInvoiceDesignGeneralSearchKeys = <String>[
  'invoice_design',
  'quote_design',
  'credit_design',
  'purchase_order_design',
  'delivery_note_design',
  'statement_design',
  'payment_receipt_design',
  'payment_refund_design',
  'page_layout',
  'page_size',
  'font_size',
  'logo_size',
  'primary_font',
  'secondary_font',
  'primary_color',
  'secondary_color',
  'show_paid_stamp',
  'show_shipping_address',
  'share_invoice_quote_columns',
  'empty_columns',
  'page_numbering',
  'invoice_embed_documents',
  'page_numbering_alignment',
];

/// General Settings tab body. Mounted by `InvoiceDesignShell` inside
/// `CascadeTabbedSettingsShell` — the shell owns the cascade VM.
class GeneralSettingsBody extends StatefulWidget {
  const GeneralSettingsBody({super.key});

  @override
  State<GeneralSettingsBody> createState() => _GeneralSettingsBodyState();
}

class _GeneralSettingsBodyState extends State<GeneralSettingsBody> {
  bool _advancedOpen = false;

  /// Above this many pixels the body splits into a Row of form + side
  /// preview. Below it we keep the single-column flow and offer the
  /// `_PreviewBar` button that opens the fullscreen-dialog preview.
  static const double _splitBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    // `StreamBuilder` wraps `LayoutBuilder` (not the other way around) so a
    // window resize across the 1024 px split breakpoint doesn't re-run the
    // designs stream — Drift returns a fresh stream instance per
    // `watchAll(...)` call, and re-subscribing on every layout decision
    // would churn the DB read for no reason.
    return StreamBuilder<List<Design>>(
      stream: companyId == null
          ? const Stream.empty()
          : services.designs.watchAll(companyId: companyId),
      builder: (context, snapshot) {
        final bundled = snapshot.data ?? const <Design>[];
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _splitBreakpoint;
            final form = _buildSections(
              context,
              bundled,
              showPreviewBar: !isDesktop,
              capWidth: !isDesktop,
            );
            if (!isDesktop || companyId == null) return form;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: form),
                VerticalDivider(width: 1, color: context.inTheme.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 420,
                    maxWidth: 560,
                  ),
                  child: _SidePreview(companyId: companyId),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSections(
    BuildContext context,
    List<Design> bundled, {
    required bool showPreviewBar,
    required bool capWidth,
  }) {
    final host = context.watch<SettingsDraftHost>();
    final settings = host.settings;
    // Module gating mirrors admin-portal. `embedDocuments` toggle only renders
    // when the Documents module is on; alignment dropdown only when page
    // numbering is enabled.
    final hasPageNumbering = settings.pageNumbering ?? false;

    final pageLayoutItems = [
      for (final v in kPageLayouts)
        DropdownMenuItem<String>(value: v, child: Text(context.tr(v))),
    ];
    final pageSizeItems = [
      for (final v in kPageSizes)
        DropdownMenuItem<String>(value: v, child: Text(context.tr(v))),
    ];
    final fontSizeItems = [
      for (final v in kFontSizes)
        DropdownMenuItem<int>(value: v, child: Text(v.toString())),
    ];
    final alignmentItems = [
      for (final v in kPageNumberingAlignments)
        DropdownMenuItem<String>(
          value: v,
          child: Text(context.tr(_alignmentLabelKey(v))),
        ),
    ];
    final emptyColumnsItems = [
      DropdownMenuItem<bool>(value: false, child: Text(context.tr('show'))),
      DropdownMenuItem<bool>(value: true, child: Text(context.tr('hide'))),
    ];

    return SettingsFormShell(
      maxWidth: capWidth ? 720 : double.infinity,
      sections: [
        if (showPreviewBar)
          _PreviewBar(onOpen: () => _openPreview(context)),
        FormSection(
          title: context.tr('design'),
          children: [
            OverridableDesignPicker(
              label: context.tr('invoice_design'),
              apiKey: 'invoice_design_id',
              bundledDesigns: bundled,
              forEntity: 'invoice',
            ),
            OverridableDesignPicker(
              label: context.tr('quote_design'),
              apiKey: 'quote_design_id',
              bundledDesigns: bundled,
              forEntity: 'quote',
            ),
            OverridableDesignPicker(
              label: context.tr('credit_design'),
              apiKey: 'credit_design_id',
              bundledDesigns: bundled,
              forEntity: 'credit',
            ),
            OverridableDesignPicker(
              label: context.tr('purchase_order_design'),
              apiKey: 'purchase_order_design_id',
              bundledDesigns: bundled,
              forEntity: 'purchase_order',
            ),
            OverridableDesignPicker(
              label: context.tr('delivery_note_design'),
              apiKey: 'delivery_note_design_id',
              allowBlank: true,
              bundledDesigns: bundled,
              forEntity: 'invoice',
            ),
            OverridableDesignPicker(
              label: context.tr('statement_design'),
              apiKey: 'statement_design_id',
              allowBlank: true,
              bundledDesigns: bundled,
              forEntity: 'statement',
            ),
            OverridableDesignPicker(
              label: context.tr('payment_receipt_design'),
              apiKey: 'payment_receipt_design_id',
              allowBlank: true,
              bundledDesigns: bundled,
              forEntity: 'payment',
            ),
            OverridableDesignPicker(
              label: context.tr('payment_refund_design'),
              apiKey: 'payment_refund_design_id',
              allowBlank: true,
              bundledDesigns: bundled,
              forEntity: 'payment',
            ),
          ],
        ),
        FormSection(
          title: context.tr('layout'),
          children: [
            OverridableDropdownField<String>(
              label: context.tr('page_layout'),
              apiKey: 'page_layout',
              value: settings.pageLayout,
              items: pageLayoutItems,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(pageLayout: v)),
            ),
            OverridableDropdownField<String>(
              label: context.tr('page_size'),
              apiKey: 'page_size',
              value: settings.pageSize,
              items: pageSizeItems,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(pageSize: v)),
            ),
            OverridableDropdownField<int>(
              label: context.tr('font_size'),
              apiKey: 'font_size',
              value: settings.fontSize,
              items: fontSizeItems,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(fontSize: v)),
            ),
            const OverridableLogoSizeField(),
          ],
        ),
        FormSection(
          title: context.tr('typography'),
          children: [
            OverridableSearchableDropdownField<GoogleFont>(
              label: context.tr('primary_font'),
              apiKey: 'primary_font',
              value: settings.primaryFont,
              items: kGoogleFonts,
              displayString: (f) => f.name,
              idOf: (f) => f.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(primaryFont: v)),
            ),
            OverridableSearchableDropdownField<GoogleFont>(
              label: context.tr('secondary_font'),
              apiKey: 'secondary_font',
              value: settings.secondaryFont,
              items: kGoogleFonts,
              displayString: (f) => f.name,
              idOf: (f) => f.id,
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(secondaryFont: v)),
            ),
            OverridableColorField(
              label: context.tr('primary_color'),
              apiKey: 'primary_color',
            ),
            OverridableColorField(
              label: context.tr('secondary_color'),
              apiKey: 'secondary_color',
            ),
          ],
        ),
        FormSection(
          title: context.tr('document_options'),
          children: [
            OverridableSwitchField(
              label: context.tr('show_paid_stamp'),
              apiKey: 'show_paid_stamp',
            ),
            OverridableSwitchField(
              label: context.tr('show_shipping_address'),
              apiKey: 'show_shipping_address',
            ),
            OverridableSwitchField(
              label: context.tr('share_invoice_quote_columns'),
              apiKey: 'sync_invoice_quote_columns',
            ),
            OverridableDropdownField<bool>(
              label: context.tr('empty_columns'),
              apiKey: 'hide_empty_columns_on_pdf',
              value: settings.hideEmptyColumnsOnPdf,
              items: emptyColumnsItems,
              onChanged: (v) => host.updateSettings(
                (s) => s.copyWith(hideEmptyColumnsOnPdf: v),
              ),
            ),
            OverridableSwitchField(
              label: context.tr('page_numbering'),
              apiKey: 'page_numbering',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(
                  _advancedOpen ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(
                  _advancedOpen
                      ? context.tr('hide_advanced')
                      : context.tr('show_advanced'),
                ),
                onPressed: () =>
                    setState(() => _advancedOpen = !_advancedOpen),
              ),
            ),
            if (_advancedOpen) ...[
              OverridableSwitchField(
                label: context.tr('invoice_embed_documents'),
                apiKey: 'embed_documents',
                subtitle: context.tr('invoice_embed_documents_help'),
              ),
              if (hasPageNumbering)
                OverridableDropdownField<String>(
                  label: context.tr('page_numbering_alignment'),
                  apiKey: 'page_numbering_alignment',
                  value: settings.pageNumberingAlignment,
                  items: alignmentItems,
                  onChanged: (v) => host.updateSettings(
                    (s) => s.copyWith(pageNumberingAlignment: v),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }

  static String _alignmentLabelKey(String v) {
    switch (v) {
      case PageNumberingAlignment.left:
        return 'left';
      case PageNumberingAlignment.center:
        return 'center';
      case PageNumberingAlignment.right:
        return 'right';
      default:
        return v;
    }
  }

  void _openPreview(BuildContext context) {
    final services = context.read<Services>();
    final host = context.read<SettingsDraftHost>();
    final level = context.read<SettingsLevelController>();
    final companyId = services.auth.session.value?.currentCompanyId;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PreviewRoute(
          host: host,
          level: level,
          service: LiveDesignService(services.apiClient),
          companyId: companyId,
        ),
      ),
    );
  }
}

/// Lightweight bar above the form sections that opens the live PDF preview
/// in a fullscreen dialog. Rendered only on the General Settings tab.
class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FilledButton.tonalIcon(
          icon: const Icon(Icons.preview_outlined),
          label: Text(context.tr('preview')),
          onPressed: onOpen,
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
        ),
      ),
    );
  }
}

/// Fullscreen dialog hosting the [LivePdfPreviewPane]. Re-provides the
/// active draft host + level so the pane (mounted under the Navigator root)
/// sees the same cascade VM the General tab is editing.
class _PreviewRoute extends StatelessWidget {
  const _PreviewRoute({
    required this.host,
    required this.level,
    required this.service,
    required this.companyId,
  });

  final SettingsDraftHost host;
  final SettingsLevelController level;
  final LiveDesignService service;
  final String? companyId;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsDraftHost>.value(value: host),
        ChangeNotifierProvider<SettingsLevelController>.value(value: level),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('preview')),
        ),
        body: companyId == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<Company?>(
                stream: services.company.watchCompany(companyId!),
                builder: (context, snapshot) {
                  return LivePdfPreviewPane(
                    service: service,
                    enabledModulesBitmask:
                        snapshot.data?.enabledModules ?? 0,
                  );
                },
              ),
      ),
    );
  }
}

/// Desktop split-pane side preview. Mounted by [GeneralSettingsBody] inside
/// an `Expanded`/`ConstrainedBox` when the parent constraints have
/// `maxWidth >= 1024`. The form column and this pane share the same
/// Provider scope, so we read [SettingsDraftHost] off the existing
/// `Provider` without re-providing.
///
/// Renders against a `surfaceAlt` background so the preview reads as a
/// distinct panel against the form's `surface`. The `VerticalDivider`
/// upstream is the only boundary chrome — no card, no shadow.
class _SidePreview extends StatefulWidget {
  const _SidePreview({required this.companyId});

  final String companyId;

  @override
  State<_SidePreview> createState() => _SidePreviewState();
}

class _SidePreviewState extends State<_SidePreview> {
  late final LiveDesignService _service;
  late final Stream<Company?> _companyStream;

  @override
  void initState() {
    super.initState();
    final services = context.read<Services>();
    _service = LiveDesignService(services.apiClient);
    // Cache the company stream so every parent rebuild doesn't trigger a
    // fresh `watchCompany(...)` call (Drift returns a new stream instance
    // per call). The bitmask only changes when the company row updates,
    // which is rare — the stream stays alive for the screen's lifetime.
    _companyStream = services.company.watchCompany(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately `read`, not `watch`: keystrokes in the form fire
    // `host.notifyListeners()` and watching here would rebuild the whole
    // preview subtree (including the cached company stream's builder) on
    // every character typed. The Save button's enable state has its own
    // narrow watcher in [_InlinePreviewSaveButton].
    final tokens = context.inTheme;
    return ColoredBox(
      color: tokens.surfaceAlt,
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<Company?>(
              stream: _companyStream,
              builder: (context, snapshot) {
                return LivePdfPreviewPane(
                  service: _service,
                  enabledModulesBitmask: snapshot.data?.enabledModules ?? 0,
                  embedded: true,
                );
              },
            ),
          ),
          const _InlinePreviewSaveButton(),
        ],
      ),
    );
  }
}

/// Save button anchored to the bottom-right of the side preview pane.
///
/// Lives as its own widget so the host watch only rebuilds this button —
/// not the preview tree. Without this split, every keystroke in the form
/// would re-run `_SidePreview.build`, which would create a fresh
/// `StreamBuilder<Company?>` subscription, etc.
///
/// `host.save()` is itself idempotent: `SettingsDraftViewModel.save()`
/// (`settings_draft_view_model.dart:312-314`) early-returns when
/// `_isSaving` is already true, so a double-click can't fire two parallel
/// saves. The `onPressed` guard below greys the button as soon as the
/// first click flips `isSaving`, so visually the user can't even reach the
/// double-click state — the VM guard is belt-and-braces.
class _InlinePreviewSaveButton extends StatelessWidget {
  const _InlinePreviewSaveButton();

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.md(context),
        vertical: InSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: host.isDirty && !host.isSaving
                ? () => host.save()
                : null,
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}

