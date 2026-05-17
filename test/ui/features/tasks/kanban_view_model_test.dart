import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/ui/features/tasks/view_models/kanban_view_model.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Task _t(
  String id, {
  String projectId = '',
  String clientId = '',
  String assignedUserId = '',
  String statusId = 's1',
}) => Task(
  id: id,
  number: id,
  description: id,
  rate: Decimal.zero,
  invoiceId: '',
  clientId: clientId,
  projectId: projectId,
  statusId: statusId,
  statusOrder: 0,
  assignedUserId: assignedUserId,
  timeLog: const [],
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  updatedAt: _epoch,
  createdAt: _epoch,
  archivedAt: null,
  isDeleted: false,
);

TaskStatus _s(String id) => TaskStatus(
  id: id,
  name: id,
  color: '',
  statusOrder: 0,
  updatedAt: _epoch,
  createdAt: _epoch,
  archivedAt: null,
  isDeleted: false,
);

class _FakeTaskRepo implements TaskRepository {
  _FakeTaskRepo(this._byStatus);
  final Map<String, List<Task>> _byStatus;
  bool reorderCalled = false;

  @override
  Stream<Map<String, List<Task>>> watchAllByStatus({
    required String companyId,
    states = const {},
  }) => Stream.value(_byStatus);

  @override
  Future<void> reorder({
    required String companyId,
    required List<String> statusIds,
    required Map<String, List<String>> orderedByStatus,
  }) async {
    reorderCalled = true;
  }

  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _FakeStatusRepo implements TaskStatusRepository {
  _FakeStatusRepo(this._statuses);
  final List<TaskStatus> _statuses;

  @override
  Stream<List<TaskStatus>> watchAll({required String companyId}) =>
      Stream.value(_statuses);

  @override
  Object? noSuchMethod(Invocation i) => throw UnimplementedError();
}

void main() {
  KanbanViewModel build(Map<String, List<Task>> byStatus, _FakeTaskRepo repo) =>
      KanbanViewModel(
        repo: repo,
        statusRepo: _FakeStatusRepo([_s('s1')]),
        companyId: 'co',
      );

  test('no filters → tasksFor returns the full status list', () async {
    final repo = _FakeTaskRepo({
      's1': [_t('a', projectId: 'p1'), _t('b', clientId: 'c1')],
    });
    final vm = build(const {}, repo);
    await Future<void>.delayed(Duration.zero);
    expect(vm.filtersActive, isFalse);
    expect(vm.tasksFor('s1').map((t) => t.id), ['a', 'b']);
  });

  test('filters by project / client / assignee (AND) before grouping',
      () async {
    final repo = _FakeTaskRepo({
      's1': [
        _t('a', projectId: 'p1', clientId: 'c1'),
        _t('b', projectId: 'p1', clientId: 'c2'),
        _t('c', projectId: 'p2', clientId: 'c1'),
      ],
    });
    final vm = build(const {}, repo);
    await Future<void>.delayed(Duration.zero);

    vm.setProjectFilter('p1');
    expect(vm.filtersActive, isTrue);
    expect(vm.tasksFor('s1').map((t) => t.id), ['a', 'b']);

    vm.setClientFilter('c1'); // AND
    expect(vm.tasksFor('s1').map((t) => t.id), ['a']);

    vm.clearFilters();
    expect(vm.filtersActive, isFalse);
    expect(vm.tasksFor('s1').map((t) => t.id), ['a', 'b', 'c']);
  });

  test('commitReorder is a no-op while a filter is active (no data loss)',
      () async {
    final repo = _FakeTaskRepo({
      's1': [_t('a', assignedUserId: 'u1'), _t('b')],
    });
    final vm = build(const {}, repo);
    await Future<void>.delayed(Duration.zero);

    vm.setAssigneeFilter('u1');
    await vm.commitReorder(orderedByStatus: {
      's1': [_t('a', assignedUserId: 'u1')],
    });
    expect(
      repo.reorderCalled,
      isFalse,
      reason: 'a reorder from a filtered/partial set must not persist',
    );
  });
}
