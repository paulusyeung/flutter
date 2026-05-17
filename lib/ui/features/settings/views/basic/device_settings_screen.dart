import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/biometric_toggle_tile.dart';
import 'package:admin/ui/features/settings/widgets/customize_colors_section.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';
import 'package:admin/ui/features/dashboard/widgets/onboarding_tour.dart';

/// Top-level "Device Settings" page. Holds the device-local, no-save controls:
/// theme (mode + palette), the per-preset colour overrides, biometric
/// security, and the "download all data locally" action. Unlike most settings
/// screens this has no cascade and no save bar — every control writes
/// immediately to a device-local store (`nav_state`). Only the accent colour
/// is server-synced; it lives on User Details → Preferences with the save bar.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  // Resolved once on mount so the Security section either renders or is
  // omitted entirely — without this gate, devices without biometrics (most
  // desktops) would see an empty labeled "Security" card.
  late final Future<bool> _biometricAvailable;

  @override
  void initState() {
    super.initState();
    _biometricAvailable = context.read<Services>().biometric.isAvailable();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsScreenScaffold(
      titleKey: 'device_settings',
      body: FutureBuilder<bool>(
        future: _biometricAvailable,
        builder: (context, snap) {
          final showSecurity = snap.data == true;
          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('theme'),
                spacing: 0,
                children: [
                  ThemeTile(controller: services.theme),
                  const Divider(height: 1),
                  CustomizeColorsSection(controller: services.theme),
                ],
              ),
              if (showSecurity)
                FormSection(
                  title: context.tr('security'),
                  children: const [BiometricToggleTile()],
                ),
              const _HelpSection(),
              const _DataSection(),
            ],
          );
        },
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  Future<void> _replayTour(BuildContext context) async {
    final onboarding = context.read<Services>().onboarding;
    await onboarding.reset();
    if (!context.mounted) return;
    await showOnboardingTour(context);
    await onboarding.markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('help'),
      children: [
        Text(
          context.tr('onboarding_welcome_body'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => _replayTour(context),
            icon: const Icon(Icons.slideshow_outlined, size: 18),
            label: Text(context.tr('show_app_tour')),
          ),
        ),
      ],
    );
  }
}

class _DataSection extends StatefulWidget {
  const _DataSection();

  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    await SettingsActions.forceResync(context);
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('data'),
      children: [
        Text(
          context.tr('download_data'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
            label: Text(context.tr('download')),
          ),
        ),
      ],
    );
  }
}
