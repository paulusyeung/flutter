import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/statics_table.dart';

part 'statics_dao.g.dart';

@DriftAccessor(tables: [Statics])
class StaticsDao extends DatabaseAccessor<AppDatabase> with _$StaticsDaoMixin {
  StaticsDao(super.db);

  Future<({String payload, int fetchedAt})?> read() async {
    final row =
        await (select(statics)
              ..where((s) => s.id.equals(0))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return (payload: row.payload, fetchedAt: row.fetchedAt);
  }

  Future<void> write({required String payload, required int fetchedAt}) =>
      into(statics).insertOnConflictUpdate(
        StaticsCompanion.insert(payload: payload, fetchedAt: fetchedAt),
      );
}
