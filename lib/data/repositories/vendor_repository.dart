import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/domain/columns/vendor_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/services/vendors_api.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';

final _log = Logger('VendorRepository');

/// Source of truth for Vendor data. The UI watches Drift via [watchPage]
/// and [watch]; the network only writes. Every mutation goes through the
/// outbox.
///
/// Page size is fixed at [pageSize]. Subsequent pages are fetched only on
/// demand — list screens call [ensurePageLoaded] near the scroll edge.
class VendorRepository extends BaseEntityRepository<Vendor, VendorApi> {
  VendorRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(
         entityType: EntityType.vendor,
         requiresPasswordFor: const {
           MutationKind.delete,
           MutationKind.purge,
           MutationKind.documentDelete,
         },
       );

  final VendorsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'vendor';

  /// Watch the first [loadedPages] pages worth of rows (so an infinite-scroll
  /// list shows everything fetched so far). [loadedPages] is 1-based — 1
  /// means "show page 1," 2 means "show pages 1+2 contiguously," etc.
  Stream<List<Vendor>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = VendorFieldIds.name,
    bool sortAscending = true,
    Map<int, Set<String>> customFilters = const {},
    Map<String, Set<String>> extraFilters = const {},
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
    return db.vendorDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
          states: states,
          sortField: sortField,
          sortAscending: sortAscending,
          customValues1: customFilters[1] ?? const {},
          customValues2: customFilters[2] ?? const {},
          customValues3: customFilters[3] ?? const {},
          customValues4: customFilters[4] ?? const {},
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Distinct non-empty values populated by vendors in `companyId` for the
  /// given custom column (1..4). Drives the bottom-sheet option list for
  /// custom-field filtering.
  Stream<List<String>> watchDistinctCustomValues({
    required String companyId,
    required int columnIndex,
  }) => db.vendorDao.watchDistinctCustomValues(
    companyId: companyId,
    columnIndex: columnIndex,
  );

  /// Live non-deleted vendor count for [companyId]. Drives the sidebar
  /// badge; emits every time a vendor is added, archived, or deleted.
  Stream<int> watchCount({required String companyId}) =>
      db.vendorDao.watchCount(companyId: companyId);

  /// Stream `(id, name)` pairs for active vendors. Powers the vendor picker
  /// on the Expense edit screen.
  Stream<List<({String id, String name})>> watchActiveNames({
    required String companyId,
  }) => db.vendorDao.watchActiveNames(companyId: companyId);

