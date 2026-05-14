import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/biometric_toggle_tile.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _signingOut = false;
  // Resolved once on mount so the Security section either renders or is
  // omitted entirely. Without this gate, devices without biometrics
  // (most desktops) would see an empty labeled "Security" card —
  // `BiometricToggleTile` self-hides via SizedBox.shrink, but the
  // FormSection chrome (header + divider + padding) stays.
  late final Future<bool> _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _biometricAvailable = context.read<Services>().biometric.isAvailable();
  }

  Future<void> _onSignOut() async {
    setState(() => _signingOut = true);
    await SettingsActions.signOut(context);
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return SettingsScreenScaffold(
      titleKey: 'user_details',
      body: FutureBuilder<bool>(
        future: _biometricAvailable,
        builder: (context, snap) {
          final showSecurity = snap.data == true;
          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('profile'),
                children: [
                  Text(
                    context.tr('user_details_coming_soon_subtitle'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
                  ),
                ],
              ),
              if (showSecurity)
                FormSection(
                  title: context.tr('security'),
                  children: const [BiometricToggleTile()],
                ),
              FormSection(
                title: context.tr('sign_out'),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _signingOut ? null : _onSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        minimumSize: const Size(64, 40),
                      ),
                      icon: _signingOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(context.tr('sign_out')),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
