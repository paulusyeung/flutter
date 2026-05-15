import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/tables/user_table.dart';

part 'user_dao.g.dart';

/// Reads/writes the per-company auth-user row. One row per (company_id, id),
/// so a multi-tenant account that switches companies sees a different row
/// each time without losing the previous one's cached values.
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Stream<UserRow?> watchByCompanyAndId({
    required String companyId,
    required String id,
  }) {
    final q = select(users)
      ..where((u) => u.companyId.equals(companyId) & u.id.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<UserRow?> getByCompanyAndId({
    required String companyId,
    required String id,
  }) {
    final q = select(users)
      ..where((u) => u.companyId.equals(companyId) & u.id.equals(id))
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// All user rows cached for the given company. Used by Email Settings's
  /// OAuth picker to filter by `oauth_provider_id`. The rebuild today only
  /// persists the auth user per company (see [UserRepository] doc), so the
  /// stream typically emits a one-element list — but the shape is ready for
  /// a future `/users` list sync without another DAO change.
  Stream<List<UserRow>> watchAllForCompany({required String companyId}) {
    final q = select(users)..where((u) => u.companyId.equals(companyId));
    return q.watch();
  }

  Future<void> upsert(UsersCompanion row) =>
      into(users).insertOnConflictUpdate(row);

  Future<int> deleteForCompany(String companyId) =>
      (delete(users)..where((u) => u.companyId.equals(companyId))).go();
}
