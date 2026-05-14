import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/custom_fields_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/custom_fields_shell.dart';
import 'package:admin/ui/features/settings/widgets/custom_field_row.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kCustomFieldsVendorsSearchKeys = <String>[
  'vendor_field',
  'contact_field',
  'label',
  'field_type',
  'single_line_text',
  'multi_line_text',
  'switch',
  'date',
  'dropdown',
];

class CustomFieldsVendorsScreen extends StatelessWidget {
  const CustomFieldsVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = customFieldsAccess(context);
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('vendor_field'),
          children: [
            for (var i = 1; i <= 4; i++)
              CustomFieldRow<CustomFieldsViewModel>(
                key: ValueKey('${access.companyId}:vendor$i'),
                prefix: 'vendor',
                slot: i,
                enabled: access.enabled,
              ),
          ],
        ),
        FormSection(
          // Vendor contacts reuse the generic `contact_field` localization
          // key — matches old Flutter `vendor_contact_field` → `contact_field`
          // alias in admin-portal `lib/ui/settings/custom_fields.dart`.
          title: context.tr('contact_field'),
          children: [
            for (var i = 1; i <= 4; i++)
              CustomFieldRow<CustomFieldsViewModel>(
                key: ValueKey('${access.companyId}:vendor_contact$i'),
                prefix: 'vendor_contact',
                slot: i,
                enabled: access.enabled,
              ),
          ],
        ),
      ],
    );
  }
}
