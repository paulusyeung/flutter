import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/expense_category_dao.dart';
import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/expense_categories_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('ExpenseCategoryRepository');

/// Repository for ExpenseCategory rows. Mirrors [TaskStatusRepository] —
/// bundled-AND-paginated, full CRUD via the outbox, settings-only UX.
///
/// [applyBundle] is **upsert-only — it never deletes**. A category that's
/// hard-deleted server-side while the device is offline will linger in the
/// local store until the user pulls `refreshAll(full: true)` from the
/// Expense Categories list page. Acceptable for this tiny entity (typical
/// workspaces carry <50 categories); not worth the bookkeeping a
/// delete-by-omission pass would add to the bundled seed path.
class ExpenseCategoryRepository
    extends BaseEntityRepository<ExpenseCategory, ExpenseCategoryApi> {
  ExpenseCategoryRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.expenseCategory);

  final ExpenseCategoriesApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'expense_category';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  Stream<List<ExpenseCategory>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = ExpenseCategoryFieldIds.name,
    bool sortAscending = true,
  }) {
    return db.expenseCategoryDao
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

  /// Watch every active category, ordered by name. Used by the Expense edit
  /// form's category picker.
  Stream<List<ExpenseCategory>> watchActive({required String companyId}) {
    return db.expenseCategoryDao
        .watchActiveNames(companyId: companyId)
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  @override
  Stream<ExpenseCategory?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.expenseCategoryDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Seed the local `expense_categories` table from the `/refresh` envelope's
  /// bundled `data[N].company.expense_categories` array. Called from
  /// `AuthRepository._persistAndActivate` (via [WiredEntities.bundleAppliers])
  /// so the first paint of the Expense Categories screen reads from Drift
  /// instead of firing a redundant `GET /expense_categories`.
  ///
  /// Upserts only — never deletes — so rows with pending local edits
  /// (`is_dirty = true`) keep their outbox-bound payload until the next
  /// real sync. Sets the keyset cursor to the bundle's max `updated_at` so
  /// a subsequent `ensurePageLoaded` treats the bundle as the freshest
  /// snapshot we've seen.
  Future<void> applyBundle({
    required String companyId,
    required List<ExpenseCategoryApi> bundle,
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
      await db.expenseCategoryDao.upsertAll(companions);
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
    await db.expenseCategoryDao.upsertAll(companions);

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
    const maxPages = 100; // ~5k categories is more than anyone needs
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

  Future<ExpenseCategory> create({
    required String companyId,
    required ExpenseCategory draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);
    await db.transaction(() async {
      await db.expenseCategoryDao.upsert(companion);
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
    required ExpenseCategory category,
  }) async {
    final companion = _domainToCompanion(category, companyId, isDirty: true);
    await db.transaction(() async {
      await db.expenseCategoryDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: category.id,
        kind: MutationKind.update,
        payload: category.toApiJson(preserveTempId: true),
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

  /// Hard-delete on the server. Password-gated per [requiresPasswordFor]; the
  /// outbox handler attaches the cached password header before POST.
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
    required ExpenseCategoryApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.expenseCategoryDao.upsert(
        _apiToCompanion(serverResponse, companyId),
      );
      if (realId != tempId) {
        await db.expenseCategoryDao.deleteById(
          companyId: companyId,
          id: tempId,
        );
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
    required ExpenseCategoryApi serverResponse,
  }) async {
    await db.expenseCategoryDao.upsert(
      _apiToCompanion(serverResponse, companyId),
    );
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.expenseCategoryDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.expenseCategoryDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  @override
  Future<void> applyPurgeResponse({
    required String companyId,
    required String id,
  }) async {
    await db.expenseCategoryDao.deleteById(companyId: companyId, id: id);
  }

  // -------------------- conversions --------------------

  ExpenseCategoriesCompanion _apiToCompanion(
    ExpenseCategoryApi a,
    String companyId,
  ) {
    return ExpenseCategoriesCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(a.name),
      color: Value(a.color),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  ExpenseCategoriesCompanion _domainToCompanion(
    ExpenseCategory c,
    String companyId, {
    required bool isDirty,
  }) {
    return ExpenseCategoriesCompanion.insert(
      id: c.id,
      companyId: companyId,
      name: Value(c.name),
      color: Value(c.color),
      updatedAt: _secs(c.updatedAt),
      createdAt: Value(_secs(c.createdAt)),
      archivedAt: c.archivedAt == null
          ? const Value.absent()
          : Value(_secs(c.archivedAt!)),
      isDirty: Value(isDirty),
      isDeleted: Value(c.isDeleted),
      payload: jsonEncode(c.toApiJson(preserveTempId: true)),
    );
  }

  /// Lift a Drift row back into the domain model. Re-applies the local-only
  /// `is_dirty` flag so the UI's "Unsynced" pill survives an app restart.
  /// Mirrors `TaskStatusRepository._fromRow`.
  ExpenseCategory _fromRow(ExpenseCategoryRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = ExpenseCategoryApi.fromJson(json);
    return ExpenseCategory.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
