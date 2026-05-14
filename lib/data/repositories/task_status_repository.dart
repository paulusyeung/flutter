import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/task_status_dao.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/task_statuses_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('TaskStatusRepository');

class TaskStatusRepository
    extends BaseEntityRepository<TaskStatus, TaskStatusApi> {
  TaskStatusRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.taskStatus);

  final TaskStatusesApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'task_status';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  Stream<List<TaskStatus>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = TaskStatusFieldIds.statusOrder,
    bool sortAscending = true,
  }) {
    return db.taskStatusDao
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

  /// Watch every active task status for a company. Used by the kanban
  /// board (one column per row) and by the status picker on Task edit.
  Stream<List<TaskStatus>> watchAll({required String companyId}) {
    return db.taskStatusDao
        .watchAll(companyId: companyId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Watch active **and** archived statuses, in canonical order. Used by
  /// the Settings → Task Statuses list when the user toggles "Show
  /// archived" so they can restore a previously-archived status.
  /// Limit is a defensive ceiling — typical workspaces have <20 statuses.
  Stream<List<TaskStatus>> watchAllIncludingArchived({
    required String companyId,
  }) {
    return db.taskStatusDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: 200,
          states: const {EntityState.active, EntityState.archived},
          sortField: TaskStatusFieldIds.statusOrder,
          sortAscending: true,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<TaskStatus?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.taskStatusDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Seed the local task_statuses table from the `/refresh` envelope's
  /// bundled `data[N].company.task_statuses` array. Called from
  /// `AuthRepository._persistAndActivate` so the first paint of the Task
  /// Statuses screen reads from Drift instead of firing a redundant
  /// `GET /task_statuses` (the data is already in hand).
  ///
  /// Upserts only — never deletes — so rows with pending local edits
  /// (`is_dirty = true`) keep their outbox-bound payload until the next
  /// real sync. Sets the keyset cursor to the bundle's max `updated_at`
  /// so a subsequent `ensurePageLoaded` treats the bundle as the freshest
  /// snapshot we've seen.
  Future<void> applyBundle({
    required String companyId,
    required List<TaskStatusApi> bundle,
  }) async {
    if (bundle.isEmpty) return;
    final byId = {
      for (final a in bundle) a.id: _apiToCompanion(a, companyId),
    };
    var maxUpdatedAt = 0;
    String? lastId;
    for (final a in bundle) {
      if (a.updatedAt > maxUpdatedAt) {
        maxUpdatedAt = a.updatedAt;
        lastId = a.id;
      }
    }
    await db.transaction(() async {
      // Bundled refresh: skip ids whose existing local row has is_dirty=true,
      // so the user's pending offline edit isn't clobbered by login/refresh.
      await db.taskStatusDao.upsertAllPreservingDirty(
        companyId: companyId,
        byId: byId,
      );
      if (lastId != null) {
        await advanceCursor(
          companyId: companyId,
          updatedAt: maxUpdatedAt,
          id: lastId,
          wasFullSync: true,
        );
      }
    });
  }

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

    // Server-refresh: skip ids whose existing local row has is_dirty=true,
    // so a paged refresh doesn't clobber the user's pending offline edit.
    await db.taskStatusDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: {for (final a in apiRows) a.id: _apiToCompanion(a, companyId)},
    );

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
    const maxPages = 100; // ~5k statuses is more than anyone needs
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
          'refreshAll hit the $maxPages page safety cap for $companyId',
        );
        break;
      }
    }
  }

  Future<TaskStatus> create({
    required String companyId,
    required TaskStatus draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    await db.transaction(() async {
      await db.taskStatusDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({
    required String companyId,
    required TaskStatus status,
  }) async {
    final companion = _domainToCompanion(status, companyId, isDirty: true);
    await db.transaction(() async {
      await db.taskStatusDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: status.id,
        kind: MutationKind.update,
        payload: status.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.delete,
        payload: {'id': id},
      );

  Future<void> archive({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.archive,
        payload: {'id': id},
      );

  Future<void> restore({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.restore,
        payload: {'id': id},
      );

  /// Hard-delete on the server. Password-gated per [requiresPasswordFor]; the
  /// outbox handler attaches the cached password header before POST.
  Future<void> purge({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.purge,
        payload: {'id': id},
      );

  /// Reorder statuses by passing the new id sequence. Updates `status_order`
  /// locally + enqueues one `MutationKind.reorder` row for `/task_statuses/sort`.
  Future<void> reorder({
    required String companyId,
    required List<String> orderedStatusIds,
  }) async {
    await db.transaction(() async {
      // Single SELECT for every status we're about to renumber, then one
      // batched upsertAll.
      final rows = await db.taskStatusDao.getByIds(
        companyId: companyId,
        ids: orderedStatusIds,
      );
      final byId = {for (final r in rows) r.id: r};
      final companions = <TaskStatusesCompanion>[];
      for (var i = 0; i < orderedStatusIds.length; i++) {
        final id = orderedStatusIds[i];
        final row = byId[id];
        if (row == null) continue;
        final domain = _fromRow(row).copyWith(statusOrder: i);
        companions.add(_domainToCompanion(domain, companyId, isDirty: true));
      }
      await db.taskStatusDao.upsertAll(companions);
      await enqueueMutation(
        companyId: companyId,
        entityId: kReorderEntityId,
        kind: MutationKind.reorder,
        payload: {'status_ids': orderedStatusIds},
      );
    });
  }

  /// Clear `is_dirty` on the statuses touched by a successful reorder
  /// POST. Mirrors `TaskRepository.clearDirtyForReorder` so the
  /// `services.dart` reorder handler can reset the flag uniformly.
  Future<void> clearDirtyForReorder({
    required String companyId,
    required Iterable<String> statusIds,
  }) async {
    await db.transaction(() async {
      final rows = await db.taskStatusDao.getByIds(
        companyId: companyId,
        ids: statusIds,
      );
      if (rows.isEmpty) return;
      final companions = [
        for (final r in rows)
          r.toCompanion(true).copyWith(isDirty: const Value(false)),
      ];
      await db.taskStatusDao.upsertAll(companions);
    });
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required TaskStatusApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.taskStatusDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.taskStatusDao.deleteById(companyId: companyId, id: tempId);
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
    required TaskStatusApi serverResponse,
  }) async {
    await db.taskStatusDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.taskStatusDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.taskStatusDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  TaskStatusesCompanion _apiToCompanion(TaskStatusApi a, String companyId) {
    return TaskStatusesCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(a.name),
      color: Value(a.color),
      statusOrder: Value(a.statusOrder ?? 0),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  TaskStatusesCompanion _domainToCompanion(
    TaskStatus s,
    String companyId, {
    required bool isDirty,
  }) {
    return TaskStatusesCompanion.insert(
      id: s.id,
      companyId: companyId,
      name: Value(s.name),
      color: Value(s.color),
      statusOrder: Value(s.statusOrder),
      updatedAt: _secs(s.updatedAt),
      createdAt: Value(_secs(s.createdAt)),
      archivedAt: s.archivedAt == null
          ? const Value.absent()
          : Value(_secs(s.archivedAt!)),
      isDirty: Value(isDirty),
      isDeleted: Value(s.isDeleted),
      payload: jsonEncode(s.toApiJson(preserveTempId: true)),
    );
  }

  TaskStatus _fromRow(TaskStatusRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = TaskStatusApi.fromJson(json);
    return TaskStatus.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
