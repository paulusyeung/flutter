import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/token_dao.dart';
import 'package:admin/data/models/api/token_api_model.dart';
import 'package:admin/data/models/domain/token.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/data/services/tokens_api.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

final _log = Logger('TokenRepository');

/// One-shot delivery of a freshly-minted token secret. The repository emits
/// this on [TokenRepository.newSecrets] as soon as [applyCreateResponse]
/// runs for a create that originated from this client (matched by
/// [tempId]). The create screen subscribes once and dismisses on receipt.
class FreshTokenSecret {
  const FreshTokenSecret({required this.tempId, required this.secret});
  final String tempId;
  final String secret;
}

/// Source of truth for API tokens. Bundled on `/refresh?first_load=true`
/// via `tokens_hashed` (server returns masked values there), and also
/// fetched page-by-page via `/api/v1/tokens` when needed.
///
/// On create, the server returns the **raw bearer secret** exactly once;
/// `applyCreateResponse` broadcasts it through [newSecrets] so the
/// create screen can surface a one-time copy dialog. Drift persists only
/// the masked form (see `Token.toApiJson` — `token` is stripped from
/// every outgoing payload).
class TokenRepository extends BaseEntityRepository<Token, TokenApi> {
  TokenRepository({
    required super.db,
    required this.api,
    super.uuid,
    super.now,
    super.onEnqueued,
    this.pageSize = 50,
  }) : super(
         entityType: EntityType.token,
         requiresPasswordFor: const {MutationKind.delete, MutationKind.purge},
       );

  final TokensApi api;
  final int pageSize;

  final _secretsController = StreamController<FreshTokenSecret>.broadcast();

  /// Fires once per successful create with the **raw** server-minted secret.
  /// Subsequent updates / lists never re-emit — the masked form lives in
  /// Drift and is what the list / detail screens read.
  Stream<FreshTokenSecret> get newSecrets => _secretsController.stream;

  @override
  String get entityTypeName => 'token';

  Stream<List<Token>> watchPage({
    required String companyId,
    int loadedPages = 1,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String sortField = TokenFieldIds.name,
    bool sortAscending = true,
  }) {
    assert(loadedPages >= 1);
    return db.tokenDao
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
      db.tokenDao.watchActiveCount(companyId: companyId);

  @override
  Stream<Token?> watchByRealId({
    required String companyId,
    required String id,
  }) => db.tokenDao
      .watchById(companyId: companyId, id: id)
      .map((row) => row == null ? null : _fromRow(row));

  /// Drain the `tokens_hashed` array carried by `/login` and
  /// `/refresh?first_load=true` into the local `tokens` table.
  /// Upserts only — never deletes.
  Future<void> applyBundle({
    required String companyId,
    required List<TokenApi> bundle,
  }) => applyBundleUpsertOnly(
    companyId: companyId,
    bundle: bundle,
    idOf: (a) => a.id,
    updatedAtOf: (a) => a.updatedAt,
    toCompanion: (a) => _apiToCompanion(a, companyId),
    upsert: (byId) => db.tokenDao.upsertAllPreservingDirty(
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
    upsert: (byId) => db.tokenDao.upsertAllPreservingDirty(
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

  Future<Token> create({
    required String companyId,
    required Token draft,
  }) async {
    final tmpId = mintTempId();
    final stored = draft.copyWith(id: tmpId);
    final companion = _domainToCompanion(stored, companyId, isDirty: true);

    await db.transaction(() async {
      await db.tokenDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: tmpId,
        kind: MutationKind.create,
        payload: stored.toApiJson(),
      );
    });
    return stored;
  }

  Future<void> save({required String companyId, required Token token}) async {
    final companion = _domainToCompanion(token, companyId, isDirty: true);
    await db.transaction(() async {
      await db.tokenDao.upsert(companion);
      await enqueueMutation(
        companyId: companyId,
        entityId: token.id,
        kind: MutationKind.update,
        payload: token.toApiJson(preserveTempId: true),
      );
    });
  }

  @override
  Future<void> applyCreateResponse({
    required String companyId,
    required String tempId,
    required TokenApi serverResponse,
  }) async {
    // Capture the raw secret BEFORE upserting (the companion stores the
    // masked value the server gave us). On a real create response the
    // server returns the unmasked token exactly once — broadcast it so
    // the create screen can dismiss its "waiting for secret…" state.
    final domain = Token.fromApi(serverResponse);
    if (!domain.isMasked && domain.token.isNotEmpty) {
      _secretsController.add(
        FreshTokenSecret(tempId: tempId, secret: domain.token),
      );
    }
    await applyCreateResponseTemplate(
      companyId: companyId,
      tempId: tempId,
      realId: serverResponse.id,
      companion: _apiToCompanion(serverResponse, companyId),
      upsert: db.tokenDao.upsert,
      deleteById: (id) => db.tokenDao.deleteById(companyId: companyId, id: id),
    );
  }

  @override
  Future<void> applyUpdateResponse({
    required String companyId,
    required TokenApi serverResponse,
  }) async {
    await db.tokenDao.upsert(_apiToCompanion(serverResponse, companyId));
  }

  @override
  Future<void> applyDeleteResponse({
    required String companyId,
    required String id,
  }) async {
    final existing =
        await db.tokenDao.watchById(companyId: companyId, id: id).first;
    if (existing == null) return;
    await db.tokenDao.upsert(
      existing
          .toCompanion(true)
          .copyWith(isDeleted: const Value(true), isDirty: const Value(false)),
    );
  }

  Future<void> dispose() async {
    await _secretsController.close();
  }

  // -------------------- conversions --------------------

  TokensCompanion _apiToCompanion(TokenApi a, String companyId) {
    return TokensCompanion.insert(
      id: a.id,
      companyId: companyId,
      name: Value(a.name),
      userId: Value(a.userId),
      token: Value(a.token),
      isSystem: Value(a.isSystem),
      updatedAt: a.updatedAt,
      createdAt: Value(a.createdAt),
      archivedAt: a.archivedAt > 0 ? Value(a.archivedAt) : const Value.absent(),
      isDirty: const Value(false),
      isDeleted: Value(a.isDeleted),
      payload: jsonEncode(a.toJson()),
    );
  }

  TokensCompanion _domainToCompanion(
    Token t,
    String companyId, {
    required bool isDirty,
  }) {
    return TokensCompanion.insert(
      id: t.id,
      companyId: companyId,
      name: Value(t.name),
      userId: Value(t.userId),
      token: Value(t.token),
      isSystem: Value(t.isSystem),
      updatedAt: t.updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: Value(t.createdAt.millisecondsSinceEpoch ~/ 1000),
      archivedAt: t.archivedAt == null
          ? const Value.absent()
          : Value(t.archivedAt!.millisecondsSinceEpoch ~/ 1000),
      isDirty: Value(isDirty),
      isDeleted: Value(t.isDeleted),
      payload: jsonEncode(t.toApiJson(preserveTempId: true)),
    );
  }

  Token _fromRow(TokenRow row) {
    final apiJson = jsonDecode(row.payload) as Map<String, dynamic>;
    // Preserve the masked / raw `token` and `user_id` from the dedicated
    // columns — `toApiJson` strips them from `payload` so we'd otherwise
    // lose them on round-trip.
    apiJson['token'] = row.token;
    apiJson['user_id'] = row.userId;
    final api = TokenApi.fromJson(apiJson);
    return Token.fromApi(api).copyWith(isDirty: row.isDirty);
  }
}