  @override
  Stream<Vendor?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.vendorDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Fetch one page from the server and upsert into Drift. Idempotent: calling
  /// for the same page repeatedly is safe (Drift upserts are by id). Advances
  /// the cursor only on a successful page that returned data.
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
    // `?include=documents` makes the list response authoritative for the
    // `documents` array — see `ClientRepository.ensurePageLoaded`.
    staticFilters: const {'include': 'documents'},
    listCall: api.list,
    itemsOf: (l) => l.data,
    idOf: (a) => a.id,
    toCompanion: (a) => _apiToCompanion(a, companyId),
    upsert: (byId) => db.vendorDao.upsertAllPreservingDirty(
      companyId: companyId,
      byId: byId,
    ),
  );

  /// Pull-to-refresh / foreground-resume entry point. Mirrors
  /// `ClientRepository.refreshAll`: pull every state into the local cache
  /// so the UI's state filter can flip without re-hitting the network.
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
        _log.warning(
          'refreshAll hit the $maxPages page safety cap for company '
          '$companyId — cursor will resume on the next sync trigger.',
        );
        break;
      }
    }
  }

  /// Create a new vendor offline. Returns the vendor with its tmp id so the
  /// UI can navigate to the detail screen immediately.
  Future<Vendor> create({
    required String companyId,
    required Vendor draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.vendorDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(), // server allocates real id
      );
    });
    return stored;
  }

  /// Save an existing vendor. The local row updates instantly via the watch
  /// stream; the outbox handles the round-trip.
  Future<void> save({required String companyId, required Vendor vendor}) async {
    final companion = _domainToCompanion(vendor, companyId, isDirty: true);
    await db.transaction(() async {
      await db.vendorDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: vendor.id,
        kind: MutationKind.update,
        payload: vendor.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({required String companyId, required String id}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.delete,
      payload: {'id': id},
    );
  }

  /// Permanently destroy the vendor (irreversible). Outbox row carries
  /// `requiresPassword=true` so the sync engine prompts via
  /// `ConfirmPasswordSheet` before hitting `POST /vendors/:id/purge`.
  Future<void> purge({required String companyId, required String id}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.purge,
      payload: {'id': id},
    );
  }

  /// Queue a document upload for this vendor.
  Future<void> uploadDocument({
    required String companyId,
    required String vendorId,
    required String localPath,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: vendorId,
      kind: MutationKind.documentUpload,
      payload: {'entity_id': vendorId, 'local_path': localPath},
    );
  }

  Future<void> deleteDocument({
    required String companyId,
    required String vendorId,
    required String documentId,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: vendorId,
      kind: MutationKind.documentDelete,
      payload: {'entity_id': vendorId, 'document_id': documentId},
    );
  }

  Future<void> setDocumentVisibility({
    required String companyId,
    required String vendorId,
    required String documentId,
    required bool isPublic,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: vendorId,
      kind: MutationKind.documentVisibility,
      payload: {
        'entity_id': vendorId,
        'document_id': documentId,
        'is_public': isPublic,
      },
    );
  }

  Future<void> archive({required String companyId, required String id}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.archive,
      payload: {'id': id},
    );
  }

  Future<void> restore({required String companyId, required String id}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.restore,
      payload: {'id': id},
    );
  }

  /// Append a user comment to this vendor's activity stream. Hits
  /// `/api/v1/activities/notes` via the outbox; the dispatcher's
  /// `customActions` map calls the `ActivitiesApi`.
  Future<void> addComment({
    required String companyId,
    required String vendorId,
    required String text,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: vendorId,
      kind: MutationKind.addComment,
      payload: {'entity_id': vendorId, 'notes': text.trim()},
    );
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required VendorApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.vendorDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.vendorDao.deleteById(companyId: companyId, id: tempId);
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
    required VendorApi serverResponse,
  }) async {
    await db.vendorDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.vendorDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.vendorDao.upsert(
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
    // Purge is irreversible server-side; remove the local row entirely so
    // the detail watcher emits null. Mirrors `ClientRepository.applyPurgeResponse`.
    await db.vendorDao.deleteById(companyId: companyId, id: id);
  }

  @override
  Map<String, String> stateQueryParams(Set<EntityState> states) {
    if (states.isEmpty || states.containsAll(EntityState.values)) {
      return const {};
    }
    final names = states.map((s) => s.serverName).toList()..sort();
    return {'client_status': names.join(',')};
  }

  // -------------------- conversions --------------------

  VendorsCompanion _apiToCompanion(VendorApi a, String companyId) {
    return VendorsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: a.name,
      number: a.number,
      idNumber: a.idNumber,
      vatNumber: a.vatNumber,
      city: a.city,
      countryId: a.countryId,
      currencyId: a.currencyId,
      balance: _moneyString(a.balance),
      paidToDate: _moneyString(a.paidToDate),
      phone: a.phone,
      displayName: _displayNameFor(name: a.name, contacts: a.contacts),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      customValue1: Value(a.customValue1),
      customValue2: Value(a.customValue2),
      customValue3: Value(a.customValue3),
      customValue4: Value(a.customValue4),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      // See `ClientRepository._apiToCompanion` for the documents-nullable
      // rationale — distinguishes JSON-omitted from JSON-empty so a
      // documents-less response doesn't clobber a populated local column.
      documents: a.documents == null
          ? const Value.absent()
          : Value(jsonEncode(a.documents!.map((d) => d.toJson()).toList())),
      payload: jsonEncode(a.toJson()),
    );
  }

  VendorsCompanion _domainToCompanion(
    Vendor v,
    String companyId, {
    required bool isDirty,
  }) {
    return VendorsCompanion.insert(
      id: v.id,
      companyId: companyId,
      name: v.name,
      number: v.number,
      idNumber: v.idNumber,
      vatNumber: v.vatNumber,
      city: v.city,
      countryId: v.countryId,
      currencyId: v.currencyId,
      balance: v.balance.toString(),
      paidToDate: v.paidToDate.toString(),
      phone: v.phone,
      displayName: _displayNameForDomain(name: v.name, contacts: v.contacts),
      updatedAt: dateToEpochSeconds(v.updatedAt),
      createdAt: Value(dateToEpochSeconds(v.createdAt)),
      archivedAt: v.archivedAt == null
          ? const Value.absent()
          : Value(dateToEpochSeconds(v.archivedAt!)),
      customValue1: Value(v.customValue1),
      customValue2: Value(v.customValue2),
      customValue3: Value(v.customValue3),
      customValue4: Value(v.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(v.isDeleted),
      documents: Value(
        jsonEncode(v.documents.map((d) => d.toApi().toJson()).toList()),
      ),
      payload: jsonEncode(v.toApiJson(preserveTempId: true)),
    );
  }

  /// Drop a document from the vendor's local `documents` JSON column.
  /// Mirror of `ClientRepository.applyDocumentDeleted` — see notes there.
  Future<void> applyDocumentDeleted({
    required String companyId,
    required String vendorId,
    required String documentId,
  }) async {
    final row = await db.vendorDao
        .watchById(companyId: companyId, id: vendorId)
        .first;
    if (row == null) return;
    final current = decodeRawDocumentsColumn(row.documents);
    final next = current.where((d) => d.id != documentId).toList();
    if (next.length == current.length) return; // not found; no-op
    await (db.update(db.vendors)..where((v) => v.id.equals(vendorId))).write(
      VendorsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  /// Replace (or insert) one document in the vendor's local `documents`
  /// JSON column. Mirror of `ClientRepository.applyDocumentChanged`.
  Future<void> applyDocumentChanged({
    required String companyId,
    required String vendorId,
    required DocumentApi document,
  }) async {
    final row = await db.vendorDao
        .watchById(companyId: companyId, id: vendorId)
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
    await (db.update(db.vendors)..where((v) => v.id.equals(vendorId))).write(
      VendorsCompanion(
        documents: Value(jsonEncode(next.map((d) => d.toJson()).toList())),
      ),
    );
  }

  Vendor _fromRow(VendorRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = VendorApi.fromJson(json);
    // is_dirty is local-only (not in the API payload), so we layer it on
    // from the Drift row. Without this, an unsaved edit shows up as clean
    // after app restart. `documents` lives in its own column (the API
    // `toApiJson` deliberately omits it) — decode separately and overlay.
    return Vendor.fromApi(api).copyWith(
      isDirty: row.isDirty,
      documents: decodeDocumentsColumn(row.documents),
    );
  }
}

/// Resolve the row-level display name from the API payload. Falls back to
/// the first contact's name when the vendor's `name` is blank — matches
/// the cascade used by `Vendor` callers that want a non-empty label.
String _displayNameFor({
  required String name,
  required List<VendorContactApi> contacts,
}) {
  if (name.isNotEmpty) return name;
  if (contacts.isEmpty) return '';
  final c = contacts.first;
  final composed = ('${c.firstName} ${c.lastName}').trim();
  if (composed.isNotEmpty) return composed;
  return c.email;
}

/// Domain-side mirror of [_displayNameFor]. Kept separate because the
/// domain `VendorContact` type doesn't share a base with `VendorContactApi`.
String _displayNameForDomain({
  required String name,
  required List<dynamic> contacts,
}) {
  if (name.isNotEmpty) return name;
  if (contacts.isEmpty) return '';
  final c = contacts.first;
  final composed = ('${c.firstName} ${c.lastName}').trim();
  if (composed.isNotEmpty) return composed;
  return c.email as String;
}

/// The server sometimes returns money as a number, sometimes as a string;
/// normalize to a string for stable storage. Mirrors `_moneyString` in
/// `product_repository.dart`.
String _moneyString(Object raw) {
  if (raw is String) return raw;
  return raw.toString();
}
