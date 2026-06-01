import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/recently_viewed_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/domain/entity_type.dart';

/// Targets RecentlyViewedController's per-company contract: de-dupe +
/// move-to-front + per-company cap, `items`/`record` scoped to the active
/// company (switching swaps lists, previous company preserved), and a
/// keyed `{companyId: [...]}` persistence round-trip through the single-row
/// nav_state blob. Debounce is zero so one event-loop turn flushes.

AuthSession _session(String companyId) => AuthSession(
  baseUrl: 'https://example.com',
  isHosted: true,
  accountId: 'acc',
  companies: const [],
  currentCompanyId: companyId,
);

void main() {
  late AppDatabase db;
  late ValueNotifier<AuthSession?> session;
  var clock = DateTime.utc(2026, 1, 1);

  RecentlyViewedController build({int maxEntries = 12}) =>
      RecentlyViewedController(
        db: db,
        session: session,
        maxEntries: maxEntries,
        now: () => clock,
        persistDebounce: Duration.zero,
      );

  // Let the zero-duration debounce Timer fire + the async DB write settle.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    session = ValueNotifier<AuthSession?>(_session('co_1'));
    clock = DateTime.utc(2026, 1, 1);
  });

  tearDown(() async {
    session.dispose();
    await db.close();
  });

  test('records newest-first and de-dupes by (type, id)', () {
    final c = build();
    addTearDown(c.dispose);

    c.record(type: EntityType.client, id: 'c1', label: 'Acme');
    c.record(type: EntityType.invoice, id: 'i1', label: '#1001');
    expect(c.items.map((r) => r.id), ['i1', 'c1']);

    c.record(type: EntityType.client, id: 'c1', label: 'Acme Inc');
    expect(c.items.map((r) => r.id), ['c1', 'i1']);
    expect(c.items.length, 2);
    expect(c.items.first.label, 'Acme Inc');
  });

  test('empty id is a no-op', () {
    final c = build();
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: '', label: 'x');
    expect(c.items, isEmpty);
  });

  test('record is a no-op when logged out (no active company)', () {
    final c = build();
    addTearDown(c.dispose);
    session.value = null;
    c.record(type: EntityType.client, id: 'c1', label: 'Acme');
    expect(c.items, isEmpty);
  });

  test('caps at maxEntries per company, dropping the oldest', () {
    final c = build(maxEntries: 3);
    addTearDown(c.dispose);
    for (var i = 0; i < 5; i++) {
      c.record(type: EntityType.task, id: 't$i', label: 'T$i');
    }
    expect(c.items.map((r) => r.id), ['t4', 't3', 't2']);
  });

  test('each company keeps its own list; switching swaps, not clears', () {
    final c = build(); // co_1
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: 'a1', label: 'A Co');

    session.value = _session('co_2'); // switch
    expect(c.items, isEmpty); // co_2 has none yet
    c.record(type: EntityType.invoice, id: 'b1', label: '#B');

    session.value = _session('co_1'); // switch back
    expect(c.items.map((r) => r.id), ['a1']); // co_1 preserved

    session.value = _session('co_2');
    expect(c.items.map((r) => r.id), ['b1']); // co_2 preserved
  });

  test('logout hides recents; relogin restores that company list', () {
    final c = build(); // co_1
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: 'c1', label: 'Acme');

    session.value = null; // logout
    expect(c.items, isEmpty);

    session.value = _session('co_1'); // log back into the same company
    expect(c.items.map((r) => r.id), ['c1']);
  });

  test('logout then login to a DIFFERENT company shows only its recents', () {
    final c = build(); // co_1
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: 'a1', label: 'A Co');

    session.value = null;
    session.value = _session('co_2');
    expect(c.items, isEmpty); // co_2's own (empty) list — no leak

    session.value = _session('co_1');
    expect(c.items.map((r) => r.id), ['a1']); // co_1 still intact
  });

  test('boot: restore loads the keyed map; session resolve shows it', () async {
    // Controller is constructed before auth.restore(); session starts null.
    final seed = build(); // records under co_1
    seed.record(type: EntityType.invoice, id: 'i1', label: '#1001');
    await flush();
    seed.dispose();

    final boot = ValueNotifier<AuthSession?>(null);
    addTearDown(boot.dispose);
    final c = RecentlyViewedController(
      db: db,
      session: boot,
      now: () => clock,
      persistDebounce: Duration.zero,
    );
    addTearDown(c.dispose);
    await c.restore();
    expect(c.items, isEmpty); // no active company yet

    boot.value = _session('co_1'); // auth resolves
    expect(c.items.map((r) => r.id), ['i1']);
  });

  test('persists + restores per company across a fresh controller', () async {
    final c1 = build(); // co_1
    c1.record(type: EntityType.invoice, id: 'i1', label: '#1001');
    c1.record(type: EntityType.client, id: 'c1', label: 'Acme');
    session.value = _session('co_2');
    c1.record(type: EntityType.task, id: 't1', label: 'Task');
    await flush();
    c1.dispose();

    session.value = _session('co_1'); // a fresh boot starts at co_1
    final c2 = build();
    addTearDown(c2.dispose);
    expect(c2.items, isEmpty); // not loaded until restore()
    await c2.restore();

    expect(c2.items.map((r) => r.id), ['c1', 'i1']); // co_1's list
    session.value = _session('co_2');
    expect(c2.items.map((r) => r.id), ['t1']); // co_2's list
  });

  test('a malformed blob restores to empty, not a throw', () async {
    await db.navStateDao.saveRecentEntities(
      recentEntitiesJson: '{not valid json',
      now: clock.millisecondsSinceEpoch,
    );
    final c = build();
    addTearDown(c.dispose);
    await c.restore();
    expect(c.items, isEmpty);
  });

  test('a legacy array blob (pre-per-company) is dropped', () async {
    await db.navStateDao.saveRecentEntities(
      recentEntitiesJson: '[{"t":"client","i":"c1","l":"Acme","v":0}]',
      now: clock.millisecondsSinceEpoch,
    );
    final c = build();
    addTearDown(c.dispose);
    await c.restore();
    expect(c.items, isEmpty); // can't attribute to a company at boot
  });

  test('unknown entity-type names are dropped, valid entries kept', () async {
    await db.navStateDao.saveRecentEntities(
      recentEntitiesJson:
          '{"co_1":[{"t":"client","i":"c1","l":"Acme","v":0},'
          '{"t":"not_an_entity","i":"x","l":"X","v":0}]}',
      now: clock.millisecondsSinceEpoch,
    );
    final c = build(); // co_1
    addTearDown(c.dispose);
    await c.restore();
    expect(c.items.map((r) => r.id), ['c1']);
  });
}
