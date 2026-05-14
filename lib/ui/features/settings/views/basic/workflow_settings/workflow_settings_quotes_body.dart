import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Quotes tab — field labels surfaced by the in-app search.
const kWorkflowSettingsQuotesSearchKeys = <String>[
  'auto_convert_quote',
  'auto_archive_quote',
  'use_quote_terms',
];

/// Quote-side workflow toggles. Two cascade-aware booleans (`settings.*`) and
/// one top-level `Company` field (`use_quote_terms_on_conversion`) that only
/// renders at company scope.
class WorkflowSettingsQuotesBody extends StatelessWidget {
  const WorkflowSettingsQuotesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();
    final isCompanyScope = scope.isCompany;

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('quote_workflow'),
          children: [
            OverridableSwitchField(
              label: context.tr('auto_convert_quote'),
              apiKey: 'auto_convert_quote',
              subtitle: context.tr('auto_convert_quote_help'),
            ),
            OverridableSwitchField(
              label: context.tr('auto_archive_quote'),
              apiKey: 'auto_archive_quote',
              subtitle: context.tr('auto_archive_quote_help'),
            ),
            if (isCompanyScope)
              SwitchListTile(
                title: Text(context.tr('use_quote_terms')),
                subtitle: Text(context.tr('use_quote_terms_help')),
                value: host.draft?.useQuoteTermsOnConversion ?? false,
                onChanged: (v) => host.updateCompany(
                  (c) => c.copyWith(useQuoteTermsOnConversion: v),
                ),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }
}
