import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

class AccountManagementOverviewScreen extends StatefulWidget {
  const AccountManagementOverviewScreen({super.key});

  @override
  State<AccountManagementOverviewScreen> createState() =>
      _AccountManagementOverviewScreenState();
}

class _AccountManagementOverviewScreenState
    extends State<AccountManagementOverviewScreen> {
  bool _resyncing = false;

  Future<void> _onForceResync() async {
    setState(() => _resyncing = true);
    await SettingsActions.forceResync(context);
    if (mounted) setState(() => _resyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'overview',
      body: SettingsFormShell(
        sections: [
          FormSection(
            title: context.tr('data'),
            spacing: 0,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(context.tr('force_full_resync')),
                subtitle: Text(context.tr('force_resync_description')),
                trailing: _resyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _resyncing ? null : _onForceResync,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
