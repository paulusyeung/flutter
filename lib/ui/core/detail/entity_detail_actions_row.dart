import 'package:flutter/material.dart';
import 'package:overflow_view/overflow_view.dart';

import 'package:admin/l10n/localization.dart';

/// One row item in an [EntityDetailActionsRow].
///
/// Whichever item carries `isPrimary: true` renders as a `FilledButton`
/// (Edit, by convention). Items with `enabled: false` render disabled and
/// are wrapped in a `coming_soon` tooltip so the legacy admin-portal
/// action surface stays visible while the wiring catches up.
class EntityActionItem<A> {
  const EntityActionItem({
    required this.kind,
    required this.icon,
    required this.label,
    required this.enabled,
    this.isPrimary = false,
    this.onTap,
  });

  final A kind;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback? onTap;
}

/// Overflow-aware action row shared by every entity detail screen.
///
/// Layout: a horizontal cluster of buttons right-aligned in the AppBar's
/// title slot; whatever doesn't fit collapses into a trailing "More"
/// `PopupMenuButton`. Per-entity wrappers (e.g. `ClientDetailActionsRow`)
/// only contribute the action enum and the [EntityActionItem] list.
class EntityDetailActionsRow<A> extends StatelessWidget {
  const EntityDetailActionsRow({super.key, required this.items});

  final List<EntityActionItem<A>> items;

  @override
  Widget build(BuildContext context) {
    // The AppBar's title slot passes loose constraints (minWidth: 0), so the
    // title widget hugs its content by default. SizedBox(width: infinity)
    // forces it to fill the slot; Align then pushes the cluster to the
    // right edge, matching the body's right padding via the scaffold's
    // titleSpacing: InSpacing.lg.
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: OverflowView.flexible(
          spacing: 8,
          children: [for (final item in items) _ActionButton<A>(item: item)],
          builder: (context, remaining) {
            final hidden = items.sublist(items.length - remaining);
            return _MoreMenu<A>(items: hidden);
          },
        ),
      ),
    );
  }
}

class _ActionButton<A> extends StatelessWidget {
  const _ActionButton({required this.item});
  final EntityActionItem<A> item;

  @override
  Widget build(BuildContext context) {
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
    if (item.enabled) return button;
    return Tooltip(message: context.tr('coming_soon'), child: button);
  }
}

class _MoreMenu<A> extends StatelessWidget {
  const _MoreMenu({required this.items});
  final List<EntityActionItem<A>> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<A>(
      tooltip: context.tr('more'),
      onSelected: (kind) {
        final item = items.firstWhere((i) => i.kind == kind);
        item.onTap?.call();
      },
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<A>(
            value: item.kind,
            enabled: item.enabled,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: 12),
                Text(item.label),
              ],
            ),
          ),
      ],
      // Wrap the trigger as an OutlinedButton so it sits flush with the
      // other action buttons (same height, border, padding). AbsorbPointer
      // lets the parent PopupMenuButton handle the tap.
      child: AbsorbPointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          icon: const Icon(Icons.more_horiz, size: 18),
          label: Text(context.tr('more')),
        ),
      ),
    );
  }
}
