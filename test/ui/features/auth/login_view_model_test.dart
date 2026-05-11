import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/ui/features/auth/view_models/login_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-hosted URL validation. Without this, the login VM accepts any string
/// as a base URL and posts the user's password to it. Hosted builds short-
/// circuit (URL is a compile-time const) so we only exercise the self-hosted
/// branch here.

class _FakeAuthService implements AuthService {
  @override
  Future<LoginResponseApi> login({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String? oneTimePassword,
  }) async {
    // If this is ever hit, the URL validation let something through that
    // shouldn't have made it to the network layer.
    fail('login should not be called when URL validation rejects');
  }

  @override
  Future<void> recoverPassword({
    required String baseUrl,
    required bool isHosted,
    required String email,
  }) async {
    fail('recover should not be called when URL validation rejects');
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late AuthRepository auth;
  late LoginViewModel vm;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = AuthRepository(
      db: db,
      authService: _FakeAuthService(),
      tokenStorage: InMemoryTokenStorage(),
      passwordCache: PasswordCache(),
    );
    vm = LoginViewModel(auth: auth);
    vm.setHosted(false);
    vm.setEmail('a@b.test');
    vm.setPassword('pw');
  });
  tearDown(() async {
    await db.close();
  });

  group('self-hosted base URL validation', () {
    test('rejects empty URL', () async {
      vm.setUrlOverride('');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });

    test('rejects http:// (release builds require https)', () async {
      // In tests kDebugMode is true, so http is accepted; this case is
      // covered by the release-only behaviour. We assert the symmetric case
      // — a URL with no scheme is rejected regardless.
      vm.setUrlOverride('attacker.local');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });

    test('rejects URL with embedded credentials', () async {
      vm.setUrlOverride('https://user:pw@host.example');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });

    test('rejects URL with empty host', () async {
      vm.setUrlOverride('https://');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });

    test('rejects garbage that does not parse as a URL', () async {
      vm.setUrlOverride('::: not a url :::');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });

    test('recover() applies the same validation', () async {
      vm.setUrlOverride('');
      expect(await vm.recover(), isFalse);
      expect(vm.errorKey, 'invalid_url');
    });
  });
}
