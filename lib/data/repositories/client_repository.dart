import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';

final _log = Logger('ClientRepository');

/// Source of truth for Client data. The UI watches Drift via [watchPage]
/// and [watch]; the network only writes. Every mutation goes through the
/// outbox.
///
/// Page size is fixed at [pageSize]. Subsequent pages are fetched only on
/// demand — list screens call [ensurePageLoaded] near the scroll edge.
class ClientRepository extends BaseEntityRepository<Client, ClientApi> {
  ClientRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(entityType: EntityType.client);

  final ClientsApi api;
  final int pageSize;

  @override
  String get entityTypeName => 'client';

  @override
  bool requiresPasswordFor(MutationKind kind) => kind == MutationKind.delete;

  /// Watch the first [loadedPages] pages worth of rows (so an infinite-scroll
  /// list shows everything fetched so far). [loadedPages] is 1-based — 1
  /// means "show page 1," 2 means "show pages 1+2 contiguously," etc.
  Stream<List<Client>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = ClientFieldIds.name,
    bool sortAscending = true,
    Map<int, Set<String>> customFilters = const {},
    Map<String, Set<String>> extraFilters = const {},
  }) {
    assert(
      loadedPages >= 1,
      'loadedPages is 1-based; pass 1 for the first page',
    );
    // `name` is `singleValue: true` on its FilterKey, so there is at most
    // one entry — take the first. Membership-id keys (country, industry,
    // …) still need their own predicates; tracked as follow-ups.
    final nameValues = extraFilters['name'];
    final nameContains = (nameValues == null || nameValues.isEmpty)
        ? null
        : nameValues.first;
    final balance = _parseBalanceWire(extraFilters['balance']);
    return db.clientDao
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
          nameContains: nameContains,
          balanceGt: balance.gt,
          balanceLt: balance.lt,
        )
        .map((rows) => rows.map(_fromRow).toList(growable: false));
  }

  /// Extracts the numeric (gt, lt) thresholds from a `BalanceFilterKey`
  /// wire. Accepts the canonical suffix form (`value:gt` / `value:lt`)
  /// and the legacy prefix form (`gt:value` / `lt:value`) so persisted
  /// state from any prior app version still narrows correctly. Returns
  /// `(null, null)` for missing, empty, or unparseable input — the caller
  /// then applies no balance predicate, matching the chip-absent state.
  ({double? gt, double? lt}) _parseBalanceWire(Set<String>? values) {
    final wire = (values == null || values.isEmpty) ? null : values.first;
    if (wire == null) return (gt: null, lt: null);
    double? parse(String s) => double.tryParse(s.trim());
    if (wire.endsWith(':gt')) {
      return (gt: parse(wire.substring(0, wire.length - 3)), lt: null);
    }
    if (wire.endsWith(':lt')) {
      return (gt: null, lt: parse(wire.substring(0, wire.length - 3)));
    }
    if (wire.startsWith('gt:')) {
      return (gt: parse(wire.substring(3)), lt: null);
    }
    if (wire.startsWith('lt:')) {
      return (gt: null, lt: parse(wire.substring(3)));
    }
    return (gt: null, lt: null);
  }

  /// Distinct non-empty values populated by clients in `companyId` for the
  /// given custom column (1..4). Drives the bottom-sheet option list for
  /// custom-field filtering.
  Stream<List<String>> watchDistinctCustomValues({
    required String companyId,
    required int columnIndex,
  }) => db.clientDao.watchDistinctCustomValues(
    companyId: companyId,
    columnIndex: columnIndex,
  );

  /// Live non-deleted client count for [companyId]. Drives the sidebar
  /// badge; emits every time a client is added, archived, or deleted.
  Stream<int> watchCount({required String companyId}) =>
      db.clientDao.watchCount(companyId: companyId);

  @override
  Stream<Client?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.clientDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Fetch one page from the server and upsert into Drift.
  ///
  /// Idempotent: calling for the same page repeatedly is safe (Drift upserts
  /// are by id). Advances the cursor only on a successful page that returned
  /// data.
  ///
  /// [states] drives the server-side `client_status` filter. Without it, the
  /// cursor only pulls `(updated_at, id)` slices and the local cache would
  /// be missing archived/deleted rows even when the user has toggled them on.
  ///
  /// [extraFilters] is an open-ended map of flat server query params
  /// (`country_id`, `group_settings_id`, …) populated from the token search
  /// field. Each value set is comma-joined.
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
    const maxPages = 1000; // 50 rows × 1000 = 50 000 clients
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
  Future<void> save({required String companyId, required Client client}) async {
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

  Future<void> delete({required String companyId, required String id}) async {
    await enqueueMutation(
      companyId: companyId,
      entityId: id,
      kind: MutationKind.delete,
      payload: {'id': id},
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

  /// Concrete handler for the `create` round-trip. See base class for
  /// the steps that run inside the transaction.
  @override
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

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required ClientApi serverResponse,
  }) async {
    await db.clientDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing = await db.clientDao
        .watchById(companyId: companyId, id: id)
        .first;
    if (existing == null) return;
    await db.clientDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  /// Translate the requested entity states into the v2 server's filter
  /// query params. The server's defaults already include active rows, so we
  /// only need to opt-in to archived/deleted explicitly.
  @override
  Map<String, String> stateQueryParams(Set<EntityState> states) {
    if (states.isEmpty || states.containsAll(EntityState.values)) {
      // No states or all states: don't constrain the server — the local
      // watch filter does the actual filtering. Sending `client_status=*`
      // would just be redundant.
      return const {};
    }
    final names = states.map((s) => s.serverName).toList()..sort();
    return {'client_status': names.join(',')};
  }

  // -------------------- conversions --------------------

  ClientsCompanion _apiToCompanion(ClientApi a, String companyId) {
    return ClientsCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: a.name,
      number: a.number,
      email: _primaryEmailOf(a.contacts, (c) => c.isPrimary, (c) => c.email),
      displayName: a.displayName.isNotEmpty ? a.displayName : a.name,
      balance: a.balance.toString(),
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
      email: _primaryEmailOf(c.contacts, (c) => c.isPrimary, (c) => c.email),
      displayName: c.displayName,
      balance: c.balance.toString(),
      updatedAt: _secs(c.updatedAt),
      createdAt: Value(_secs(c.createdAt)),
      archivedAt: c.archivedAt == null
          ? const Value.absent()
          : Value(_secs(c.archivedAt!)),
      customValue1: Value(c.customValue1),
      customValue2: Value(c.customValue2),
      customValue3: Value(c.customValue3),
      customValue4: Value(c.customValue4),
      isDirty: Value(isDirty),
      isDeleted: Value(c.isDeleted),
      payload: jsonEncode(c.toApiJson(preserveTempId: true)),
    );
  }

  Client _fromRow(ClientRow row) {
    final json = jsonDecode(row.payload) as Map<String, dynamic>;
    final api = ClientApi.fromJson(json);
    // is_dirty is local-only (not in the API payload), so we layer it on
    // from the Drift row. Without this, an unsaved edit shows up as clean
    // after app restart.
    return Client.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}

/// Pick the primary contact's email, falling back to the first contact, then
/// empty string. Generic over both `ContactApi` and `Contact` so the API and
/// domain mappers share one walk.
String _primaryEmailOf<T>(
  List<T> contacts,
  bool Function(T) isPrimary,
  String Function(T) email,
) {
  if (contacts.isEmpty) return '';
  for (final c in contacts) {
    if (isPrimary(c)) return email(c);
  }
  return email(contacts.first);
}

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
