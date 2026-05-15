import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/design_dao.dart';
import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('DesignRepository');

class DesignRepository extends BaseEntityRepository<Design, DesignApi> {
  DesignRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(
         entityType: EntityType.design,
         requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
       );

  final DesignsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'design';

  Stream<List<Design>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = DesignFieldIds.name,
    bool sortAscending = true,
  }) {
    return db.designDao
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

  /// Watch every active design. Used by the Invoice Design pickers (which
  /// filter by entity-type client-side) and the upcoming Custom Designs list.
  Stream<List<Design>> watchAll({required String companyId}) {
    return db.designDao
        .watchAll(companyId: companyId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<Design?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.designDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Seed the local `designs` table from the `/refresh` envelope's bundled
  /// `data[N].company.designs` array. Mirrors
  /// [TaskStatusRepository.applyBundle] — upsert-only, never deletes, so
  /// rows with pending local edits (`is_dirty=true`) keep their
  /// outbox-bound payload. Sets the keyset cursor so a subsequent
  /// `ensurePageLoaded` treats the bundle as the freshest snapshot.
  Future<void> applyBundle({
    required String companyId,
    required List<DesignApi> bundle,
  }) => applyBundleUpsertOnly(
    companyId: companyId,
    bundle: bundle,
    idOf: (a) => a.id,
    updatedAtOf: (a) => a.updatedAt,
    toCompanion: (a) => _apiToCompanion(a, companyId),
    upsert: (byId) => db.designDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: byId,
    ),
  );

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
    upsert: (byId) => db.designDao.upsertAllPreservingDirty(
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
          'refreshAll hit the $maxPages page safety cap for $companyId',
        );
        break;
      }
    }
  }

  Future<Design> create({
    required String companyId,
    required Design draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    await db.transaction(() async {
      await db.designDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({required String companyId, required Design design}) async {
    final companion = _domainToCompanion(design, companyId, isDirty: true);
    await db.transaction(() async {
      await db.designDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: design.id,
        kind: MutationKind.update,
        payload: design.toApiJson(preserveTempId: true),
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
    required DesignApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.designDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.designDao.deleteById(companyId: companyId, id: tempId);
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
    required DesignApi serverResponse,
  }) async {
    await db.designDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.designDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.designDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  DesignsCompanion _apiToCompanion(DesignApi a, String companyId) {
    return DesignsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(a.name),
      isCustom: Value(a.isCustom),
      isActive: Value(a.isActive),
      isTemplate: Value(a.isTemplate),
      isFree: Value(a.isFree),
      entities: Value(a.entities),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  DesignsCompanion _domainToCompanion(
    Design d,
    String companyId, {
    required bool isDirty,
  }) {
    return DesignsCompanion.insert(
      id: d.id,
      companyId: companyId,
      name: Value(d.name),
      isCustom: Value(d.isCustom),
      isActive: Value(d.isActive),
      isTemplate: Value(d.isTemplate),
      isFree: Value(d.isFree),
      entities: Value(d.entities.join(',')),
      updatedAt: _secs(d.updatedAt),
      createdAt: Value(_secs(d.createdAt)),
      archivedAt: d.archivedAt == null
          ? const Value.absent()
          : Value(_secs(d.archivedAt!)),
      isDirty: Value(isDirty),
      isDeleted: Value(d.isDeleted),
      payload: jsonEncode(_domainToApiJson(d)),
    );
  }

  /// Build the wire-shape JSON used in the local `payload` blob. The
  /// outbox payload uses [DesignPayload.toApiJson]; here we preserve the
  /// full DesignApi shape (incl. timestamps + flags the wire holds) so
  /// `_fromRow` can round-trip without losing data.
  Map<String, dynamic> _domainToApiJson(Design d) {
    return <String, dynamic>{
      'id': d.id,
      'name': d.name,
      'is_custom': d.isCustom,
      'is_active': d.isActive,
      'is_template': d.isTemplate,
      'is_free': d.isFree,
      'entities': d.entities.join(','),
      'design': d.template.toApi().toJson(),
      'created_at': _secs(d.createdAt),
      'updated_at': _secs(d.updatedAt),
      'archived_at': d.archivedAt == null ? 0 : _secs(d.archivedAt!),
      'is_deleted': d.isDeleted,
    };
  }

  Design _fromRow(DesignRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = DesignApi.fromJson(json);
    return Design.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
