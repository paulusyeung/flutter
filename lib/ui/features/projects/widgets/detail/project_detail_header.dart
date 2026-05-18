import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/project.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Uses the project name
/// (falling back to `no_name_fallback`) and renders `#<number>` as the
/// subtitle when present.
class ProjectDetailHeader extends StatelessWidget {
  const ProjectDetailHeader({super.key, required this.project, this.formatter});

  final Project project;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Project>(
      entity: project,
      entityType: EntityType.project,
      recordId: project.id,
      formatter: formatter,
      project: (context, p) => EntityHeaderFields(
        seedForAvatar: p.id,
        displayName: p.name.isEmpty ? context.tr('no_name_fallback') : p.name,
        number: p.number.isEmpty ? null : p.number,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        isDeleted: p.isDeleted,
        isArchived: p.archivedAt != null,
        isDirty: p.isDirty,
      ),
    );
  }
}
