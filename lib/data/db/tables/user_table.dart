import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for User rows. One row per `(company_id, id)` — the same user
/// can appear under multiple companies with distinct per-company permissions
/// and settings.
///
/// Two flows write here:
///  * Auth user — `AuthRepository._persistAndActivate` upserts each
///    `data[N].user` block on every login + refresh.
///  * Settings → User Management list — `UserRepository.ensurePageLoaded`
///    upserts each page of `/api/v1/users`.
///
/// `payload` carries the full server JSON; the denormalized columns
/// (`first_name`, `email`, `permissions`, `is_admin`, …) are the ones the
/// management list filters / sorts / role-badges on.
///
/// `@DataClassName('UserRow')` keeps the generated row class from colliding
/// with the domain `User` in `lib/data/models/domain/user.dart`.
@DataClassName('UserRow')
class Users extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get firstName => text().named('first_name')();
  TextColumn get lastName => text().named('last_name')();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get languageId => text().named('language_id')();
  TextColumn get signature => text()();

  /// Comma-separated permission tokens (e.g. `view_client,edit_invoice`).
  /// Empty when `is_admin = true` (administrators implicitly have all perms).
  TextColumn get permissions =>
      text().withDefault(const Constant(''))();

  /// Server `company_user.is_owner`.
  BoolColumn get isOwner =>
      boolean().named('is_owner').withDefault(const Constant(false))();

  /// Server `company_user.is_admin`.
  BoolColumn get isAdmin =>
      boolean().named('is_admin').withDefault(const Constant(false))();

  /// Server `company_user.is_locked`.
  BoolColumn get isLocked =>
      boolean().named('is_locked').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {companyId, id};
}
