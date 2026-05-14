import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/tasks_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('TaskRepository');

/// Source of truth for Task data. Mirrors `ProductRepository`'s shape with
/// two task-specific additions:
///   * `watchAllForKanban` — un-paginated stream for the kanban board.
///   * `watchRunning` — the single most-recently-updated running task,
///     for the global running-timer pill.
///   * `reorder` — enqueues a `MutationKind.reorder` row carrying the
///     bulk kanban-sort payload.
class TaskRepository extends BaseEntityRepository<Task, TaskApi> {
  TaskRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.task);

  final TasksApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'task';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  /// Paginated list view. The list screen calls this; the kanban board
  /// uses [watchAllForKanban] instead.
  Stream<List<Task>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = TaskFieldIds.updatedAt,
    bool sortAscending = false,
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
    return db.taskDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
          states: states,
          sortField: sortField,
          sortAscending: sortAscending,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Stream of tasks grouped by `status_id` for the kanban board. Empty
  /// keys are included so newly-created statuses with no tasks still get
  /// a column (the kanban VM joins this with the watch-all status stream).
  Stream<Map<String, List<Task>>> watchAllByStatus({
    required String companyId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    return db.taskDao
        .watchAllForKanban(companyId: companyId, states: states)
        .map((rows) {
          final result = <String, List<Task>>{};
          for (final row in rows) {
            final task = _fromRow(row);
            result.putIfAbsent(task.statusId, () => <Task>[]).add(task);
          }
          return result;
        });
  }

  /// The single most-recently-updated running task, or null. Backs the
  /// global running-timer pill (mounted in `AppShell`).
  Stream<Task?> watchRunning({required String companyId}) {
    return db.taskDao
        .watchRunning(companyId: companyId)
        .map((row) => row == null ? null : _fromRow(row));
  }

  Stream<int> watchCount({required String companyId}) =>
      db.taskDao.watchCount(companyId: companyId);

  /// Active, non-deleted tasks for a single project. Backs the "Tasks"
  /// card on the Project detail screen.
  Stream<List<Task>> watchForProject({
    required String companyId,
    required String projectId,
  }) {
    if (projectId.isEmpty) {
      return Stream<List<Task>>.value(const <Task>[]);
    }
    return db.taskDao
        .watchForProject(companyId: companyId, projectId: projectId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<Task?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.taskDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    bool ignoreCursor = false,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await db.syncStateDao.read(
            companyId: companyId,
            entityType: entityTypeName,
          );

    final filters = <String, String>{
      ...stateQueryParams(states),
      for (final entry in extraFilters.entries)
        if (entry.value.isNotEmpty)
          entry.key: (entry.value.toList()..sort()).join(','),
    };

    final result = await api.list(
      page: page,
      perPage: pageSize,
      search: search,
      sinceUpdatedAt: cursor?.updatedAt,
      sinceId: cursor?.id,
      filters: filters,
    );

    final apiRows = result.data.data;
    if (apiRows.isEmpty) return false;

    final companions = apiRows
        .map((a) => _apiToCompanion(a, companyId))
        .toList(growable: false);
    await db.taskDao.upsertAll(companions);

    if (result.cursorUpdatedAt != null && result.cursorId != null) {
      await advanceCursor(
        companyId: companyId,
        updatedAt: result.cursorUpdatedAt!,
        id: result.cursorId!,
        wasFullSync: ignoreCursor && page == 1,
      );
    }
    return apiRows.length >= pageSize;
  }

  Future<void> refreshAll({
    required String companyId,
    bool full = false,
  }) async {
    if (full) {
      await db.syncStateDao.reset(
        companyId: companyId,
        entityType: entityTypeName,
      );
    }
    var page = 1;
    var hasMore = true;
    const maxPages = 1000;
    final allStates = EntityState.values.toSet();
    while (hasMore) {
      hasMore = await ensurePageLoaded(
        companyId: companyId,
        page: page,
        states: allStates,
        ignoreCursor: full && page == 1,
      );
      page++;
      if (page > maxPages) {
        _log.warning(
          'refreshAll hit the $maxPages page safety cap for company '
          '$companyId — cursor will resume on the next sync trigger.',
        );
        break;
      }
    }
  }

  Future<Task> create({required String companyId, required Task draft}) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.taskDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({required String companyId, required Task task}) async {
    final companion = _domainToCompanion(task, companyId, isDirty: true);
    await db.transaction(() async {
      await db.taskDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: task.id,
        kind: MutationKind.update,
        payload: task.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.delete,
      payload: {'id': id},
    );
  }

  Future<void> purge({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.purge,
      payload: {'id': id},
    );
  }

  Future<void> archive({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.archive,
      payload: {'id': id},
    );
  }

  /// Surgical "stop the running entry, save through the outbox" — used by
  /// the global running-timer pill, where building the modified `Task`
  /// inline in the widget would duplicate the read-modify-write the repo
  /// already understands. The outbox payload is still the full task (via
  /// the standard `save` path); a future v2 optimization can swap to a
  /// targeted `MutationKind.stopTimer` that ships only `time_log`, but
  /// today this centralizes the logic in one place.
  Future<void> stopRunningTimer({
    required String companyId,
    required String taskId,
  }) async {
    final row = await db.taskDao
        .watchById(companyId: companyId, id: taskId)
        .first;
    if (row == null) return;
    final task = _fromRow(row);
    if (task.timeLog.isEmpty || !task.timeLog.last.isRunning) return;
    final entries = <TimeEntry>[...task.timeLog];
    entries[entries.length - 1] = entries.last.copyWith(stop: DateTime.now());
    await save(
      companyId: companyId,
      task: task.copyWith(timeLog: entries),
    );
  }

  Future<void> restore({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.restore,
      payload: {'id': id},
    );
  }

  /// Apply a kanban reorder optimistically + queue the server batch.
  ///
  /// [orderedByStatus] is the new layout: `{ statusId: [taskId, ...], ... }`
  /// with each list in the order the user just dropped them. Local rows
  /// get the new `status_id` + `status_order` written transactionally;
  /// one `MutationKind.reorder` row hits the outbox carrying the same
  /// payload the server expects on `/tasks/sort`.
  Future<void> reorder({
    required String companyId,
    required List<String> statusIds,
    required Map<String, List<String>> orderedByStatus,
  }) async {
    final flatUpdates = <({String taskId, String statusId, int order})>[];
    for (final statusId in statusIds) {
      final ids = orderedByStatus[statusId] ?? const <String>[];
      for (var i = 0; i < ids.length; i++) {
        flatUpdates.add((taskId: ids[i], statusId: statusId, order: i));
      }
    }

    await db.transaction(() async {
      // Preload every affected row in a single SELECT so we don't pay
      // for one watch-subscription per task. The companions we write
      // back also batch into a single `upsertAll` — Drift collapses the
      // statements internally, which matters when the user just dropped
      // a card that triggered a 50-task re-shuffle.
      final touchedIds = flatUpdates.map((u) => u.taskId);
      final rows = await db.taskDao.getByIds(
        companyId: companyId,
        ids: touchedIds,
      );
      final byId = {for (final r in rows) r.id: r};
      final companions = <TasksCompanion>[];
      for (final u in flatUpdates) {
        final existing = byId[u.taskId];
        if (existing == null) continue;
        // Rewrite the task row's denormalized status_id + status_order +
        // mark is_dirty so an inbound delta sync that brings down old
        // server ordering can't clobber the optimistic state.
        final domain = _fromRow(
          existing,
        ).copyWith(statusId: u.statusId, statusOrder: u.order);
        companions.add(_domainToCompanion(domain, companyId, isDirty: true));
      }
      await db.taskDao.upsertAll(companions);
      await enqueueMutation(
        companyId: companyId,
        entityId: kReorderEntityId,
        kind: MutationKind.reorder,
        payload: {'status_ids': statusIds, 'task_ids': orderedByStatus},
      );
    });
  }

  /// Clear the `is_dirty` flag on every task touched by a successful
  /// reorder POST. Called from the `MutationKind.reorder` custom-action
  /// handler in `services.dart`. Without this, the optimistic
  /// `is_dirty = true` set by [reorder] would survive forever — blocking
  /// inbound deltas from refreshing the rows.
  Future<void> clearDirtyForReorder({
    required String companyId,
    required Iterable<String> taskIds,
  }) async {
    await db.transaction(() async {
      final rows = await db.taskDao.getByIds(
        companyId: companyId,
        ids: taskIds,
      );
      if (rows.isEmpty) return;
      final companions = [
        for (final r in rows)
          r.toCompanion(true).copyWith(isDirty: const Value(false)),
      ];
      await db.taskDao.upsertAll(companions);
    });
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required TaskApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.taskDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.taskDao.deleteById(companyId: companyId, id: tempId);
      }
      await recordCreateSuccess(
        companyId: companyId,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required TaskApi serverResponse,
  }) async {
    await db.taskDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.taskDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.taskDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  TasksCompanion _apiToCompanion(TaskApi a, String companyId) {
    final entries = TimeEntry.parseLog(a.timeLog);
    final isRunning = entries.isNotEmpty && entries.last.isRunning;
    return TasksCompanion.insert(
      id: a.id,
      companyId: companyId,
      taskNumber: Value(a.number),
      description: Value(a.description),
      rate: Value(_moneyString(a.rate)),
      clientId: Value(a.clientId),
      projectId: Value(a.projectId),
      invoiceId: Value(a.invoiceId),
      taskStatusId: Value(a.statusId),
      statusOrder: Value(a.statusOrder ?? 0),
      isRunning: Value(isRunning),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      customValue1: Value(a.customValue1),
      customValue2: Value(a.customValue2),
      customValue3: Value(a.customValue3),
      customValue4: Value(a.customValue4),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  TasksCompanion _domainToCompanion(
    Task t,
    String companyId, {
    required bool isDirty,
  }) {
    return TasksCompanion.insert(
      id: t.id,
      companyId: companyId,
      taskNumber: Value(t.number),
      description: Value(t.description),
      rate: Value(t.rate.toString()),
      clientId: Value(t.clientId),
      projectId: Value(t.projectId),
      invoiceId: Value(t.invoiceId),
      taskStatusId: Value(t.statusId),
      statusOrder: Value(t.statusOrder),
      isRunning: Value(t.isRunning),
      updatedAt: _secs(t.updatedAt),
      createdAt: Value(_secs(t.createdAt)),
      archivedAt: t.archivedAt == null
          ? const Value.absent()
          : Value(_secs(t.archivedAt!)),
      customValue1: Value(t.customValue1),
      customValue2: Value(t.customValue2),
      customValue3: Value(t.customValue3),
      customValue4: Value(t.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(t.isDeleted),
      payload: jsonEncode(t.toApiJson(preserveTempId: true)),
    );
  }

  Task _fromRow(TaskRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = TaskApi.fromJson(json);
    return Task.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
