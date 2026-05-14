import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/company_gateway_dao.dart';
import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/company_gateways_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('CompanyGatewayRepository');

/// Source of truth for CompanyGateway data. UI watches Drift via [watchPage]
/// and [watch]; the network only writes. Every mutation goes through the
/// outbox.
///
/// Gateways are a small entity — typical accounts have < 10 rows total — so
/// [pageSize] is set to a high cap and the list is loaded in a single page.
/// This still flows through the standard `ensurePageLoaded` cursor so future
/// edits or server-side additions surface naturally.
class CompanyGatewayRepository
    extends BaseEntityRepository<CompanyGateway, CompanyGatewayApi> {
  CompanyGatewayRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.companyGateway);

  final CompanyGatewaysApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'company_gateway';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  /// Watch the first [loadedPages] pages worth of rows. [loadedPages] is
  /// 1-based — 1 means "show page 1," 2 means "show pages 1+2," etc.
  Stream<List<CompanyGateway>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = CompanyGatewayFieldIds.updatedAt,
    bool sortAscending = false,
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
    return db.companyGatewayDao
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
      db.companyGatewayDao.watchActiveCount(companyId: companyId);

  @override
  Stream<CompanyGateway?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.companyGatewayDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Fetch one page from the server and upsert into Drift.
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
    if (apiRows.isEmpty) {
      return false;
    }

    final companions = apiRows
        .map((a) => _apiToCompanion(a, companyId))
        .toList(growable: false);
    await db.companyGatewayDao.upsertAll(companions);

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
    const maxPages = 100; // gateways are bounded; cap defensively.
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

  Future<CompanyGateway> create({
    required String companyId,
    required CompanyGateway draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.companyGatewayDao.upsert(companion);
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
    required CompanyGateway gateway,
  }) async {
    final companion = _domainToCompanion(gateway, companyId, isDirty: true);
    await db.transaction(() async {
      await db.companyGatewayDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: gateway.id,
        kind: MutationKind.update,
        payload: gateway.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.delete,
      payload: {'id': id},
    );
  }

  Future<void> archive({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.archive,
      payload: {'id': id},
    );
  }

  Future<void> restore({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.restore,
      payload: {'id': id},
    );
  }

  Future<void> purge({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.purge,
      payload: {'id': id},
    );
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required CompanyGatewayApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.companyGatewayDao.upsert(
        _apiToCompanion(serverResponse, companyId),
      );
      if (realId != tempId) {
        await db.companyGatewayDao.deleteById(companyId: companyId, id: tempId);
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
    required CompanyGatewayApi serverResponse,
  }) async {
    await db.companyGatewayDao.upsert(
      _apiToCompanion(serverResponse, companyId),
    );
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.companyGatewayDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.companyGatewayDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  CompanyGatewaysCompanion _apiToCompanion(
    CompanyGatewayApi a,
    String companyId,
  ) {
    return CompanyGatewaysCompanion.insert(
      id: a.id,
      companyId: companyId,
      gatewayKey: Value(a.gatewayKey),
      label: Value(a.label),
      testMode: Value(a.testMode),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  CompanyGatewaysCompanion _domainToCompanion(
    CompanyGateway g,
    String companyId, {
    required bool isDirty,
  }) {
    return CompanyGatewaysCompanion.insert(
      id: g.id,
      companyId: companyId,
      gatewayKey: Value(g.gatewayKey),
      label: Value(g.label),
      testMode: Value(g.testMode),
      updatedAt: g.updatedAt == 0
          ? DateTime.now().millisecondsSinceEpoch ~/ 1000
          : g.updatedAt,
      createdAt: Value(g.createdAt),
      archivedAt: g.archivedAt > 0 ? Value(g.archivedAt) : const Value.absent(),
      isDirty: Value(isDirty),
      isDeleted: Value(g.isDeleted),
      payload: jsonEncode(g.toApiJson(preserveTempId: true)),
    );
  }

  CompanyGateway _fromRow(CompanyGatewayRow row) {
    final apiJson = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = CompanyGatewayApi.fromJson(apiJson);
    return CompanyGateway.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}
