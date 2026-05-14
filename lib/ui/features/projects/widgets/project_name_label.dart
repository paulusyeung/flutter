import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/project.dart';

/// Resolves the project name from the local Drift cache and renders it
/// as a `Text`. Falls back to the raw `projectId` while the watch is
/// empty (first sync hasn't landed for this project) or when the
/// project isn't in the cache. Mirrors `ClientNameLabel`.
///
/// Drift watch streams dedupe identical queries, so N rows each rendering
/// a label for the same `projectId` share one underlying subscription.
class ProjectNameLabel extends StatelessWidget {
  const ProjectNameLabel({
    super.key,
    required this.projectId,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String projectId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (projectId.isEmpty) {
      return Text(
        '—',
        style: style ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _text(projectId);
    }
    return StreamBuilder<Project?>(
      stream: services.projects.watch(companyId: companyId, id: projectId),
      builder: (context, snapshot) {
        final project = snapshot.data;
        final name = project == null || project.name.isEmpty
            ? projectId
            : project.name;
        return _text(name);
      },
    );
  }

  Widget _text(String text) =>
      Text(text, maxLines: maxLines, overflow: overflow, style: style);
}
