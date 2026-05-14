import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/custom_fields_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/custom_fields_shell.dart';
import 'package:admin/ui/features/settings/widgets/custom_field_row.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kCustomFieldsClientsSearchKeys = <String>[
  'client_field',
  'contact_field',
  'location_field',
  'label',
  'field_type',
  'single_line_text',
  'multi_line_text',
  'switch',
  'date',
  'dropdown',
];

class CustomFieldsClientsScreen extends StatelessWidget {
  const CustomFieldsClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = customFieldsAccess(context);
    return SettingsFormShell(
      sections: [
        _section(context, access, 'client_field', 'client'),
        _section(context, access, 'contact_field', 'contact'),
        _section(context, access, 'location_field', 'location'),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    ({String companyId, bool enabled}) access,
    String titleKey,
    String prefix,
  ) => FormSection(
    title: context.tr(titleKey),
    children: [
      for (var i = 1; i <= 4; i++)
        CustomFieldRow<CustomFieldsViewModel>(
          key: ValueKey('${access.companyId}:$prefix$i'),
          prefix: prefix,
          slot: i,
          enabled: access.enabled,
        ),
    ],
  );
}
