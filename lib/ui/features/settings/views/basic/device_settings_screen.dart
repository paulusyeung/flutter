import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Top-level "Device Settings" page. Holds app-specific options that are not
/// stored on the server: theme, and the "download all data locally" action.
/// Unlike most settings screens this has no cascade — every control writes
/// directly to a device-local store (e.g. `nav_state` for theme).
class DeviceSettingsScreen extends StatelessWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('device_settings')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: SettingsFormShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSection(
                  title: context.tr('theme'),
                  children: [_ThemeControl(controller: services.theme)],
                ),
                const _DataSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeControl extends StatelessWidget {
  const _ThemeControl({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(context.tr('auto')),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(context.tr('light')),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(context.tr('dark')),
            ),
          ],
          selected: {controller.value},
          onSelectionChanged: (s) => controller.set(s.first),
        ),
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
        const SizedBox(height: InSpacing.md),
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
