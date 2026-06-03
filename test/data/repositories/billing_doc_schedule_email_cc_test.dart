import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// `scheduleEmail` must carry `cc_email` through the outbox payload — the
/// CC field is shared by the immediate-send and scheduled paths on the
/// full-screen Send Email surface, and previously the scheduled path
/// silently dropped it. Invoice is the representative billing doc (the
/// helper is identical on quote / credit / PO / recurring).
class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceRepository repo() => InvoiceRepository(
    db: db,
    api: _FakeInvoicesApi(),
    settings: SettingsRepository(db: db),
  );

  test(
    'scheduleEmail carries cc_email + send_at + overrides in the payload',
    () async {
      await repo().scheduleEmail(
        companyId: 'co',
        id: 'inv1',
        template: 'reminder1',
        sendAt: '2026-07-01T09:00:00Z',
        subject: 'Hi',
        body: 'Body',
        ccEmail: 'cc@example.com',
      );

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending, hasLength(1));
      final row = pending.single;
      expect(row.entityType, 'invoice');
      expect(row.entityId, 'inv1');
      expect(row.mutationKind, MutationKind.scheduleEmail.wireName);

      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      expect(payload['template'], 'reminder1');
      expect(payload['send_at'], '2026-07-01T09:00:00Z');
      expect(payload['subject'], 'Hi');
      expect(payload['body'], 'Body');
      expect(payload['cc_email'], 'cc@example.com');
    },
  );

  test('scheduleEmail omits optional keys when not provided', () async {
    await repo().scheduleEmail(
      companyId: 'co',
      id: 'inv2',
      template: 'invoice',
      sendAt: '2026-07-01T09:00:00Z',
    );

    final pending = await db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);
    final payload = jsonDecode(pending.single.payload) as Map<String, dynamic>;
    expect(payload.containsKey('cc_email'), isFalse);
    expect(payload.containsKey('subject'), isFalse);
    expect(payload.containsKey('body'), isFalse);
  });
}
