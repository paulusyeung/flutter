import 'package:flutter/material.dart';

import 'package:admin/data/static/pdf_catalogs.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_reorderable_field_list.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Tab body that renders a single PDF-variable section as a reorderable
/// multi-select. Backs all 10 variable tabs (Client/Company/Address details,
/// per-document details, product / quote-product / task columns, total
/// fields).
class PdfVariableListBody extends StatelessWidget {
  const PdfVariableListBody({super.key, required this.sectionKey});

  /// One of [PdfVariableSection.*] (e.g. `'client_details'`).
  final String sectionKey;

  @override
  Widget build(BuildContext context) {
    final catalog = kPdfVariableSections[sectionKey];
    if (catalog == null) {
      // Defensive: a route that points at a section key we don't recognize.
      // Shouldn't happen in normal use because the shell only registers the
      // catalog's known keys, but if it does we render a quiet message
      // instead of throwing.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.tr('not_found')),
        ),
      );
    }

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr(catalog.titleKey),
          children: [OverridableReorderableFieldList(catalog: catalog)],
        ),
      ],
    );
  }
}
