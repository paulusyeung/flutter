import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// One entry in a [TabbedSettingsShell]'s tab list.
class TabbedSettingsTab {
  const TabbedSettingsTab({
    required this.slug,
    required this.labelKey,
    required this.body,
  });

  /// URL suffix without leading slash. The default tab uses an empty
  /// string — it resolves to the shell's bare base path (no `:tab`
  /// segment). The remaining tabs use their literal slug.
  final String slug;

  /// Localization key for the TabBar label (passed through `context.tr`).
  final String labelKey;

  /// Tab body. Construct fresh per build — see the non-const-children note
  /// on [TabbedSettingsShell]'s `TabBarView` for why.
  final Widget body;
}

/// Generic tabbed shell for company-only settings pages whose contents are
/// split across tabs (Company Details today; Client Portal / Templates &
/// Reminders next). Owns:
///
/// * the [TabController] (length matches [tabs], vsync = this) and its
///   disposal,
/// * the bi-directional URL ↔ tab-index sync (`_onTabControllerChanged`
///   pushes the settled index into the route via `context.go`; the build
///   method animates the controller when the URL changes externally — e.g.
///   the back button, a deep link, or the settings-search jump),
/// * the compose pattern `SettingsCompanyScopedHost<V>` →
///   `SettingsPageScaffold<V>` with `bottom: TabBar(...)` and
///   `body: TabBarView(...)`.
///
/// The caller supplies just `titleKey`, `basePath`, the optional `initialTab`
/// from the route, a `companyVmFactory`, and the `tabs` list. The shell calls
/// `vm.load()` itself, matching the precedent in the cascade scaffold.
///
/// Pair with [tabbedSettingsRoutePair] (in `settings_routes.dart`) to
/// register the matching bare-URL + `/:tab(<a>|<b>|...)` route entries — the
/// shared page key in that helper is what keeps the [TabController] + draft
/// VM alive across the two paths.
class TabbedSettingsShell<V extends SettingsDraftHost> extends StatefulWidget {
  const TabbedSettingsShell({
    super.key,
    required this.titleKey,
    required this.basePath,
    required this.initialTab,
    required this.companyVmFactory,
    required this.tabs,
    this.extraActions = const <Widget>[],
  }) : assert(tabs.length >= 2, 'TabbedSettingsShell needs at least two tabs');

  /// Localization key for the AppBar title.
  final String titleKey;

  /// Absolute path of the shell's bare URL (no trailing `/`). Used to
  /// build the per-tab URL when the controller settles on a new index.
  final String basePath;

  /// The `:tab` path-parameter from the route, or null on the bare URL
  /// (resolves to the first tab).
  final String? initialTab;

  /// Build the typed VM for the active company. Same shape as the
  /// `create` callback on [SettingsCompanyScopedHost]; the shell calls
  /// `vm.load()` itself, so the factory should *not* invoke load.
  final V Function(String companyId) companyVmFactory;

  /// Tab definitions, in display order. The first entry's `slug` should
  /// be empty (the default tab); the rest carry their literal slug.
  final List<TabbedSettingsTab> tabs;

  /// Additional AppBar action widgets rendered to the right of the Save
  /// button (passthrough to [SettingsPageScaffold]).
  final List<Widget> extraActions;

  @override
  State<TabbedSettingsShell<V>> createState() => _TabbedSettingsShellState<V>();
}

class _TabbedSettingsShellState<V extends SettingsDraftHost>
    extends State<TabbedSettingsShell<V>>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: _indexForSlug(widget.initialTab),
    );
    _tabController.addListener(_onTabControllerChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Push the controller's settled index into the URL so deep links + back
  /// button reflect the active tab. Skipped while `indexIsChanging` because
  /// the animation hasn't settled yet — we only want one navigation per
  /// user interaction.
  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    final slug = widget.tabs[_tabController.index].slug;
    final desiredPath = slug.isEmpty
        ? widget.basePath
        : '${widget.basePath}/$slug';
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == desiredPath) return;
    context.go(desiredPath);
  }

  int _indexForSlug(String? slug) {
    if (slug == null || slug.isEmpty) return 0;
    for (var i = 0; i < widget.tabs.length; i++) {
      if (widget.tabs[i].slug == slug) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller in sync if the URL changed externally (back
    // button, deep link, settings search). The `!= _tabController.index`
    // guard prevents the controller listener (which pushes URL updates)
    // from looping back into another `animateTo`.
    final currentTab = GoRouterState.of(context).pathParameters['tab'];
    final urlIndex = _indexForSlug(currentTab);
    if (urlIndex != _tabController.index && !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (urlIndex != _tabController.index) {
          _tabController.animateTo(urlIndex);
        }
      });
    }

    final tokens = context.inTheme;
    return SettingsCompanyScopedHost<V>(
      create: (companyId) {
        final vm = widget.companyVmFactory(companyId);
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) => SettingsPageScaffold<V>(
        titleKey: widget.titleKey,
        viewModel: vm,
        extraActions: widget.extraActions,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelColor: tokens.ink,
          unselectedLabelColor: tokens.ink3,
          indicatorColor: tokens.accent,
          indicatorWeight: 2,
          tabs: [
            for (final tab in widget.tabs) Tab(text: context.tr(tab.labelKey)),
          ],
        ),
        // Children are intentionally non-const: when external state
        // changes (e.g. statics finish loading, scope flips) and the shell
        // rebuilds, fresh widget instances let `Element.updateChild`
        // walk into the subtree instead of short-circuiting on identity.
        body: TabBarView(
          controller: _tabController,
          children: [for (final tab in widget.tabs) tab.body],
        ),
      ),
    );
  }
}
