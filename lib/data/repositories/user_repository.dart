import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/user_api_model.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/data/services/users_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Outbox `entity_type` value for the user-record PUT flow. `EntityRegistry`
/// routes rows with this wire name to [UserSyncDispatcher].
///
/// Distinct from `kUserSettingsWireName` (`'user_settings'`) which goes to
/// `/company_users/{id}` — see [UserSettingsRepository] for that flow.
const String kUserWireName = 'user';

/// Source of truth for the authenticated user's profile. One row per
/// `(company_id, id)` in the `users` Drift table; the UI watches that row,
/// the network layer writes to it.
class UserRepository {
  UserRepository({
    required this.db,
    required this.api,
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
    this.onEnqueued,
  }) : _uuid = uuid,
       _now = now ?? DateTime.now;

  final AppDatabase db;
  final UsersApi api;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Wired in `Services.build` to `SyncRepository.drainOnce` so an update
  /// drains immediately when online — same contract as the entity repos.
  final void Function(String companyId)? onEnqueued;

  /// Watch the auth user for a given `(companyId, userId)`. Emits `null`
  /// until `AuthRepository.refresh()` (or the initial login) populates the
  /// row — `_persistAndActivate` writes the auth user record into the
  /// `users` table from the `/refresh` envelope's `data[N].user` block.
  /// We deliberately do not round-trip `GET /api/v1/users/{id}` because
  /// the server gates that route with a 412 password check and the
  /// `/refresh` payload already carries the full profile shape.
  Stream<User?> watch({required String companyId, required String userId}) {
    return db.userDao
        .watchByCompanyAndId(companyId: companyId, id: userId)
        .map(_fromRow);
  }

  /// Stream the users eligible to send mail through the given OAuth provider.
  /// Used by Settings → Email Settings's Gmail / Microsoft picker.
  ///
  /// Filter: `oauthProviderId == provider && oauthUserToken.isNotEmpty`.
  /// (Matches admin-portal's `isConnectedToEmail && isConnectedToGoogle`
  /// check — a stale provider id without a live token would otherwise let
  /// the user save an unsendable config.)
  ///
  /// The rebuild's `users` table only holds the authenticated user's row
  /// per company (`_persistAndActivate` writes one row from `data[N].user`;
  /// no `/users` list endpoint is wired). That means the stream emits at
  /// most one user — the auth user — when their own OAuth connection
  /// matches. Adding a true multi-user catalogue is out of scope for the
  /// Email Settings port; React's `/users?sending_users=true` round-trip
  /// will land when the broader Users CRUD does.
  Stream<List<User>> watchEmailSendingUsers({
    required String companyId,
    required String provider,
  }) {
    final lower = provider.toLowerCase();
    return db.userDao.watchAllForCompany(companyId: companyId).map(
      (rows) {
        return rows
            .map(_fromRow)
            .whereType<User>()
            .where(
              (u) =>
                  (u.oauthProviderId).toLowerCase() == lower &&
                  u.oauthUserToken.isNotEmpty,
            )
            .toList(growable: false);
      },
    );
  }

  Future<User?> get({required String companyId, required String userId}) async {
    final row = await db.userDao.getByCompanyAndId(
      companyId: companyId,
      id: userId,
    );
    return _fromRow(row);
  }

  /// Persist the user record returned by the server. Public so the sync
  /// dispatcher can apply update responses without reaching into Drift.
  Future<void> applyApiResponse({
    required String companyId,
    required UserApi api,
  }) => _upsertFromApi(companyId: companyId, api: api);

  /// Enqueue an outbox row that PUTs the user. The Drift row is updated
  /// optimistically with the user-level fields; the `company_user.settings`
  /// blob round-trips via the JSON payload.
  ///
  /// Existing pending rows for this `(companyId, user)` pair are collapsed
  /// — settings edits are idempotent, and a user spamming Save shouldn't
  /// pile up duplicate requests in the queue.
  Future<void> enqueueUpdate({
    required String companyId,
    required User draft,
    required Map<String, dynamic> body,
    bool requiresPassword = false,
  }) async {
    final nowMs = _now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await db.userDao.upsert(
        UsersCompanion(
          id: Value(draft.id),
          companyId: Value(companyId),
          firstName: Value(draft.firstName),
          lastName: Value(draft.lastName),
          email: Value(draft.email),
          phone: Value(draft.phone),
          languageId: Value(draft.languageId),
          signature: Value(draft.signature),
          updatedAt: Value(nowMs),
          isDirty: const Value(true),
          payload: Value(jsonEncode(body)),
        ),
      );
      final existing = await db.outboxDao.findPending(
        companyId: companyId,
        entityType: kUserWireName,
      );
      if (existing != null) {
        await db.outboxDao.updatePayload(
          id: existing.id,
          payload: jsonEncode(body),
        );
      } else {
        await db.outboxDao.enqueue(
          OutboxCompanion.insert(
            companyId: companyId,
            entityType: kUserWireName,
            entityId: draft.id,
            mutationKind: MutationKind.update.wireName,
            payload: jsonEncode(body),
            idempotencyKey: _uuid.v4(),
            nextAttemptAt: nowMs,
            createdAt: nowMs,
            requiresPassword: Value(requiresPassword),
          ),
        );
      }
    });
    onEnqueued?.call(companyId);
  }

  Future<void> _upsertFromApi({
    required String companyId,
    required UserApi api,
  }) async {
    final nowMs = _now().millisecondsSinceEpoch;
    await db.userDao.upsert(
      UsersCompanion(
        id: Value(api.id),
        companyId: Value(companyId),
        firstName: Value(api.firstName),
        lastName: Value(api.lastName),
        email: Value(api.email),
        phone: Value(api.phone),
        languageId: Value(api.languageId),
        signature: Value(api.signature),
        updatedAt: Value(nowMs),
        isDirty: const Value(false),
        payload: Value(jsonEncode(api.toJson())),
      ),
    );
  }

  User? _fromRow(UserRow? row) {
    if (row == null) return null;
    UserApi apiUser;
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is Map<String, dynamic>) {
        apiUser = UserApi.fromJson(decoded);
      } else {
        apiUser = const UserApi();
      }
    } catch (_) {
      apiUser = const UserApi();
    }
    // Overlay the indexed columns onto the typed view so a local edit lands
    // in the UI before the next server round-trip writes the payload back.
    final overlaid = apiUser.copyWith(
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      email: row.email,
      phone: row.phone,
      languageId: row.languageId,
      signature: row.signature,
    );
    return User.fromApi(overlaid);
  }
}
