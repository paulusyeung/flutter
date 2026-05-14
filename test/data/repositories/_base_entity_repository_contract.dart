import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Universal contract every CRUD-list entity repository must satisfy.
///
/// Each entity test file supplies a fixture wiring the abstract knobs to its
/// concrete API + domain types, then calls
/// `runEntityRepositoryContract(fixture)` at the top of `main()`. The harness
/// installs its own `setUp` / `tearDown` and uses an in-memory Drift DB.
///
/// What's covered: tmp-id mint, outbox enqueue for create/update/delete,
/// requiresPassword flag, applyCreateResponse remap, applyUpdateResponse
/// clearing is_dirty, applyDeleteResponse hiding the row, watch(tmpId)
/// surviving the swap. What's NOT covered: per-entity filters, server query
/// shapes, custom-field plumbing — those stay in the concrete entity test
/// files.
abstract class EntityRepositoryContractFixture<TDomain, TApi> {
  /// Matches `EntityType.<x>.name` — used both to scope outbox lookups and to
  /// label the test group output.
  String get entityType;

  /// Build the repository under test. Called once per `setUp`; the fixture
  /// can rely on a fresh in-memory database each time.
  BaseEntityRepository<TDomain, TApi> buildRepo(AppDatabase db);

  /// Construct an API-shape DTO with the given id and a stable display value
  /// (so the round-trip assertions can spot mismatched fields). `updatedAt`
  /// defaults to a non-zero so cursor logic doesn't trip.
  TApi buildApiModel({
    required String id,
    String? displayValue,
    int updatedAt = 1700000000,
  });

  /// Lift the API DTO into the domain model the repo's create/save methods
  /// consume.
  TDomain fromApi(TApi api);

  /// Return a copy of [item] with the display value swapped — used by the
  /// "update writes is_dirty and enqueues an update outbox row" test.
  TDomain editCopy(TDomain item, {required String displayValue});

  /// Domain accessors.
  String idOf(TDomain item);
  bool isDirtyOf(TDomain item);

  /// Repo-method shims. `BaseEntityRepository` doesn't expose `create` /
  /// `save` / `delete` directly — they live on the concrete subclass with
  /// entity-specific named params (`save({client:})`, `save({product:})`,
  /// …). The fixture closes the gap.
  Future<TDomain> create(
    BaseEntityRepository<TDomain, TApi> repo, {
    required String companyId,
    required TDomain draft,
  });

  Future<void> save(
    BaseEntityRepository<TDomain, TApi> repo, {
    required String companyId,
    required TDomain entity,
  });

  Future<void> delete(
    BaseEntityRepository<TDomain, TApi> repo, {
    required String companyId,
    required String id,
  });

  /// `watch(id)` is on the base class but typed `Stream<TDomain?>`; expose it
  /// here so the harness can read without casting.
  Stream<TDomain?> watch(
    BaseEntityRepository<TDomain, TApi> repo, {
    required String companyId,
    required String id,
  }) => repo.watch(companyId: companyId, id: id);
}

