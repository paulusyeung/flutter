import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/companies_table.dart';

part 'companies_dao.g.dart';

@DriftAccessor(tables: [Companies, Accounts])
class CompaniesDao extends DatabaseAccessor<AppDatabase>
    with _$CompaniesDaoMixin {
  CompaniesDao(super.db);

  Future<List<CompanyRow>> all() => select(companies).get();
  Stream<List<CompanyRow>> watchAll() => select(companies).watch();

  Future<CompanyRow?> byId(String id) =>
      (select(companies)
            ..where((c) => c.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsertAll(List<CompaniesCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(companies, rows));
  }

  Future<AccountRow?> account() =>
      (select(accounts)..limit(1)).getSingleOrNull();

  Future<void> upsertAccount(AccountsCompanion row) =>
      into(accounts).insertOnConflictUpdate(row);

  Future<void> wipe() async {
    await transaction(() async {
      await delete(companies).go();
      await delete(accounts).go();
    });
  }
}
