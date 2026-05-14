import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/project.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_layout.dart';

/// Edit + Create form for a Project. See `EntityEditScreenScaffold` for the
/// shared chrome (loading state, dead-outbox 422 recovery, post-save
/// cleanup).
class ProjectEditScreen extends StatelessWidget {
  const ProjectEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillClientId,
    super.key,
  });

  final String? existingId;

  /// When non-null and [existingId] is null, the create form opens
  /// pre-filled with this project's fields (Clone action). Identity-bearing
  /// fields (id, number, timestamps, deleted/archived state) should already
  /// be stripped by the caller.
  final Project? cloneFrom;

  /// Optional clientId seed for the create form. Used when the user kicks
  /// off "New project" from a Client detail screen — pre-fills the picker
  /// so the user doesn't repeat the selection.
  final String? prefillClientId;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Project, ProjectEditViewModel>(
      existingId: existingId,
      entityTypeName: 'project',
      fetchExisting: (ctx, services, companyId, id) =>
          services.projects.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        // If the caller seeded a clientId (e.g. "New project" from a client
        // detail screen) and we're not cloning, build a minimal cloneFrom
        // that carries just the clientId — the edit VM treats `cloneFrom`
        // as the initial draft when no `existing` is provided.
        Project? clone = cloneFrom;
        if (clone == null && prefillClientId != null && existing == null) {
          clone = _seedFromClient(prefillClientId!);
        }
        return ProjectEditViewModel(
          repo: services.projects,
          companyId: companyId,
          existing: existing,
          cloneFrom: clone,
        );
      },
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_project') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_project')
          : (vm.draft.name.isNotEmpty
                ? '${ctx.tr('edit')} · ${vm.draft.name}'
                : ctx.tr('edit')),
      bodyBuilder: (ctx, vm) => ProjectEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (p) => p.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/projects/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}

Project _seedFromClient(String clientId) => Project(
  id: '',
  userId: '',
  assignedUserId: '',
  clientId: clientId,
  number: '',
  name: '',
  taskRate: Decimal.zero,
  dueDate: null,
  privateNotes: '',
  publicNotes: '',
  budgetedHours: 0,
  currentHours: 0,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  color: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
