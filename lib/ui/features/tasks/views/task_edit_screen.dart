import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/edit/edit_action_filter.dart';
import 'package:admin/ui/core/edit/entity_edit_screen_scaffold.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/edit/task_edit_layout.dart';
import 'package:admin/ui/features/tasks/widgets/task_actions.dart';

/// Edit + Create form for a Task. Standard scaffold wiring; the body is
/// in `TaskEditLayout`, which composes the identity / times / custom-fields
/// sections.
///
/// Stateful so we can hold a [Formatter] resolved via
/// [FormatterHostMixin] — the time-log rows render their date portion
/// through this formatter so the date layout honors the company setting.
class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({
    this.existingId,
    this.cloneFrom,
    this.prefillProjectId,
    super.key,
  });

  final String? existingId;
  final Task? cloneFrom;

  /// Optional project id seed. When non-null and we're in create mode,
  /// the VM resolves the project and calls `selectProject(...)` so the
  /// task picks up the project's clientId + (when current rate is zero)
  /// the project's task_rate. Wired by the "Add task" affordance on
  /// Project detail's Tasks card.
  final String? prefillProjectId;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen>
    with FormatterHostMixin {
  late final Services _services;
  late String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    loadFormatter(_services, _companyId);
    _services.auth.session.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    _companyId = s.currentCompanyId;
    clearFormatter();
    loadFormatter(_services, _companyId);
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityEditScreenScaffold<Task, TaskEditViewModel>(
      existingId: widget.existingId,
      entityTypeName: 'task',
      fetchExisting: (ctx, services, companyId, id) =>
          services.tasks.watch(companyId: companyId, id: id).first,
      buildVm: (ctx, services, companyId, existing) {
        final vm = TaskEditViewModel(
          repo: services.tasks,
          companyId: companyId,
          now: DateTime.now,
          existing: existing,
          cloneFrom: widget.cloneFrom,
        );
        // Seed the project picker on first build. Fire-and-forget — the
        // watch resolves the project once Drift has it, then runs the
        // same selectProject side-effects as the dropdown (sets clientId,
        // conditionally fills rate, locks the client picker).
        //
        // `unawaited` so the analyzer accepts the dropped future; the
        // `.catchError` is defensive so a transient stream error (e.g.
        // Drift restarted mid-rebuild) doesn't surface as an uncaught
        // zone exception. If the project isn't cached locally (offline +
        // never synced) the resolved value is null and we no-op — the
        // user can pick the project manually from the dropdown.
        // Wrapped in postFrame so the scaffold's listeners are attached
        // before vm.selectProject's notifyListeners fires. See
        // InvoiceEditScreen for the full trace.
        final seedId = widget.prefillProjectId;
        if (seedId != null && seedId.isNotEmpty && existing == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(
              services.projects
                  .watch(companyId: companyId, id: seedId)
                  .first
                  .then((project) {
                    if (project != null) vm.selectProject(project);
                  })
                  .catchError((Object _) {}),
            );
          });
        }
        return vm;
      },
      titleWhileLoading: (ctx) =>
          widget.existingId == null ? ctx.tr('new_task') : ctx.tr('edit'),
      titleBuilder: (ctx, vm) => vm.isCreate
          ? ctx.tr('new_task')
          : (vm.draft.description.isNotEmpty
                ? '${ctx.tr('edit')} · ${vm.draft.description}'
                : ctx.tr('edit')),
      // Invoiced tasks are server-immutable — hide the Save button so the
      // user can't enqueue a doomed mutation. The lockout banner inside
      // the body explains why the form is read-only.
      canSave: (vm) => !vm.isSaving && !vm.draft.isInvoiced,
      bodyBuilder: (ctx, vm) => TaskEditLayout(vm: vm, formatter: formatter),
      resetToEmpty: (vm) => vm.resetToEmpty(),
      entityIdOf: (t) => t.id,
      actionsBuilder: (ctx, vm, onTap, saveButton) =>
          EntityOverflowActionBar<TaskAction>(
            leading: saveButton,
            items: filterForEditScreen(
              TaskActions.itemsFor(ctx, vm.draft, (a) => onTap(a)),
              isCreate: vm.isCreate,
              isLifecycle: TaskActions.isLifecycle,
            ),
          ),
      onAfterSaveAction: (ctx, saved, a) {
        final services = ctx.read<Services>();
        return TaskActions.dispatch(
          ctx,
          services,
          services.auth.session.value!.currentCompanyId,
          saved,
          a as TaskAction,
        );
      },
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
