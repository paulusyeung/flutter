import 'package:admin/data/models/api/two_factor_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/two_factor_repository.dart';
import 'package:admin/data/services/two_factor_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures every call so each test can assert exactly what hit the wire.
class _FakeApi implements TwoFactorApi {
  TwoFactorSetupApi setup = const TwoFactorSetupApi(
    qrCode: 'aGVsbG8=', // "hello"
    secret: 'JBSWY3DPEHPK3PXP',
  );
  Object? nextError;

  final calls = <String>[];
  final List<Map<String, String>> bodies = [];

  Future<T> _run<T>(String name, T value, [Map<String, String>? body]) async {
    calls.add(name);
    if (body != null) bodies.add(body);
    final err = nextError;
    if (err != null) {
      nextError = null;
      throw err;
    }
    return value;
  }

  @override
  Future<TwoFactorSetupApi> fetchSetup() => _run('fetchSetup', setup);

  @override
  Future<void> confirmEnable({
    required String secret,
    required String oneTimePassword,
  }) => _run<void>('confirmEnable', null, {
    'secret': secret,
    'one_time_password': oneTimePassword,
  });

  @override
  Future<void> disable() => _run<void>('disable', null);

  @override
  Future<void> sendSmsCode({required String email}) =>
      _run<void>('sendSmsCode', null, {'email': email});

  @override
  Future<void> verifySmsCode({required String code, required String email}) =>
      _run<void>('verifySmsCode', null, {'code': code, 'email': email});

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Captures every session-flip call so each test can check the
/// in-memory propagation contract.
class _FakeAuth implements AuthRepository {
  bool? lastEnabledFlip;
  bool phoneVerifiedCalled = false;
  String? lastVerifiedPhone;
  int refreshCount = 0;

  @override
  void markTwoFactorEnabled(bool enabled) {
    lastEnabledFlip = enabled;
  }

  @override
  void markPhoneVerified({String? phone}) {
    phoneVerifiedCalled = true;
    lastVerifiedPhone = phone;
  }

  @override
  Future<void> refreshSession({bool fullSync = false}) async {
    refreshCount++;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeApi api;
  late _FakeAuth auth;
  late TwoFactorRepository repo;

  setUp(() {
    api = _FakeApi();
    auth = _FakeAuth();
    repo = TwoFactorRepository(api: api, auth: auth);
  });

  test('fetchSetup forwards to api', () async {
    final setup = await repo.fetchSetup();
    expect(setup.secret, 'JBSWY3DPEHPK3PXP');
    expect(api.calls, ['fetchSetup']);
  });

  test(
    'confirmEnable flips session flag and kicks a background refresh',
    () async {
      await repo.confirmEnable(secret: 's', oneTimePassword: '123456');

      expect(api.calls, ['confirmEnable']);
      expect(api.bodies.single, {'secret': 's', 'one_time_password': '123456'});
      expect(auth.lastEnabledFlip, isTrue);
      // refreshSession is fire-and-forget — yield once so the microtask runs.
      await Future<void>.delayed(Duration.zero);
      expect(auth.refreshCount, 1);
    },
  );

  test('confirmEnable bubbles errors and does NOT flip the flag', () async {
    api.nextError = StateError('boom');
    await expectLater(
      () => repo.confirmEnable(secret: 's', oneTimePassword: '123456'),
      throwsStateError,
    );
    expect(
      auth.lastEnabledFlip,
      isNull,
      reason: 'failed confirm must leave the session untouched',
    );
  });

  test('disable flips the flag off and refreshes', () async {
    await repo.disable();
    expect(auth.lastEnabledFlip, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(auth.refreshCount, 1);
  });

  test('verifySmsCode forwards code+email and marks phone verified', () async {
    await repo.verifySmsCode(
      code: '000000',
      email: 'user@example.com',
      phone: '+15551234',
    );
    expect(api.bodies.single, {'code': '000000', 'email': 'user@example.com'});
    expect(auth.phoneVerifiedCalled, isTrue);
    expect(auth.lastVerifiedPhone, '+15551234');
  });

  test('sendSmsCode passes the email payload through', () async {
    await repo.sendSmsCode(email: 'user@example.com');
    expect(api.bodies.single, {'email': 'user@example.com'});
  });
}
