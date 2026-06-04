import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/data/services/tasks_api.dart';

/// Task-specific repository behavior the base contract doesn't probe:
/// the kanban invoiced-exclusion (B6) and the bulk `startTimer` op (B7).
void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Task task({
    String statusId = 's1',
    String invoiceId = '',
    List<TimeEntry> timeLog = const <TimeEntry>[],
  }) => Task(
    id: '',
    number: '',
    description: '',
    rate: Decimal.zero,
    invoiceId: invoiceId,
    clientId: '',
    projectId: '',
    statusId: statusId,
    statusOrder: 0,
    assignedUserId: '',
    timeLog: timeLog,
    customValue1: '',
    customValue2: '',
    customValue3: '',
    customValue4: '',
    updatedAt: epoch,
    createdAt: epoch,
    archivedAt: null,
    isDeleted: false,
  );

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  TaskRepository makeRepo() => TaskRepository(db: db, api: _FakeTasksApi());

  test(
    'watchAllByStatus excludes invoiced tasks from the kanban (B6)',
    () async {
      final repo = makeRepo();
      await repo.create(
        companyId: 'co',
        draft: task(statusId: 's1'),
      );
      await repo.create(
        companyId: 'co',
        draft: task(statusId: 's1', invoiceId: 'inv_1'),
      );

      final byStatus = await repo.watchAllByStatus(companyId: 'co').first;
      expect(byStatus['s1'], hasLength(1));
      expect(byStatus['s1']!.single.isInvoiced, isFalse);
    },
  );

  test('startTimer appends a running entry (B7 bulk start)', () async {
    final repo = makeRepo();
    final created = await repo.create(companyId: 'co', draft: task());
    final id = created.entity.id;

    await repo.startTimer(companyId: 'co', taskId: id);

    final after = await repo.watchByRealId(companyId: 'co', id: id).first;
    expect(after, isNotNull);
    expect(after!.timeLog, hasLength(1));
    expect(after.isRunning, isTrue);
  });

  test('startTimer is a no-op on an invoiced task', () async {
    final repo = makeRepo();
    final created = await repo.create(
      companyId: 'co',
      draft: task(invoiceId: 'inv_1'),
    );

    await repo.startTimer(companyId: 'co', taskId: created.entity.id);

    final after = await repo
        .watchByRealId(companyId: 'co', id: created.entity.id)
        .first;
    expect(after!.isRunning, isFalse);
    expect(after.timeLog, isEmpty);
  });
}

/// The repo paths under test never hit the network, so a throwing stub is
/// sufficient (mirrors `_FakeProductsApi`).
class _FakeTasksApi implements TasksApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
