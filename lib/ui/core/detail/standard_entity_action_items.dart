import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

/// Standard [EntityActionItem] factories — the universal Edit / Archive /
/// Restore / Delete / Purge actions every entity exposes. Each entity's
/// `<Entity>Actions.itemsFor()` composes from these + its entity-specific
/// extras, so the icon, label key, and `isPrimary` / `enabled` defaults
/// stay consistent across entities.
///
/// `archive` and `restore` return null when the entity isn't in the right
/// state — the caller spreads the conditional with `?...` rather than
/// repeating an `if (canArchive)` per entity.

/// Primary "Edit" action. Renders as the `FilledButton` in the row.
EntityActionItem<A> editActionItem<A>({
  required BuildContext context,
  required A kind,
  required VoidCallback onTap,
}) => EntityActionItem(
  kind: kind,
  icon: Icons.edit_outlined,
  label: context.tr('edit'),
  enabled: true,
  isPrimary: true,
  onTap: onTap,
);

/// Archive action. Returns null when the entity is already archived or
/// soft-deleted — caller must check the right preconditions.
EntityActionItem<A>? archiveActionItem<A>({
  required BuildContext context,
  required A kind,
  required bool canArchive,
  required VoidCallback onTap,
}) {
  if (!canArchive) return null;
  return EntityActionItem(
    kind: kind,
    icon: Icons.archive_outlined,
    label: context.tr('archive'),
    enabled: true,
    onTap: onTap,
  );
}

/// Restore action. Returns null when the entity is in a fresh / live state.
EntityActionItem<A>? restoreActionItem<A>({
  required BuildContext context,
  required A kind,
  required bool canRestore,
  required VoidCallback onTap,
}) {
  if (!canRestore) return null;
  return EntityActionItem(
    kind: kind,
    icon: Icons.unarchive_outlined,
    label: context.tr('restore'),
    enabled: true,
    onTap: onTap,
  );
}

/// Delete placeholder — disabled until per-entity wiring lands. Returns
/// the disabled variant so it shows up in the "More" menu with a
/// `coming_soon` tooltip.
EntityActionItem<A> deleteActionItemPlaceholder<A>({
  required BuildContext context,
  required A kind,
}) => EntityActionItem.disabled(
  kind: kind,
  icon: Icons.delete_outline,
  label: context.tr('delete'),
);

/// Purge placeholder — disabled until per-entity wiring lands. Same
/// shape as [deleteActionItemPlaceholder].
EntityActionItem<A> purgeActionItemPlaceholder<A>({
  required BuildContext context,
  required A kind,
}) => EntityActionItem.disabled(
  kind: kind,
  icon: Icons.delete_forever_outlined,
  label: context.tr('purge'),
);
