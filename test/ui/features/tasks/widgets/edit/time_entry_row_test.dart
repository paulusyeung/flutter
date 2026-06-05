import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/ui/features/tasks/widgets/edit/time_entry_row.dart';

import '../../../../../_responsive_helper.dart';

/// `TimeEntryRow` is the phone fallback for the time-log (rendered below the
/// 800px table breakpoint). Its fixed 220px date column used to overflow the
/// smallest phones once a running entry added a wide live-duration label plus
/// the non-billable icon and delete button; it now stacks below ~400px.
void main() {
  TimeEntry entry({required bool running, required bool billable}) {
    final start = DateTime(2026, 6, 5, 9);
    return TimeEntry(
      start: start,
      stop: running ? null : start.add(const Duration(hours: 1, minutes: 23)),
      description: 'Worked on the quarterly onboarding revamp for a while now',
      billable: billable,
    );
  }

  Widget row({required bool running, required bool billable}) => TimeEntryRow(
    entry: entry(running: running, billable: billable),
    onTap: () {},
    onRemove: () {},
  );

  testWidgets('no overflow on a narrow phone — stopped, non-billable', (
    tester,
  ) async {
    await pumpAt(tester, 360, row(running: false, billable: false));
    expectNoOverflow(tester);
  });

  testWidgets('no overflow on a narrow phone — running, non-billable', (
    tester,
  ) async {
    await pumpAt(tester, 360, row(running: true, billable: false));
    expectNoOverflow(tester);
    // Tear down the live-ticking duration's periodic timer.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no overflow at the wide table width', (tester) async {
    await pumpAt(tester, 800, row(running: false, billable: true));
    expectNoOverflow(tester);
  });
}
