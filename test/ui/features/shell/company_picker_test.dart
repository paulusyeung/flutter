import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/sync_repository.dart' show kMaxAttempts;
import 'package:admin/ui/features/shell/widgets/company_avatar.dart';
import 'package:admin/ui/features/shell/widgets/company_picker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_shell_test_helpers.dart';

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every company and marks the active one', (tester) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co'),
        FakeCompany(id: 'c2', name: 'Stark Industries'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Co'), findsOneWidget);
    expect(find.text('Stark Industries'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await _drain(tester);
  });

  testWidgets('passes settings.company_logo through to CompanyAvatar', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(
          id: 'c1',
          name: 'Acme Co',
          logoUrl: 'https://example.com/logo.png',
        ),
        FakeCompany(id: 'c2', name: 'Stark Industries'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    final avatars = tester
        .widgetList<CompanyAvatar>(find.byType(CompanyAvatar))
        .toList();
    final acmeAvatar = avatars.firstWhere((a) => a.seed == 'c1');
    final starkAvatar = avatars.firstWhere((a) => a.seed == 'c2');
    expect(acmeAvatar.logoUrl, 'https://example.com/logo.png');
    expect(starkAvatar.logoUrl, isNull);

    await _drain(tester);
  });

  testWidgets('New Company action opens a confirm dialog (owner)', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co', isOwner: true)],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Company'));
    await tester.pumpAndSettle();

    // Confirm dialog rendered. The `add_company` localization key is reused
    // for both the title and the FilledButton, so the literal "Add Company"
    // appears twice inside the same AlertDialog.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add Company'),
      ),
      findsNWidgets(2),
    );
    expect(
      find.text(
        'A new company will be created on your account. '
        'You can rename and configure it after.',
      ),
      findsOneWidget,
    );

    // Cancel — picker stays mounted, no network call made.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('New Company'), findsOneWidget);

    await _drain(tester);
  });

  testWidgets('New Company action is disabled for non-owners', (tester) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co', isOwner: false)],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    // The disabled-reason subtitle is rendered inline so mobile users can
    // see why the action isn't available (Tooltip wouldn't fire on tap).
    expect(
      find.text('Only the account owner can add companies'),
      findsOneWidget,
    );

    // Tapping the disabled row is a no-op — the confirm dialog must not open.
    await tester.tap(find.text('New Company'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);

    await _drain(tester);
  });

  testWidgets('switching without pending outbox calls auth.switchCompany', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
        FakeCompany(id: 'c2', name: 'Stark Industries', token: 'tok-c2'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stark Industries'));
    await tester.pumpAndSettle();

    expect(fixture.services.auth.session.value?.currentCompanyId, 'c2');

    await _drain(tester);
  });

  testWidgets('switching with pending outbox surfaces the confirm dialog', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
        FakeCompany(id: 'c2', name: 'Stark Industries', token: 'tok-c2'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    // Park one pending outbox row for c1 so the picker has to prompt.
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
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stark Industries'));
    await tester.pumpAndSettle();

    expect(find.text('Unsynced changes'), findsOneWidget);
    expect(find.text('Sync first'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Cancel and confirm the active company didn't change.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(fixture.services.auth.session.value?.currentCompanyId, 'c1');

    await _drain(tester);
  });

  testWidgets('online + pending row that resolves during precheck skips the '
      'dialog and switches', (tester) async {
    // Setup: online, plus a row primed to die on its next attempt
    // (attempts = kMaxAttempts - 1). The precheck's silent flushNow will
    // hit the real ApiClient → http.Client, fail with NetworkException,
    // trip _retryWithBackoff → _markDead. The row leaves the pending
    // state, pendingCountFor returns 0, and the dialog stays away.
    //
    // This proves the silent-flush precheck branch — not a Mock of the
    // sync engine. The actual code path runs end-to-end.
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co', token: 'tok-c1'),
        FakeCompany(id: 'c2', name: 'Stark Industries', token: 'tok-c2'),
      ],
      currentCompanyId: 'c1',
      online: true,
    );
    addTearDown(fixture.dispose);

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
        attempts: const Value(kMaxAttempts - 1),
        requiresPassword: const Value(false),
      ),
    );

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stark Industries'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unsynced changes'),
      findsNothing,
      reason:
          'precheck flushNow resolved the row (marked dead), so no dialog '
          'should appear',
    );
    expect(
      fixture.services.auth.session.value?.currentCompanyId,
      'c2',
      reason: 'switch must go through after the silent flush',
    );

    await _drain(tester);
  });
}
