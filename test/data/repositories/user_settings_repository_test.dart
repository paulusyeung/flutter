import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests pin the wire format the new app uses for column preferences
/// — it has to match the old admin-portal exactly so customisations sync.

void main() {
  late AppDatabase db;
  late UserSettingsRepository repo;
  const companyId = 'co1';
  const userId = 'user1';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserSettingsRepository(db: db);
    // Simulate the login-time hydration the auth repo does.
    await db.userSettingsDao.upsert(
      UserSettingsCompanion(
        companyId: const Value(companyId),
        userId: const Value(userId),
        tableColumnsJson: const Value('{}'),
        extraJson: Value(jsonEncode({'accent_color': '#ff0000'})),
        updatedAt: const Value(0),
      ),
    );
  });
  tearDown(() async {
    await db.close();
  });

  group('table_columns wire format', () {
    test('map key is the literal "EntityType.client" toString', () async {
      await repo.setColumns(
        companyId: companyId,
        entityType: EntityType.client,
        columns: const ['name', 'balance'],
      );
      final row = await db.userSettingsDao.get(companyId);
      final stored = jsonDecode(row!.tableColumnsJson) as Map<String, dynamic>;
      expect(stored.keys, contains('EntityType.client'));
      expect(stored['EntityType.client'], equals(['name', 'balance']));
    });

    test('watchColumns emits the saved list for the entity type', () async {
      await repo.setColumns(
        companyId: companyId,
        entityType: EntityType.client,
        columns: const ['number', 'name', 'balance'],
      );
      final emitted = await repo
          .watchColumns(companyId: companyId, entityType: EntityType.client)
          .first;
      expect(emitted, ['number', 'name', 'balance']);
    });

    test('resetColumns removes the entity key from table_columns', () async {
      await repo.setColumns(
        companyId: companyId,
        entityType: EntityType.client,
        columns: const ['name'],
      );
      await repo.resetColumns(
        companyId: companyId,
        entityType: EntityType.client,
      );
      final row = await db.userSettingsDao.get(companyId);
      final stored = jsonDecode(row!.tableColumnsJson) as Map<String, dynamic>;
      expect(stored.containsKey('EntityType.client'), isFalse);
    });

    test('unknown table_columns keys preserved across writes', () async {
      // Simulate the server having a column list for an entity this app
      // doesn't model yet — it must round-trip untouched.
      await db.userSettingsDao.upsert(
        UserSettingsCompanion(
          companyId: const Value(companyId),
          userId: const Value(userId),
          tableColumnsJson: Value(
            jsonEncode({
              'EntityType.invoice': ['number', 'amount'],
              'EntityType.client': ['name'],
            }),
          ),
          extraJson: const Value('{}'),
          updatedAt: const Value(0),
        ),
      );
      await repo.setColumns(
        companyId: companyId,
        entityType: EntityType.client,
        columns: const ['name', 'balance'],
      );
      final row = await db.userSettingsDao.get(companyId);
      final stored = jsonDecode(row!.tableColumnsJson) as Map<String, dynamic>;
      expect(stored['EntityType.invoice'], ['number', 'amount']);
      expect(stored['EntityType.client'], ['name', 'balance']);
    });
  });

  group('outbox enqueue', () {
    test(
      'enqueues an update_user_settings row with the full PUT body',
      () async {
        await repo.setColumns(
          companyId: companyId,
          entityType: EntityType.client,
          columns: const ['name', 'balance'],
        );
        final rows = await db.outboxDao.nextReady(
          companyId: companyId,
          now: DateTime.now().millisecondsSinceEpoch,
        );
        expect(rows, hasLength(1));
        final row = rows.first;
        expect(row.entityType, equals(kUserSettingsWireName));
        expect(row.entityId, equals(userId));
        expect(row.mutationKind, equals(MutationKind.update.wireName));
        final body = jsonDecode(row.payload) as Map<String, dynamic>;
        expect(body['id'], userId);
        final companyUser = body['company_user'] as Map<String, dynamic>;
        final settings = companyUser['settings'] as Map<String, dynamic>;
        // Round-trip the unrelated setting we seeded.
        expect(settings['accent_color'], '#ff0000');
        // And the new table_columns under the correct wire key.
        final tableColumns = settings['table_columns'] as Map<String, dynamic>;
        expect(tableColumns['EntityType.client'], ['name', 'balance']);
      },
    );

    test('rapid changes collapse into a single pending outbox row', () async {
      for (final cols in [
        ['name'],
        ['name', 'balance'],
        ['name', 'balance', 'paid_to_date'],
      ]) {
        await repo.setColumns(
          companyId: companyId,
          entityType: EntityType.client,
          columns: cols,
        );
      }
      final rows = await db.outboxDao.nextReady(
        companyId: companyId,
        now: DateTime.now().millisecondsSinceEpoch,
      );
      expect(rows, hasLength(1));
      final body = jsonDecode(rows.first.payload) as Map<String, dynamic>;
      final tc =
          (body['company_user']
                  as Map<String, dynamic>)['settings']['table_columns']
              as Map<String, dynamic>;
      expect(tc['EntityType.client'], ['name', 'balance', 'paid_to_date']);
    });
  });

  group('applyServerResponse', () {
    test(
      'overwrites local settings with the canonical server response',
      () async {
        await repo.applyServerResponse(
          companyId: companyId,
          response: {
            'data': {
              'user': {'id': userId},
              'settings': {
                'accent_color': '#00ff00',
                'table_columns': {
                  'EntityType.client': ['name', 'updated_at'],
                },
              },
            },
          },
        );
        final row = await db.userSettingsDao.get(companyId);
        expect(row!.userId, userId);
        final tc = jsonDecode(row.tableColumnsJson) as Map<String, dynamic>;
        expect(tc['EntityType.client'], ['name', 'updated_at']);
        final extra = jsonDecode(row.extraJson) as Map<String, dynamic>;
        expect(extra['accent_color'], '#00ff00');
        expect(extra.containsKey('table_columns'), isFalse);
      },
    );
  });
}
