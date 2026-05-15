import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';

/// Parse a `#RRGGBB` hex string (case-insensitive). Returns [fallback]
/// for malformed input. Shared so the kanban column header, the status
/// pill, and the live preview in `_StatusPreview` agree on parsing.
Color parseStatusColor(String hex, {required Color fallback}) {
  final raw = hex.trim().replaceFirst('#', '');
  if (raw.length == 6) {
    final v = int.tryParse(raw, radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return fallback;
}

/// Compact "● Status name" badge — color dot + status name on a tinted
/// rounded-rect background. The tint is derived from the task status's
/// per-company hex color at 15 % alpha (there's no paired soft token).
///
/// Subscribes to `services.taskStatuses.watch(companyId, statusId)`.
/// Drift watch streams dedupe identical queries internally, so N rows
/// each showing a pill for the same status share one underlying query.
class TaskStatusPill extends StatelessWidget {
  const TaskStatusPill({
    super.key,
    required this.statusId,
    this.dotSize = 8,
    this.textStyle,
  });

  final String statusId;
  final double dotSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (statusId.isEmpty) {
      return Text(
        '—',
        style: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _label(context, status: null, tokens: tokens);
    }
    return StreamBuilder<TaskStatus?>(
      stream: services.taskStatuses.watch(companyId: companyId, id: statusId),
      builder: (context, snapshot) =>
          _label(context, status: snapshot.data, tokens: tokens),
    );
  }

  Widget _label(
    BuildContext context, {
    required TaskStatus? status,
    required InTheme tokens,
  }) {
    final color = status == null
        ? tokens.ink3
        : parseStatusColor(status.color, fallback: tokens.ink3);
    final name = status == null || status.name.isEmpty ? statusId : status.name;
    return StatusPill(
      label: name,
      fgColor: color,
      // bgColor: null → core widget derives soft tone at 15 % alpha.
      dotSize: dotSize,
      textStyle: textStyle ?? TextStyle(fontSize: 13, color: tokens.ink),
    );
  }
}
