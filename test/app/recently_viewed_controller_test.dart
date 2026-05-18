import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/recently_viewed_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/domain/entity_type.dart';

/// Targets RecentlyViewedController's contract: de-dupe + move-to-front +
/// cap, company-scoped clear off the session notifier (same guarantee as
/// NavHistoryController), and a persistence round-trip through the single-row
/// nav_state table. Debounce is set to zero so a single event-loop turn
/// flushes the write.

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

    // Re-visiting an existing entity moves it to the front with the new
    // label, not a duplicate.
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

  test('caps at maxEntries, dropping the oldest', () {
    final c = build(maxEntries: 3);
    addTearDown(c.dispose);
    for (var i = 0; i < 5; i++) {
      c.record(type: EntityType.task, id: 't$i', label: 'T$i');
    }
    expect(c.items.map((r) => r.id), ['t4', 't3', 't2']);
  });

  test('clears on company switch', () {
    final c = build();
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: 'c1', label: 'Acme');
    expect(c.items, isNotEmpty);

    session.value = _session('co_2');
    expect(c.items, isEmpty);
  });

  test('clears on logout (session -> null)', () {
    final c = build();
    addTearDown(c.dispose);
    c.record(type: EntityType.client, id: 'c1', label: 'Acme');

    session.value = null;
    expect(c.items, isEmpty);
  });

  test('persists and restores across a fresh controller', () async {
    final c1 = build();
    c1.record(type: EntityType.invoice, id: 'i1', label: '#1001');
    c1.record(type: EntityType.client, id: 'c1', label: 'Acme');
    await flush();
    c1.dispose();

    final c2 = build();
    addTearDown(c2.dispose);
    expect(c2.items, isEmpty); // not loaded until restore()
    await c2.restore();

    expect(c2.items.map((r) => r.id), ['c1', 'i1']);
    expect(c2.items.first.type, EntityType.client);
    expect(c2.items.first.label, 'Acme');
  });

  test('a malformed/legacy blob restores to empty, not a throw', () async {
    await db.navStateDao.saveRecentEntities(
      recentEntitiesJson: '{not valid json',
      now: clock.millisecondsSinceEpoch,
    );
    final c = build();
    addTearDown(c.dispose);

    await c.restore();
    expect(c.items, isEmpty);
  });

  test('an unknown entity-type name is dropped, valid entries kept',
      () async {
    await db.navStateDao.saveRecentEntities(
      recentEntitiesJson:
          '[{"t":"client","i":"c1","l":"Acme","v":0},'
          '{"t":"not_an_entity","i":"x","l":"X","v":0}]',
      now: clock.millisecondsSinceEpoch,
    );
    final c = build();
    addTearDown(c.dispose);

    await c.restore();
    expect(c.items.map((r) => r.id), ['c1']);
  });
}
