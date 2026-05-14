import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/task_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/standard_crud_bulk_actions.dart';

/// List ViewModel for the Tasks screen. Drives both the standard list view
/// and the kanban board — the kanban subscribes to the same filter/search
/// state so flipping the AppBar toggle doesn't lose work-in-progress
/// filtering.
class TaskListViewModel extends GenericListViewModel<Task> {
  TaskListViewModel({
    required this.repo,
    required super.companyId,
    required super.navStateDao,
    required super.userSettings,
    super.savedViews,
    super.searchDebounce,
    super.persistDebounce,
    super.now,
  });

  final TaskRepository repo;

  @override
  EntityType get entityType => EntityType.task;

  @override
  List<ColumnDefinition<Task>> get allColumns => kAllTaskColumns;

  @override
  List<String> get defaultColumnIds => kDefaultTaskColumns;

  @override
  String get defaultSortField => TaskFieldIds.updatedAt;

  @override
  bool isValidColumnId(String field) =>
      taskColumnsById.containsKey(field) || field == TaskFieldIds.updatedAt;

  @override
  String idOf(Task item) => item.id;

  @override
  bool isArchived(Task item) => item.archivedAt != null;

  @override
  bool isDeleted(Task item) => item.isDeleted;

  @override
  Stream<List<Task>> watchPage() => repo.watchPage(
    companyId: companyId,
    loadedPages: loadedPages,
    search: search.isEmpty ? null : search,
    states: states,
    sortField: sortField,
    sortAscending: sortAscending,
  );

  @override
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required Map<String, Set<String>> extraFilters,
    required bool ignoreCursor,
  }) => repo.ensurePageLoaded(
    companyId: companyId,
    page: page,
    search: search,
    states: states,
    extraFilters: extraFilters,
    ignoreCursor: ignoreCursor,
  );

  @override
  Future<void> refreshAll() => repo.refreshAll(companyId: companyId);

  @override
  Iterable<BulkAction<Task>> get bulkActions => standardCrudBulkActions(
    isArchived: isArchived,
    isDeleted: isDeleted,
    archive: (id) => repo.archive(companyId: companyId, id: id),
    restore: (id) => repo.restore(companyId: companyId, id: id),
    delete: (id) => repo.delete(companyId: companyId, id: id),
  );
}
