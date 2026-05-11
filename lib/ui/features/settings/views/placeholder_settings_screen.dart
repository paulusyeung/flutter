import 'package:flutter/material.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Stub scaffold used by every Settings sub-page that hasn't been built yet.
/// Drop in `title` (e.g. 'Logo') and you get a responsive screen with the
/// drawer wired up on narrow widths.
class PlaceholderSettingsScreen extends StatelessWidget {
  const PlaceholderSettingsScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(title),
            leading: wide ? null : const DrawerHamburger(),
          ),
          body: const Center(child: Text('Coming soon')),
        );
      },
    );
  }
}
