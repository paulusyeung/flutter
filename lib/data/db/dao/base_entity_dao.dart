import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';

/// Universal CRUD-list scaffolding for per-entity DAOs. Owns the five
/// methods every entity DAO needs to expose identically — `watchById`,
/// `watchCount`, `upsert`, `upsertAll`, `deleteById` — leaving the
/// concrete subclass to wire its table reference + the three column
/// expressions the base needs at runtime.
///
/// The mixins in `tables/_entity_table_mixin.dart` guarantee every entity
/// table has these three columns by the right name; the override hooks
/// here just bind them so the base can build queries without resorting
/// to dynamic column lookups.
///
/// Concrete DAOs still own `watchPage` (entity-specific filters + sort
/// expressions vary too much to share) and any entity-specific queries
/// — see [ClientDao.watchDistinctCustomValues], [TaskDao.watchRunning],
/// etc. The Drift-generated `_$XxxDaoMixin` still wires `@DriftAccessor`
/// like before.
abstract class BaseEntityDao<TableT extends Table, RowT>
    extends DatabaseAccessor<AppDatabase>
    with CompanyScopedDao {
  BaseEntityDao(super.db);

  /// The entity's Drift table accessor (e.g. `products`). [TableT] is the
  /// Drift-generated `$XxxTable` (a subclass of the hand-written `Xxx`
  /// table-source), so the runtime select/delete/insert flows here carry
  /// the same typing the per-DAO code would.
  TableInfo<TableT, RowT> get table;

  /// `id` column. Always non-null; `tmp_<uuid>` until the server assigns
  /// a real one.
  GeneratedColumn<String> get idColumn;

  /// `company_id` column. Every list query scopes by it — direct table
  /// access bypassing this check is caught by the `CompanyScopedDao` lint.
  GeneratedColumn<String> get companyIdColumn;

  /// `is_deleted` column. Soft-delete marker; the default `watchCount`
  /// excludes deleted rows.
  GeneratedColumn<bool> get isDeletedColumn;

  /// Count of non-deleted rows for [companyId]. Drives the empty-state UI
  /// and total-count badges on list screens.
  Stream<int> watchCount({required String companyId}) {
    final count = idColumn.count();
    final q = selectOnly(table)
      ..addColumns([count])
      ..where(
        companyIdColumn.equals(companyId) & isDeletedColumn.equals(false),
      );
    return q.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Single-row watch. Used by detail screens and edit screens that survive
  /// the tmp→real id swap (`id_remap` resolves the watched id under the
  /// hood, so callers don't have to track the swap themselves).
  Stream<RowT?> watchById({required String companyId, required String id}) {
    final q = select(table)
      ..where((_) => companyIdColumn.equals(companyId) & idColumn.equals(id))
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// Insert-or-update one row. The repository uses this on every applyXxx
  /// response handler.
  Future<void> upsert(Insertable<RowT> row) =>
      into(table).insertOnConflictUpdate(row);

  /// Batched insert-or-update; short-circuits when the list is empty so
  /// callers don't have to guard themselves.
  Future<void> upsertAll(List<Insertable<RowT>> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(table, rows));
  }

  /// Hard-delete a single row. Repositories use this when the outbox drain
  /// confirms a delete (the row has been removed server-side too).
  Future<int> deleteById({required String companyId, required String id}) {
    return (delete(table)..where(
          (_) => companyIdColumn.equals(companyId) & idColumn.equals(id),
        ))
        .go();
  }
}
