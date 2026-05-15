import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/views/advanced/templates_reminders/templates_reminders_body.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/templates_reminders_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';

class TemplatesRemindersScreen extends StatelessWidget {
  const TemplatesRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CascadeSettingsScaffold(
      titleKey: 'templates_and_reminders',
      companyVmFactory: ({required repo, required companyId}) =>
          TemplatesRemindersViewModel(repo: repo, companyId: companyId),
      body: const TemplatesRemindersBody(),
    );
  }
}
