import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/task_status_dao.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/task_repository.dart'
    show kReorderEntityId;
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

  @override
  Stream<TaskStatus?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.taskStatusDao
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
    await db.taskStatusDao.upsertAll(companions);

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

  /// Reorder statuses by passing the new id sequence. Updates `status_order`
  /// locally + enqueues one `MutationKind.reorder` row for `/task_statuses/sort`.
  Future<void> reorder({
    required String companyId,
    required List<String> orderedStatusIds,
  }) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedStatusIds.length; i++) {
        final id = orderedStatusIds[i];
        final row = await db.taskStatusDao
            .watchById(companyId: companyId, id: id)
            .first;
        if (row == null) continue;
        final domain = _fromRow(row).copyWith(statusOrder: i);
        await db.taskStatusDao.upsert(
          _domainToCompanion(domain, companyId, isDirty: true),
        );
      }
      await enqueueMutation(
        companyId: companyId,
        entityId: kReorderEntityId,
        kind: MutationKind.reorder,
        payload: {'status_ids': orderedStatusIds},
      );
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
