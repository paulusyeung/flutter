import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/schedule_api_model.dart';
import 'package:admin/data/models/domain/schedule.dart';
import 'package:admin/data/models/domain/schedule_constants.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/repositories/schedule_repository.dart';
import 'package:admin/data/services/schedules_api.dart';

import '_base_entity_repository_contract.dart';

/// Covers the universal `BaseEntityRepository` contract via the shared
/// harness, plus schedule-specific assertions for the per-template
/// parameter shape, applyBundle upsert semantics, and Decimal typing of
/// payment-schedule row amounts (CLAUDE.md § Strict rules forbids `double`).
class _ScheduleFixture
    extends EntityRepositoryContractFixture<Schedule, ScheduleApi> {
  @override
  String get entityType => 'schedule';

  @override
  ScheduleRepository buildRepo(AppDatabase db) =>
      ScheduleRepository(db: db, api: _FakeSchedulesApi());

  @override
  ScheduleApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  }) => ScheduleApi(
    id: id,
    name: displayValue ?? id,
    template: kScheduleTemplateEmailStatement,
    frequencyId: '5',
    nextRun: '2026-06-01',
    remainingCycles: -1,
    parameters: const <String, dynamic>{
      'date_range': 'last30_days',
      'status': 'all',
      'show_aging_table': true,
      'clients': <String>[],
    },
    updatedAt: updatedAt,
  );

  @override
  Schedule fromApi(ScheduleApi api) => Schedule.fromApi(api);

  @override
  Schedule editCopy(Schedule item, {required String displayValue}) =>
      item.copyWith(name: displayValue);

  @override
  String idOf(Schedule item) => item.id;

  @override
  bool isDirtyOf(Schedule item) => item.isDirty;

  @override
  Future<Schedule> create(
    BaseEntityRepository<Schedule, ScheduleApi> repo, {
    required String companyId,
    required Schedule draft,
  }) => (repo as ScheduleRepository).create(
    companyId: companyId,
    draft: draft,
  );

  @override
  Future<void> save(
    BaseEntityRepository<Schedule, ScheduleApi> repo, {
    required String companyId,
    required Schedule entity,
  }) => (repo as ScheduleRepository)
      .save(companyId: companyId, schedule: entity);

  @override
  Future<void> delete(
    BaseEntityRepository<Schedule, ScheduleApi> repo, {
    required String companyId,
    required String id,
  }) => (repo as ScheduleRepository).delete(companyId: companyId, id: id);
}

