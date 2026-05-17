import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// End-to-end proof that `AuthRepository.signup` reuses the same
/// session-activation tail as `login`: a real `AuthService` (MockClient
/// returning the standard login envelope) → `_persistAndActivate` →
/// session + credentials + secure-storage tokens. Kept in its own file so
/// it doesn't touch the large, concurrently-edited `auth_repository_test`.
String _envelopeJson() => jsonEncode({
      'data': [
        {
          'is_admin': true,
          'is_owner': true,
          'permissions': 'view_client',
          'user': {'id': 'user_1'},
          'company': {'id': 'co_1', 'name': 'Acme'},
          'token': {'token': 'tok_1'},
          'account': {
            'id': 'acct_1',
            'default_company_id': 'co_1',
            'plan': 'pro',
            'num_trial_days': 14,
          },
        },
      ],
    });

void main() {
  late AppDatabase db;
  late InMemoryTokenStorage storage;
  late AuthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    storage = InMemoryTokenStorage();
  });
  tearDown(() async {
    await db.close();
  });

  test('signup activates the session exactly like login', () async {
    Uri? url;
    final svc = AuthService(
      httpClient: MockClient((req) async {
        url = req.url;
        return http.Response(
          _envelopeJson(),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );
    repo = AuthRepository(
      db: db,
      authService: svc,
      tokenStorage: storage,
      passwordCache: PasswordCache(),
    );

    await repo.signup(
      baseUrl: 'https://test',
      isHosted: true,
      email: 'new@user.test',
      password: 'pw123456',
    );

    expect(url!.path, '/api/v1/signup');
    // Session + credentials primed by the shared _persistAndActivate tail.
    expect(repo.session.value, isNotNull);
    expect(repo.session.value!.currentCompanyId, 'co_1');
    expect(repo.credentials.value!.token, 'tok_1');
    expect(repo.credentials.value!.baseUrl, 'https://test');
    expect(repo.isAuthenticated, isTrue);

    // Tokens reach secure storage (same path as login).
    final raw = await storage.read('invoiceninja.tokens.v1');
    expect(raw, isNotNull);
    expect(jsonDecode(raw!) as Map<String, dynamic>, {'co_1': 'tok_1'});

    // Company + account landed in Drift.
    expect((await db.companiesDao.all()).map((c) => c.id), contains('co_1'));
    expect((await db.companiesDao.account())?.id, 'acct_1');
  });
}
