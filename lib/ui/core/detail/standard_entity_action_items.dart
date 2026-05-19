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
    isLifecycle: true,
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
    isLifecycle: true,
    onTap: onTap,
  );
}

/// Delete action. Returns null when the entity is already soft-deleted
/// (Restore is the correct action in that state, not another Delete).
EntityActionItem<A>? deleteActionItem<A>({
  required BuildContext context,
  required A kind,
  required bool canDelete,
  required VoidCallback onTap,
}) {
  if (!canDelete) return null;
  return EntityActionItem(
    kind: kind,
    icon: Icons.delete_outline,
    label: context.tr('delete'),
    enabled: true,
    isLifecycle: true,
    onTap: onTap,
  );
}

/// Purge action. Permanently destroys the entity and every related
/// record. Returns null when the user lacks permission ([canPurge] is
/// false), hiding the menu item entirely — matches React's
/// `isAdmin || isOwner` gate.
EntityActionItem<A>? purgeActionItem<A>({
  required BuildContext context,
  required A kind,
  required bool canPurge,
  required VoidCallback onTap,
}) {
  if (!canPurge) return null;
  return EntityActionItem(
    kind: kind,
    icon: Icons.delete_forever_outlined,
    label: context.tr('purge'),
    enabled: true,
    isLifecycle: true,
    onTap: onTap,
  );
}

/// "Clone" group parent. Collapses an entity's several clone variants
/// (Clone, Clone to Invoice/Quote/Credit/PO/Recurring) into one
/// fly-out submenu so they stop burying the rest of the actions menu.
/// The parent is never dispatched — selecting a [children] leaf invokes
/// that child's own `onTap`.
EntityActionItem<A> cloneGroupActionItem<A>({
  required BuildContext context,
  required A kind,
  required List<EntityActionItem<A>> children,
}) => EntityActionItem(
  kind: kind,
  icon: Icons.copy_outlined,
  label: context.tr('clone'),
  enabled: children.any((c) => c.enabled),
  children: children,
);

/// "New" group parent. Collapses an entity's "create related record"
/// variants (New Invoice / Quote / Payment / Task / Expense) into one
/// fly-out submenu so they stop burying the rest of the actions menu.
/// The parent is never dispatched — selecting a [children] leaf invokes
/// that child's own `onTap`.
EntityActionItem<A> newGroupActionItem<A>({
  required BuildContext context,
  required A kind,
  required List<EntityActionItem<A>> children,
}) => EntityActionItem(
  kind: kind,
  icon: Icons.add_circle_outline,
  label: context.tr('create_new'),
  enabled: children.any((c) => c.enabled),
  children: children,
);

/// "PDF" group parent. Collapses View / Download / Print PDF (and, for
/// invoices, Delivery Note) into one fly-out submenu so they stop burying
/// the rest of the actions menu. The parent is never dispatched —
/// selecting a [children] leaf invokes that child's own `onTap`.
EntityActionItem<A> pdfGroupActionItem<A>({
  required BuildContext context,
  required A kind,
  required List<EntityActionItem<A>> children,
}) => EntityActionItem(
  kind: kind,
  icon: Icons.picture_as_pdf_outlined,
  label: context.tr('pdf'),
  enabled: children.any((c) => c.enabled),
  children: children,
);