void main() {
  runEntityRepositoryContract(_ScheduleFixture());

  group('ScheduleRepository — entity-specific', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    ScheduleRepository makeRepo() =>
        ScheduleRepository(db: db, api: _FakeSchedulesApi());

    test(
      'email_statement round-trip preserves typed parameter accessors',
      () {
        const api = ScheduleApi(
          id: 's_1',
          name: 'Monthly statement',
          template: kScheduleTemplateEmailStatement,
          frequencyId: '5',
          nextRun: '2026-06-01',
          parameters: <String, dynamic>{
            'date_range': 'this_quarter',
            'status': 'unpaid',
            'show_aging_table': true,
            'show_payments_table': false,
            'only_clients_with_invoices': true,
            'clients': <String>['c_1', 'c_2'],
          },
          updatedAt: 1700000000,
        );
        final s = Schedule.fromApi(api);
        expect(s.statementDateRange, 'this_quarter');
        expect(s.statementStatus, 'unpaid');
        expect(s.statementShowAgingTable, isTrue);
        expect(s.statementShowPaymentsTable, isFalse);
        expect(s.statementOnlyClientsWithInvoices, isTrue);
        expect(s.statementClients, ['c_1', 'c_2']);
      },
    );

    test(
      'email_record round-trip preserves entity_id + email template',
      () {
        const api = ScheduleApi(
          id: 's_2',
          template: kScheduleTemplateEmailRecord,
          nextRun: '2026-07-15',
          parameters: <String, dynamic>{
            'entity': 'invoice',
            'entity_id': 'inv_42',
            'template': 'reminder2',
          },
          updatedAt: 1700000100,
        );
        final s = Schedule.fromApi(api);
        expect(s.recordEntityType, 'invoice');
        expect(s.recordEntityId, 'inv_42');
        expect(s.recordEmailTemplate, 'reminder2');
      },
    );

    test(
      'email_report round-trip resolves CSV vendor list back to List<String>',
      () {
        const api = ScheduleApi(
          id: 's_3',
          template: kScheduleTemplateEmailReport,
          frequencyId: '7',
          nextRun: '2026-04-01',
          parameters: <String, dynamic>{
            'report_name': 'expense',
            'date_range': 'this_quarter',
            'send_email': true,
            // React serializes these as CSV strings on the wire.
            'vendors': 'v_1,v_2,v_3',
            'projects': 'p_1, p_2',
            'categories': '',
            'clients': <String>['c_99'],
          },
          updatedAt: 1700000200,
        );
        final s = Schedule.fromApi(api);
        expect(s.reportName, 'expense');
        expect(s.reportVendors, ['v_1', 'v_2', 'v_3']);
        expect(s.reportProjects, ['p_1', 'p_2']);
        expect(s.reportCategories, isEmpty);
        expect(s.reportClients, ['c_99']);
      },
    );

    test('payment_schedule row amount is a Decimal, never a double', () {
      const api = ScheduleApi(
        id: 's_4',
        template: kScheduleTemplatePaymentSchedule,
        parameters: <String, dynamic>{
          'invoice_id': 'inv_77',
          'auto_bill': true,
          'schedule': <Map<String, dynamic>>[
            {
              'id': 1,
              'date': '2026-06-01',
              'amount': '250.50',
              'is_amount': true,
            },
            {
              'id': 2,
              'date': '2026-07-01',
              'amount': '249.50',
              'is_amount': true,
            },
          ],
        },
        updatedAt: 1700000300,
      );
      final s = Schedule.fromApi(api);
      expect(s.paymentScheduleInvoiceId, 'inv_77');
      expect(s.paymentScheduleAutoBill, isTrue);
      final rows = s.paymentScheduleRows;
      expect(rows, hasLength(2));
      expect(rows[0].amount, Decimal.parse('250.50'));
      expect(rows[0].amount, isA<Decimal>());
      expect(rows[1].amount, Decimal.parse('249.50'));
      // is_amount applies uniformly across the rows (matches React's
      // first-row-only-mode contract).
      expect(rows.every((r) => r.isAmount), isTrue);
    });

    test(
      'applyBundle upserts every row and advances the cursor to max updatedAt',
      () async {
        final repo = makeRepo();
        await repo.applyBundle(
          companyId: 'co',
          bundle: const [
            ScheduleApi(
              id: 's_a',
              template: kScheduleTemplateEmailStatement,
              frequencyId: '5',
              nextRun: '2026-06-01',
              updatedAt: 1700000100,
            ),
            ScheduleApi(
              id: 's_b',
              template: kScheduleTemplateEmailReport,
              frequencyId: '7',
              nextRun: '2026-07-01',
              updatedAt: 1700000200,
            ),
          ],
        );
        final rows = await repo.watchAll(companyId: 'co').first;
        expect(rows.map((s) => s.id).toSet(), {'s_a', 's_b'});
        final cursor = await db.syncStateDao.read(
          companyId: 'co',
          entityType: 'schedule',
        );
        expect(cursor.updatedAt, 1700000200);
        expect(cursor.id, 's_b');
      },
    );

    test(
      'applyBundle preserves the local payload of an is_dirty row '
      'so an offline edit is not clobbered by a re-bundle',
      () async {
        final repo = makeRepo();
        // Local offline create of an email_statement schedule.
        final draft = Schedule.empty()
            .withTemplate(kScheduleTemplateEmailStatement)
            .copyWith(name: 'Local edit');
        await repo.create(companyId: 'co', draft: draft);
        final dirtyBefore =
            (await repo.watchAll(companyId: 'co').first).single;
        expect(dirtyBefore.isDirty, isTrue);

        await repo.applyBundle(
          companyId: 'co',
          bundle: const [
            ScheduleApi(
              id: 's_server',
              template: kScheduleTemplateEmailReport,
              frequencyId: '7',
              nextRun: '2026-04-01',
              updatedAt: 1700000500,
            ),
          ],
        );
        final all = await repo.watchAll(companyId: 'co').first;
        expect(all, hasLength(2));
        final stillDirty = all.firstWhere((s) => s.name == 'Local edit');
        expect(stillDirty.isDirty, isTrue);
      },
    );

    test(
      '_fromRow overlays is_dirty so an offline create reads as dirty',
      () async {
        final repo = makeRepo();
        final draft = Schedule.empty()
            .withTemplate(kScheduleTemplateEmailStatement);
        await repo.create(companyId: 'co', draft: draft);
        final rows = await repo.watchAll(companyId: 'co').first;
        expect(rows, hasLength(1));
        expect(rows.first.isDirty, isTrue);
      },
    );

    test(
      'setPaused flips is_paused and re-enqueues an update mutation',
      () async {
        final repo = makeRepo();
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 's_x',
          serverResponse: const ScheduleApi(
            id: 's_x',
            template: kScheduleTemplateEmailStatement,
            frequencyId: '5',
            nextRun: '2026-06-01',
            updatedAt: 1700000000,
          ),
        );
        final loaded = (await repo.watchAll(companyId: 'co').first).single;
        expect(loaded.isPaused, isFalse);
        await repo.setPaused(
          companyId: 'co',
          schedule: loaded,
          paused: true,
        );
        final paused = (await repo.watchAll(companyId: 'co').first).single;
        expect(paused.isPaused, isTrue);
        // An outbox row was enqueued for the update.
        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: DateTime.now().millisecondsSinceEpoch,
        );
        expect(pending, isNotEmpty);
      },
    );
  });
}

class _FakeSchedulesApi implements SchedulesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
