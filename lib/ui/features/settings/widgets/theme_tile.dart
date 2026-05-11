import 'package:flutter/material.dart';

import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';

/// ListTile that exposes the system / light / dark theme choice. Bound to a
/// [ThemeController] so toggling persists through `nav_state.theme_mode` and
/// flips the app theme immediately. Used on both User Details → Preferences
/// and the top-level Device Settings page.
class ThemeTile extends StatelessWidget {
  const ThemeTile({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mode = controller.value;
        return ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: Text(context.tr('theme')),
          subtitle: Text(_label(context, mode)),
          trailing: SegmentedButton<ThemeMode>(
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
            selected: {mode},
            onSelectionChanged: (s) => controller.set(s.first),
          ),
        );
      },
    );
  }

  String _label(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.tr('match_system'),
    ThemeMode.light => context.tr('light'),
    ThemeMode.dark => context.tr('dark'),
  };
}
