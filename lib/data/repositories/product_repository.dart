import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/product_dao.dart';
import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/models/domain/product.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/products_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('ProductRepository');

/// Source of truth for Product data. The UI watches Drift via [watchPage]
/// and [watch]; the network only writes. Every mutation goes through the
/// outbox.
///
/// Page size is fixed at [pageSize]. Subsequent pages are fetched only on
/// demand — list screens call [ensurePageLoaded] near the scroll edge.
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
      kind == MutationKind.delete ||
      kind == MutationKind.purge ||
      kind == MutationKind.documentDelete;

  /// Watch the first [loadedPages] pages worth of rows (so an infinite-scroll
  /// list shows everything fetched so far). [loadedPages] is 1-based — 1
  /// means "show page 1," 2 means "show pages 1+2 contiguously," etc.
  ///
  /// Unlike `ClientRepository.watchPage`, this method takes no `customFilters`
  /// or `extraFilters` — products have no custom-field columns or token-search
  /// filter dimensions on the server yet. When they're added, restore the
  /// parameters here, plumb them into `productDao.watchPage`, and update
  /// `ProductListViewModel.watchPage()`'s call site to forward them.
  Stream<List<Product>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = ProductFieldIds.productKey,
    bool sortAscending = true,
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
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

  /// Fetch one page from the server and upsert into Drift.
  ///
  /// Idempotent: calling for the same page repeatedly is safe (Drift upserts
  /// are by id). Advances the cursor only on a successful page that returned
  /// data.
  ///
  /// [states] drives the server-side filter. Without it, the cursor only
  /// pulls `(updated_at, id)` slices and the local cache would be missing
  /// archived/deleted rows even when the user has toggled them on.
  ///
  /// [extraFilters] is an open-ended map of flat server query params populated
  /// from the token search field. Each value set is comma-joined. Products
  /// don't expose any token-search filter dimensions today, but the parameter
  /// mirrors `ClientRepository.ensurePageLoaded` so `GenericListViewModel.fetchPage`
  /// (which mandates `extraFilters`) flows uniformly across all entities — the
  /// implementation is a no-op for empty maps.
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
      // `?include=documents` — see `ClientRepository.ensurePageLoaded` for
      // the rationale. Without it the list response omits documents and
      // remote uploads never propagate to the local cache.
      'include': 'documents',
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
      return false; // no more pages
    }

    // Server-refresh: skip ids whose existing local row has is_dirty=true,
    // so a paged refresh doesn't clobber the user's pending offline edit.
    await db.productDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: {for (final a in apiRows) a.id: _apiToCompanion(a, companyId)},
    );

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

  /// Pull-to-refresh / foreground-resume entry point. With [full] true, we
  /// ignore the cursor and re-pull page 1 from scratch; otherwise we send
  /// `since=<cursor>` for a delta.
  ///
  /// Filter-agnostic by design: we pull every state into the local cache so
  /// the UI's state filter can flip between active/archived/deleted without
  /// re-hitting the network. The local watch stream applies the user's
  /// current selection on top.
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
    const maxPages = 1000; // 50 rows × 1000 = 50 000 products
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

  /// Create a new product offline. Returns the product with its tmp id so the
  /// UI can navigate to the detail screen immediately.
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

  /// Save an existing product. The local row updates instantly via the watch
  /// stream; the outbox handles the round-trip.
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

  /// Queue a document upload for this product. See
  /// `ClientRepository.uploadDocument` for the lifecycle notes — same
  /// payload shape, same outbox kind.
  Future<void> uploadDocument({
    required String companyId,
    required String productId,
    required String localPath,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: productId,
      kind: MutationKind.documentUpload,
      payload: {'entity_id': productId, 'local_path': localPath},
    );
  }

  /// Delete one document attached to a product. Password-gated — see
  /// `requiresPasswordFor` above.
  Future<void> deleteDocument({
    required String companyId,
    required String productId,
    required String documentId,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: productId,
      kind: MutationKind.documentDelete,
      payload: {'entity_id': productId, 'document_id': documentId},
    );
  }

  /// Flip a document's public/private flag.
  Future<void> setDocumentVisibility({
    required String companyId,
    required String productId,
    required String documentId,
    required bool isPublic,
  }) {
    return enqueueMutation(
      companyId: companyId,
      entityId: productId,
      kind: MutationKind.documentVisibility,
      payload: {
        'entity_id': productId,
        'document_id': documentId,
        'is_public': isPublic,
      },
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

  /// Concrete handler for the `create` round-trip. See base class for
  /// the steps that run inside the transaction.
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
      // See `ClientRepository._apiToCompanion` for the rationale — nullable
      // DTO distinguishes JSON-omitted from JSON-empty; `Value.absent()`
      // preserves prior column value on `insertOnConflictUpdate`'s UPDATE
      // branch.
      documents: a.documents == null
          ? const Value.absent()
          : Value(jsonEncode(a.documents!.map((d) => d.toJson()).toList())),
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
      updatedAt: dateToEpochSeconds(p.updatedAt),
      createdAt: Value(dateToEpochSeconds(p.createdAt)),
      archivedAt: p.archivedAt == null
          ? const Value.absent()
          : Value(dateToEpochSeconds(p.archivedAt!)),
      customValue1: Value(p.customValue1),
      customValue2: Value(p.customValue2),
      customValue3: Value(p.customValue3),
      customValue4: Value(p.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(p.isDeleted),
      documents: Value(
        jsonEncode(p.documents.map((d) => d.toApi().toJson()).toList()),
      ),
      payload: jsonEncode(p.toApiJson(preserveTempId: true)),
    );
  }

  /// Drop a document from the product's local `documents` JSON column.
  /// Mirror of `ClientRepository.applyDocumentDeleted` — see notes there.
  Future<void> applyDocumentDeleted({
    required String companyId,
    required String productId,
    required String documentId,
  }) async {
    final row = await db.productDao
        .watchById(companyId: companyId, id: productId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = current.where((d) => d.id != documentId).toList();
    if (next.length == current.length) return;
    await (db.update(db.products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  /// Replace (or insert) one document in the product's local `documents`
  /// JSON column. Mirror of `ClientRepository.applyDocumentChanged`.
  Future<void> applyDocumentChanged({
    required String companyId,
    required String productId,
    required DocumentApi document,
  }) async {
    final row = await db.productDao
        .watchById(companyId: companyId, id: productId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = [
      for (final d in current)
        if (d.id == document.id) document else d,
    ];
    if (!current.any((d) => d.id == document.id)) {
      next.add(document);
    }
    await (db.update(db.products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  Product _fromRow(ProductRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = ProductApi.fromJson(json);
    // is_dirty is local-only (not in the API payload), so we layer it on
    // from the Drift row. `documents` lives in its own column (the API
    // `toApiJson` deliberately omits it) — decode separately and overlay.
    return Product.fromApi(api).copyWith(
      isDirty: row.isDirty,
      documents: decodeDocumentsColumn(row.documents),
    );
  }
}

/// The server sometimes returns money as a number, sometimes as a string;
/// normalize to a string for stable storage.
String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}
