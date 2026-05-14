import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_activity_tab.dart';

/// Bottom of the client detail screen: a tab strip listing every related-
/// entity table we plan to ship (Invoices, Quotes, Payments, …) plus the
/// already-wired Activity tab.
///
/// Most tabs are still placeholders ("coming soon" body); the Activity tab
/// renders [ClientActivityTabBody] — the comments stream + Add Comment
/// affordance. The tab list order mirrors the React reference at
/// `react/src/pages/clients/show/useTabs.tsx`; Activity sits at the end so
/// graduating placeholder tabs doesn't reshuffle its index.
///
/// Navigation is local `TabController` state — not router-driven.
class ClientDetailTabs extends StatefulWidget {
  const ClientDetailTabs({
    required this.client,
    required this.formatter,
    super.key,
  });

  final Client client;
  final Formatter? formatter;

  @override
  State<ClientDetailTabs> createState() => _ClientDetailTabsState();
}

class _ClientDetailTabsState extends State<ClientDetailTabs>
    with SingleTickerProviderStateMixin {
  static const _tabs = <_TabDef>[
    _TabDef(labelKey: 'invoices', icon: Icons.receipt_long_outlined),
    _TabDef(labelKey: 'quotes', icon: Icons.request_quote_outlined),
    _TabDef(labelKey: 'payments', icon: Icons.payments_outlined),
    _TabDef(labelKey: 'recurring_invoices', icon: Icons.autorenew),
    _TabDef(labelKey: 'credits', icon: Icons.credit_card_outlined),
    _TabDef(labelKey: 'projects', icon: Icons.folder_outlined),
    _TabDef(labelKey: 'tasks', icon: Icons.check_circle_outline),
    _TabDef(labelKey: 'expenses', icon: Icons.account_balance_wallet_outlined),
    _TabDef(labelKey: 'documents', icon: Icons.description_outlined),
    _TabDef(labelKey: 'activity', icon: Icons.history),
  ];

  static const _activityIndex = 9;

  late final TabController _controller = TabController(
    length: _tabs.length,
    vsync: this,
  );

  // Tabs the user has activated at least once. `IndexedStack` mounts every
  // child eagerly, which would fire each tab's data fetches before the user
  // ever looked at them. We gate construction on this set so a tab's body
  // (and its `initState` side effects) only runs after first activation,
  // then stays alive for the rest of the screen's lifetime.
  final Set<int> _activated = <int>{};

  @override
  void initState() {
    super.initState();
    _activated.add(_controller.index);
    _controller.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_activated.add(_controller.index)) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
        boxShadow: tokens.shadow1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabStrip(controller: _controller, tabs: _tabs),
          Divider(height: 1, thickness: 1, color: tokens.border),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return IndexedStack(
                index: _controller.index,
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    _activated.contains(i)
                        ? _buildTabBody(i)
                        : const SizedBox.shrink(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(int index) {
    if (index == _activityIndex) {
      return ClientActivityTabBody(
        client: widget.client,
        formatter: widget.formatter,
      );
    }
    return const _ComingSoonBody();
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.lg,
        vertical: InSpacing.xl,
      ),
      child: Center(
        child: Text(
          context.tr('coming_soon_subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.labelKey, required this.icon});
  final String labelKey;
  final IconData icon;
}

/// Horizontal, scrollable tab strip — adapted from the route-based strip in
/// `company_details_shell.dart` but driven by a [TabController] instead.
/// Active tab gets the `accent` underline + `ink` text; inactive tabs use
/// `ink3`.
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller, required this.tabs});

  final TabController controller;
  final List<_TabDef> tabs;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final activeIndex = controller.index;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: InSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _TabButton(
                  label: context.tr(tabs[i].labelKey),
                  icon: tabs[i].icon,
                  active: i == activeIndex,
                  tokens: tokens,
                  onTap: () {
                    if (controller.index != i) controller.animateTo(i);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final InTheme tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Inactive uses `ink2`, not `ink3`. ink3 was reading too light on a
    // surface bg; ink2 is muted-but-clearly-readable and keeps a clean
    // contrast against the active state.
    final color = active ? tokens.ink : tokens.ink2;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InSpacing.md,
          vertical: InSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? tokens.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: InSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
