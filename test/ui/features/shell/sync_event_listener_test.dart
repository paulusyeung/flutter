// Verifies the SyncEventListener escalation added for unrecoverable outbox
// failures: when the user is online and no caller is surfacing the failure
// itself, a dead row pops a MODAL (so the user can't miss it); offline it
// stays a non-blocking toast. Uses the real `Services` from the shell test
// helpers so the actual `services.sync` event stream + `connectivity` drive
// the listener, not a stub.

import 'package:admin/data/db/app_database.dart';
import 'package:admin/ui/features/shell/widgets/sync_event_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_shell_test_helpers.dart';

void main() {
  // Enqueue a row whose mutation kind can't be parsed: the drain marks it dead
  // and emits a DeadEvent (handledByCaller=false, since no `awaitRow` caller) —
  // the same shape a 400 reactivate-email failure produces, without needing a
  // mock HTTP layer.
  Future<void> enqueueDeadlyRow(
    ShellFixture fixture,
  ) => fixture.services.db.outboxDao.enqueue(
    OutboxCompanion.insert(
      companyId: 'co',
      entityType:
          'client', // registered, so we hit "unknown kind" not "no dispatcher"
      entityId: 'c1',
      mutationKind: 'action:bogus',
      payload: '{}',
      idempotencyKey: 'k1',
      nextAttemptAt: 0,
      createdAt: 0,
    ),
  );

  testWidgets('online + caller-unhandled dead row → modal alert', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'co', name: 'Co')],
      currentCompanyId: 'co',
      online: true,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        const SyncEventListener(child: SizedBox.shrink()),
      ),
    );
    // Let the listener subscribe (it does so in didChangeDependencies) BEFORE
    // the event is produced — the event stream is broadcast and doesn't buffer.
    await tester.pump();

    await enqueueDeadlyRow(fixture);
    await fixture.services.sync.drainOnce(companyId: 'co');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Could not save'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);

    // Dismiss closes the modal.
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('offline → no modal (stays a toast, never blocks the user)', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'co', name: 'Co')],
      currentCompanyId: 'co',
      online: false,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        const SyncEventListener(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();

    await enqueueDeadlyRow(fixture);
    await fixture.services.sync.drainOnce(companyId: 'co');
    await tester.pumpAndSettle();

    expect(
      find.byType(AlertDialog),
      findsNothing,
      reason: 'offline failures must not pop a blocking modal',
    );
  });
}
