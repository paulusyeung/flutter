import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Identity falls back:
/// description → `#<number>` → `no_name_fallback`. The `#<number>` subtitle
/// appears only when the description carries the identity.
class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({super.key, required this.task, this.formatter});

  final Task task;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Task>(
      entity: task,
      entityType: EntityType.task,
      recordId: task.id,
      formatter: formatter,
      project: (context, t) {
        final hasDescription = t.description.isNotEmpty;
        final name = hasDescription
            ? t.description
            : (t.number.isNotEmpty
                  ? '#${t.number}'
                  : context.tr('no_name_fallback'));
        final number = hasDescription && t.number.isNotEmpty ? t.number : null;
        return EntityHeaderFields(
          seedForAvatar: t.id,
          displayName: name,
          number: number,
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
          isDeleted: t.isDeleted,
          isArchived: t.archivedAt != null,
          isDirty: t.isDirty,
        );
      },
    );
  }
}
