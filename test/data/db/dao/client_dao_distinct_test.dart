import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';

/// Guards the `.distinctRows()` dedup added to every DAO `watchPage`
/// stream (perf plan 4.2). Drift table watches are table-grained: any
/// write to `clients` re-runs every active query on it. `distinctRows`
/// must drop a re-emission whose visible result is byte-identical
/// (e.g. a write to another company) while still passing through any
/// change to a rendered field on an in-page row.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ClientsCompanion client({
    required String id,
    String companyId = 'co',
    String name = 'Acme',
    int updatedAt = 1,
  }) => ClientsCompanion.insert(
    id: id,
    companyId: companyId,
    name: name,
    number: '',
    email: '',
    displayName: '',
    balance: '0',
    updatedAt: updatedAt,
    payload: '{}',
  );

  // Let Drift's watch re-run + the stream transformer settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test(
    'watchPage drops an identical re-emission caused by an unrelated '
    "company's write, but emits on an in-page rendered-field change",
    () async {
      await db.clientDao.upsert(client(id: 'a', name: 'Acme'));

      final emissions = <List<String>>[];
      final sub = db.clientDao
          .watchPage(companyId: 'co', offset: 0, limit: 50)
          .listen((rows) => emissions.add(rows.map((r) => r.name).toList()));
      await settle();
      expect(emissions, [
        ['Acme'],
      ], reason: 'initial emission');

      // Write to a DIFFERENT company — the `co`-filtered result is
      // unchanged, so distinctRows must suppress the re-emission.
      await db.clientDao.upsert(client(id: 'x', companyId: 'other'));
      await settle();
      expect(
        emissions,
        [
          ['Acme'],
        ],
        reason: 'unrelated-company write must not re-emit',
      );

      // Change a rendered field on the in-page row — must emit.
      await db.clientDao.upsert(client(id: 'a', name: 'Acme Renamed'));
      await settle();
      expect(
        emissions,
        [
          ['Acme'],
          ['Acme Renamed'],
        ],
        reason: 'in-page rendered-field change must emit',
      );

      await sub.cancel();
    },
  );
}
