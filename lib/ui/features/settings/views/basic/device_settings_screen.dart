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
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';

/// Top-level "Device Settings" page. Holds app-specific options that are not
/// stored on the server: theme, and the "download all data locally" action.
/// Unlike most settings screens this has no cascade — every control writes
/// directly to a device-local store (e.g. `nav_state` for theme).
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
                children: [ThemeTile(controller: services.theme)],
              ),
              if (showSecurity)
                FormSection(
                  title: context.tr('security'),
                  children: const [BiometricToggleTile()],
                ),
              const _DataSection(),
            ],
          );
        },
      ),
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
