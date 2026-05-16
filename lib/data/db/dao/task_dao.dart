import 'package:drift/drift.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/base_entity_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/tasks_table.dart';

part 'task_dao.g.dart';

/// Stable field-id constants used by the list ViewModel for column +
/// sort selection. Keep in sync with `TaskRepository.watchPage`.
class TaskFieldIds {
  static const String number = 'number';
  static const String description = 'description';
  static const String rate = 'rate';
  static const String clientId = 'client_id';
  static const String projectId = 'project_id';
  static const String taskStatusId = 'task_status_id';
  static const String statusOrder = 'status_order';
  static const String updatedAt = 'updated_at';
}

@DriftAccessor(tables: [Tasks])
class TaskDao extends BaseEntityDao<$TasksTable, TaskRow> with _$TaskDaoMixin {
  TaskDao(super.db);

  @override
  $TasksTable get table => tasks;
  @override
  GeneratedColumn<String> get idColumn => tasks.id;
  @override
  GeneratedColumn<String> get companyIdColumn => tasks.companyId;
  @override
  GeneratedColumn<bool> get isDeletedColumn => tasks.isDeleted;
  @override
  GeneratedColumn<bool> get isDirtyColumn => tasks.isDirty;

  Stream<List<TaskRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = TaskFieldIds.updatedAt,
    bool sortAscending = false,
    String? clientId,
  }) {
    final q = select(tasks)..where((t) => t.companyId.equals(companyId));

    if (clientId != null && clientId.isNotEmpty) {
      q.where((t) => t.clientId.equals(clientId));
    }

    if (states.isNotEmpty) {
      q.where(
        (t) => entityStateFilter(
          states: states,
          archivedAt: t.archivedAt,
          isDeleted: t.isDeleted,
        ),
      );
    }

    if (search != null && search.isNotEmpty) {
      final needle = '%${search.toLowerCase()}%';
      q.where(
        (t) =>
            t.taskNumber.lower().like(needle) |
            t.description.lower().like(needle),
      );
    }

    q.orderBy([
      (t) => OrderingTerm(
        expression: _sortExpression(t, sortField),
        mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
      ),
      (t) => OrderingTerm(expression: t.id),
    ]);

    q.limit(limit, offset: offset);
    return q.watch();
  }

  Expression _sortExpression(Tasks t, String field) {
    switch (field) {
      case TaskFieldIds.number:
        return t.taskNumber.lower();
      case TaskFieldIds.description:
        return t.description.lower();
      case TaskFieldIds.rate:
        return t.rate.cast<double>();
      case TaskFieldIds.clientId:
        return t.clientId;
      case TaskFieldIds.projectId:
        return t.projectId;
      case TaskFieldIds.taskStatusId:
        return t.taskStatusId;
      case TaskFieldIds.statusOrder:
        return t.statusOrder;
      case TaskFieldIds.updatedAt:
        return t.updatedAt;
      default:
        return t.updatedAt;
    }
  }

  /// Watch every active+non-deleted task for a company, sorted by
  /// `(status_order ASC, updated_at DESC)`. The repository groups by
  /// `task_status_id` in Dart for the kanban board.
  Stream<List<TaskRow>> watchAllForKanban({
    required String companyId,
    Set<EntityState> states = const {EntityState.active},
  }) {
    final q = select(tasks)..where((t) => t.companyId.equals(companyId));
    if (states.isNotEmpty) {
      q.where(
        (t) => entityStateFilter(
          states: states,
          archivedAt: t.archivedAt,
          isDeleted: t.isDeleted,
        ),
      );
    }
    q.orderBy([
      (t) => OrderingTerm(expression: t.statusOrder),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id),
    ]);
    return q.watch();
  }

  /// Watch the single most-recently-updated running task for the company.
  /// O(1) thanks to the denormalized `is_running` column. Backs the global
  /// running-timer pill.
  Stream<TaskRow?> watchRunning({required String companyId}) {
    final q = select(tasks)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.isRunning.equals(true) &
            t.isDeleted.equals(false),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// Active, non-deleted tasks belonging to one project. Used by the
  /// Project detail's Tasks card. Excludes archived rows — they belong on
  /// the parent Task list, not in a project's overview.
  Stream<List<TaskRow>> watchForProject({
    required String companyId,
    required String projectId,
  }) {
    final q = select(tasks)
      ..where(
        (t) =>
            t.companyId.equals(companyId) &
            t.projectId.equals(projectId) &
            t.isDeleted.equals(false) &
            t.archivedAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return q.watch();
  }

  /// One-shot batch read by id. Used by the reorder path so a single
  /// query replaces N `watchById(...).first` subscriptions inside a
  /// transaction. Empty input returns an empty list.
  Future<List<TaskRow>> getByIds({
    required String companyId,
    required Iterable<String> ids,
  }) {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return Future.value(const <TaskRow>[]);
    final q = select(tasks)
      ..where((t) => t.companyId.equals(companyId) & t.id.isIn(list));
    return q.get();
  }
}
