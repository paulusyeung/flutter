import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/static/google_fonts_catalog.dart';
import 'package:admin/data/static/pdf_catalogs.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_color_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_design_picker.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_logo_size_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_radio_field.dart';
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
class GeneralSettingsBody extends StatelessWidget {
  const GeneralSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    // The live PDF preview now lives at the shell level (persistent across
    // tabs) — this body is just the form. The `StreamBuilder` still feeds the
    // design pickers their bundled designs.
    return StreamBuilder<List<Design>>(
      stream: companyId == null
          ? const Stream.empty()
          : services.designs.watchAll(companyId: companyId),
      builder: (context, snapshot) {
        final bundled = snapshot.data ?? const <Design>[];
        return _buildSections(context, bundled);
      },
    );
  }

  Widget _buildSections(BuildContext context, List<Design> bundled) {
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
    return SettingsFormShell(
      sections: [
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
          title: context.tr('custom_designs'),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(context.tr('custom_designs')),
              subtitle: Text(context.tr('custom_designs_help')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.go('/settings/invoice_design/custom_designs'),
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
            OverridableRadioField<bool>(
              label: context.tr('empty_columns'),
              apiKey: 'hide_empty_columns_on_pdf',
              value: settings.hideEmptyColumnsOnPdf,
              options: [
                (value: false, label: context.tr('show')),
                (value: true, label: context.tr('hide')),
              ],
              onChanged: (v) => host.updateSettings(
                (s) => s.copyWith(hideEmptyColumnsOnPdf: v),
              ),
            ),
            OverridableSwitchField(
              label: context.tr('page_numbering'),
              apiKey: 'page_numbering',
            ),
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
}
