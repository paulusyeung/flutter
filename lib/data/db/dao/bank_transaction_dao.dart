import 'package:drift/drift.dart';

import 'package:admin/domain/entity_state.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';
import 'package:admin/data/db/dao/entity_query_helpers.dart';
import 'package:admin/data/db/tables/bank_transactions_table.dart';

part 'bank_transaction_dao.g.dart';

class BankTransactionFieldIds {
  static const String date = 'date';
  static const String amount = 'amount';
  static const String description = 'description';
  static const String participantName = 'participant_name';
  static const String statusId = 'status_id';
  static const String baseType = 'base_type';
  static const String state = 'state';
  static const String updatedAt = 'updated_at';
  static const String createdAt = 'created_at';
}

@DriftAccessor(tables: [BankTransactions])
class BankTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$BankTransactionDaoMixin, CompanyScopedDao {
  BankTransactionDao(super.db);

  Stream<List<BankTransactionRow>> watchPage({
    required String companyId,
    required int offset,
    required int limit,
    String? search,
    Set<EntityState> states = const {EntityState.active},
    String? bankAccountId,
    Set<String>? statusIds,
    String? baseType,
    String sortField = BankTransactionFieldIds.date,
    bool sortAscending = false,
  }) {
    final q = select(bankTransactions)
      ..where((t) => t.companyId.equals(companyId));

    if (states.isNotEmpty) {
      q.where(
        (t) => entityStateFilter(
          states: states,
          archivedAt: t.archivedAt,
          isDeleted: t.isDeleted,
        ),
      );
    }

    if (bankAccountId != null && bankAccountId.isNotEmpty) {
      q.where((t) => t.bankAccountId.equals(bankAccountId));
    }
    if (statusIds != null && statusIds.isNotEmpty) {
      q.where((t) => t.statusId.isIn(statusIds.toList(growable: false)));
    }
    if (baseType != null && baseType.isNotEmpty) {
      q.where((t) => t.baseType.equals(baseType));
    }
    if (search != null && search.isNotEmpty) {
      final needle = '%${search.toLowerCase()}%';
      q.where(
        (t) =>
            t.description.lower().like(needle) |
            t.participantName.lower().like(needle) |
            t.participant.lower().like(needle),
      );
    }

    q.orderBy([
      (t) => OrderingTerm(
        expression: _sortExpression(t, sortField),
        mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
      ),
      (t) => OrderingTerm(expression: t.id),
    ]);

    q.limit(limit, offset: offset);
    return q.watch();
  }

  Expression _sortExpression(BankTransactions t, String field) {
    switch (field) {
      case BankTransactionFieldIds.date:
        return t.date;
      case BankTransactionFieldIds.amount:
        return const CustomExpression<double>('CAST(amount AS REAL)');
      case BankTransactionFieldIds.description:
        return t.description.lower();
      case BankTransactionFieldIds.participantName:
        return t.participantName.lower();
      case BankTransactionFieldIds.statusId:
        return t.statusId;
      case BankTransactionFieldIds.baseType:
        return t.baseType;
      case BankTransactionFieldIds.createdAt:
        return t.createdAt;
      case BankTransactionFieldIds.updatedAt:
      default:
        return t.updatedAt;
    }
  }

  Stream<BankTransactionRow?> watchById({
    required String companyId,
    required String id,
  }) {
    return (select(bankTransactions)
          ..where((t) => t.companyId.equals(companyId) & t.id.equals(id))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsert(BankTransactionsCompanion row) =>
      into(bankTransactions).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<BankTransactionsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(bankTransactions, rows));
  }

  Future<void> upsertAllPreservingDirty({
    required String companyId,
    required Map<String, BankTransactionsCompanion> byId,
  }) async {
    if (byId.isEmpty) return;
    final candidateIds = byId.keys.toList(growable: false);
    final dirtyQ = selectOnly(bankTransactions)
      ..addColumns([bankTransactions.id])
      ..where(
        bankTransactions.companyId.equals(companyId) &
            bankTransactions.id.isIn(candidateIds) &
            bankTransactions.isDirty.equals(true),
      );
    final dirty = {
      for (final r in await dirtyQ.get()) r.read(bankTransactions.id)!,
    };
    final filtered = [
      for (final entry in byId.entries)
        if (!dirty.contains(entry.key)) entry.value,
    ];
    await upsertAll(filtered);
  }

  Future<int> deleteById({required String companyId, required String id}) {
    return (delete(
      bankTransactions,
    )..where((t) => t.companyId.equals(companyId) & t.id.equals(id))).go();
  }

  Stream<int> watchActiveCount({required String companyId}) {
    final q = selectOnly(bankTransactions)
      ..addColumns([bankTransactions.id.count()])
      ..where(
        bankTransactions.companyId.equals(companyId) &
            bankTransactions.isDeleted.equals(false) &
            bankTransactions.archivedAt.isNull(),
      );
    return q
        .map((row) => row.read(bankTransactions.id.count()) ?? 0)
        .watchSingle();
  }
}
