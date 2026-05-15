import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/offline_banner.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
import 'package:admin/ui/features/shell/widgets/keyboard_shortcuts_dialog.dart';
import 'package:admin/ui/features/shell/widgets/show_company_picker.dart';
import 'package:admin/ui/features/shell/widgets/sync_event_listener.dart';
import 'package:admin/ui/features/tasks/widgets/running_timer_pill.dart';

/// Persistent shell for the authenticated app.
///
/// Hosts the active [StatefulNavigationShell] branch and renders
/// platform-appropriate navigation: the v2 design `InSidebar` on wide
/// layouts and a `MobileTopBar` + bottom `NavigationBar` on narrow ones.
/// The list of bottom destinations is the subset of the sidebar that has
/// a real route today — Clients, Dashboard, Settings.
///
/// Three global keyboard shortcuts live here:
/// - `⌘K` / `Ctrl+K` opens the company picker.
/// - `?` opens the Keyboard Shortcuts helper dialog.
/// - `/` focuses the active list screen's token search field (no-op on
///   screens without one).
///
/// `?` and `/` use [CharacterActivator] so they fire on the produced
/// character, layout-independently — `Shift+/` on US, `Shift+Comma` on
/// AZERTY, etc.
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
        // Character-based activators handle the layout-independent case:
        // `Shift+/` on US, `Shift+Comma` on AZERTY, etc. all produce the
        // same character and trigger the same intent. SingleActivator on
        // a logical key wouldn't fire here — there is no logical key for
        // `?`, and `slash + shift` doesn't reach the matcher reliably
        // across platforms. See Flutter SDK shortcuts.dart docstring on
        // `CharacterActivator`.
        CharacterActivator('?'): _OpenKeyboardShortcutsIntent(),
        CharacterActivator('/'): _FocusSearchIntent(),
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
          _OpenKeyboardShortcutsIntent:
              CallbackAction<_OpenKeyboardShortcutsIntent>(
                onInvoke: (_) {
                  // Same EditableText guard as Cmd/Ctrl+K — a `?` typed
                  // inside a search or notes field must reach the field.
                  final focus = FocusManager.instance.primaryFocus;
                  final widget = focus?.context?.widget;
                  if (widget is EditableText) return null;
                  showKeyboardShortcutsDialog(context);
                  return null;
                },
              ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              // Same guard so `/` typed in any text field types `/`.
              final focus = FocusManager.instance.primaryFocus;
              final widget = focus?.context?.widget;
              if (widget is EditableText) return null;
              context.read<Services>().searchFocus.current?.requestFocus();
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
                                Expanded(
                                  child: Stack(
                                    children: [
                                      navigationShell,
                                      // Pinned bottom-right above the active
                                      // route's body. Hidden when no task is
                                      // running — see `RunningTimerPill`.
                                      const Positioned(
                                        right: 16,
                                        bottom: 16,
                                        child: RunningTimerPill(),
                                      ),
                                    ],
                                  ),
                                ),
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
                      Expanded(
                        child: Stack(
                          children: [
                            navigationShell,
                            // Narrow: pin above the bottom NavigationBar each
                            // screen owns + clear of the per-screen FAB
                            // (Material default bottom 16, FAB extends to ~72;
                            // bottom: 112 guarantees a 40px gap on shorter
                            // phones where the nav bar pushes the FAB up).
                            // The pill hides itself when no task is running,
                            // so it never obstructs empty space.
                            const Positioned(
                              right: 12,
                              bottom: 112,
                              child: RunningTimerPill(),
                            ),
                          ],
                        ),
                      ),
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

class _OpenKeyboardShortcutsIntent extends Intent {
  const _OpenKeyboardShortcutsIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}
