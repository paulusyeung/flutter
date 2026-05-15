import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/bank_account_dao.dart';
import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/models/domain/bank_account.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/bank_accounts_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('BankAccountRepository');

/// Source of truth for BankAccount (`bank_integration`) data. UI watches
/// Drift via [watchPage] / [watch]; the network only writes. Every
/// mutation goes through the outbox.
class BankAccountRepository
    extends BaseEntityRepository<BankAccount, BankAccountApi> {
  BankAccountRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(
         entityType: EntityType.bankAccount,
         requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
       );

  final BankAccountsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'bank_account';

  Stream<List<BankAccount>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = BankAccountFieldIds.updatedAt,
    bool sortAscending = false,
  }) {
    assert(loadedPages >= 1);
    return db.bankAccountDao
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

  Stream<int> watchCount({required String companyId}) =>
      db.bankAccountDao.watchActiveCount(companyId: companyId);

  /// Active rows only (no archived / deleted). For the settings list.
  Stream<List<BankAccount>> watchAll({required String companyId}) {
    return db.bankAccountDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * 4,
          sortField: BankAccountFieldIds.name,
          sortAscending: true,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Active + archived rows (deleted still excluded). For the settings
  /// list when "Show archived" is on.
  Stream<List<BankAccount>> watchAllIncludingArchived({
    required String companyId,
  }) {
    return db.bankAccountDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * 4,
          states: const {EntityState.active, EntityState.archived},
          sortField: BankAccountFieldIds.name,
          sortAscending: true,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<BankAccount?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.bankAccountDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    Map<String, Set<String>> extraFilters = const {},
    bool ignoreCursor = false,
  }) => ensurePageLoadedTemplate(
    companyId: companyId,
    page: page,
    pageSize: pageSize,
    search: search,
    states: states,
    extraFilters: extraFilters,
    ignoreCursor: ignoreCursor,
    listCall: api.list,
    itemsOf: (l) => l.data,
    idOf: (a) => a.id,
    toCompanion: (a) => _apiToCompanion(a, companyId),
    upsert: (byId) => db.bankAccountDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: byId,
    ),
  );

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
          'refreshAll hit the $maxPages page safety cap for company '
          '$companyId — cursor will resume on the next sync trigger.',
        );
        break;
      }
    }
  }

  Future<BankAccount> create({
    required String companyId,
    required BankAccount draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.bankAccountDao.upsert(companion);
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
    required BankAccount account,
  }) async {
    final companion = _domainToCompanion(account, companyId, isDirty: true);
    await db.transaction(() async {
      await db.bankAccountDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: account.id,
        kind: MutationKind.update,
        payload: account.toApiJson(preserveTempId: true),
      );
    });
  }

  /// Custom non-standard action: ask upstream providers (Yodlee/Nordigen)
  /// to refresh the connected account list + balances. Goes through the
  /// outbox as a `MutationKind.refreshAccounts` row keyed under the
  /// synthetic [kRefreshAccountsEntityId] so it retries on connectivity
  /// loss but doesn't pretend to point at a specific bank integration.
  Future<void> refreshAccounts({required String companyId}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: kRefreshAccountsEntityId,
      kind: MutationKind.refreshAccounts,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required BankAccountApi serverResponse,
  }) => applyCreateResponseTemplate(
    companyId: companyId,
    tempId: tempId,
    realId: serverResponse.id,
    companion: _apiToCompanion(serverResponse, companyId),
    upsert: db.bankAccountDao.upsert,
    deleteById: (id) =>
        db.bankAccountDao.deleteById(companyId: companyId, id: id),
  );

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required BankAccountApi serverResponse,
  }) async {
    await db.bankAccountDao.upsert(
      _apiToCompanion(serverResponse, companyId),
    );
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.bankAccountDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.bankAccountDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  BankAccountsCompanion _apiToCompanion(
    BankAccountApi a,
    String companyId,
  ) {
    final domain = BankAccount.fromApi(a);
    return BankAccountsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(domain.name),
      status: Value(domain.status),
      type: Value(domain.type),
      provider: Value(domain.provider),
      balance: Value(domain.balance.toString()),
      currencyCode: Value(domain.currency),
      fromDate: Value(domain.fromDate?.toIso() ?? ''),
      autoSync: Value(domain.autoSync),
      disabledUpstream: Value(domain.disabledUpstream),
      integrationType: Value(domain.integrationType),
      nordigenInstitutionId: Value(domain.nordigenInstitutionId),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt:
          a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  BankAccountsCompanion _domainToCompanion(
    BankAccount b,
    String companyId, {
    required bool isDirty,
  }) {
    return BankAccountsCompanion.insert(
      id: b.id,
      companyId: companyId,
      name: Value(b.name),
      status: Value(b.status),
      type: Value(b.type),
      provider: Value(b.provider),
      balance: Value(b.balance.toString()),
      currencyCode: Value(b.currency),
      fromDate: Value(b.fromDate?.toIso() ?? ''),
      autoSync: Value(b.autoSync),
      disabledUpstream: Value(b.disabledUpstream),
      integrationType: Value(b.integrationType),
      nordigenInstitutionId: Value(b.nordigenInstitutionId),
      updatedAt: b.updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: Value(b.createdAt.millisecondsSinceEpoch ~/ 1000),
      archivedAt: b.archivedAt == null
          ? const Value.absent()
          : Value(b.archivedAt!.millisecondsSinceEpoch ~/ 1000),
      isDirty: Value(isDirty),
      isDeleted: Value(b.isDeleted),
      payload: jsonEncode(b.toApiJson(preserveTempId: true)),
    );
  }

  BankAccount _fromRow(BankAccountRow row) {
    final apiJson = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = BankAccountApi.fromJson(apiJson);
    return BankAccount.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}
