import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// Full Company Details screen — owns the [CompanyDetailsViewModel] (one
/// draft across all tabs), keeps the [TabController] in sync with the URL,
/// and handles company-switch via session listener. All chrome (Save button,
/// PopScope, unsaved-changes guard, FormSaveScope, load-error banner, save
/// toast) is delegated to [SettingsPageScaffold].
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
    return SettingsPageScaffold<CompanyDetailsViewModel>(
      titleKey: 'company_details',
      viewModel: _vm,
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          CompanyDetailsScreen(),
          CompanyDetailsAddressScreen(),
          CompanyDetailsLogoScreen(),
          CompanyDetailsDefaultsScreen(),
          CompanyDetailsDocumentsScreen(),
          CompanyDetailsCustomFieldsScreen(),
        ],
      ),
    );
  }
}
