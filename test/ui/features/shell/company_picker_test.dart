import 'package:admin/data/db/app_database.dart';
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

  testWidgets('New Company action pops a Coming soon SnackBar', (tester) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const CompanyPicker(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Company'));
    await tester.pump();
    expect(find.text('Coming soon'), findsOneWidget);

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
}
