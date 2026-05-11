import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import '../../domain/entity_type.dart';
import '../../domain/sync/mutation.dart';
import '../db/app_database.dart';
import '../models/api/client_api_model.dart';
import '../models/domain/client.dart';
import '../models/domain/contact.dart';
import '../services/clients_api.dart';
import 'base_entity_repository.dart';

final _log = Logger('ClientRepository');

/// Source of truth for Client data. The UI watches Drift via [watchPage]
/// and [watch]; the network only writes. Every mutation goes through the
/// outbox.
///
/// Page size is fixed at [pageSize]. Subsequent pages are fetched only on
/// demand — list screens call [ensurePageLoaded] near the scroll edge.
class ClientRepository extends BaseEntityRepository {
  ClientRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    this.pageSize = 50,
  }) : super(entityType: EntityType.client);

  final ClientsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'client';

  @override
  bool requiresPasswordFor(MutationKind kind) =>
      kind == MutationKind.delete;

  /// Watch the first [loadedPages] pages worth of rows (so an infinite-scroll
  /// list shows everything fetched so far). [loadedPages] is 1-based — 1
  /// means "show page 1," 2 means "show pages 1+2 contiguously," etc.
  Stream<List<Client>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
  }) {
    assert(loadedPages >= 1, 'loadedPages is 1-based; pass 1 for the first page');
    return db.clientDao
        .watchPage(
          companyId: companyId,
          offset: 0,
          limit: pageSize * loadedPages,
          search: search,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Watch a single client by id. The id may be a tmp id; we transparently
  /// resolve through `id_remap` so an open detail screen survives the swap
  /// the sync engine makes after a successful create.
  Stream<Client?> watch({
    required String companyId,
    required String id,
  }) async* {
    final resolved = await resolveId(id);
    yield* db.clientDao
        .watchById(companyId: companyId, id: resolved)
        .map((row) => row == null ? null : _fromRow(row));
  }

  /// Fetch one page from the server and upsert into Drift.
  ///
  /// Idempotent: calling for the same page repeatedly is safe (Drift upserts
  /// are by id). Advances the cursor only on a successful page that returned
  /// data.
  Future<bool> ensurePageLoaded({
    required String companyId,
    required int page,
    String? search,
    bool ignoreCursor = false,
  }) async {
    final cursor = ignoreCursor
        ? null
        : await db.syncStateDao
            .read(companyId: companyId, entityType: entityTypeName);

    final result = await api.list(
      page: page,
      perPage: pageSize,
      search: search,
      sinceUpdatedAt: cursor?.updatedAt,
      sinceId: cursor?.id,
    );

    final apiRows = result.data.data;
    if (apiRows.isEmpty) {
      return false; // no more pages
    }

    final companions = apiRows
        .map((a) => _apiToCompanion(a, companyId))
        .toList(growable: false);
    await db.clientDao.upsertAll(companions);

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
  Future<void> refreshAll({
    required String companyId,
    bool full = false,
  }) async {
    if (full) {
      await db.syncStateDao
          .reset(companyId: companyId, entityType: entityTypeName);
    }
    var page = 1;
    var hasMore = true;
    const maxPages = 1000; // 50 rows × 1000 = 50 000 clients
    while (hasMore) {
      hasMore = await ensurePageLoaded(
        companyId: companyId,
        page: page,
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

  /// Create a new client offline. Returns the client with its tmp id so the
  /// UI can navigate to the detail screen immediately.
  Future<Client> create({
    required String companyId,
    required Client draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.clientDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(), // server allocates real id
      );
    });
    return stored;
  }

  /// Save an existing client. The local row updates instantly via the watch
  /// stream; the outbox handles the round-trip.
  Future<void> save({
    required String companyId,
    required Client client,
  }) async {
    final companion = _domainToCompanion(client, companyId, isDirty: true);
    await db.transaction(() async {
      await db.clientDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: client.id,
        kind: MutationKind.update,
        payload: client.toApiJson(preserveTempId: true),
      );
    });
  }

  Future<void> delete({
    required String companyId,
    required String id,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.delete,
      payload: {'id': id},
    );
  }

  Future<void> archive({
    required String companyId,
    required String id,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.archive,
      payload: {'id': id},
    );
  }

  Future<void> restore({
    required String companyId,
    required String id,
  }) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.restore,
      payload: {'id': id},
    );
  }

  /// Sync engine entry point for "the server accepted our `create` and
  /// returned the real entity." All cleanup happens in one transaction:
  ///   1. The new row is upserted under the real id (with the real payload).
  ///   2. The tmp row is deleted.
  ///   3. The `id_remap` row is recorded so open `watch(tmpId)` streams
  ///      resolve to the real entity transparently.
  ///   4. Pending outbox payloads referencing the tmp id are rewritten.
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required ClientApi serverResponse,
  }) async {
    final realId = serverResponse.id;
    await db.transaction(() async {
      await db.clientDao.upsert(_apiToCompanion(serverResponse, companyId));
      if (realId != tempId) {
        await db.clientDao.deleteById(companyId: companyId, id: tempId);
      }
      await recordCreateSuccess(
        companyId: companyId,
        tempId: tempId,
        realId: realId,
      );
    });
  }

  /// Sync engine entry point for "the server accepted our `update` and
  /// returned the canonical entity." Clears `is_dirty` and refreshes the
  /// payload.
  Future<void> applyUpdateResponse({
    required String companyId,
    required ClientApi serverResponse,
  }) async {
    await db.clientDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  /// Sync engine entry point for "the server accepted our `delete`."
  /// Marks the local row as `is_deleted=true` so the list hides it
  /// immediately, without waiting for a server-side refresh.
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing =
        await db.clientDao.watchById(companyId: companyId, id: id).first;
    if (existing == null) return;
    await db.clientDao.upsert(
      existing.toCompanion(true).copyWith(
            isDeleted: const Value(true),
            isDirty: const Value(false),
          ),
    );
  }

  // -------------------- conversions --------------------

  ClientsCompanion _apiToCompanion(ClientApi a, String companyId) {
    return ClientsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: a.name,
      number: a.number,
      email: _primaryEmail(a),
      displayName: a.displayName.isNotEmpty ? a.displayName : a.name,
      balance: a.balance.toString(),
      updatedAt: a.updatedAt,
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  ClientsCompanion _domainToCompanion(
    Client c,
    String companyId, {
    required bool isDirty,
  }) {
    return ClientsCompanion.insert(
      id: c.id,
      companyId: companyId,
      name: c.name,
      number: c.number,
      email: _domainPrimaryEmail(c.contacts),
      displayName: c.displayName,
      balance: c.balance.toString(),
      updatedAt: c.updatedAt.millisecondsSinceEpoch ~/ 1000,
      archivedAt: c.archivedAt == null
          ? const Value.absent()
          : Value(c.archivedAt!.millisecondsSinceEpoch ~/ 1000),
      isDirty: Value(isDirty),
      isDeleted: Value(c.isDeleted),
      payload: jsonEncode(c.toApiJson(preserveTempId: true)),
    );
  }

  String _domainPrimaryEmail(List<Contact> contacts) {
    if (contacts.isEmpty) return '';
    for (final c in contacts) {
      if (c.isPrimary) return c.email;
    }
    return contacts.first.email;
  }

  Client _fromRow(ClientRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = ClientApi.fromJson(json);
    // is_dirty is local-only (not in the API payload), so we layer it on
    // from the Drift row. Without this, an unsaved edit shows up as clean
    // after app restart.
    return Client.fromApi(api).copyWith(isDirty: row.isDirty);
  }

  String _primaryEmail(ClientApi a) {
    if (a.contacts.isEmpty) return '';
    for (final c in a.contacts) {
      if (c.isPrimary) return c.email;
    }
    return a.contacts.first.email;
  }
}
