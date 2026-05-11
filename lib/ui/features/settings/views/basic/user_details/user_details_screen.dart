import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _signingOut = false;

  Future<void> _onSignOut() async {
    setState(() => _signingOut = true);
    await SettingsActions.signOut(context);
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('user_details')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(context.tr('coming_soon')),
                subtitle: Text(
                  context.tr('user_details_coming_soon_subtitle'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  context.tr('sign_out'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
                enabled: !_signingOut,
                onTap: _signingOut ? null : _onSignOut,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
