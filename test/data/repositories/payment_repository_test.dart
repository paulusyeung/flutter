import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/payment_api_model.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/payment_repository.dart';
import 'package:admin/data/services/payments_api.dart';
import 'package:admin/domain/payment_status.dart';
import 'package:admin/domain/sync/mutation.dart';

import '_base_entity_repository_contract.dart';

class _PaymentFixture
    extends EntityRepositoryContractFixture<Payment, PaymentApi> {
  @override
  String get entityType => 'payment';

  @override
  PaymentRepository buildRepo(AppDatabase db) =>
      PaymentRepository(db: db, api: _FakePaymentsApi());

  @override
  PaymentApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => PaymentApi(
    id: id,
    number: displayValue ?? id,
    updatedAt: updatedAt,
  );

  @override
  Payment fromApi(PaymentApi api) => Payment.fromApi(api);

  @override
  Payment editCopy(Payment item, {required String displayValue}) =>
      item.copyWith(number: displayValue);

  @override
  String idOf(Payment item) => item.id;

  @override
  bool isDirtyOf(Payment item) => item.isDirty;

  @override
  Future<SaveResult<Payment>> create(
    BaseEntityRepository<Payment, PaymentApi> repo, {
    required String companyId,
    required Payment draft,
  }) => (repo as PaymentRepository).create(
    companyId: companyId,
    draft: draft,
    sendEmail: false,
  );

  @override
  Future<SaveResult<Payment>> save(
    BaseEntityRepository<Payment, PaymentApi> repo, {
    required String companyId,
    required Payment entity,
  }) => (repo as PaymentRepository).save(
    companyId: companyId,
    payment: entity,
    sendEmail: false,
  );

  @override
  Future<void> delete(
    BaseEntityRepository<Payment, PaymentApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as PaymentRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_PaymentFixture());

  group('PaymentRepository — entity-specific', () {
    test(
      'PaymentApi → Payment round-trip preserves Decimal precision on '
      'amount / applied / refunded / exchange_rate',
      () {
        const api = PaymentApi(
          id: 'p_1',
          amount: '1234.5678',
          applied: '500.1234',
          refunded: '25.0000',
          exchangeRate: '0.876543',
        );
        final domain = Payment.fromApi(api);
        expect(domain.amount, Decimal.parse('1234.5678'));
        expect(domain.applied, Decimal.parse('500.1234'));
        expect(domain.refunded, Decimal.parse('25.0000'));
        expect(domain.exchangeRate, Decimal.parse('0.876543'));
      },
    );

    test(
      'calculatedStatusId returns the virtual -1 / -2 codes on completed '
      'payments based on the applied/amount balance',
      () {
        final completedFull = Payment.fromApi(const PaymentApi(
          id: 'p_2',
          statusId: kPaymentStatusCompleted,
          amount: '100',
          applied: '100',
        ));
        expect(completedFull.calculatedStatusId, kPaymentStatusCompleted);

        final completedPartial = Payment.fromApi(const PaymentApi(
          id: 'p_3',
          statusId: kPaymentStatusCompleted,
          amount: '100',
          applied: '40',
        ));
        expect(
          completedPartial.calculatedStatusId,
          kPaymentStatusPartiallyUnapplied,
        );

        final completedUnapplied = Payment.fromApi(const PaymentApi(
          id: 'p_4',
          statusId: kPaymentStatusCompleted,
          amount: '100',
          applied: '0',
        ));
        expect(
          completedUnapplied.calculatedStatusId,
          kPaymentStatusUnapplied,
        );

        // Non-completed statuses pass through unchanged.
        final failed = Payment.fromApi(const PaymentApi(
          id: 'p_5',
          statusId: kPaymentStatusFailed,
          amount: '100',
          applied: '0',
        ));
        expect(failed.calculatedStatusId, kPaymentStatusFailed);
      },
    );

    test(
      'refundable + unapplied getters reflect amount minus refunded/applied',
      () {
        final p = Payment.fromApi(const PaymentApi(
          id: 'p_6',
          amount: '100',
          applied: '60',
          refunded: '30',
        ));
        expect(p.refundable, Decimal.parse('70'));
        expect(p.unapplied, Decimal.parse('40'));
        expect(p.hasUnappliedFunds, true);
      },
    );

    test(
      'paymentables list round-trips through fromApi as PaymentableEntity '
      'rows with the per-row refunded amount preserved',
      () {
        const api = PaymentApi(
          id: 'p_7',
          amount: '500',
          paymentables: [
            PaymentableApi(
              id: 'pa_1',
              invoiceId: 'i_1',
              amount: '300',
              refunded: '50',
            ),
            PaymentableApi(
              id: 'pa_2',
              creditId: 'c_1',
              amount: '200',
            ),
          ],
        );
        final domain = Payment.fromApi(api);
        expect(domain.paymentables.length, 2);
        expect(domain.paymentables[0].invoiceId, 'i_1');
        expect(domain.paymentables[0].amount, Decimal.parse('300'));
        expect(domain.paymentables[0].refunded, Decimal.parse('50'));
        expect(domain.paymentables[1].creditId, 'c_1');
      },
    );

    test(
      'toApiJson filters paymentables with zero amount or no target id — '
      'guards against the edit dialog persisting cleared rows (B2)',
      () {
        final api = const PaymentApi(
          id: 'p_zero',
          paymentables: [
            PaymentableApi(invoiceId: 'i_keep', amount: '50'),
            PaymentableApi(invoiceId: 'i_drop_zero', amount: '0'),
            PaymentableApi(amount: '25'), // no id
          ],
        );
        final p = Payment.fromApi(api);
        final wire = p.toApiJson();
        final rows = wire['paymentables'] as List;
        expect(rows, hasLength(1));
        final only = rows.single as Map<String, dynamic>;
        expect(only['invoice_id'], 'i_keep');
        expect(only['amount'], '50');
      },
    );
  });

  group('PaymentRepository — refund + apply enqueue', () {
    late AppDatabase db;
    late PaymentRepository repo;
    const companyId = 'co_1';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PaymentRepository(db: db, api: _FakePaymentsApi());
    });
    tearDown(() async {
      await db.close();
    });

    test('refund enqueues an outbox row with the right MutationKind + body',
        () async {
      await repo.refund(
        companyId: companyId,
        paymentId: 'p_real_1',
        date: '2026-05-15',
        invoices: [
          {'invoice_id': 'inv_1', 'amount': '25.00', 'id': ''},
        ],
        sendEmail: true,
        gatewayRefund: false,
      );
      final rows = await db.outboxDao.nextReady(
        companyId: companyId,
        now: 1 << 60,
      );
      expect(rows.length, 1);
      final row = rows.first;
      expect(row.mutationKind, MutationKind.refundPayment.wireName);
      expect(row.entityType, 'payment');
      expect(row.entityId, 'p_real_1');
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      expect(payload['id'], 'p_real_1');
      expect(payload['date'], '2026-05-15');
      expect(payload['send_email'], true);
      expect(payload['gateway_refund'], false);
      final entries = (payload['invoices'] as List).cast<Map<String, dynamic>>();
      expect(entries.first['invoice_id'], 'inv_1');
      expect(entries.first['amount'], '25.00');
    });

    test('apply enqueues an outbox row with allocations under invoices key',
        () async {
      await repo.apply(
        companyId: companyId,
        paymentId: 'p_real_2',
        allocations: [
          {'_id': 'aa', 'invoice_id': 'inv_2', 'amount': '40.00'},
        ],
      );
      final rows = await db.outboxDao.nextReady(
        companyId: companyId,
        now: 1 << 60,
      );
      expect(rows.length, 1);
      final row = rows.first;
      expect(row.mutationKind, MutationKind.applyPayment.wireName);
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      expect(payload['id'], 'p_real_2');
      final allocations = (payload['invoices'] as List).cast<Map<String, dynamic>>();
      expect(allocations.first['invoice_id'], 'inv_2');
      expect(allocations.first['amount'], '40.00');
    });

    test('create threads send_email through the synthetic payload key',
        () async {
      final draft = Payment.fromApi(const PaymentApi(
        id: '',
        clientId: 'c_1',
        amount: '100',
      ));
      await repo.create(
        companyId: companyId,
        draft: draft,
        sendEmail: true,
      );
      final rows = await db.outboxDao.nextReady(
        companyId: companyId,
        now: 1 << 60,
      );
      final create = rows.firstWhere(
        (r) => r.mutationKind == MutationKind.create.wireName,
      );
      final payload = jsonDecode(create.payload) as Map<String, dynamic>;
      expect(payload[kPaymentSendEmailKey], true);
    });
  });

  group('PaymentRepository — DB smoke', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('repo can be constructed against an in-memory DB', () {
      final repo = PaymentRepository(db: db, api: _FakePaymentsApi());
      expect(repo.entityTypeName, 'payment');
      expect(repo.requiresPasswordFor(MutationKind.delete), true);
      expect(repo.requiresPasswordFor(MutationKind.purge), true);
      expect(repo.requiresPasswordFor(MutationKind.documentDelete), true);
      expect(repo.requiresPasswordFor(MutationKind.refundPayment), false);
    });
  });
}

class _FakePaymentsApi implements PaymentsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
