import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Thin wrapper over [EntityDetailHeader]. Identity falls back through:
///   description → `#<number>` → `no_name_fallback`.
/// Subtitle shows `#<number>` when the description carries the identity.
class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({super.key, required this.task, this.formatter});

  final Task task;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final hasDescription = task.description.isNotEmpty;
    final name = hasDescription
        ? task.description
        : (task.number.isNotEmpty
              ? '#${task.number}'
              : context.tr('no_name_fallback'));
    final number = hasDescription && task.number.isNotEmpty
        ? '#${task.number}'
        : null;
    return EntityDetailHeader(
      seedForAvatar: task.id,
      displayName: name,
      number: number,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      isDeleted: task.isDeleted,
      isArchived: task.archivedAt != null,
      isDirty: task.isDirty,
      formatter: formatter,
    );
  }
}
