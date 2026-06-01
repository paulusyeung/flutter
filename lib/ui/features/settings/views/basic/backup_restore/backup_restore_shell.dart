import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/widgets/backup_tab.dart';
import 'package:admin/ui/features/settings/views/basic/backup_restore/widgets/restore_tab.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Settings → Backup | Restore. Two URL-driven tabs:
///
/// * `/settings/backup_restore` → Backup tab (server emails the user a
///   download link for the current company's export).
/// * `/settings/backup_restore/restore` → Restore tab (chunked .zip upload
///   into `/api/v1/import_json`).
///
/// Pairs with `tabbedSettingsRoutePair(...)` in `settings_routes.dart` — both
/// URLs resolve to a single Navigator Page so swiping a tab from the bare URL
/// doesn't remount the shell (and the in-progress upload state on Restore
/// survives a quick detour to Backup).
///
/// Modeled on `TabbedSettingsShell` (`widgets/tabbed_settings_shell.dart`) but
/// without the VM scaffolding — neither tab has a Save button or settings
/// draft, so the cascade host would be pure overhead here.
class BackupRestoreShell extends StatefulWidget {
  const BackupRestoreShell({super.key, this.initialTab});

  /// The `:tab` path-parameter from the route, or null on the bare URL
  /// (defaults to the Backup tab).
  final String? initialTab;

  @override
  State<BackupRestoreShell> createState() => _BackupRestoreShellState();
}

class _BackupRestoreShellState extends State<BackupRestoreShell>
    with SingleTickerProviderStateMixin {
  static const _basePath = '/settings/backup_restore';
  static const _tabs = <_TabDef>[
    _TabDef(slug: '', labelKey: 'backup'),
    _TabDef(slug: 'restore', labelKey: 'restore'),
  ];

  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _indexForSlug(widget.initialTab),
    );
    _controller.addListener(_onTabSettled);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabSettled);
    _controller.dispose();
    super.dispose();
  }

  void _onTabSettled() {
    if (_controller.indexIsChanging) return;
    final tab = _tabs[_controller.index];
    final desired = tab.slug.isEmpty ? _basePath : '$_basePath/${tab.slug}';
    final current = GoRouterState.of(context).uri.path;
    if (current == desired) return;
    context.go(desired);
  }

  int _indexForSlug(String? slug) {
    if (slug == null || slug.isEmpty) return 0;
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].slug == slug) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller in sync if the URL changed externally (back
    // button, deep link, settings search). The `!=` guard prevents the
    // controller listener (which pushes URL updates) from looping back.
    final currentTab = GoRouterState.of(context).pathParameters['tab'];
    final urlIndex = _indexForSlug(currentTab);
    if (urlIndex != _controller.index && !_controller.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (urlIndex != _controller.index) {
          _controller.animateTo(urlIndex);
        }
      });
    }

    final tokens = context.inTheme;
    return SettingsScreenScaffold(
      titleKey: 'backup_restore',
      bottom: TabBar(
        controller: _controller,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        labelColor: tokens.ink,
        unselectedLabelColor: tokens.ink3,
        indicatorColor: tokens.accent,
        indicatorWeight: 2,
        tabs: [for (final tab in _tabs) Tab(text: context.tr(tab.labelKey))],
      ),
      body: TabBarView(
        controller: _controller,
        children: const [BackupTabBody(), RestoreTabBody()],
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.slug, required this.labelKey});
  final String slug;
  final String labelKey;
}
