import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/saved_views_repository.dart';
import 'package:admin/domain/entity_type.dart';

/// Pins the persistence shape the saved-views feature relies on:
///   * snapshot envelope `{"v": 1, "data": {...}}`
///   * `apply` writes the snapshot into `nav_state.filters_json` at the
///     `companyId → entityType.name` slot
///   * corrupt / unknown rows are filtered out of the watch stream rather
///     than crashing the sidebar.
void main() {
  late AppDatabase db;
  late SavedViewsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedViewsRepository(
      db: db,
      uuid: const Uuid(),
      now: () => DateTime.fromMillisecondsSinceEpoch(1000),
    );
  });
  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test('round-trips name + entity + snapshot', () async {
      final view = await repo.create(
        companyId: 'co',
        entityType: EntityType.client,
        name: 'Acme US',
        snapshot: {
          'search': 'acme',
          'extraFilters': {
            'country_id': ['US'],
          },
        },
      );
      expect(view.companyId, 'co');
      expect(view.entityType, EntityType.client);
      expect(view.name, 'Acme US');
      expect(view.snapshot['search'], 'acme');
      expect(view.createdAt, 1000);

      final row = await db.savedViewsDao.byId(view.id);
      // Stored payload is wrapped in the schema-versioned envelope.
      final decoded = jsonDecode(row!.payloadJson) as Map<String, dynamic>;
      expect(decoded['v'], 1);
      expect(decoded['data'], isA<Map<String, dynamic>>());
      expect((decoded['data'] as Map)['search'], 'acme');
    });
  });

  group('apply', () {
    test('splices snapshot into nav_state.filters_json', () async {
      // Seed nav_state with an unrelated company entry so we can verify
      // the apply doesn't clobber other slots.
      await db.navStateDao.saveFilters(
        filtersJson: jsonEncode({
          'co_other': {
            'client': {'search': 'keep me'},
          },
        }),
        now: 0,
      );
      final view = await repo.create(
        companyId: 'co',
        entityType: EntityType.client,
        name: 'Acme US',
        snapshot: {'search': 'acme', 'sortField': 'name'},
      );
      await repo.apply(view.id);

      final row = await db.navStateDao.current();
      final doc = jsonDecode(row!.filtersJson!) as Map<String, dynamic>;
      // Other company's slot is preserved.
      expect((doc['co_other'] as Map)['client']['search'], 'keep me');
      // Our slot landed.
      final ours = (doc['co'] as Map)['client'] as Map;
      expect(ours['search'], 'acme');
      expect(ours['sortField'], 'name');
    });

    test('on a missing id is a no-op (no nav_state mutation)', () async {
      await repo.apply('does-not-exist');
      final row = await db.navStateDao.current();
      expect(row?.filtersJson, anyOf(isNull, isEmpty));
    });
  });

  group('watchAll', () {
    test('filters out rows referencing unknown entity types', () async {
      // Forge a row with an entity_type the build doesn't know — would
      // otherwise blank out the sidebar via a stray throw.
      await db.savedViewsDao.insertView(
        SavedViewsCompanion(
          id: const Value('bad'),
          companyId: const Value('co'),
          entityType: const Value('mythical_beast'),
          name: const Value('Bad row'),
          payloadJson: const Value('{"v":1,"data":{}}'),
          createdAt: const Value(0),
          updatedAt: const Value(0),
        ),
      );
      // And one good row alongside it.
      await repo.create(
        companyId: 'co',
        entityType: EntityType.client,
        name: 'Good',
        snapshot: const {},
      );

      final views = await repo.watchAll('co').first;
      expect(views.length, 1);
      expect(views.first.name, 'Good');
    });

    test('decodes legacy bare-snapshot payloads', () async {
      // Forge a row written without the {v,data} envelope (forward-compat
      // lane — never produced today but the repo must accept it).
      await db.savedViewsDao.insertView(
        SavedViewsCompanion(
          id: const Value('legacy'),
          companyId: const Value('co'),
          entityType: const Value('client'),
          name: const Value('Legacy'),
          payloadJson: Value(jsonEncode({'search': 'old'})),
          createdAt: const Value(0),
          updatedAt: const Value(0),
        ),
      );
      final views = await repo.watchAll('co').first;
      expect(views.length, 1);
      expect(views.first.snapshot['search'], 'old');
    });
  });

  group('delete', () {
    test('removes the row', () async {
      final view = await repo.create(
        companyId: 'co',
        entityType: EntityType.client,
        name: 'X',
        snapshot: const {},
      );
      await repo.delete(view.id);
      final views = await repo.watchAll('co').first;
      expect(views, isEmpty);
    });
  });

  group('matchingView', () {
    test(
      'emits the view whose snapshot deep-matches and null otherwise',
      () async {
        final acme = await repo.create(
          companyId: 'co',
          entityType: EntityType.client,
          name: 'Acme US',
          snapshot: {
            'search': 'acme',
            'extraFilters': {
              'country_id': ['US'],
            },
          },
        );
        await repo.create(
          companyId: 'co',
          entityType: EntityType.client,
          name: 'Top 10',
          snapshot: {'sortField': 'balance'},
        );
        // Snapshot matches the first view exactly.
        final hits = await repo
            .matchingView(
              companyId: 'co',
              entityType: EntityType.client,
              currentSnapshot: {
                'search': 'acme',
                'extraFilters': {
                  'country_id': ['US'],
                },
              },
            )
            .first;
        expect(hits, isNotNull);
        expect(hits!.id, acme.id);
        // A snapshot that matches nothing emits null.
        final miss = await repo
            .matchingView(
              companyId: 'co',
              entityType: EntityType.client,
              currentSnapshot: {'search': 'something else'},
            )
            .first;
        expect(miss, isNull);
      },
    );
  });

  group('updateSnapshot', () {
    test('overwrites payload while preserving id and name', () async {
      final view = await repo.create(
        companyId: 'co',
        entityType: EntityType.client,
        name: 'X',
        snapshot: {'search': 'old'},
      );
      await repo.updateSnapshot(viewId: view.id, snapshot: {'search': 'new'});
      final reloaded = (await repo.watchAll('co').first).single;
      expect(reloaded.id, view.id);
      expect(reloaded.name, 'X');
      expect(reloaded.snapshot['search'], 'new');
    });
  });
}
