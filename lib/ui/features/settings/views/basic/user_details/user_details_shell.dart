import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/connect_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/notifications_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/password_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/preferences_screen.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/two_factor_screen.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Settings > User Details — 6 tabs (Details, Password, Connect, Two Factor,
/// Notifications, Preferences) hosted by the generic [TabbedSettingsShell].
/// Mirrors the layout of the React user-details page minus the Custom Fields
/// tab; user custom-field definitions live under Settings > Custom Fields
/// instead. The accent-colour picker now lives inside the Preferences tab.
class UserDetailsShell extends StatelessWidget {
  const UserDetailsShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null on the bare
  /// `/settings/user_details` URL (defaults to the Details tab).
  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return TabbedSettingsShell<UserDetailsViewModel>(
      titleKey: 'user_details',
      basePath: '/settings/user_details',
      initialTab: initialTab,
      companyVmFactory: (companyId) => UserDetailsViewModel(
        repo: services.user,
        auth: services.auth,
        companyId: companyId,
      ),
      resolveErrorTabSlug: (vm) => vm.tabSlugForFirstError(),
      tabs: const [
        TabbedSettingsTab(
          slug: '',
          labelKey: 'details',
          body: UserDetailsDetailsScreen(),
        ),
        TabbedSettingsTab(
          slug: 'password',
          labelKey: 'password',
          body: UserDetailsPasswordScreen(),
        ),
        TabbedSettingsTab(
          slug: 'connect',
          labelKey: 'oauth_mail',
          body: UserDetailsConnectScreen(),
        ),
        TabbedSettingsTab(
          slug: 'enable_two_factor',
          labelKey: 'enable_two_factor',
          body: UserDetailsTwoFactorScreen(),
          contributesToSave: false,
        ),
        TabbedSettingsTab(
          slug: 'notifications',
          labelKey: 'notifications',
          body: UserDetailsNotificationsScreen(),
        ),
        TabbedSettingsTab(
          slug: 'preferences',
          labelKey: 'preferences',
          body: UserDetailsPreferencesScreen(),
        ),
      ],
    );
  }
}
