import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_markdown_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsDefaultsSearchKeys = <String>[
  'invoice_terms',
  'invoice_footer',
  'quote_terms',
  'quote_footer',
  'credit_terms',
  'credit_footer',
  'purchase_order_terms',
  'purchase_order_footer',
];

/// "Defaults" tab — the eight pairs of terms/footer fields applied by
/// default to every newly-created invoice, quote, credit, and purchase
/// order. Each field is a WYSIWYG markdown editor; the server renders the
/// markdown into PDFs and emails when `company.markdown_enabled` is on.
class CompanyDetailsDefaultsScreen extends StatelessWidget {
  const CompanyDetailsDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('invoice'),
          children: [
            OverridableMarkdownField(
              label: context.tr('terms'),
              apiKey: 'invoice_terms',
            ),
            OverridableMarkdownField(
              label: context.tr('footer'),
              apiKey: 'invoice_footer',
            ),
          ],
        ),
        FormSection(
          title: context.tr('quote'),
          children: [
            OverridableMarkdownField(
              label: context.tr('terms'),
              apiKey: 'quote_terms',
            ),
            OverridableMarkdownField(
              label: context.tr('footer'),
              apiKey: 'quote_footer',
            ),
          ],
        ),
        FormSection(
          title: context.tr('credit'),
          children: [
            OverridableMarkdownField(
              label: context.tr('terms'),
              apiKey: 'credit_terms',
            ),
            OverridableMarkdownField(
              label: context.tr('footer'),
              apiKey: 'credit_footer',
            ),
          ],
        ),
        FormSection(
          title: context.tr('purchase_order'),
          children: [
            OverridableMarkdownField(
              label: context.tr('terms'),
              apiKey: 'purchase_order_terms',
            ),
            OverridableMarkdownField(
              label: context.tr('footer'),
              apiKey: 'purchase_order_footer',
            ),
          ],
        ),
      ],
    );
  }
}
