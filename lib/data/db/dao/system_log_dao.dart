import 'package:drift/drift.dart';

import 'package:admin/data/db/dao/_distinct_stream.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/company_scoped_dao.dart';
import 'package:admin/data/db/tables/system_logs_table.dart';

part 'system_log_dao.g.dart';

@DriftAccessor(tables: [SystemLogs])
class SystemLogDao extends DatabaseAccessor<AppDatabase>
    with _$SystemLogDaoMixin, CompanyScopedDao {
  SystemLogDao(super.db);

  /// Most recent [limit] log rows for [companyId], newest first.
  Stream<List<SystemLogRow>> watchForCompany({
    required String companyId,
    int limit = 200,
  }) {
    final q = select(systemLogs)
      ..where((s) => s.companyId.equals(companyId))
      ..orderBy([
        (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
        (s) => OrderingTerm(expression: s.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return q.watch().distinctRows();
  }

  /// Replace every cached row for [companyId] in a single transaction. The
  /// server is the only writer, so a full overwrite mirrors React's
  /// overwrite-on-refetch cache strategy and avoids stale rows lingering
  /// after they're deleted upstream.
  Future<void> replaceForCompany({
    required String companyId,
    required List<SystemLogsCompanion> rows,
  }) async {
    await transaction(() async {
      await (delete(
        systemLogs,
      )..where((s) => s.companyId.equals(companyId))).go();
      if (rows.isNotEmpty) {
        await batch((b) => b.insertAll(systemLogs, rows));
      }
    });
  }

  /// Latest `fetched_at` across the company's cached rows, as a [DateTime]
  /// (UTC, from unix seconds). Used for the "Last refreshed" hint and the
  /// 1-hour staleness check.
  Future<DateTime?> lastFetchedAt(String companyId) async {
    final maxCol = systemLogs.fetchedAt.max();
    final q = selectOnly(systemLogs)
      ..addColumns([maxCol])
      ..where(systemLogs.companyId.equals(companyId));
    final row = await q.getSingleOrNull();
    final epoch = row?.read(maxCol);
    if (epoch == null || epoch == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
  }
}
