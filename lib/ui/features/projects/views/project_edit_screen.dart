import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/after_save_create_action.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_layout.dart';
import 'package:admin/ui/features/projects/widgets/project_actions.dart';

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
          sync: services.sync,
          connectivity: services.connectivity,
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
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<ProjectAction>(
            leading: saveButton,
            items: filterForEditScreen(
              ProjectActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: ProjectActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return ProjectActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as ProjectAction,
        );
      },
      // Create-mode: resolve the tmp id to the real one so New Task / Invoice /
      // Quote / Expense navigate with the real project id seed.
      onAfterSaveActionOnCreate: (ctx, saved, a) {
        final services = ctx.read<Services>();
        final companyId = services.auth.session.value!.currentCompanyId;
        return dispatchAfterSaveOnCreate<Project, ProjectAction>(
          ctx,
          saved: saved,
          idOf: (p) => p.id,
          withId: (p, id) => p.copyWith(id: id),
          resolveId: services.projects.resolveId,
          action: a as ProjectAction,
          navigatesOnCreate: ProjectActions.navigatesOnCreate,
          dispatch: (c, resolved, act) =>
              ProjectActions.dispatch(c, services, companyId, resolved, act),
        );
      },
      onSaved: (ctx, vm, saved) => goAfterEntitySave(
        ctx,
        isCreate: vm.isCreate,
        basePath: '/projects',
        savedId: saved.id,
      ),
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
