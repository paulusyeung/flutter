import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Stub scaffold used by every Settings sub-page that hasn't been built yet.
/// Drop in `titleKey` (e.g. 'logo') and you get a responsive screen with the
/// drawer wired up on narrow widths.
class PlaceholderSettingsScreen extends StatelessWidget {
  const PlaceholderSettingsScreen({super.key, required this.titleKey});

  /// Localization key for the AppBar title. Resolved via `context.tr(titleKey)`.
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: titleKey,
      body: Center(child: Text(context.tr('coming_soon'))),
    );
  }
}
