import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Task taskWith(List<TimeEntry> log) => Task(
    id: 't',
    number: '',
    description: '',
    rate: Decimal.zero,
    invoiceId: '',
    clientId: '',
    projectId: '',
    statusId: '',
    statusOrder: 0,
    assignedUserId: '',
    timeLog: log,
    customValue1: '',
    customValue2: '',
    customValue3: '',
    customValue4: '',
    updatedAt: epoch,
    createdAt: epoch,
    archivedAt: null,
    isDeleted: false,
  );

  TimeEntry entry(int startS, int stopS, {bool billable = true}) => TimeEntry(
    start: DateTime.fromMillisecondsSinceEpoch(startS * 1000, isUtc: true),
    stop: DateTime.fromMillisecondsSinceEpoch(stopS * 1000, isUtc: true),
    billable: billable,
  );

  test('loggedDuration sums every entry; billableDuration only billable', () {
    final t = taskWith([
      entry(0, 3600), // 1h billable
      entry(3600, 7200, billable: false), // 1h non-billable
    ]);
    // A3: the UI shows total logged time (all entries)…
    expect(t.loggedDuration().inHours, 2);
    // …while invoice quantity uses billable hours only.
    expect(t.billableDuration().inHours, 1);
  });

  test('both are zero for an empty log', () {
    final t = taskWith(const []);
    expect(t.loggedDuration(), Duration.zero);
    expect(t.billableDuration(), Duration.zero);
  });
}
