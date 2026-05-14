import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('ProductRepository');

/// Source of truth for Product data. Mirrors `ClientRepository` — the UI
/// watches Drift; the network only writes. Every mutation goes through
/// the outbox.
class ProductRepository extends BaseEntityRepository<Product, ProductApi> {
  ProductRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.product);

  final ProductsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'product';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete || kind == MutationKind.purge;

  /// Watch the first [loadedPages] pages worth of rows. Signature mirrors
  /// `ClientRepository.watchPage` so list ViewModels forward the same filter
  /// state uniformly across entities. `customFilters` / `extraFilters` are
  /// accepted but unused today — products have no custom-field columns or
  /// per-key dimensions on the server yet.
  Stream<List<Product>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = ProductFieldIds.productKey,
    bool sortAscending = true,
    Map<int, Set<String>> customFilters = const {},
    Map<String, Set<String>> extraFilters = const {},
  }) {
    assert(loadedPages >= 1, 'loadedPages is 1-based');
    return db.productDao
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
      db.productDao.watchCount(companyId: companyId);

  @override
  Stream<Product?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.productDao
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
    await db.productDao.upsertAll(companions);

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

  /// Create a new product offline. Returns the product with its tmp id.
  Future<Product> create({
    required String companyId,
    required Product draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.productDao.upsert(companion);
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
    required Product product,
  }) async {
    final companion = _domainToCompanion(product, companyId, isDirty: true);
    await db.transaction(() async {
      await db.productDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: product.id,
        kind: MutationKind.update,
        payload: product.toApiJson(preserveTempId: true),
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

  /// Permanently destroy the product. Irreversible. The outbox row carries
  /// `requiresPassword=true` so the sync engine prompts via
  /// `ConfirmPasswordSheet` before hitting `POST /products/:id/purge`.
  Future<void> purge({required String companyId, required String id}) {
    return enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.purge,
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
    required ProductApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.productDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.productDao.deleteById(companyId: companyId, id: tempId);
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
    required ProductApi serverResponse,
  }) async {
    await db.productDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.productDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.productDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  // -------------------- conversions --------------------

  ProductsCompanion _apiToCompanion(ProductApi a, String companyId) {
    return ProductsCompanion.insert(
      id: a.id,
      companyId: companyId,
      productKey: a.productKey,
      notes: a.notes,
      price: _moneyString(a.price),
      cost: _moneyString(a.cost),
      quantity: _moneyString(a.quantity),
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

  ProductsCompanion _domainToCompanion(
    Product p,
    String companyId, {
    required bool isDirty,
  }) {
    return ProductsCompanion.insert(
      id: p.id,
      companyId: companyId,
      productKey: p.productKey,
      notes: p.notes,
      price: p.price.toString(),
      cost: p.cost.toString(),
      quantity: p.quantity.toString(),
      updatedAt: _secs(p.updatedAt),
      createdAt: Value(_secs(p.createdAt)),
      archivedAt: p.archivedAt == null
          ? const Value.absent()
          : Value(_secs(p.archivedAt!)),
      customValue1: Value(p.customValue1),
      customValue2: Value(p.customValue2),
      customValue3: Value(p.customValue3),
      customValue4: Value(p.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(p.isDeleted),
      payload: jsonEncode(p.toApiJson(preserveTempId: true)),
    );
  }

  Product _fromRow(ProductRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = ProductApi.fromJson(json);
    // is_dirty is local-only; overlay from the Drift row so unsaved edits
    // don't appear clean after restart.
    return Product.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

/// The server sometimes returns money as a number, sometimes as a string;
/// normalize to a string for stable storage.
String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
