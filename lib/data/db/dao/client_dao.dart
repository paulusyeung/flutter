import 'package:drift/drift.dart';

import '../app_database.dart';
import '../company_scoped_dao.dart';
import '../tables/clients_table.dart';

part 'client_dao.g.dart';

@DriftAccessor(tables: [Clients])
class ClientDao extends DatabaseAccessor<AppDatabase>
    with _$ClientDaoMixin, CompanyScopedDao {
  ClientDao(super.db);

  Stream<List<ClientRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
  }) {
    final q = select(clients)
      ..where((c) => c.companyId.equals(companyId) & c.isDeleted.equals(false));
    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(
        (c) =>
            c.name.like(pattern) |
            c.number.like(pattern) |
            c.email.like(pattern),
      );
    }
    q
      ..orderBy([(c) => OrderingTerm(expression: c.name)])
      ..limit(limit, offset: offset);
    return q.watch();
  }

  Stream<ClientRow?> watchById({
    required String companyId,
    required String id,
  }) {
    final q = select(clients)
      ..where((c) => c.companyId.equals(companyId) & c.id.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<void> upsertAll(List<ClientsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(clients, rows);
    });
  }

  Future<void> upsert(ClientsCompanion row) =>
      into(clients).insertOnConflictUpdate(row);

  Future<void> deleteById({
    required String companyId,
    required String id,
  }) async {
    await (delete(clients)
          ..where((c) => c.companyId.equals(companyId) & c.id.equals(id)))
        .go();
  }

  Future<void> remapId({
    required String companyId,
    required String tempId,
    required String realId,
  }) async {
    final existing = await (select(clients)
          ..where(
            (c) => c.companyId.equals(companyId) & c.id.equals(tempId),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing == null) return;
    await transaction(() async {
      await (delete(clients)
            ..where(
              (c) => c.companyId.equals(companyId) & c.id.equals(tempId),
            ))
          .go();
      await into(clients).insert(
        existing.toCompanion(true).copyWith(
              id: Value(realId),
              tempId: Value(tempId),
            ),
      );
    });
  }
}
