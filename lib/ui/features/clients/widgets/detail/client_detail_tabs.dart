import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// Bottom-half of the client detail screen: a tab strip listing every
/// related-entity table we plan to ship (Invoices, Quotes, Payments, …) and
/// an empty-state body per tab.
///
/// M1 ships clients only — every tab is a placeholder. When a real entity
/// lands (Invoices in M2, etc.) the matching entry below moves to a dedicated
/// builder that renders the list. The tab list order mirrors the React
/// reference at `react/src/pages/clients/show/useTabs.tsx`.
///
/// Navigation is local `TabController` state — not router-driven. Deep
/// linking to placeholder tabs is over-engineering; when a tab grows real
/// content we can promote it to a route then (the `company_details_shell`
/// pattern is the template).
class ClientDetailTabs extends StatefulWidget {
  const ClientDetailTabs({super.key});

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
  ];

  late final TabController _controller = TabController(
    length: _tabs.length,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabStrip(controller: _controller, tabs: _tabs),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                for (final tab in _tabs)
                  EmptyState(
                    icon: tab.icon,
                    title: context.tr(tab.labelKey),
                    subtitle: context.tr('coming_soon_subtitle'),
                  ),
              ],
            ),
          ),
        ],
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
    final color = active ? tokens.ink : tokens.ink3;
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
