import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/domain/entity_state.dart';

/// State for the Kanban board view. Subscribes to:
///   * Every TaskStatus row → the column set (sorted by `status_order`).
///   * Every active Task grouped by `status_id` → the cards in each column.
///
/// Owns optimistic drag state: when the user drops a card the in-memory
/// `Map<String, List<Task>>` is mutated before the repo writes hit Drift,
/// so the board re-renders instantly. The repo write's watch-stream
/// emission then replaces the optimistic frame seamlessly.
class KanbanViewModel extends ChangeNotifier {
  KanbanViewModel({
    required this.repo,
    required this.statusRepo,
    required this.companyId,
  }) {
    _statusesSub = statusRepo
        .watchAll(companyId: companyId)
        .listen(_onStatuses);
    _tasksSub = repo
        .watchAllByStatus(
          companyId: companyId,
          states: const {EntityState.active},
        )
        .listen(_onTasks);
  }

  final TaskRepository repo;
  final TaskStatusRepository statusRepo;
  final String companyId;

  StreamSubscription<List<TaskStatus>>? _statusesSub;
  StreamSubscription<Map<String, List<Task>>>? _tasksSub;

  List<TaskStatus> _statuses = const [];
  List<TaskStatus> get statuses => _statuses;

  Map<String, List<Task>> _tasksByStatus = const {};
  Map<String, List<Task>> get tasksByStatus => _tasksByStatus;

  bool _isResolving = true;
  bool get isResolving => _isResolving;

  bool _isReordering = false;
  bool get isReordering => _isReordering;

  void _onStatuses(List<TaskStatus> next) {
    _statuses = next;
    _isResolving = false;
    notifyListeners();
  }

  void _onTasks(Map<String, List<Task>> next) {
    _tasksByStatus = next;
    notifyListeners();
  }

  /// Tasks for [statusId] in the order the user last saw them. Returns an
  /// empty list when nothing is grouped under that status yet.
  List<Task> tasksFor(String statusId) =>
      _tasksByStatus[statusId] ?? const <Task>[];

  /// Persist a card move. The board has already applied the optimistic
  /// rearrangement; this method writes the new `(status_id, status_order)`
  /// for every affected task and enqueues the bulk `reorder` outbox row.
  ///
  /// [orderedByStatus] is the *full* board layout — not just the changed
  /// column — so a drag from column A into column B writes both columns.
  Future<void> commitReorder({
    required Map<String, List<Task>> orderedByStatus,
  }) async {
    if (_isReordering) return;
    _isReordering = true;
    notifyListeners();
    try {
      final statusIds = _statuses.map((s) => s.id).toList(growable: false);
      final taskIds = <String, List<String>>{
        for (final sid in statusIds)
          sid: (orderedByStatus[sid] ?? const <Task>[])
              .map((t) => t.id)
              .toList(growable: false),
      };
      await repo.reorder(
        companyId: companyId,
        statusIds: statusIds,
        orderedByStatus: taskIds,
      );
    } finally {
      _isReordering = false;
      notifyListeners();
    }
  }

  /// Persist a column-header drag (status reordering on kanban).
  Future<void> commitStatusReorder(List<String> orderedStatusIds) async {
    await statusRepo.reorder(
      companyId: companyId,
      orderedStatusIds: orderedStatusIds,
    );
  }

  @override
  void dispose() {
    _statusesSub?.cancel();
    _tasksSub?.cancel();
    super.dispose();
  }
}
