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
    this.onTitleLongPress,
  });

  final String titleKey;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// Optional long-press handler on the AppBar title. Used by the System
  /// Logs screen to reveal a hidden debug panel — keep it as an opt-in so
  /// the affordance only attaches where it's intentionally wired.
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    final globalNav = Breakpoints.isGlobalNavVisible(context);
    final titleText = Text(context.tr(titleKey));
    final title = onTitleLongPress == null
        ? titleText
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: onTitleLongPress,
            child: titleText,
          );
    return Scaffold(
      drawer: globalNav ? null : const AppDrawer(),
      appBar: AppBar(
        title: title,
        leading: globalNav ? null : const DrawerHamburger(),
        automaticallyImplyLeading: !globalNav,
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
