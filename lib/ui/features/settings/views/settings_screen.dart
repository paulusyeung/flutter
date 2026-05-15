import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/settings/settings_search_catalog.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// Plan tier surfaced on a locked sidebar row / search hit. The tooltip on
/// the lock icon reads "Pro Plan" / "Enterprise Plan" so the user knows
/// which tier unblocks the section before tapping in.
enum PlanTier { pro, enterprise }

/// Master list of settings sections — pure list, no `Scaffold`. Used as the
/// left pane on wide screens (mounted by `SettingsShell`) and as the body of
/// `SettingsScreen` on narrow screens. Reads the current go_router location
/// to highlight whichever top-level section is active.
///
/// The basic-settings group header carries a search icon. Tapping it swaps
/// the section list for a TextField + flat list of matching fields drawn
/// from `kSettingsSearchCatalog`.
class SettingsListSidebar extends StatefulWidget {
  const SettingsListSidebar({super.key});

  @override
  State<SettingsListSidebar> createState() => _SettingsListSidebarState();
}

class _SettingsListSidebarState extends State<SettingsListSidebar> {
  bool _searching = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    // Defer until the TextField is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _closeSearch() {
    _controller.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) return _buildSearch(context);
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final activeSlug = _activeSlug(GoRouterState.of(context).uri.path);
    final isClient = context.watch<SettingsLevelController>().isClient;
    bool inScope(SettingsSectionDef s) => !isClient || s.clientEditable;
    final basic = kSettingsSections.where((s) => s.isBasic && inScope(s));
    final advanced = kSettingsSections.where((s) => !s.isBasic && inScope(s));
    // Listen to session so the lock icons appear / disappear when a fresh
    // refresh lands (e.g. after the user upgrades in the portal and lands
    // back in the app). Only the list body wraps — search state lives
    // above this builder.
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: context.read<Services>().auth.session,
      builder: (context, session, _) {
        return ListView(
          children: [
            _GroupHeader(
              context.tr('basic_settings'),
              trailing: IconButton(
                icon: const Icon(Icons.search),
                tooltip: context.tr('search_settings'),
                onPressed: _openSearch,
              ),
            ),
            for (final s in basic) _tile(context, s, activeSlug, session),
            const Divider(height: 1),
            _GroupHeader(context.tr('advanced_settings')),
            for (final s in advanced) _tile(context, s, activeSlug, session),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildSearch(BuildContext context) {
    final l10n = Localization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: context.tr('search_settings'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.tr('cancel'),
                onPressed: _closeSearch,
              ),
            ],
          ),
        ),
        Expanded(child: _buildResults(context, l10n)),
      ],
    );
  }

  Widget _buildResults(BuildContext context, Localization? l10n) {
    if (l10n == null) return const SizedBox.shrink();
    final hits = searchSettings(_controller.text, l10n);
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('no_results'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final session = context.read<Services>().auth.session.value;
    return ListView.builder(
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        final gate = _gateLevelFor(hit.section.slug, session);
        return ListTile(
          leading: Icon(hit.section.icon),
          title: Text(l10n.lookup(hit.fieldKey)),
          subtitle: Text(l10n.lookup(hit.section.titleKey)),
          trailing: gate == null ? null : _PlanChip(tier: gate),
          onTap: () async {
            if (!await _confirmIfDirty(context)) return;
            if (!context.mounted) return;
            context.go(hit.section.route);
            _closeSearch();
          },
        );
      },
    );
  }

  Future<bool> _confirmIfDirty(BuildContext context) {
    return context.read<Services>().unsavedChangesGuard.confirmIfDirty(context);
  }

  Widget _tile(
    BuildContext context,
    SettingsSectionDef section,
    String? activeSlug,
    AuthSession? session,
  ) {
    final tokens = context.inTheme;
    final selected = section.slug == activeSlug;
    final gate = _gateLevelFor(section.slug, session);
    return ListTile(
      leading: Icon(section.icon),
      title: Text(context.tr(section.titleKey)),
      trailing: gate == null
          ? null
          : Tooltip(
              message: context.tr(
                gate == PlanTier.enterprise ? 'enterprise_plan' : 'pro_plan',
              ),
              child: Icon(Icons.lock_outline, size: 16, color: tokens.ink3),
            ),
      selected: selected,
      selectedTileColor: tokens.accentSoft,
      // Drives both leading icon + title color when `selected` is true.
      // Matches the SidebarNavItem active-state pattern.
      selectedColor: tokens.accentInk,
      iconColor: tokens.ink3,
      textColor: tokens.ink2,
      onTap: () async {
        if (!await _confirmIfDirty(context)) return;
        if (!context.mounted) return;
        context.go(section.route);
      },
    );
  }

  /// Decides whether to render a trailing lock icon on a sidebar / search row.
  /// Returns the gate tier when the active session lacks access, null when
  /// the section is ungated or the user already qualifies (incl. self-hosted).
  static PlanTier? _gateLevelFor(String slug, AuthSession? session) {
    if (session == null) return null;
    if (kEnterpriseGatedSettings.contains(slug) && !session.isEnterprisePlan) {
      return PlanTier.enterprise;
    }
    if (kProGatedSettings.contains(slug) && !session.isProPlan) {
      return PlanTier.pro;
    }
    return null;
  }

  /// Extract the top-level section slug from a path like
  /// `/settings/user_details/preferences` → `user_details`. Returns null when
  /// the user is on `/settings` itself (no section selected).
  static String? _activeSlug(String path) {
    if (!path.startsWith('/settings')) return null;
    final rest = path.substring('/settings'.length);
    if (rest.isEmpty || rest == '/') return null;
    final segments = rest.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.first;
  }
}

/// Narrow-only route target for `/settings`. On wide screens the shell shows
/// `SettingsListSidebar` directly in the left pane, so this screen never gets
/// rendered — but it remains the route's `builder` so the back-button on
/// narrow lands on the list cleanly.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final globalNav = Breakpoints.isGlobalNavVisible(context);
    return Scaffold(
      drawer: globalNav ? null : const AppDrawer(),
      appBar: AppBar(
        title: Text(context.tr('settings')),
        leading: globalNav ? null : const DrawerHamburger(),
        automaticallyImplyLeading: !globalNav,
      ),
      body: const SettingsListSidebar(),
    );
  }
}

/// Small "Pro" / "Enterprise" chip rendered on search-result rows when the
/// section is plan-gated and the active session lacks access. Keeps search
/// discoverable without surprising the user with a banner on tap-in.
class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.tier});

  final PlanTier tier;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final labelKey = tier == PlanTier.enterprise ? 'enterprise' : 'pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Text(
        context.tr(labelKey),
        style: theme.textTheme.labelSmall?.copyWith(
          color: tokens.accentInk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label, {this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(label, style: style),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          trailing!,
        ],
      ),
    );
  }
}
