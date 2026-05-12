import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/dialogs/discard_changes_dialog.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Full Company Details screen — owns the [CompanyDetailsViewModel] (one
/// draft across all tabs), renders the AppBar with the Save action, and
/// mounts all 6 sub-screens inside a [TabBarView] so switching tabs slides
/// and supports swipe.
///
/// The optional `:tab` path segment in the URL drives the initial tab and
/// stays in sync with the controller, preserving deep-linkable URLs.
class CompanyDetailsShell extends StatefulWidget {
  const CompanyDetailsShell({super.key, this.initialTab});

  /// The `:tab` path parameter from the route, or null when on the parent
  /// `/settings/company_details` URL (defaults to the Details tab).
  final String? initialTab;

  @override
  State<CompanyDetailsShell> createState() => _CompanyDetailsShellState();
}

class _CompanyDetailsShellState extends State<CompanyDetailsShell>
    with SingleTickerProviderStateMixin {
  late CompanyDetailsViewModel _vm;
  late final SettingsLevelController _levelController;
  late final Services _services;
  late final TabController _tabController;
  String _currentCompanyId = '';

  // Tab order matches TabBar/TabBarView children. The path-suffix entry for
  // the Details tab is empty (it's the parent route).
  static const _tabs = <(String pathSuffix, String labelKey)>[
    ('', 'details'),
    ('/address', 'address'),
    ('/logo', 'logo'),
    ('/defaults', 'defaults'),
    ('/documents', 'documents'),
    ('/custom_fields', 'custom_fields'),
  ];

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _currentCompanyId = _services.auth.session.value?.currentCompanyId ?? '';
    _vm = CompanyDetailsViewModel(
      repo: _services.company,
      companyId: _currentCompanyId,
    );
    _vm.load();
    _levelController = SettingsLevelController();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _indexForSuffix(widget.initialTab),
    );
    _tabController.addListener(_onTabControllerChanged);
    _services.auth.session.addListener(_onSessionChanged);
    // If a stale statics cache is missing the size/industry bands, force a
    // fresh /api/v1/statics fetch so the Details-tab dropdowns can populate.
    final statics = _services.statics;
    if (statics.sizes.isEmpty || statics.industries.isEmpty) {
      statics.ensureLoaded(force: true).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    _vm.dispose();
    _levelController.dispose();
    super.dispose();
  }

  /// Replace the in-progress VM when the user switches companies. The old
  /// draft is intentionally discarded — it belongs to the previous tenant
  /// and would be invalid against the new one's id.
  void _onSessionChanged() {
    final next = _services.auth.session.value?.currentCompanyId ?? '';
    if (next == _currentCompanyId) return;
    setState(() {
      _vm.dispose();
      _currentCompanyId = next;
      _vm = CompanyDetailsViewModel(repo: _services.company, companyId: next);
      _vm.load();
    });
  }

  /// Push the controller's settled index into the URL so deep links + back
  /// button reflect the active tab. Skipped while `indexIsChanging` because
  /// the animation hasn't settled yet — we only want one navigation per
  /// user interaction.
  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    final desiredSuffix = _tabs[_tabController.index].$1;
    final currentPath = GoRouterState.of(context).uri.path;
    const base = '/settings/company_details';
    final desiredPath = '$base$desiredSuffix';
    if (currentPath == desiredPath) return;
    context.go(desiredPath);
  }

  int _indexForSuffix(String? tab) {
    if (tab == null || tab.isEmpty) return 0;
    for (var i = 0; i < _tabs.length; i++) {
      final suffix = _tabs[i].$1;
      if (suffix == '/$tab') return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller in sync if the URL changed externally (e.g. the
    // back button, a deep link, or the settings search). The guard below
    // (`!= _tabController.index`) prevents the controller listener that
    // pushes URL updates from looping back into another `animateTo`.
    final currentTab = GoRouterState.of(context).pathParameters['tab'];
    final urlIndex = _indexForSuffix(currentTab);
    if (urlIndex != _tabController.index && !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (urlIndex != _tabController.index) {
          _tabController.animateTo(urlIndex);
        }
      });
    }

    final tokens = context.inTheme;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _vm),
        ChangeNotifierProvider.value(value: _levelController),
      ],
      child: UnsavedChangesScope(
        isDirty: () => _vm.isDirty,
        source: _vm,
        onDiscard: _vm.reset,
        child: PopScope(
          canPop: !_vm.isDirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (!_vm.isDirty) return;
            final discard = await showDiscardChangesDialog(context);
            if (!discard) return;
            _vm.reset();
            if (!context.mounted) return;
            await Navigator.of(context).maybePop();
          },
          child: SettingsScreenScaffold(
            titleKey: 'company_details',
            actions: [
              ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  final canSave = _vm.isDirty && !_vm.isSaving;
                  return TextButton(
                    onPressed: canSave ? () => _save(context) : null,
                    style: TextButton.styleFrom(foregroundColor: tokens.accent),
                    child: _vm.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('save')),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: tokens.ink,
              unselectedLabelColor: tokens.ink3,
              indicatorColor: tokens.accent,
              indicatorWeight: 2,
              tabs: [for (final (_, key) in _tabs) Tab(text: context.tr(key))],
            ),
            body: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                if (!_vm.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final err = _vm.loadError;
                final tabBarView = TabBarView(
                  controller: _tabController,
                  children: const [
                    CompanyDetailsScreen(),
                    CompanyDetailsAddressScreen(),
                    CompanyDetailsLogoScreen(),
                    CompanyDetailsDefaultsScreen(),
                    CompanyDetailsDocumentsScreen(),
                    CompanyDetailsCustomFieldsScreen(),
                  ],
                );
                if (err != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LoadErrorBanner(message: err),
                      Expanded(child: tabBarView),
                    ],
                  );
                }
                return tabBarView;
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final successText = context.tr('saved_settings');
    final errorFallback = context.tr('error_refresh_page');
    final result = await _vm.save();
    if (!context.mounted) return;
    if (result != null) {
      Notify.success(context, successText);
      return;
    }
    // The VM stashes the raw exception text on `submitError`; surface it as
    // the detail line so the user (or dev tester) sees what actually broke
    // instead of a generic banner.
    Notify.error(context, errorFallback, detail: _vm.submitError);
  }
}

/// Inline error banner shown above the tab body when `vm.loadError` is set.
/// The form below it still renders against whatever subset of the settings
/// the typed parse could recover, so the user can read + edit the parts
/// that work while the developer chases down the bad field.
class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('error_refresh_page'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SelectableText(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: context.tr('copy'),
              color: theme.colorScheme.onErrorContainer,
              onPressed: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final copiedText = context.tr('copied_to_clipboard');
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    Notify.success(context, copiedText);
  }
}
