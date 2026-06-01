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

  /// `is_dirty` column. Local-only flag — true means an unsynced edit is
  /// pending in the outbox. Used by [upsertAllPreservingDirty] to skip
  /// server-payload upserts that would otherwise clobber the user's
  /// in-flight edit.
  GeneratedColumn<bool> get isDirtyColumn;

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

  /// Server-refresh upsert that preserves the user's in-flight edits.
  ///
  /// For ids whose existing local row has `is_dirty = true`, the incoming
  /// companion is dropped — the user's pending edit (and the queued
  /// outbox row carrying it) survives the refresh. Everything else is
  /// upserted normally.
  ///
  /// Use this on every server-payload write path: `ensurePageLoaded`
  /// (paged refresh) and `applyBundle` (login/refresh fan-out). Single-
  /// row `applyXxxResponse` handlers (post-drain success) intentionally
  /// keep using [upsert] — the dirty bit on that row was set by the very
  /// mutation that just succeeded, and clearing it is correct.
  Future<void> upsertAllPreservingDirty({
    required String companyId,
    required Map<String, Insertable<RowT>> byId,
  }) async {
    if (byId.isEmpty) return;
    final candidateIds = byId.keys.toList(growable: false);
    final dirty = await _dirtyIdsAmong(companyId, candidateIds);
    final filtered = [
      for (final entry in byId.entries)
        if (!dirty.contains(entry.key)) entry.value,
    ];
    await upsertAll(filtered);
  }

  Future<Set<String>> _dirtyIdsAmong(String companyId, List<String> ids) async {
    if (ids.isEmpty) return const {};
    final q = selectOnly(table)
      ..addColumns([idColumn])
      ..where(
        companyIdColumn.equals(companyId) &
            idColumn.isIn(ids) &
            isDirtyColumn.equals(true),
      );
    final rows = await q.get();
    return {for (final r in rows) r.read(idColumn)!};
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
