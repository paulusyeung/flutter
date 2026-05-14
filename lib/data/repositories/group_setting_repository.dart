import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/group_setting_dao.dart';
import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/group_settings_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('GroupSettingRepository');

/// Source of truth for group_settings. Mirrors `ProductRepository` — the
/// UI watches Drift; the network only writes. Every mutation goes through
/// the outbox.
class GroupSettingRepository
    extends BaseEntityRepository<GroupSetting, GroupSettingApi> {
  GroupSettingRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.group);

  final GroupSettingsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'group';

  @override
  bool requiresPasswordFor(MutationKind kind) => kind == MutationKind.delete;

  /// Watch the first [loadedPages] pages worth of rows. Matches
  /// `ProductRepository.watchPage` for forward-compat with the generic
  /// list ViewModel, though the settings UI uses [watchAll] instead.
  Stream<List<GroupSetting>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = GroupSettingFieldIds.name,
    bool sortAscending = true,
  }) {
    assert(loadedPages >= 1, 'loadedPages is 1-based');
    return db.groupSettingDao
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

  /// Watch every active group for [companyId], sorted by name ascending.
  /// Drives the settings list screen and the Assign Group dialog dropdown.
  Stream<List<GroupSetting>> watchAll({required String companyId}) => db
      .groupSettingDao
      .watchAll(companyId: companyId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  Stream<int> watchCount({required String companyId}) =>
      db.groupSettingDao.watchCount(companyId: companyId);

  @override
  Stream<GroupSetting?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.groupSettingDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Fetch one page from the server and upsert into Drift. Returns true
  /// if there may be more pages (we got a full page).
  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    bool ignoreCursor = false,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await db.syncStateDao.read(
            companyId: companyId,
            entityType: entityTypeName,
          );

    final filters = <String, String>{...stateQueryParams(states)};

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
    await db.groupSettingDao.upsertAll(companions);

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

  /// Pull-to-refresh / foreground-resume.
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
    const maxPages = 1000;
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
        _log.warning('refreshAll hit safety cap for company $companyId');
        break;
      }
    }
  }

  /// Create a new group offline. Returns the group with its tmp id.
  Future<GroupSetting> create({
    required String companyId,
    required GroupSetting draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.groupSettingDao.upsert(companion);
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
    required GroupSetting group,
  }) async {
    final companion = _domainToCompanion(group, companyId, isDirty: true);
    await db.transaction(() async {
      await db.groupSettingDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: group.id,
        kind: MutationKind.update,
        payload: group.toApiJson(preserveTempId: true),
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

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required GroupSettingApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.groupSettingDao.upsert(
        _apiToCompanion(serverResponse, companyId),
      );
      if (realId != tempId) {
        await db.groupSettingDao.deleteById(companyId: companyId, id: tempId);
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
    required GroupSettingApi serverResponse,
  }) async {
    await db.groupSettingDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.groupSettingDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.groupSettingDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  GroupSettingsCompanion _apiToCompanion(GroupSettingApi a, String companyId) {
    return GroupSettingsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: a.name,
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      customValue1: Value(a.customValue1),
      customValue2: Value(a.customValue2),
      customValue3: Value(a.customValue3),
      customValue4: Value(a.customValue4),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  GroupSettingsCompanion _domainToCompanion(
    GroupSetting g,
    String companyId, {
    required bool isDirty,
  }) {
    return GroupSettingsCompanion.insert(
      id: g.id,
      companyId: companyId,
      name: g.name,
      updatedAt: dateToEpochSeconds(g.updatedAt),
      createdAt: Value(dateToEpochSeconds(g.createdAt)),
      archivedAt: g.archivedAt == null
          ? const Value.absent()
          : Value(dateToEpochSeconds(g.archivedAt!)),
      customValue1: Value(g.customValue1),
      customValue2: Value(g.customValue2),
      customValue3: Value(g.customValue3),
      customValue4: Value(g.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(g.isDeleted),
      payload: jsonEncode(g.toApiJson(preserveTempId: true)),
    );
  }

  GroupSetting _fromRow(GroupSettingRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = GroupSettingApi.fromJson(json);
    return GroupSetting.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}
