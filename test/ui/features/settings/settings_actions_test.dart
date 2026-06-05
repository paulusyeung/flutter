// Regression guard for the Settings "Sign out" pending-outbox check. The
// company picker's switch / sign-out paths already quiesce the outbox before
// wiping the session; this proves the Settings → Sign out action does too, so
// an unsynced offline edit can't be silently dropped on logout.

import 'package:admin/data/db/app_database.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../shell/_shell_test_helpers.dart';

void main() {
  testWidgets(
    'Settings sign-out with a pending outbox row surfaces the unsynced-changes '
    'guard instead of logging out silently',
    (tester) async {
      final fixture = await buildFixture(
        companies: const [
          FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
        ],
        currentCompanyId: 'c1',
      );
      addTearDown(fixture.dispose);

      // Park one pending outbox row for the active company.
      await fixture.db.outboxDao.enqueue(
        OutboxCompanion.insert(
          companyId: 'c1',
          entityType: 'client',
          entityId: 'x',
          mutationKind: 'update',
          payload: '{}',
          idempotencyKey: 'k',
          createdAt: 0,
          nextAttemptAt: 0,
          requiresPassword: const Value(false),
        ),
      );

      await tester.pumpWidget(
        wrapWithShell(
          fixture.services,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => SettingsActions.signOut(context),
              child: const Text('trigger-signout'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger → generic "sign out?" confirm appears first.
      await tester.tap(find.text('trigger-signout'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Confirm sign-out (the confirm dialog's only FilledButton). The
      // pending-outbox guard must intercept before logout/DB wipe.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Unsynced changes'), findsOneWidget);
      expect(find.text('Sync first'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Cancel the guard → still signed in, session (and its DB) intact.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(fixture.services.auth.session.value?.currentCompanyId, 'c1');

      // The recently-viewed controller arms a debounce timer when restore()
      // first set the session; dispose it before the binding's pending-timer
      // check (ShellFixture.dispose doesn't touch it — no double-dispose).
      fixture.services.recentlyViewed.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Settings sign-out with an unsaved (dirty) editor surfaces the '
      'discard-changes guard instead of logging out silently', (tester) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    // Register an always-dirty editor so the in-memory guard must prompt.
    // Teardown order (LIFO): unregister runs before source.dispose, so the
    // guard's listener is removed before the notifier is torn down.
    final source = ValueNotifier<int>(0);
    addTearDown(source.dispose);
    final unregister = fixture.services.unsavedChangesGuard.register(
      isDirty: () => true,
      source: source,
    );
    addTearDown(unregister);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SettingsActions.signOut(context),
            child: const Text('trigger-signout'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger → generic "sign out?" confirm; confirm it (its only
    // FilledButton). The in-memory dirty guard must intercept before logout.
    await tester.tap(find.text('trigger-signout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);

    // Keep editing → aborts sign-out, still signed in.
    await tester.tap(find.widgetWithText(TextButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(fixture.services.auth.session.value?.currentCompanyId, 'c1');

    fixture.services.recentlyViewed.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
