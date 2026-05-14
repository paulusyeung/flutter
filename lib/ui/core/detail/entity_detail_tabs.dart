import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// One tab in an [EntityDetailTabs] strip. `label` is the rendered string
/// (already localized + optionally suffixed with a count badge); the body
/// is built lazily via [bodyBuilder] so per-tab data fetches don't fire
/// until the user first activates the tab.
class EntityDetailTab {
  const EntityDetailTab({
    required this.label,
    required this.icon,
    required this.bodyBuilder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder bodyBuilder;
}

/// Bordered card with a horizontal tab strip on top and an [IndexedStack]
/// of tab bodies below. Extracted from `ClientDetailTabs` so other entity
/// detail screens (Product, Invoice, …) can reuse the same scaffolding.
///
/// Lazy-mount semantics: a tab body is only built the first time the user
/// activates it, then stays alive for the rest of the screen's lifetime
/// (so scroll position + sub-VM state survive tab switches).
class EntityDetailTabs extends StatefulWidget {
  const EntityDetailTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
  });

  final List<EntityDetailTab> tabs;
  final int initialIndex;

  @override
  State<EntityDetailTabs> createState() => _EntityDetailTabsState();
}

class _EntityDetailTabsState extends State<EntityDetailTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.initialIndex.clamp(0, widget.tabs.length - 1),
  );

  // Tabs the user has activated at least once. `IndexedStack` mounts every
  // child eagerly, which would fire each tab's data fetches before the user
  // ever looked at them — gate on this set so a tab's `initState` only
  // runs after first activation, then stays alive for the rest of the
  // screen's lifetime.
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
          _TabStrip(controller: _controller, tabs: widget.tabs),
          Divider(height: 1, thickness: 1, color: tokens.border),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return IndexedStack(
                index: _controller.index,
                children: [
                  for (var i = 0; i < widget.tabs.length; i++)
                    _activated.contains(i)
                        ? Builder(builder: widget.tabs[i].bodyBuilder)
                        : const SizedBox.shrink(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Horizontal, scrollable strip — adapted from the route-based strip in
/// `company_details_shell.dart` but driven by a [TabController] instead.
/// Active tab gets the `accent` underline + `ink` text; inactive tabs use
/// `ink2`.
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller, required this.tabs});

  final TabController controller;
  final List<EntityDetailTab> tabs;

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
                  label: tabs[i].label,
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
