import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/ui/features/tasks/widgets/daily/task_daily_actions.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

Task _t(
  String id, {
  String number = '',
  int statusOrder = 0,
  String invoiceId = '',
  List<TimeEntry> log = const [],
}) => Task(
  id: id,
  number: number,
  description: id,
  rate: Decimal.zero,
  invoiceId: invoiceId,
  clientId: 'c1',
  projectId: 'p1',
  statusId: 's1',
  statusOrder: statusOrder,
  assignedUserId: 'u1',
  timeLog: log,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  updatedAt: _epoch,
  createdAt: _epoch,
  archivedAt: null,
  isDeleted: false,
);

TimeEntry _e(DateTime start, DateTime? stop) =>
    TimeEntry(start: start, stop: stop);

void main() {
  test(
    'buildDuplicate blanks server-owned identity + shifts entries +1 day',
    () {
      final src = _t(
        'a',
        number: '0007',
        statusOrder: 3,
        invoiceId: 'inv1',
        log: [_e(DateTime(2026, 6, 9, 9), DateTime(2026, 6, 9, 11))],
      );
      final dup = TaskDailyActions.buildDuplicate(src)!;

      // Server-owned identity reset so the create gets a fresh number/order.
      expect(dup.id, '');
      expect(dup.number, '');
      expect(dup.statusOrder, 0);
      expect(dup.invoiceId, '');
      // Client/project/assignee carried.
      expect(dup.clientId, 'c1');
      expect(dup.projectId, 'p1');
      expect(dup.assignedUserId, 'u1');
      // Entry shifted to the next local day, same wall-clock + duration.
      final e = dup.timeLog.single;
      expect(e.start!.toLocal().day, 10);
      expect(e.start!.toLocal().hour, 9);
      expect(e.stop!.difference(e.start!), const Duration(hours: 2));
    },
  );

  test('buildDuplicate returns null when there is no stopped entry', () {
    expect(TaskDailyActions.buildDuplicate(_t('a')), isNull); // empty log
    expect(
      TaskDailyActions.buildDuplicate(
        _t('b', log: [_e(DateTime(2026, 6, 9, 9), null)]), // running only
      ),
      isNull,
    );
  });
}
