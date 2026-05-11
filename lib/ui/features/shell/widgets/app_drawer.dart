import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';

/// Mobile drawer that consolidates what desktop shows in the persistent
/// `InSidebar`: company switcher + branch nav + trial footer.
///
/// Reads the active `StatefulNavigationShell` from a `Provider` rooted on
/// `ScaffoldWithNav` so branch swaps go through `goBranch(...)` —
/// preserving each branch's inner navigator stack (e.g. an open client
/// detail survives a Dashboard detour).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<StatefulNavigationShell>();
    return Drawer(
      width: 280,
      child: InSidebar(
        // Null = stretch to fill the drawer's 280 instead of the desktop 232.
        width: null,
        currentBranch: nav.currentIndex,
        onBeforeCompanyPicker: () => Navigator.pop(context),
        onSelectBranch: (index) {
          Navigator.pop(context);
          nav.goBranch(index, initialLocation: index == nav.currentIndex);
        },
      ),
    );
  }
}

/// Convenience hamburger that opens the nearest `Scaffold`'s drawer.
/// Drop into an `AppBar.leading` on top-level mobile screens. Wraps a
/// `Builder` so `Scaffold.of(context)` finds the surrounding Scaffold
/// instead of looking above it.
class DrawerHamburger extends StatelessWidget {
  const DrawerHamburger({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        tooltip: context.tr('menu'),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}
