import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/services_design_handlers.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Drives the *real* `setDefaultDesignHandlers` factory (the one wired into the
/// Client + GroupSetting dispatchers) through a [BaseEntitySyncDispatcher] and
/// asserts it forwards the outbox payload to `CompaniesApi.setDefaultDesign`
/// with the correct scope args — `client_id` for client scope,
/// `group_settings_id` for group scope. Mirrors
/// `base_entity_sync_dispatcher_custom_action_test.dart`.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  ({
    BaseEntitySyncDispatcher<ClientItemApi, ClientApi> dispatcher,
    _RecordingCompaniesApi companies,
  })
  build() {
    final clientsApi = _NoopClientsApi();
    final companies = _RecordingCompaniesApi();
    final dispatcher = BaseEntitySyncDispatcher<ClientItemApi, ClientApi>(
      api: clientsApi,
      repo: ClientRepository(db: db, api: clientsApi),
      dataOf: (item) => item.data,
      // The factory is generic on TInner; the handler body is scope-agnostic,
      // so <ClientApi> exercises the same closure that <GroupSettingApi> wires.
      customActions: setDefaultDesignHandlers<ClientApi>(companies),
    );
    return (dispatcher: dispatcher, companies: companies);
  }

  OutboxRow row(Map<String, dynamic> payload, {String entityType = 'client'}) =>
      OutboxRow(
        id: 1,
        companyId: 'co',
        entityType: entityType,
        entityId:
            payload['client_id'] as String? ??
            payload['group_settings_id'] as String? ??
            'x',
        mutationKind: MutationKind.setDefaultDesign.wireName,
        payload: jsonEncode(payload),
        idempotencyKey: 'idk-1',
        state: 'pending',
        attempts: 0,
        nextAttemptAt: 0,
        createdAt: 0,
        requiresPassword: false,
      );

  test(
    'client scope → setDefaultDesign called with client_id, no group id',
    () async {
      final (:dispatcher, :companies) = build();

      await dispatcher.dispatch(
        row: row(const {
          'design_id': 'd7',
          'entity': 'invoice',
          'settings_level': 'client',
          'client_id': 'c1',
        }),
        kind: MutationKind.setDefaultDesign,
      );

      expect(companies.calls, 1);
      expect(companies.designId, 'd7');
      expect(companies.entity, 'invoice');
      expect(companies.settingsLevel, 'client');
      expect(companies.clientId, 'c1');
      expect(companies.groupSettingsId, isNull);
      expect(companies.idempotencyKey, 'idk-1');
    },
  );

  test('group scope → setDefaultDesign called with group_settings_id, no '
      'client id', () async {
    final (:dispatcher, :companies) = build();

    await dispatcher.dispatch(
      row: row(const {
        'design_id': 'd9',
        'entity': 'quote',
        'settings_level': 'group_settings',
        'group_settings_id': 'g1',
      }, entityType: 'group'),
      kind: MutationKind.setDefaultDesign,
    );

    expect(companies.calls, 1);
    expect(companies.designId, 'd9');
    expect(companies.entity, 'quote');
    expect(companies.settingsLevel, 'group_settings');
    expect(companies.groupSettingsId, 'g1');
    expect(companies.clientId, isNull);
  });
}

class _RecordingCompaniesApi implements CompaniesApi {
  int calls = 0;
  String? designId;
  String? entity;
  String? settingsLevel;
  String? clientId;
  String? groupSettingsId;
  String? idempotencyKey;

  @override
  Future<void> setDefaultDesign({
    required String designId,
    required String entity,
    required String settingsLevel,
    required String idempotencyKey,
    String? clientId,
    String? groupSettingsId,
  }) async {
    calls++;
    this.designId = designId;
    this.entity = entity;
    this.settingsLevel = settingsLevel;
    this.idempotencyKey = idempotencyKey;
    this.clientId = clientId;
    this.groupSettingsId = groupSettingsId;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '_RecordingCompaniesApi.${invocation.memberName}',
  );
}

class _NoopClientsApi implements ClientsApi {
  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_NoopClientsApi.${invocation.memberName}');
}
