import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/custom_fields_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/custom_fields/custom_fields_shell.dart';
import 'package:admin/ui/features/settings/widgets/custom_field_row.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kCustomFieldsProductsSearchKeys = <String>[
  'product_field',
  'label',
  'field_type',
  'single_line_text',
  'multi_line_text',
  'switch',
  'date',
  'dropdown',
];

class CustomFieldsProductsScreen extends StatelessWidget {
  const CustomFieldsProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final access = customFieldsAccess(context);
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('product_field'),
          children: [
            for (var i = 1; i <= 4; i++)
              CustomFieldRow<CustomFieldsViewModel>(
                key: ValueKey('${access.companyId}:product$i'),
                prefix: 'product',
                slot: i,
                enabled: access.enabled,
              ),
          ],
        ),
      ],
    );
  }
}
