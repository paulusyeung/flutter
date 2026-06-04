import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/view_models/online_payments_view_model.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/cascade_draft_resolver.dart';
import 'package:admin/ui/features/settings/views/basic/online_payments/online_payments_defaults_body.dart';
import 'package:admin/ui/features/settings/views/basic/online_payments/online_payments_emails_body.dart';
import 'package:admin/ui/features/settings/views/basic/online_payments/online_payments_general_body.dart';
import 'package:admin/ui/features/settings/widgets/settings_company_scoped_host.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_page_scaffold.dart';

/// URL slug → tab-index mapping for the three Online Payments tabs. Order
/// matches the user-facing tab order (General, Defaults, Emails) and the
/// first entry is intentionally empty to denote the default tab (matches
/// `tabbedSettingsRoutePair` semantics).
const _kTabSlugs = <String>['', 'defaults', 'emails'];

/// Online Payments settings page — three sections (General, Defaults, Emails).
///
/// Adapts its layout to the viewport width:
///   * **wide (≥ Breakpoints.wide)**: single scrollable page with all three
///     sections stacked. The settings page scaffold owns chrome; the body is
///     a column of `FormSection`s. URL `:tab` is ignored — every section is
///     already on screen.
///   * **narrow (< Breakpoints.wide)**: `TabBar` (in the AppBar `bottom`
///     slot) + `TabBarView`. Matches the legacy admin-portal Flutter UX.
///     `:tab` from the route selects the initial index and tab changes push
///     the matching slug into the URL via `context.go`.
///
/// Cascade behavior is preserved at both widths — the shell composes
/// `SettingsCompanyScopedHost` with the same VM selection the cascade
/// scaffold does (via `resolveCascadeDraftVm`: company VM at company scope;
/// `GroupSettingsDraftViewModel` at group scope; `ClientSettingsDraftViewModel`
/// at client scope) so the `Overridable*` widgets render the override
/// checkbox at group/client scope and bind to a real draft at company scope.
class OnlinePaymentsShell extends StatefulWidget {
  const OnlinePaymentsShell({super.key, this.initialTab});

  /// `:tab` path-parameter from the route, or null on the bare URL (resolves
  /// to the General tab).
  final String? initialTab;

  @override
  State<OnlinePaymentsShell> createState() => _OnlinePaymentsShellState();
}

class _OnlinePaymentsShellState extends State<OnlinePaymentsShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _kTabSlugs.length,
      vsync: this,
      initialIndex: _indexForSlug(widget.initialTab),
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Push the controller's settled index into the URL so deep links + the
  /// back button reflect the active tab. Skipped while `indexIsChanging`
  /// because the animation hasn't settled yet — one navigation per swipe.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final slug = _kTabSlugs[_tabController.index];
    final desired = slug.isEmpty
        ? '/settings/online_payments'
        : '/settings/online_payments/$slug';
    if (GoRouterState.of(context).uri.path == desired) return;
    context.go(desired);
  }

  int _indexForSlug(String? slug) {
    if (slug == null || slug.isEmpty) return 0;
    for (var i = 0; i < _kTabSlugs.length; i++) {
      if (_kTabSlugs[i] == slug) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller in sync if the URL changed externally (back
    // button, deep link, settings search). The `!= controller.index` guard
    // prevents the controller listener (which pushes URL updates) from
    // looping back into another animateTo.
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
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;

    return SettingsCompanyScopedHost<SettingsDraftHost>(
      // Scope is captured once at mount. Safe because
      // `tabbedSettingsRoutePair` wraps this shell in `_SettingsLevelKeyed`,
      // which remounts the whole subtree on level/targetId flips.
      create: (companyId) {
        final vm = resolveCascadeDraftVm(
          services,
          companyId,
          () => OnlinePaymentsViewModel(
            repo: services.company,
            companyId: companyId,
          ),
        );
        unawaited(vm.load());
        return vm;
      },
      builder: (context, vm) {
        return SettingsPageScaffold<SettingsDraftHost>(
          titleKey: 'online_payments',
          viewModel: vm,
          bottom: isWide
              ? null
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  labelColor: tokens.ink,
                  unselectedLabelColor: tokens.ink3,
                  indicatorColor: tokens.accent,
                  indicatorWeight: 2,
                  tabs: [
                    Tab(text: context.tr('settings')),
                    Tab(text: context.tr('defaults')),
                    Tab(text: context.tr('emails')),
                  ],
                ),
          body: isWide
              ? const SettingsFormShell(
                  sections: [
                    OnlinePaymentsGeneralBody(),
                    OnlinePaymentsDefaultsBody(),
                    OnlinePaymentsEmailsBody(),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  // Children are intentionally non-const: when external
                  // state changes (statics finish loading, scope flips) and
                  // the shell rebuilds, fresh widget instances let
                  // `Element.updateChild` walk into the subtree instead of
                  // short-circuiting on identity.
                  children: [
                    SettingsFormShell(
                      sections: const [OnlinePaymentsGeneralBody()],
                    ),
                    SettingsFormShell(
                      sections: const [OnlinePaymentsDefaultsBody()],
                    ),
                    SettingsFormShell(
                      sections: const [OnlinePaymentsEmailsBody()],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
