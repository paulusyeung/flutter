import 'package:flutter/material.dart' show Icons;

import '../data/db/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/client_sync_dispatcher.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/statics_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/clients_api.dart';
import '../data/services/password_cache.dart';
import '../data/services/statics_service.dart';
import '../data/services/token_storage.dart';
import '../domain/entity_registry.dart';
import '../domain/entity_type.dart';
import '../domain/sync/mutation.dart';

/// The bag of singletons the app builds on startup. Provided via
/// `Provider<Services>` so ViewModels can read what they need without
/// hand-wiring every constructor.
///
/// Not a service locator — anything beyond app bootstrap should still take
/// its dependencies via constructor injection (ViewModel ctors do this).
class Services {
  Services._({
    required this.db,
    required this.auth,
    required this.clients,
    required this.statics,
    required this.settings,
    required this.sync,
    required this.passwordCache,
    required this.apiClient,
  });

  final AppDatabase db;
  final AuthRepository auth;
  final ClientRepository clients;
  final StaticsRepository statics;
  final SettingsRepository settings;
  final SyncRepository sync;
  final PasswordCache passwordCache;
  final ApiClient apiClient;

  /// Construct the full graph. The DB is passed in so `main.dart` can pick
  /// the open-with-recovery code path and surface a banner if needed.
  static Services build({
    required AppDatabase db,
    TokenStorage? tokenStorage,
  }) {
    final passwordCache = PasswordCache();
    final authService = AuthService();
    final auth = AuthRepository(
      db: db,
      authService: authService,
      tokenStorage: tokenStorage ?? SecureTokenStorage(),
    );
    final apiClient = ApiClient(
      credentials: auth.credentials,
      passwordCache: passwordCache,
      onUnauthorized: auth.logout,
    );
    final clientsApi = ClientsApi(apiClient);
    final clientRepo = ClientRepository(db: db, api: clientsApi);
    final statics = StaticsRepository(
      db: db,
      service: StaticsService(apiClient),
    );
    final settings = SettingsRepository(db: db);
    final registry = EntityRegistry({
      EntityType.client: EntityHandlers(
        type: EntityType.client,
        wireName: 'client',
        apiPath: '/api/v1/clients',
        routePath: '/clients',
        icon: Icons.people,
        requiresPasswordFor: const {MutationKind.delete},
        dispatcher: ClientSyncDispatcher(api: clientsApi, repo: clientRepo),
      ),
    });
    final sync = SyncRepository(db: db, registry: registry);
    return Services._(
      db: db,
      auth: auth,
      clients: clientRepo,
      statics: statics,
      settings: settings,
      sync: sync,
      passwordCache: passwordCache,
      apiClient: apiClient,
    );
  }
}
