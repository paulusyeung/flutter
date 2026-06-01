import 'package:flutter/material.dart';
import 'package:overflow_view/overflow_view.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// One row item in an [EntityDetailActionsRow].
///
/// Whichever item carries `isPrimary: true` renders as a `FilledButton`
/// (Edit, by convention). An item with `enabled: false` is **hidden** —
/// an action that isn't supported in the current context (e.g. "Refund
/// Payment" while creating a new invoice) simply doesn't appear, rather
/// than rendering greyed-out with a misleading "Coming soon" hint.
///
/// The one exception: a transient/busy disable (e.g. a button greyed only
/// while a bulk op is in flight) passes `disabledTooltipKey: null`, which
/// keeps the item visible-but-inert so it doesn't flicker out and back
/// mid-operation. So an item renders iff
/// `enabled || disabledTooltipKey == null` ([isVisible]).
class EntityActionItem<A> {
  const EntityActionItem({
    required this.kind,
    required this.icon,
    required this.label,
    required this.enabled,
    this.isPrimary = false,
    this.onTap,
    this.children,
    this.disabledTooltipKey = 'coming_soon',
    this.isLifecycle = false,
  });

  final A kind;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback? onTap;

  /// True for the universal lifecycle actions (Archive / Restore / Delete /
  /// Purge), set only by the standard factories in
  /// `standard_entity_action_items.dart`. [menuChildrenFor] auto-inserts a
  /// single divider before the first visible lifecycle item so the
  /// destructive group reads as separate from the entity-specific actions
  /// above it.
  final bool isLifecycle;

  /// Controls how a disabled (`enabled: false`) item is treated.
  ///
  /// Non-null (default `coming_soon`): the item is **hidden** — an action
  /// unsupported in the current context just doesn't appear. Pass `null`
  /// for a transient/busy disable (e.g. greyed only while a bulk op is in
  /// flight): the item stays **visible-but-inert** so it doesn't flicker
  /// out and back mid-operation. See [isVisible].
  final String? disabledTooltipKey;

  /// When non-null, this item is a parent group: it renders as a
  /// `SubmenuButton` whose fly-out lists [children] (e.g. the "Clone"
  /// group over the various clone / clone-to targets). `onTap` is ignored
  /// for parent items — selecting a leaf child invokes its own `onTap`.
  final List<EntityActionItem<A>>? children;

  bool get hasChildren => children != null && children!.isNotEmpty;

  /// Whether this item is rendered at all. An unsupported action
  /// (`enabled: false` with a non-null [disabledTooltipKey]) is hidden;
  /// only enabled items and transient-busy ones (`disabledTooltipKey ==
  /// null`) appear. A parent group whose children are all hidden resolves
  /// `enabled: false` (see `standard_entity_action_items`) and is dropped
  /// here too, so no empty submenu is left behind.
  bool get isVisible => enabled || disabledTooltipKey == null;

  /// Maps [items] to the `MenuAnchor` child widgets shared by both menu
  /// surfaces (the detail-header overflow [_MoreMenu] and the list-row
  /// `EntityActionsPopupButton`) so they always agree on styling,
  /// hide-when-unsupported behavior, and submenu nesting. Recurses into
  /// [children] to render nested fly-out submenus.
  static List<Widget> menuChildrenFor<A>(
    BuildContext context,
    List<EntityActionItem<A>> items,
  ) {
    // Auto-divider: emit one separator before the first visible lifecycle
    // item (Archive/Restore/Delete/Purge), but only if a visible
    // non-lifecycle item preceded it in this pass. That single guard also
    // suppresses a stray leading divider when the slice is lifecycle-only
    // (e.g. an overflow "More" menu whose hidden tail is all lifecycle).
    final children = <Widget>[];
    var sawNonLifecycle = false;
    var dividerEmitted = false;
    for (final item in items) {
      if (!item.isVisible) continue;
      if (item.isLifecycle) {
        if (sawNonLifecycle && !dividerEmitted) {
          children.add(Divider(height: 9, color: context.inTheme.border));
          dividerEmitted = true;
        }
      } else {
        sawNonLifecycle = true;
      }
      if (item.hasChildren) {
        children.add(
          SubmenuButton(
            leadingIcon: Icon(item.icon, size: 18),
            menuChildren: menuChildrenFor<A>(context, item.children!),
            child: Text(item.label),
          ),
        );
      } else if (item.enabled) {
        children.add(
          MenuItemButton(
            leadingIcon: Icon(item.icon, size: 18),
            onPressed: item.onTap,
            child: Text(item.label),
          ),
        );
      } else {
        // Only reachable for a transient-busy disable
        // (disabledTooltipKey == null); no tooltip by design.
        children.add(
          MenuItemButton(
            leadingIcon: Icon(item.icon, size: 18),
            onPressed: null,
            child: Text(item.label),
          ),
        );
      }
    }
    return children;
  }
}

