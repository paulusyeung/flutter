import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/payment_term_dao.dart';
import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/domain/payment_term.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/payment_terms_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('PaymentTermRepository');

class PaymentTermRepository
    extends BaseEntityRepository<PaymentTerm, PaymentTermApi> {
  PaymentTermRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.paymentTerm);

  final PaymentTermsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'payment_term';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  Stream<List<PaymentTerm>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = PaymentTermFieldIds.numDays,
    bool sortAscending = true,
  }) {
    return db.paymentTermDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
          states: states,
          sortField: sortField,
          sortAscending: sortAscending,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Watch every active payment term for a company. Used by the dropdown
  /// on Online Payments → Defaults and the settings list screen.
  Stream<List<PaymentTerm>> watchAll({required String companyId}) {
    return db.paymentTermDao
        .watchAll(companyId: companyId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Watch active **and** archived terms, in canonical order. Used by the
  /// Settings → Payment Terms list when the user toggles "Show archived".
  Stream<List<PaymentTerm>> watchAllIncludingArchived({
    required String companyId,
  }) {
    return db.paymentTermDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: 200,
          states: const {EntityState.active, EntityState.archived},
          sortField: PaymentTermFieldIds.numDays,
          sortAscending: true,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<PaymentTerm?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.paymentTermDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Seed the local payment_terms table from the `/refresh` envelope's
  /// bundled `data[N].company.payment_terms` array. Called from
  /// `Services.build`'s `auth.onPersistBundles` so the first paint of the
  /// Payment Terms screen and the Online Payments → Defaults dropdown read
  /// from Drift instead of firing a redundant `GET /payment_terms`.
  ///
  /// Upserts only — never deletes — so rows with pending local edits
  /// (`is_dirty = true`) keep their outbox-bound payload until the next
  /// real sync. Sets the keyset cursor to the bundle's max `updated_at`
  /// so a subsequent `ensurePageLoaded` treats the bundle as the freshest
  /// snapshot we've seen.
  Future<void> applyBundle({
    required String companyId,
    required List<PaymentTermApi> bundle,
  }) async {
    if (bundle.isEmpty) return;
    final companions = bundle
        .map((a) => _apiToCompanion(a, companyId))
        .toList(growable: false);
    var maxUpdatedAt = 0;
    String? lastId;
    for (final a in bundle) {
      if (a.updatedAt > maxUpdatedAt) {
        maxUpdatedAt = a.updatedAt;
        lastId = a.id;
      }
    }
    await db.transaction(() async {
      await db.paymentTermDao.upsertAll(companions);
      if (lastId != null) {
        await advanceCursor(
          companyId: companyId,
          updatedAt: maxUpdatedAt,
          id: lastId,
          wasFullSync: true,
        );
      }
    });
  }

  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    bool ignoreCursor = false,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await db.syncStateDao.read(
            companyId: companyId,
            entityType: entityTypeName,
          );

    final filters = <String, String>{
      ...stateQueryParams(states),
      for (final entry in extraFilters.entries)
        if (entry.value.isNotEmpty)
          entry.key: (entry.value.toList()..sort()).join(','),
    };

    final result = await api.list(
      page: page,
      perPage: pageSize,
      search: search,
      sinceUpdatedAt: cursor?.updatedAt,
      sinceId: cursor?.id,
      filters: filters,
    );

    final apiRows = result.data.data;
    if (apiRows.isEmpty) return false;

    final companions = apiRows
        .map((a) => _apiToCompanion(a, companyId))
        .toList(growable: false);
    await db.paymentTermDao.upsertAll(companions);

    if (result.cursorUpdatedAt != null && result.cursorId != null) {
      await advanceCursor(
        companyId: companyId,
        updatedAt: result.cursorUpdatedAt!,
        id: result.cursorId!,
        wasFullSync: ignoreCursor && page == 1,
      );
    }
    return apiRows.length >= pageSize;
  }

  Future<void> refreshAll({
    required String companyId,
    bool full = false,
  }) async {
    if (full) {
      await db.syncStateDao.reset(
        companyId: companyId,
        entityType: entityTypeName,
      );
    }
    var page = 1;
    var hasMore = true;
    const maxPages = 100;
    final allStates = EntityState.values.toSet();
    while (hasMore) {
      hasMore = await ensurePageLoaded(
        companyId: companyId,
        page: page,
        states: allStates,
        ignoreCursor: full && page == 1,
      );
      page++;
      if (page > maxPages) {
        _log.warning(
          'refreshAll hit the $maxPages page safety cap for $companyId',
        );
        break;
      }
    }
  }

  Future<PaymentTerm> create({
    required String companyId,
    required PaymentTerm draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    await db.transaction(() async {
      await db.paymentTermDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({
    required String companyId,
    required PaymentTerm term,
  }) async {
    final companion = _domainToCompanion(term, companyId, isDirty: true);
    await db.transaction(() async {
      await db.paymentTermDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: term.id,
        kind: MutationKind.update,
        payload: term.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.delete,
        payload: {'id': id},
      );

  Future<void> archive({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.archive,
        payload: {'id': id},
      );

  Future<void> restore({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.restore,
        payload: {'id': id},
      );

  Future<void> purge({required String companyId, required String id}) =>
      enqueueMutation(
        companyId: companyId,
        entityId: id,
        kind: MutationKind.purge,
        payload: {'id': id},
      );

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required PaymentTermApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.paymentTermDao.upsert(
        _apiToCompanion(serverResponse, companyId),
      );
      if (realId != tempId) {
        await db.paymentTermDao.deleteById(companyId: companyId, id: tempId);
      }
      await recordCreateSuccess(
        companyId: companyId,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required PaymentTermApi serverResponse,
  }) async {
    await db.paymentTermDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.paymentTermDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.paymentTermDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  PaymentTermsCompanion _apiToCompanion(PaymentTermApi a, String companyId) {
    return PaymentTermsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(a.name),
      numDays: Value(a.numDays),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  PaymentTermsCompanion _domainToCompanion(
    PaymentTerm t,
    String companyId, {
    required bool isDirty,
  }) {
    return PaymentTermsCompanion.insert(
      id: t.id,
      companyId: companyId,
      name: Value(t.name),
      numDays: Value(t.numDays),
      updatedAt: _secs(t.updatedAt),
      createdAt: Value(_secs(t.createdAt)),
      archivedAt: t.archivedAt == null
          ? const Value.absent()
          : Value(_secs(t.archivedAt!)),
      isDirty: Value(isDirty),
      isDeleted: Value(t.isDeleted),
      payload: jsonEncode(t.toApiJson(preserveTempId: true)),
    );
  }

  PaymentTerm _fromRow(PaymentTermRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = PaymentTermApi.fromJson(json);
    return PaymentTerm.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
