import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Stub scaffold used by every Settings sub-page that hasn't been built yet.
/// Drop in `titleKey` (e.g. 'logo') and you get a responsive screen with the
/// drawer wired up on narrow widths.
class PlaceholderSettingsScreen extends StatelessWidget {
  const PlaceholderSettingsScreen({super.key, required this.titleKey});

  /// Localization key for the AppBar title. Resolved via `context.tr(titleKey)`.
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr(titleKey)),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: Center(child: Text(context.tr('coming_soon'))),
        );
      },
    );
  }
}
