import 'package:flutter/material.dart';
import 'package:overflow_view/overflow_view.dart';

import 'package:admin/l10n/localization.dart';

/// One row item in an [EntityDetailActionsRow].
///
/// Whichever item carries `isPrimary: true` renders as a `FilledButton`
/// (Edit, by convention). Items with `enabled: false` render disabled and
/// are wrapped in a [disabledTooltipKey] tooltip (defaulting to
/// `coming_soon`) so the legacy admin-portal action surface stays visible
/// while the wiring catches up. Transient-disable callers (e.g. a button
/// greyed only while a bulk op is in flight) pass `disabledTooltipKey: null`
/// so the button just renders inert without a misleading "Coming soon" hint.
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
  });

  /// Placeholder action: rendered grayed in both surfaces with a
  /// `coming_soon` tooltip on hover. Used while wiring catches up — the
  /// enum case still exists so future implementations are grep-able.
  const EntityActionItem.disabled({
    required this.kind,
    required this.icon,
    required this.label,
  }) : enabled = false,
       isPrimary = false,
       onTap = null,
       children = null,
       disabledTooltipKey = 'coming_soon';

  final A kind;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback? onTap;

  /// Localization key for the tooltip shown when [enabled] is `false`.
  /// Defaults to `coming_soon` (the unimplemented-action convention). Pass
  /// `null` to disable the tooltip entirely for a transient/busy disable
  /// (the button still renders greyed, just without a misleading hint).
  final String? disabledTooltipKey;

  /// When non-null, this item is a parent group: it renders as a
  /// `SubmenuButton` whose fly-out lists [children] (e.g. the "Clone"
  /// group over the various clone / clone-to targets). `onTap` is ignored
  /// for parent items — selecting a leaf child invokes its own `onTap`.
  final List<EntityActionItem<A>>? children;

  bool get hasChildren => children != null && children!.isNotEmpty;

  /// Maps [items] to the `MenuAnchor` child widgets shared by both menu
  /// surfaces (the detail-header overflow [_MoreMenu] and the list-row
  /// `EntityActionsPopupButton`) so they always agree on styling, the
  /// `coming_soon` tooltip behavior, and submenu nesting. Recurses into
  /// [children] to render nested fly-out submenus.
  static List<Widget> menuChildrenFor<A>(
    BuildContext context,
    List<EntityActionItem<A>> items,
  ) {
    return [
      for (final item in items)
        if (item.hasChildren)
          SubmenuButton(
            leadingIcon: Icon(item.icon, size: 18),
            menuChildren: menuChildrenFor<A>(context, item.children!),
            child: Text(item.label),
          )
        else if (item.enabled)
          MenuItemButton(
            leadingIcon: Icon(item.icon, size: 18),
            onPressed: item.onTap,
            child: Text(item.label),
          )
        else
          MenuItemButton(
            leadingIcon: Icon(item.icon, size: 18),
            onPressed: null,
            child: item.disabledTooltipKey == null
                ? Text(item.label)
                : Tooltip(
                    message: context.tr(item.disabledTooltipKey!),
                    child: Text(item.label),
                  ),
          ),
    ];
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

  /// Optional widget rendered as the first child of the cluster (e.g. the
  /// edit screen's Save button). It is laid out before [items] so the
  /// `OverflowView` — which collapses from the *end* — never hides it; every
  /// hidden child is therefore still a trailing [items] entry, keeping the
  /// `remaining`→`hidden` slice below correct.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return OverflowView.flexible(
      spacing: 8,
      children: [
        if (leading != null) leading!,
        for (final item in items) _ActionButton<A>(item: item),
      ],
      builder: (context, remaining) {
        // `remaining` counts hidden children from the end of the full
        // children list (which includes [leading] at index 0). When the
        // bar is so tight even `leading` collapses, `remaining` can reach
        // `items.length + 1`; clamp so the slice never goes negative —
        // `leading` (Save) is never a menu entry anyway.
        final hiddenCount = remaining > items.length
            ? items.length
            : remaining;
        final hidden = items.sublist(items.length - hiddenCount);
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
