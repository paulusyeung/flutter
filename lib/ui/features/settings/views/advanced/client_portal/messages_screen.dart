import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Searchable label keys rendered by the Messages tab. Mirrors the field
/// list below; aggregated into `kSettingsSearchCatalog['client_portal']`.
const kClientPortalMessagesSearchKeys = <String>[
  'messages',
  'dashboard',
  'unpaid_invoice',
  'paid_invoice',
  'unapproved_quote',
];

/// Messages tab — long-form custom messages shown on the dashboard /
/// invoice / quote pages of the public portal. Dashboard is company-scope
/// only; the per-state invoice / quote messages cascade to group / client.
class ClientPortalMessagesScreen extends StatelessWidget {
  const ClientPortalMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final level = context.watch<SettingsLevelController>().level;
    final showDashboard = level == SettingsLevel.company;
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('messages'),
          children: [
            if (showDashboard) ...[
              OverridableTextField(
                label: context.tr('dashboard'),
                apiKey: 'custom_message_dashboard',
                maxLines: 6,
              ),
              SizedBox(height: InSpacing.md(context)),
            ],
            OverridableTextField(
              label: context.tr('unpaid_invoice'),
              apiKey: 'custom_message_unpaid_invoice',
              maxLines: 6,
            ),
            SizedBox(height: InSpacing.md(context)),
            OverridableTextField(
              label: context.tr('paid_invoice'),
              apiKey: 'custom_message_paid_invoice',
              maxLines: 6,
            ),
            SizedBox(height: InSpacing.md(context)),
            OverridableTextField(
              label: context.tr('unapproved_quote'),
              apiKey: 'custom_message_unapproved_quote',
              maxLines: 6,
            ),
          ],
        ),
      ],
    );
  }
}