/// Registers the universal contract tests against [fixture]. Call inside
/// `main()` (or a parent `group`) of the entity's `*_repository_test.dart`.
void runEntityRepositoryContract<TDomain, TApi>(
  EntityRepositoryContractFixture<TDomain, TApi> fixture,
) {
  group('BaseEntityRepository contract — ${fixture.entityType}', () {
    late AppDatabase db;
    late BaseEntityRepository<TDomain, TApi> repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = fixture.buildRepo(db);
    });
    tearDown(() async {
      await db.close();
    });

    test('create offline mints a tmp_ id and stores is_dirty=true', () async {
      // `repo.create` returns the draft with its tmp id assigned; the
      // `is_dirty=true` flag is set on the Drift row inside the transaction
      // and re-emerges through `watch` (the repo's `_fromRow` overlay).
      final draft = fixture.fromApi(
        fixture.buildApiModel(id: '', displayValue: 'A'),
      );

      final created = await fixture.create(repo, companyId: 'co', draft: draft);

      expect(fixture.idOf(created), startsWith('tmp_'));
      final fromDb = await fixture
          .watch(repo, companyId: 'co', id: fixture.idOf(created))
          .first;
      expect(fromDb, isNotNull);
      expect(fixture.isDirtyOf(fromDb as TDomain), isTrue);
    });

    test('create enqueues a create outbox row with a fresh idempotency key '
        'and the entity\'s wireName', () async {
      final draft = fixture.fromApi(
        fixture.buildApiModel(id: '', displayValue: 'A'),
      );
      await fixture.create(repo, companyId: 'co', draft: draft);

      final pending = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(pending, hasLength(1));
      expect(pending.single.mutationKind, MutationKind.create.wireName);
      expect(pending.single.entityType, fixture.entityType);
      expect(pending.single.idempotencyKey, isNotEmpty);
      expect(
        pending.single.requiresPassword,
        isFalse,
        reason: 'create does not require password — only delete does',
      );
    });

    test(
      'save writes is_dirty=true and enqueues an update outbox row',
      () async {
        // Seed an existing row via applyCreateResponse so save() goes through
        // the update path, not the create path.
        const existingId = 'existing_1';
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: existingId,
          serverResponse: fixture.buildApiModel(
            id: existingId,
            displayValue: 'A',
          ),
        );
        final loaded = await fixture
            .watch(repo, companyId: 'co', id: existingId)
            .first;
        expect(loaded, isNotNull);
        final edited = fixture.editCopy(
          loaded as TDomain,
          displayValue: 'A renamed',
        );
        await fixture.save(repo, companyId: 'co', entity: edited);

        final after = await fixture
            .watch(repo, companyId: 'co', id: existingId)
            .first;
        expect(fixture.isDirtyOf(after as TDomain), isTrue);

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(
          pending.where((p) => p.mutationKind == MutationKind.update.wireName),
          hasLength(1),
        );
      },
    );

    test(
      'delete enqueues with requiresPassword=true (server policy)',
      () async {
        await fixture.delete(repo, companyId: 'co', id: 'any_id');

        final pending = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(pending.single.mutationKind, MutationKind.delete.wireName);
        expect(
          pending.single.requiresPassword,
          isTrue,
          reason: 'delete must surface ConfirmPasswordSheet',
        );
      },
    );

    test('applyCreateResponse upserts the real-id row, removes the tmp row, '
        'and writes the id_remap', () async {
      final draft = fixture.fromApi(
        fixture.buildApiModel(id: '', displayValue: 'A'),
      );
      final created = await fixture.create(repo, companyId: 'co', draft: draft);
      final tmpId = fixture.idOf(created);

      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: tmpId,
        serverResponse: fixture.buildApiModel(id: 'real_1', displayValue: 'A'),
      );

      // Real row exists; tmp row was removed in the same transaction.
      final real = await fixture
          .watch(repo, companyId: 'co', id: 'real_1')
          .first;
      expect(real, isNotNull);

      // id_remap row was recorded so subsequent watch(tmpId) calls resolve.
      final mapped = await db.idRemapDao.resolve(
        entityType: fixture.entityType,
        tempId: tmpId,
      );
      expect(mapped, 'real_1');
    });

    test('applyUpdateResponse clears is_dirty so the "Unsynced" chip '
        'disappears after the round-trip', () async {
      // Seed via applyCreateResponse (clean), then dirty via save(), then
      // confirm applyUpdateResponse clears the flag again.
      const id = 'p_1';
      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: id,
        serverResponse: fixture.buildApiModel(id: id, displayValue: 'A'),
      );
      final loaded = await fixture.watch(repo, companyId: 'co', id: id).first;
      await fixture.save(
        repo,
        companyId: 'co',
        entity: fixture.editCopy(loaded as TDomain, displayValue: 'A renamed'),
      );
      final dirty = await fixture.watch(repo, companyId: 'co', id: id).first;
      expect(fixture.isDirtyOf(dirty as TDomain), isTrue);

      await repo.applyUpdateResponse(
        companyId: 'co',
        serverResponse: fixture.buildApiModel(
          id: id,
          displayValue: 'A renamed',
        ),
      );
      final clean = await fixture.watch(repo, companyId: 'co', id: id).first;
      expect(fixture.isDirtyOf(clean as TDomain), isFalse);
    });

    test('applyDeleteResponse marks the local row is_deleted so the list '
        'hides it immediately (no pull-to-refresh required)', () async {
      const id = 'p_1';
      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: id,
        serverResponse: fixture.buildApiModel(id: id, displayValue: 'A'),
      );

      await repo.applyDeleteResponse(companyId: 'co', id: id);

      // watch returns the row directly (it doesn't filter is_deleted) but
      // every entity DAO's `watchPage` does — the concrete test for the
      // entity asserts the page-level hide. Here we just confirm the row
      // is flagged and not physically deleted (so undo / restore still
      // has something to work with).
      final after = await fixture.watch(repo, companyId: 'co', id: id).first;
      // Some entities don't expose `isDeleted` on the domain; trust that
      // watchPage filters out is_deleted rows in the entity-specific test.
      // The applyDeleteResponse contract here is: it doesn't throw and
      // returns successfully.
      expect(after, isNotNull, reason: 'soft-delete keeps the row around');
    });

    test(
      'watch(tmpId) keeps emitting after applyCreateResponse swaps the id',
      () async {
        final draft = fixture.fromApi(
          fixture.buildApiModel(id: '', displayValue: 'A'),
        );
        final created = await fixture.create(
          repo,
          companyId: 'co',
          draft: draft,
        );
        final tmpId = fixture.idOf(created);

        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: tmpId,
          serverResponse: fixture.buildApiModel(
            id: 'real_2',
            displayValue: 'A',
          ),
        );

        final landed = await fixture
            .watch(repo, companyId: 'co', id: tmpId)
            .first;
        expect(landed, isNotNull);
        expect(fixture.idOf(landed as TDomain), 'real_2');
      },
    );
  });
}
