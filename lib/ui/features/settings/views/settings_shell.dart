import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/views/settings_screen.dart';

/// Master-detail shell for `/settings/*` on wide screens.
///
/// - **Wide (≥600 px)**: left pane is `SettingsListSidebar` (always visible);
///   right pane is the routed child, or a "Select a setting" hint when the
///   user is sitting on `/settings` with no section chosen.
/// - **Narrow**: passes through so each section page (or `SettingsScreen` at
///   `/settings`) renders as its own full-screen Scaffold.
class SettingsShell extends StatelessWidget {
  const SettingsShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        if (!wide) return child;

        final atIndex = GoRouterState.of(context).uri.path == '/settings';
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 280,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: const SettingsListSidebar(),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: atIndex ? const _SelectAHint() : child),
            ],
          ),
        );
      },
    );
  }
}

class _SelectAHint extends StatelessWidget {
  const _SelectAHint();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            'Select a setting from the list',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