/// Overflow-aware action row shared by every entity detail screen.
///
/// Layout: a horizontal cluster of buttons right-aligned in the AppBar's
/// title slot; whatever doesn't fit collapses into a trailing "More"
/// `PopupMenuButton`. Per-entity wrappers (e.g. `ClientDetailActionsRow`)
/// only contribute the action enum and the [EntityActionItem] list.
/// The bare overflow-aware button cluster: visible buttons left-to-right,
/// whatever doesn't fit collapses into a trailing "More" menu. Shared by the
/// detail-header action row ([EntityDetailActionsRow]) and the list-screen
/// multi-select AppBar so both surfaces overflow identically. The caller owns
/// outer sizing / alignment — this widget just lays the cluster out at its
/// natural width.
class EntityOverflowActionBar<A> extends StatelessWidget {
  const EntityOverflowActionBar({super.key, required this.items, this.leading});

  final List<EntityActionItem<A>> items;

  /// Optional widget rendered as the first child of the cluster (the edit
  /// screen's Save button). It must be a plain button — NO `Tooltip` /
  /// `AnimatedSize` / `OverlayPortal` — because `OverflowView` lays its
  /// children out inside a layout callback (see the Save-button comment in
  /// `entity_edit_scaffold.dart`). It is laid out before [items] so the
  /// `OverflowView` — which collapses from the *end* — never hides it; every
  /// hidden child is therefore still a trailing [items] entry, keeping the
  /// `remaining`→`hidden` slice below correct.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    // Drop unsupported actions up front so the visible cluster and the
    // `remaining`→`hidden` overflow slice both index the same list — the
    // hidden-count math below depends on that.
    final shown = [
      for (final item in items)
        if (item.isVisible) item,
    ];
    return OverflowView.flexible(
      spacing: 8,
      children: [
        if (leading != null) leading!,
        for (final item in shown) _ActionButton<A>(item: item),
      ],
      builder: (context, remaining) {
        // `remaining` counts hidden children from the end of the full
        // children list (which includes [leading] at index 0). When the
        // bar is so tight even `leading` would collapse, `remaining` can
        // reach `shown.length + 1`; clamp so the slice never goes negative.
        final hiddenCount = remaining > shown.length ? shown.length : remaining;
        final hidden = shown.sublist(shown.length - hiddenCount);
        return _MoreMenu<A>(items: hidden);
      },
    );
  }
}

class EntityDetailActionsRow<A> extends StatelessWidget {
  const EntityDetailActionsRow({super.key, required this.items});

  final List<EntityActionItem<A>> items;

  @override
  Widget build(BuildContext context) {
    // The AppBar's title slot passes loose constraints (minWidth: 0), so the
    // title widget hugs its content by default. SizedBox(width: infinity)
    // forces it to fill the slot; Align then pushes the cluster to the
    // right edge, matching the body's right padding via the scaffold's
    // titleSpacing: InSpacing.lg(context).
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: EntityOverflowActionBar<A>(items: items),
      ),
    );
  }
}

class _ActionButton<A> extends StatelessWidget {
  const _ActionButton({required this.item});
  final EntityActionItem<A> item;

  @override
  Widget build(BuildContext context) {
    // Group parent (e.g. "Clone"): there's no single action to fire, so
    // render a MenuAnchor that opens the same fly-out the overflow "More"
    // menu would. Without this a visible (non-overflowed) group would be a
    // dead button — `onTap` is null on a group item.
    if (item.hasChildren) {
      return MenuAnchor(
        consumeOutsideTap: true,
        menuChildren: EntityActionItem.menuChildrenFor<A>(
          context,
          item.children!,
        ),
        builder: (context, controller, _) => OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          icon: Icon(item.icon, size: 18),
          label: Text(item.label),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      );
    }
    final Widget button = item.isPrimary
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: Icon(item.icon, size: 18),
            label: Text(item.label),
            onPressed: item.enabled ? item.onTap : null,
          )
        : OutlinedButton.icon(
            // CLAUDE.md: OutlinedButton inside a Row must override the
            // theme's Size.fromHeight(40) default, otherwise the infinite
            // minWidth crashes the surrounding Row layout.
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            icon: Icon(item.icon, size: 18),
            label: Text(item.label),
            onPressed: item.enabled ? item.onTap : null,
          );
    if (item.enabled || item.disabledTooltipKey == null) return button;
    return Tooltip(
      message: context.tr(item.disabledTooltipKey!),
      child: button,
    );
  }
}

class _MoreMenu<A> extends StatelessWidget {
  const _MoreMenu({required this.items});
  final List<EntityActionItem<A>> items;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      consumeOutsideTap: true,
      menuChildren: EntityActionItem.menuChildrenFor<A>(context, items),
      // Trigger styled as an OutlinedButton so it sits flush with the
      // other action buttons (same height, border, padding).
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
        icon: const Icon(Icons.more_horiz, size: 18),
        label: Text(context.tr('more')),
      ),
    );
  }
}
