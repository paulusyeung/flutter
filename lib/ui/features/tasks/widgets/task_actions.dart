import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Action set surfaced for a task. Mirrors `ProductAction` — only the
/// edit / archive / restore / delete / purge branches are wired through
/// the standard infrastructure; start/stop/resume mutate `time_log` on a
/// fresh edit-screen open, viewClient navigates, and the invoice-related
/// actions render disabled with a coming-soon tooltip (the entities
/// haven't been wired yet).
enum TaskAction {
  edit,
  start,
  stop,
  resume,
  newInvoice,
  addToInvoice,
  viewClient,
  clone,
  archive,
  restore,
  delete,
  purge,
}

class TaskActions {
  TaskActions._();

  static List<EntityActionItem<TaskAction>> itemsFor(
    BuildContext context,
    Task task,
    void Function(TaskAction) onTap,
  ) {
    final canArchive = task.archivedAt == null && !task.isDeleted;
    final canRestore = task.archivedAt != null || task.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    // Start/Stop/Resume — only one renders at a time, gated by task state.
    EntityActionItem<TaskAction>? timerItem;
    if (!task.isInvoiced && !task.isDeleted) {
      if (task.isRunning) {
        timerItem = EntityActionItem(
          kind: TaskAction.stop,
          icon: Icons.stop_circle_outlined,
          label: context.tr('stop'),
          enabled: true,
          onTap: () => onTap(TaskAction.stop),
        );
      } else if (task.timeLog.isNotEmpty) {
        timerItem = EntityActionItem(
          kind: TaskAction.resume,
          icon: Icons.play_circle_outlined,
          label: context.tr('resume'),
          enabled: true,
          onTap: () => onTap(TaskAction.resume),
        );
      } else {
        timerItem = EntityActionItem(
          kind: TaskAction.start,
          icon: Icons.play_arrow_outlined,
          label: context.tr('start'),
          enabled: true,
          onTap: () => onTap(TaskAction.start),
        );
      }
    }

    return [
      editActionItem(
        context: context,
        kind: TaskAction.edit,
        onTap: () => onTap(TaskAction.edit),
      ),
      ?timerItem,
      EntityActionItem.disabled(
        kind: TaskAction.newInvoice,
        icon: Icons.receipt_long_outlined,
        label: context.tr('new_invoice'),
      ),
      EntityActionItem.disabled(
        kind: TaskAction.addToInvoice,
        icon: Icons.playlist_add,
        label: context.tr('add_to_invoice'),
      ),
      if (task.clientId.isNotEmpty)
        EntityActionItem(
          kind: TaskAction.viewClient,
          icon: Icons.person_outline,
          label: context.tr('view_client'),
          enabled: true,
          onTap: () => onTap(TaskAction.viewClient),
        ),
      EntityActionItem(
        kind: TaskAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_task'),
        enabled: true,
        onTap: () => onTap(TaskAction.clone),
      ),
      ?archiveActionItem(
        context: context,
        kind: TaskAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(TaskAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: TaskAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(TaskAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: TaskAction.delete,
        canDelete: !task.isDeleted,
        onTap: () => onTap(TaskAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: TaskAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(TaskAction.purge),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Task task,
    TaskAction action,
  ) async {
    switch (action) {
      case TaskAction.edit:
        context.go('/tasks/${task.id}/edit');
      case TaskAction.start:
        // tmp ids haven't synced yet — server can't accept a time-log
        // change for an entity it doesn't know exists.
        if (task.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await _startTimer(context, services, companyId, task);
      case TaskAction.stop:
        if (task.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await _stopTimer(context, services, companyId, task);
      case TaskAction.resume:
        if (task.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await _resumeTimer(context, services, companyId, task);
      case TaskAction.viewClient:
        if (task.clientId.isEmpty) return;
        context.go('/clients/${task.clientId}');
      case TaskAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'task',
          op: () => services.tasks.archive(companyId: companyId, id: task.id),
        );
      case TaskAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'task',
          op: () => services.tasks.restore(companyId: companyId, id: task.id),
        );
      case TaskAction.clone:
        final draft = task.copyWith(
          id: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          invoiceId: '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/tasks/new', extra: draft);
      case TaskAction.delete:
        if (task.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'task',
          op: () => services.tasks.delete(companyId: companyId, id: task.id),
        );
      case TaskAction.purge:
        if (task.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.purge(
          context: context,
          wireName: 'task',
          op: () => services.tasks.purge(companyId: companyId, id: task.id),
        );
        if (context.mounted) context.go('/tasks');
      case TaskAction.newInvoice:
      case TaskAction.addToInvoice:
        break;
    }
  }

  /// Start a fresh timer on [task]. Atomically stops any currently-
  /// running entry first (the running case is reachable via Stop, not
  /// Start, but the guard is cheap and defensive).
  static Future<void> _startTimer(
    BuildContext context,
    Services services,
    String companyId,
    Task task,
  ) async {
    final now = DateTime.now();
    final entries = <TimeEntry>[...task.timeLog];
    if (entries.isNotEmpty && entries.last.isRunning) {
      entries[entries.length - 1] = entries.last.copyWith(stop: now);
    }
    entries.add(TimeEntry(start: now, stop: null));
    final next = task.copyWith(timeLog: entries);
    await services.tasks.save(companyId: companyId, task: next);
  }

  /// Stop the running entry, leaving everything else untouched.
  static Future<void> _stopTimer(
    BuildContext context,
    Services services,
    String companyId,
    Task task,
  ) async {
    if (task.timeLog.isEmpty || !task.timeLog.last.isRunning) return;
    final now = DateTime.now();
    final entries = <TimeEntry>[...task.timeLog];
    entries[entries.length - 1] = entries.last.copyWith(stop: now);
    final next = task.copyWith(timeLog: entries);
    await services.tasks.save(companyId: companyId, task: next);
  }

  /// Append a new running entry seeded from the previous entry's
  /// description + billable. Matches admin-portal's "Resume" semantics.
  static Future<void> _resumeTimer(
    BuildContext context,
    Services services,
    String companyId,
    Task task,
  ) async {
    if (task.timeLog.isEmpty) {
      await _startTimer(context, services, companyId, task);
      return;
    }
    final last = task.timeLog.last;
    final now = DateTime.now();
    final entries = <TimeEntry>[
      ...task.timeLog,
      TimeEntry(
        start: now,
        stop: null,
        description: last.description,
        billable: last.billable,
      ),
    ];
    final next = task.copyWith(timeLog: entries);
    await services.tasks.save(companyId: companyId, task: next);
  }
}
