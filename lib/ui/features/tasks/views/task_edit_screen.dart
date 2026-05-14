import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/edit/task_edit_layout.dart';

/// Edit + Create form for a Task. Standard scaffold wiring; the body is
/// in `TaskEditLayout`, which composes the identity / times / custom-fields
/// sections.
class TaskEditScreen extends StatelessWidget {
  const TaskEditScreen({this.existingId, this.cloneFrom, super.key});

  final String? existingId;
  final Task? cloneFrom;

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Task, TaskEditViewModel>(
      existingId: existingId,
      entityTypeName: 'task',
      fetchExisting: (ctx, services, companyId, id) =>
          services.tasks.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) => TaskEditViewModel(
        repo: services.tasks,
        companyId: companyId,
        now: DateTime.now,
        existing: existing,
        cloneFrom: cloneFrom,
      ),
      titleWhileLoading: (ctx) =>
          existingId == null ? ctx.tr('new_task') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_task')
          : (vm.draft.description.isNotEmpty
                ? '${ctx.tr('edit')} · ${vm.draft.description}'
                : ctx.tr('edit')),
      // Invoiced tasks are server-immutable — hide the Save button so the
      // user can't enqueue a doomed mutation. The lockout banner inside
      // the body explains why the form is read-only.
      canSave: (vm) => !vm.isSaving && !vm.draft.isInvoiced,
      bodyBuilder: (ctx, vm) => TaskEditLayout(vm: vm),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (t) => t.id,
      onSaved: (ctx, vm, saved) {
        if (vm.isCreate) {
          ctx.go('/tasks/${saved.id}');
        } else {
          ctx.pop();
        }
      },
    );
  }
}
