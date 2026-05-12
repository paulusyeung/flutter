import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Shared chrome for every settings screen: a wide/narrow-aware [Scaffold]
/// with an [AppDrawer] on narrow widths and a consistent [AppBar] that
/// localizes its title via [titleKey]. Use [actions] and [bottom] to extend
/// the AppBar (e.g. a Save button + TabBar on Company Details).
class SettingsScreenScaffold extends StatelessWidget {
  const SettingsScreenScaffold({
    super.key,
    required this.titleKey,
    required this.body,
    this.actions,
    this.bottom,
  });

  final String titleKey;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

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
            actions: actions,
            bottom: bottom,
          ),
          body: body,
        );
      },
    );
  }
}
