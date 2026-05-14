import 'package:flutter/widgets.dart';

import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Value object holding every field [EntityDetailHeader] needs.
///
/// Per-entity wrappers build one of these from their domain model and hand
/// it to [EntityDetailHeaderHost] — the host then renders the underlying
/// [EntityDetailHeader] without any per-entity glue.
class EntityHeaderFields {
  const EntityHeaderFields({
    required this.seedForAvatar,
    required this.displayName,
    this.number,
    required this.createdAt,
    required this.updatedAt,
    required this.isArchived,
    required this.isDeleted,
    required this.isDirty,
  });

  final String seedForAvatar;
  final String displayName;
  final String? number;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final bool isDeleted;
  final bool isDirty;
}

/// Generic projection-based wrapper over [EntityDetailHeader]. Per-entity
/// header widgets shrink to a one-liner that supplies the entity + a
/// `project: (T) => EntityHeaderFields` function — the only genuinely
/// entity-specific part is the display-name cascade inside the projection.
class EntityDetailHeaderHost<T> extends StatelessWidget {
  const EntityDetailHeaderHost({
    super.key,
    required this.entity,
    required this.project,
    this.formatter,
  });

  final T entity;
  final EntityHeaderFields Function(BuildContext context, T entity) project;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final f = project(context, entity);
    return EntityDetailHeader(
      seedForAvatar: f.seedForAvatar,
      displayName: f.displayName,
      number: f.number,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
      isDeleted: f.isDeleted,
      isArchived: f.isArchived,
      isDirty: f.isDirty,
      formatter: formatter,
    );
  }
}
