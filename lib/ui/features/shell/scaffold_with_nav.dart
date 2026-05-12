import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/offline_banner.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
import 'package:admin/ui/features/shell/widgets/show_company_picker.dart';
import 'package:admin/ui/features/shell/widgets/sync_event_listener.dart';

/// Persistent shell for the authenticated app.
///
/// Hosts the active [StatefulNavigationShell] branch and renders
/// platform-appropriate navigation: the v2 design `InSidebar` on wide
/// layouts and a `MobileTopBar` + bottom `NavigationBar` on narrow ones.
/// The list of bottom destinations is the subset of the sidebar that has
/// a real route today — Clients, Dashboard, Settings.
///
/// A global `⌘K` / `Ctrl+K` shortcut opens the company picker.
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  Future<void> _goBranch(BuildContext context, int index) async {
    final guard = context.read<Services>().unsavedChangesGuard;
    if (!await guard.confirmIfDirty(context)) return;
    if (!context.mounted) return;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _OpenCompanyPickerIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _OpenCompanyPickerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenCompanyPickerIntent: CallbackAction<_OpenCompanyPickerIntent>(
            onInvoke: (_) {
              // Ignore the shortcut when the user is typing in a TextField —
              // a focused EditableText handles the key itself, but other
              // focused widgets (e.g. a focused button) still bubble up.
              final focus = FocusManager.instance.primaryFocus;
              final widget = focus?.context?.widget;
              if (widget is EditableText) return null;
              showCompanyPicker(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Provider<StatefulNavigationShell>.value(
            // Expose the shell so descendants (notably `AppDrawer` on each
            // top-level mobile screen) can call `goBranch` without
            // re-receiving it through a constructor chain.
            value: navigationShell,
            child: SyncEventListener(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (Breakpoints.isWide(constraints)) {
                    return Scaffold(
                      body: Row(
                        children: [
                          InSidebar(
                            currentBranch: navigationShell.currentIndex,
                            onSelectBranch: (i) => _goBranch(context, i),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const OfflineBanner(),
                                Expanded(child: navigationShell),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Narrow: passthrough — each top-level screen renders its
                  // own Scaffold with `drawer: AppDrawer()` + a hamburger.
                  // No outer Scaffold avoids `Scaffold.of(context)` ambiguity.
                  // The banner stacks above the per-screen Scaffold here;
                  // `OfflineBanner` handles its own top inset when shown so
                  // it doesn't disappear behind the status bar / notch.
                  return Column(
                    children: [
                      const OfflineBanner(),
                      Expanded(child: navigationShell),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenCompanyPickerIntent extends Intent {
  const _OpenCompanyPickerIntent();
}
