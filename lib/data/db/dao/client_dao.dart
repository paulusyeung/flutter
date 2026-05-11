import 'package:drift/drift.dart';

import '../../../domain/columns/client_columns.dart';
import '../../../domain/entity_state.dart';
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
    Set<EntityState> states = const {EntityState.active},
    String sortField = ClientFieldIds.name,
    bool sortAscending = true,
    Set<String> customValues1 = const {},
    Set<String> customValues2 = const {},
    Set<String> customValues3 = const {},
    Set<String> customValues4 = const {},
  }) {
    final q = select(clients)..where((c) => c.companyId.equals(companyId));

    // State filter: OR'd group across the requested states. An empty set
    // matches nothing — the UI guards against this by snapping back to
    // {active}, but we make the SQL safe anyway.
    if (states.isEmpty) {
      q.where((_) => const Constant(false));
    } else {
      q.where((c) {
        Expression<bool>? acc;
        for (final s in states) {
          final pred = switch (s) {
            EntityState.active =>
              c.archivedAt.isNull() & c.isDeleted.equals(false),
            EntityState.archived =>
              c.archivedAt.isNotNull() & c.isDeleted.equals(false),
            EntityState.deleted => c.isDeleted.equals(true),
          };
          acc = acc == null ? pred : acc | pred;
        }
        return acc!;
      });
    }

    if (search != null && search.isNotEmpty) {
      final pattern = '%$search%';
      q.where(
        (c) =>
            c.name.like(pattern) |
            c.number.like(pattern) |
            c.email.like(pattern),
      );
    }

    if (customValues1.isNotEmpty) {
      q.where((c) => c.customValue1.isIn(customValues1.toList()));
    }
    if (customValues2.isNotEmpty) {
      q.where((c) => c.customValue2.isIn(customValues2.toList()));
    }
    if (customValues3.isNotEmpty) {
      q.where((c) => c.customValue3.isIn(customValues3.toList()));
    }
    if (customValues4.isNotEmpty) {
      q.where((c) => c.customValue4.isIn(customValues4.toList()));
    }

    final mode = sortAscending ? OrderingMode.asc : OrderingMode.desc;
    q.orderBy([
      (c) =>
          OrderingTerm(expression: _sortExpression(c, sortField), mode: mode),
      // Always tiebreak on id so paginated reads are stable when the primary
      // sort has duplicates (common for balance=0 or empty number).
      (c) => OrderingTerm(expression: c.id, mode: mode),
    ]);
    q.limit(limit, offset: offset);
    return q.watch();
  }

  /// Wire-id → Drift ordering expression. Most ids map to a dedicated Drift
  /// column; anything else falls through to `json_extract(payload, '$.<id>')`
  /// so the table can be sorted by any column the user has shown — including
  /// fields we don't denormalize (e.g. address, contact name).
  ///
  /// Safety: [field] is interpolated into a `CustomExpression`. The caller
  /// (VM) validates it against `clientColumnsById` before reaching here, and
  /// this method drops back to `name` for ids we don't recognize, so untrusted
  /// payloads can't inject SQL. The double-check is intentional belt-and-
  /// suspenders.
  Expression _sortExpression(Clients c, String field) {
    switch (field) {
      case ClientFieldIds.name:
        return c.name;
      case ClientFieldIds.number:
        return c.number;
      // Balance is stored as text (Decimal.toString()); sorting it as text
      // puts "9" after "1000". Cast to REAL so the ordering is numeric.
      case ClientFieldIds.balance:
        return const CustomExpression<double>('CAST(balance AS REAL)');
      case ClientFieldIds.updatedAt:
        return c.updatedAt;
      case ClientFieldIds.createdAt:
        return c.createdAt;
      case ClientFieldIds.archivedAt:
        return c.archivedAt;
      case ClientFieldIds.custom1:
        return c.customValue1;
      case ClientFieldIds.custom2:
        return c.customValue2;
      case ClientFieldIds.custom3:
        return c.customValue3;
      case ClientFieldIds.custom4:
        return c.customValue4;
    }
    if (!clientColumnsById.containsKey(field)) {
      // Unknown id — protect against the CustomExpression interpolation path.
      return c.name;
    }
    // Monetary payload fields: cast to REAL so "9" < "1000".
    if (field == ClientFieldIds.paidToDate ||
        field == ClientFieldIds.creditBalance) {
      return CustomExpression<double>(
        "CAST(json_extract(payload, '\$.$field') AS REAL)",
      );
    }
    return CustomExpression<String>("json_extract(payload, '\$.$field')");
  }

  /// Distinct non-empty values of `custom_value{columnIndex}` for the given
  /// company, ordered ascending. Drives the bottom-sheet option list for
  /// custom-field filtering.
  Stream<List<String>> watchDistinctCustomValues({
    required String companyId,
    required int columnIndex,
  }) {
    final column = switch (columnIndex) {
      1 => clients.customValue1,
      2 => clients.customValue2,
      3 => clients.customValue3,
      4 => clients.customValue4,
      _ => throw ArgumentError('columnIndex must be 1..4 (got $columnIndex)'),
    };
    final q = selectOnly(clients, distinct: true)
      ..addColumns([column])
      ..where(clients.companyId.equals(companyId) & column.equals('').not())
      ..orderBy([OrderingTerm(expression: column)]);
    return q.map((row) => row.read(column)!).watch();
  }

  Stream<int> watchCount({required String companyId}) {
    final count = clients.id.count();
    final q = selectOnly(clients)
      ..addColumns([count])
      ..where(
        clients.companyId.equals(companyId) & clients.isDeleted.equals(false),
      );
    return q.map((row) => row.read(count) ?? 0).watchSingle();
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
    await (delete(
      clients,
    )..where((c) => c.companyId.equals(companyId) & c.id.equals(id))).go();
  }

  Future<void> remapId({
    required String companyId,
    required String tempId,
    required String realId,
  }) async {
    final existing =
        await (select(clients)
              ..where(
                (c) => c.companyId.equals(companyId) & c.id.equals(tempId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing == null) return;
    await transaction(() async {
      await (delete(clients)
            ..where((c) => c.companyId.equals(companyId) & c.id.equals(tempId)))
          .go();
      await into(clients).insert(
        existing
            .toCompanion(true)
            .copyWith(id: Value(realId), tempId: Value(tempId)),
      );
    });
  }
}
