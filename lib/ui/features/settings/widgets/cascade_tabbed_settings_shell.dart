import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/client_settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_settings_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/tabbed_settings_shell.dart';

/// Cascade-aware counterpart to [TabbedSettingsShell]. Use this for any
/// settings page that:
///   * binds to `company.settings.*` fields (i.e. needs the cascade override
///     wrapper at group / client scope — see [CascadeSettingsScaffold]), AND
///   * splits its content across tabs (Localization today; Templates &
///     Reminders / Client Portal will be next).
///
/// Picks the right VM for the active [SettingsLevel] (company → caller's
/// factory; client → shared `ClientSettingsDraftViewModel`) and owns the
/// [TabController] + URL ↔ tab-index sync. The tabs themselves are scope-
/// agnostic because they read [SettingsDraftHost] off Provider just like a
/// non-tabbed cascade screen.
///
/// Pair with [tabbedSettingsRoutePair] in `settings_routes.dart` — the
/// shared page key in that helper is what keeps the [TabController] + draft
/// VM alive across the two route variants.
class CascadeTabbedSettingsShell extends StatefulWidget {
  const CascadeTabbedSettingsShell({
    super.key,
    required this.titleKey,
    required this.basePath,
    required this.initialTab,
    required this.companyVmFactory,
    required this.tabs,
    this.extraActions = const <Widget>[],
    this.resolveErrorTabSlug,
  }) : assert(
         tabs.length >= 2,
         'CascadeTabbedSettingsShell needs at least two tabs',
       );

  /// Localization key for the AppBar title.
  final String titleKey;

  /// Absolute path of the shell's bare URL (no trailing `/`). Used to
  /// build the per-tab URL when the controller settles on a new index.
  final String basePath;

  /// The `:tab` path-parameter from the route, or null on the bare URL
  /// (resolves to the first tab).
  final String? initialTab;

  /// Build the typed VM for the active company. Used at
  /// [SettingsLevel.company]; at [SettingsLevel.client] the shell substitutes
  /// `ClientSettingsDraftViewModel` automatically. Same shape as
  /// [CascadeSettingsScaffold.companyVmFactory].
  final CompanySettingsVmFactory companyVmFactory;

  /// Tab definitions, in display order. First entry should use an empty
  /// `slug` (the default tab); the rest carry their literal slug.
  final List<TabbedSettingsTab> tabs;

  /// Additional AppBar action widgets rendered to the right of the Save
  /// button.
  final List<Widget> extraActions;

  /// Optional 422 → tab-jump resolver. Same semantics as
  /// [TabbedSettingsShell.resolveErrorTabSlug].
  final String? Function(SettingsDraftHost vm)? resolveErrorTabSlug;

  @override
  State<CascadeTabbedSettingsShell> createState() =>
      _CascadeTabbedSettingsShellState();
}

class _CascadeTabbedSettingsShellState extends State<CascadeTabbedSettingsShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ValueNotifier<bool> _saveVisible;

  SettingsDraftHost? _boundVm;
  void Function()? _vmListener;

  @override
  void initState() {
    super.initState();
    final initialIndex = _indexForSlug(widget.initialTab);
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabControllerChanged);
    _saveVisible = ValueNotifier<bool>(
      widget.tabs[initialIndex].contributesToSave,
    );
  }

  @override
  void dispose() {
    _detachVm();
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    _saveVisible.dispose();
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = widget.tabs[_tabController.index];
    _saveVisible.value = tab.contributesToSave;
    final desiredPath = tab.slug.isEmpty
        ? widget.basePath
        : '${widget.basePath}/${tab.slug}';
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == desiredPath) return;
    context.go(desiredPath);
  }

  void _attachVm(SettingsDraftHost vm) {
    if (identical(_boundVm, vm)) return;
    _detachVm();
    final resolve = widget.resolveErrorTabSlug;
    if (resolve == null) return;
    void listener() {
      if (!mounted) return;
      final slug = resolve(vm);
      if (slug == null) return;
      final index = _indexForSlug(slug);
      if (index == _tabController.index || _tabController.indexIsChanging) {
        return;
      }
      _tabController.animateTo(index);
    }

    vm.addListener(listener);
    _boundVm = vm;
    _vmListener = listener;
  }

  void _detachVm() {
    final vm = _boundVm;
    final listener = _vmListener;
    if (vm != null && listener != null) {
      vm.removeListener(listener);
    }
    _boundVm = null;
    _vmListener = null;
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

    final services = context.read<Services>();
    final tokens = context.inTheme;
    return SettingsCompanyScopedHost<SettingsDraftHost>(
      // Scope is captured once at mount. Safe only because
      // `tabbedSettingsRoutePair` (settings_routes.dart) wraps the shellBuilder
      // in `_SettingsLevelKeyed`, which remounts the whole subtree on level/
      // targetId flips. Mount this shell outside that helper and the level
      // change won't pick up here.
      create: (companyId) {
        final scope = services.settingsLevel;
        final clientId = scope.targetId;
        final SettingsDraftHost vm;
        if (scope.level == SettingsLevel.client && clientId != null) {
          vm = ClientSettingsDraftViewModel(
            repo: services.clients,
            db: services.db,
            companyId: companyId,
            clientId: clientId,
          );
        } else {
          vm = widget.companyVmFactory(
            repo: services.company,
            companyId: companyId,
          );
        }
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) {
        _attachVm(vm);
        return SettingsPageScaffold<SettingsDraftHost>(
          titleKey: widget.titleKey,
          viewModel: vm,
          extraActions: widget.extraActions,
          saveVisible: _saveVisible,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: tokens.ink,
            unselectedLabelColor: tokens.ink3,
            indicatorColor: tokens.accent,
            indicatorWeight: 2,
            tabs: [
              for (final tab in widget.tabs)
                Tab(text: context.tr(tab.labelKey)),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [for (final tab in widget.tabs) tab.body],
          ),
        );
      },
    );
  }
}
