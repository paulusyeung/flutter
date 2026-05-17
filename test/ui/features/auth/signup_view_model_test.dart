import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/auth_service.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/ui/features/auth/view_models/signup_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local validation gates the network call: an obviously-bad signup must
/// never reach the wire. If `signup` is hit, validation let something
/// through that shouldn't have.
class _GuardAuthService implements AuthService {
  @override
  Future<LoginResponseApi> signup({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String referralCode = '',
  }) async {
    fail('signup should not be called when local validation rejects');
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late AuthRepository auth;
  late SignupViewModel vm;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = AuthRepository(
      db: db,
      authService: _GuardAuthService(),
      tokenStorage: InMemoryTokenStorage(),
      passwordCache: PasswordCache(),
    );
    vm = SignupViewModel(auth: auth);
  });
  tearDown(() async {
    await db.close();
  });

  group('SignupViewModel local validation (no network)', () {
    test('empty email or password → please_fill_out_all_fields', () async {
      vm.setPassword('pw');
      vm.setConfirmPassword('pw');
      vm.setAcceptedTerms(true);
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'please_fill_out_all_fields');

      vm.setEmail('a@b.test');
      vm.setPassword('');
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'please_fill_out_all_fields');
    });

    test('password mismatch → passwords_do_not_match', () async {
      vm.setEmail('a@b.test');
      vm.setPassword('pw123456');
      vm.setConfirmPassword('different');
      vm.setAcceptedTerms(true);
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'passwords_do_not_match');
    });

    test('terms not accepted → accept_terms_to_continue', () async {
      vm.setEmail('a@b.test');
      vm.setPassword('pw123456');
      vm.setConfirmPassword('pw123456');
      // acceptedTerms defaults false
      expect(await vm.submit(), isFalse);
      expect(vm.errorKey, 'accept_terms_to_continue');
    });

    test('valid input passes local gates and reaches the service '
        '(guard fails → proves no early rejection)', () async {
      vm.setEmail('a@b.test');
      vm.setPassword('pw123456');
      vm.setConfirmPassword('pw123456');
      vm.setAcceptedTerms(true);
      // _GuardAuthService.signup calls fail() — reaching it means all local
      // gates passed, which is the assertion. Catch the TestFailure so the
      // test body completes deterministically.
      await expectLater(vm.submit(), throwsA(isA<TestFailure>()));
    });
  });
}
