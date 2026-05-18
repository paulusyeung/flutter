import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/list/embedded_list_scope.dart';

/// List-row trailing popup that consumes the same [EntityActionItem] list
/// the detail header renders. Mirrors the disabled-styled menu rows that
/// the detail header's `_MoreMenu` overflow uses, so the two surfaces feel
/// identical when an action is a "coming soon" placeholder.
class EntityActionsPopupButton<A> extends StatelessWidget {
  const EntityActionsPopupButton({
    super.key,
    required this.items,
    this.icon = Icons.more_vert,
  });

  final List<EntityActionItem<A>> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Embedded detail-tab lists adopt the Client-datatable vertical menu
    // regardless of the icon a tile passes for its standalone screen.
    final effectiveIcon =
        EmbeddedListScope.of(context) ? Icons.more_vert : icon;
    return MenuAnchor(
      // Match the old PopupMenuButton: an outside tap only dismisses the
      // menu, it doesn't also activate the row/widget underneath.
      consumeOutsideTap: true,
      menuChildren: EntityActionItem.menuChildrenFor<A>(context, items),
      builder: (context, controller, _) => IconButton(
        icon: Icon(effectiveIcon),
        tooltip: context.tr('actions'),
        // Zero padding keeps the icon flush with the row's `kColWMoreMenu`
        // slot so it stays aligned with the column header's `…` cell.
        padding: EdgeInsets.zero,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
