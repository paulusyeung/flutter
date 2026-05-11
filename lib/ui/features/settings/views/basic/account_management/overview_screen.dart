import 'package:flutter/material.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: const Text('Overview'),
            leading: wide ? null : const DrawerHamburger(),
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Force full resync'),
                subtitle: const Text(
                  'Re-download all clients from the server. Use this if the '
                  'local cache feels out of date.',
                ),
                trailing: _resyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _resyncing ? null : _onForceResync,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
