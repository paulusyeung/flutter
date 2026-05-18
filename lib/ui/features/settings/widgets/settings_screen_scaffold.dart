import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/widgets/settings_scope_banner.dart';
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
    this.leading,
  });

  final String titleKey;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// Optional explicit AppBar leading. When non-null it is used on **every**
  /// width and `automaticallyImplyLeading` is forced false — for drill-in
  /// screens (e.g. Custom Designs) that need a real back affordance even on
  /// wide layouts, where the default behavior shows no leading at all.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final globalNav = Breakpoints.isGlobalNavVisible(context);
    return Scaffold(
      drawer: globalNav ? null : const AppDrawer(),
      appBar: AppBar(
        title: Text(context.tr(titleKey)),
        leading: leading ?? (globalNav ? null : const DrawerHamburger()),
        automaticallyImplyLeading: leading == null && !globalNav,
        actions: actions,
        bottom: bottom,
      ),
      // Banner sits above the body so the user always sees the scope they're
      // editing. The widget self-hides at company scope, so wide-mode (where
      // the shell renders its own banner) doesn't get a duplicate — narrow
      // mode bypasses the shell entirely and this is the only path.
      body: Column(
        children: [
          const SettingsScopeBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}
