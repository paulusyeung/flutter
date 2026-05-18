import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The billing-doc `reactivateInvitationEmail` seam: enqueue only, keyed to
/// the doc id, `reactivate_email` wire name, `{message_id}` payload — no
/// local Drift write. The dispatcher routes `reactivateEmail` through
/// `customActions` (handler returns null → no `applyUpdateResponse`); that
/// arm is covered by the client reactivate test + the customActions-before-
/// switch precedence in `base_entity_sync_dispatcher`. Invoice is the
/// representative billing doc (identical helper on quote/credit/PO/recurring).
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
    'reactivateInvitationEmail enqueues a reactivate_email row keyed to the '
    'doc with the message_id payload — no Drift write',
    () async {
      await repo().reactivateInvitationEmail(
        companyId: 'co',
        id: 'inv1',
        messageId: 'pm-msg-42',
      );

      final pending =
          await db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);
      expect(pending, hasLength(1));
      final row = pending.single;
      expect(row.entityType, 'invoice');
      expect(row.entityId, 'inv1');
      expect(row.mutationKind, MutationKind.reactivateEmail.wireName);
      expect(row.mutationKind, 'reactivate_email');
      expect(row.idempotencyKey, isNotEmpty);
      expect(row.requiresPassword, isFalse);

      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      expect(payload['message_id'], 'pm-msg-42');

      final invoiceRow =
          await db.invoiceDao.watchById(companyId: 'co', id: 'inv1').first;
      expect(invoiceRow, isNull, reason: 'reactivation never touches Drift');
    },
  );
}
