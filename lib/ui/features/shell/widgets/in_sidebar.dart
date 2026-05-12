import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/shell/widgets/company_switcher_button.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_footer_actions.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_nav_item.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_section_header.dart';
import 'package:admin/ui/features/shell/widgets/trial_footer.dart';

/// Width of the persistent sidebar used by `ScaffoldWithNav` on wide
/// layouts. Exposed so overlay-based widgets (e.g. the date-range picker
/// popover) can reserve this width and not render beneath the rail.
const double kInSidebarWidth = 232.0;

/// Collapsed width — matches Material's standard `NavigationRail` width,
/// wide enough for a centered 18-px icon and a 44-ish-px tap target.
const double kInSidebarCollapsedWidth = 64.0;

/// 232 px sidebar used in the wide (desktop / tablet) layout of the
/// authenticated shell. Drives off the static [_items] list — branch
/// indices match `lib/app/router.dart` (`0=Clients`, `1=Dashboard`,
/// `2=Products`, `3=Settings`, `4=Outbox`).
///
/// On the wide layout the user can collapse it to [kInSidebarCollapsedWidth]
/// via the bottom toggle button; the choice is owned by
/// `Services.sidebar` and persists across restarts. Inside `AppDrawer` the
/// collapse mode never engages — the drawer passes its own `width` and the
/// `ValueListenableBuilder` simply doesn't constrain anything in that case.
class InSidebar extends StatelessWidget {
  const InSidebar({
    required this.currentBranch,
    required this.onSelectBranch,
    this.width = kInSidebarWidth,
    this.onBeforeCompanyPicker,
    super.key,
  });

  final int currentBranch;
  final ValueChanged<int> onSelectBranch;

  /// Fixed width of the sidebar. The persistent desktop rail uses the
  /// default 232 px; `AppDrawer` passes `null` so the sidebar fills the
  /// drawer's own (wider) width.
  final double? width;

  /// Fires before the company picker opens (when the user taps the
  /// switcher header). Used by `AppDrawer` to pop itself first so the
  /// picker doesn't stack on top of an open drawer.
  final VoidCallback? onBeforeCompanyPicker;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = context.read<Services>();
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: services.auth.session,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: services.sidebar,
          builder: (context, collapsedPref, _) {
            // The drawer passes `width: null` to fill its own container —
            // the collapse toggle is wide-layout-only, so ignore the
            // preference when there's no fixed width.
            final canCollapse = width != null;
            final collapsed = canCollapse && collapsedPref;
            final effectiveWidth = canCollapse
                ? (collapsed ? kInSidebarCollapsedWidth : kInSidebarWidth)
                : null;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: effectiveWidth,
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(right: BorderSide(color: tokens.border)),
              ),
              // ClipRect swallows the brief mid-tween overflow when children
              // re-layout at their final-state size.
              child: ClipRect(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: CompanySwitcherButton(
                        session: session,
                        onBeforeOpen: onBeforeCompanyPicker,
                        compact: collapsed,
                      ),
                    ),
                    Container(height: 1, color: tokens.border),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildItems(
                            context,
                            session.currentCompanyId,
                            compact: collapsed,
                          ),
                        ),
                      ),
                    ),
                    Container(height: 1, color: tokens.border),
                    SidebarFooterActions(
                      compact: collapsed,
                      showCollapseToggle: canCollapse,
                    ),
                    TrialFooter(compact: collapsed),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildItems(
    BuildContext context,
    String companyId, {
    required bool compact,
  }) {
    final widgets = <Widget>[];
    for (final item in _items) {
      switch (item) {
        case _Section(:final labelKey):
          widgets.add(
            SidebarSectionHeader(
              labelKey == null ? null : context.tr(labelKey),
              compact: compact,
            ),
          );
        case _Nav():
          widgets.add(_buildNav(context, item, companyId, compact: compact));
      }
    }
    return widgets;
  }

  Widget _buildNav(
    BuildContext context,
    _Nav item,
    String companyId, {
    required bool compact,
  }) {
    final isActive = item.branch != null && item.branch == currentBranch;
    final label = context.tr(item.labelKey);
    final base = SidebarNavItem(
      label: label,
      icon: item.icon,
      active: isActive,
      disabled: item.disabled,
      compact: compact,
      onTap: item.branch == null ? null : () => onSelectBranch(item.branch!),
    );
    // The Clients row gets a live count badge layered on via a StreamBuilder
    // wrapper — keyed on the stable branch index rather than the (localized)
    // label so language switches don't drop the badge.
    if (item.branch == 0) {
      return StreamBuilder<int>(
        stream: context.read<Services>().clients.watchCount(
          companyId: companyId,
        ),
        builder: (context, snap) => SidebarNavItem(
          label: label,
          icon: item.icon,
          active: isActive,
          disabled: item.disabled,
          compact: compact,
          count: snap.data,
          onTap: item.branch == null
              ? null
              : () => onSelectBranch(item.branch!),
        ),
      );
    }
    // Outbox shows a combined pending + dead count and is hidden entirely
    // when there's nothing queued — the sidebar already has plenty of
    // permanent entries; we only surface this one when it's actionable.
    if (item.branch == 4) {
      final dao = context.read<Services>().db.outboxDao;
      return StreamBuilder<int>(
        stream: _combineOutboxCounts(
          dao.watchPendingCount(companyId: companyId),
          dao.watchDeadCount(companyId: companyId),
        ),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return SidebarNavItem(
            label: label,
            icon: item.icon,
            active: isActive,
            disabled: item.disabled,
            compact: compact,
            count: count,
            onTap: item.branch == null
                ? null
                : () => onSelectBranch(item.branch!),
          );
        },
      );
    }
    return base;
  }
}

