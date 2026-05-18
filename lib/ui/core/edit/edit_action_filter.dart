import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

/// Adapts a detail-screen action list for the edit/create AppBar overflow
/// bar, porting the old admin-portal `getActions` show/hide rules without
/// touching any per-entity `itemsFor` body.
///
/// Two adjustments vs. the detail surface:
///
///  * **The primary action is always dropped.** By the
///    `standard_entity_action_items` convention the only `isPrimary` item
///    is "Edit" — pointless on the screen that *is* the editor.
///  * **On create**, lifecycle/clone actions the old app hid on a new
///    record are dropped: `clone`, the whole clone group, `archive`,
///    `restore`, `delete`. The caller supplies [isLifecycle] (a tiny
///    per-entity tear-off over the action enum). The clone *group* parent
///    is dropped as a whole — its kind should satisfy [isLifecycle] — so
///    no empty submenu is left behind.
///
/// On an existing record (`isCreate == false`) the full set is kept (minus
/// the primary), matching the detail screen.
List<EntityActionItem<A>> filterForEditScreen<A>(
  List<EntityActionItem<A>> items, {
  required bool isCreate,
  required bool Function(A kind) isLifecycle,
}) {
  return [
    for (final item in items)
      if (!item.isPrimary && !(isCreate && isLifecycle(item.kind))) item,
  ];
}
