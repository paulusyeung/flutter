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

/// Clients tab: three sections — Client / Contact / Location — each with the
/// usual four `<prefix><n>` slots. Section titles are spelled out with
/// literal `context.tr('<key>')` calls so the search-catalog consistency
/// test's regex picks them up.
class CustomFieldsClientsScreen extends StatelessWidget {
  const CustomFieldsClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = customFieldsAccess(context);
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('client_field'),
          children: _rows(access, 'client'),
        ),
        FormSection(
          title: context.tr('contact_field'),
          children: _rows(access, 'contact'),
        ),
        FormSection(
          title: context.tr('location_field'),
          children: _rows(access, 'location'),
        ),
      ],
    );
  }

  List<Widget> _rows(
    ({String companyId, bool enabled}) access,
    String prefix,
  ) => [
    for (var i = 1; i <= 4; i++)
      CustomFieldRow<CustomFieldsViewModel>(
        key: ValueKey('${access.companyId}:$prefix$i'),
        prefix: prefix,
        slot: i,
        enabled: access.enabled,
      ),
  ];
}