/// Merge the pending and dead outbox-count streams. Emits the sum on every
/// emission from either source — the user wants one badge that reflects
/// total mutations awaiting action.
Stream<int> _combineOutboxCounts(Stream<int> pending, Stream<int> dead) async* {
  int p = 0;
  int d = 0;
  final controller = StreamController<int>();
  final subP = pending.listen((v) {
    p = v;
    controller.add(p + d);
  });
  final subD = dead.listen((v) {
    d = v;
    controller.add(p + d);
  });
  try {
    yield* controller.stream;
  } finally {
    await subP.cancel();
    await subD.cancel();
    await controller.close();
  }
}

sealed class _Item {
  const _Item();
}

class _Section extends _Item {
  const _Section(this.labelKey);
  // Null = unlabeled section spacer (currently used above Settings to put
  // visual breathing room between the saved list and the bottom row).
  final String? labelKey;
}

class _Nav extends _Item {
  const _Nav({
    required this.labelKey,
    required this.icon,
    this.branch,
    this.disabled = false,
  });

  final String labelKey;
  final IconData icon;
  final int? branch;
  final bool disabled;
}

const List<_Item> _items = [
  _Section('section_workspace'),
  _Nav(labelKey: 'dashboard', icon: Icons.dashboard_outlined, branch: 1),
  _Nav(labelKey: 'clients', icon: Icons.people_outline, branch: 0),
  _Nav(labelKey: 'products', icon: Icons.inventory_2_outlined, branch: 2),
  _Nav(labelKey: 'invoices', icon: Icons.receipt_long_outlined, disabled: true),
  _Nav(labelKey: 'quotes', icon: Icons.request_quote_outlined, disabled: true),
  _Nav(labelKey: 'payments', icon: Icons.payments_outlined, disabled: true),
  _Nav(
    labelKey: 'expenses',
    icon: Icons.account_balance_wallet_outlined,
    disabled: true,
  ),
  _Nav(labelKey: 'projects', icon: Icons.work_outline, disabled: true),
  _Nav(labelKey: 'tasks', icon: Icons.task_outlined, disabled: true),
  _Nav(labelKey: 'vendors', icon: Icons.store_outlined, disabled: true),
  _Section('section_saved'),
  _Nav(
    labelKey: 'saved_overdue_this_week',
    icon: Icons.flag_outlined,
    disabled: true,
  ),
  _Nav(
    labelKey: 'saved_high_value_open',
    icon: Icons.attach_money,
    disabled: true,
  ),
  _Nav(labelKey: 'saved_top_clients', icon: Icons.star_outline, disabled: true),
  _Section(null),
  _Nav(labelKey: 'outbox', icon: Icons.outbox_outlined, branch: 4),
  _Nav(labelKey: 'settings', icon: Icons.settings_outlined, branch: 3),
];
