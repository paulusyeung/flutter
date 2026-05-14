import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

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
    return PopupMenuButton<A>(
      tooltip: context.tr('actions'),
      icon: Icon(icon),
      // Zero padding keeps the icon flush with the row's `kColWMoreMenu`
      // slot so it stays aligned with the column header's `…` cell.
      padding: EdgeInsets.zero,
      onSelected: (kind) =>
          items.firstWhere((i) => i.kind == kind).onTap?.call(),
      itemBuilder: (context) => [
        for (final item in items) item.toPopupMenuItem(context),
      ],
    );
  }
}
