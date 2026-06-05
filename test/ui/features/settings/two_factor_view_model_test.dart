import 'package:admin/data/models/api/two_factor_api_model.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/data/repositories/two_factor_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/features/settings/views/basic/user_details/view_models/two_factor_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stub repository — the VM's only collaborator. Records every call so each
/// test can assert that the state-machine transitions actually wired up to
/// the right repo methods with the right args.
class _FakeRepo implements TwoFactorRepository {
  TwoFactorSetupApi setup = const TwoFactorSetupApi(
    qrCode: 'aGVsbG8=',
    secret: 'JBSWY3DPEHPK3PXP',
  );
  Object? fetchError;
  Object? confirmError;
  Object? smsSendError;
  Object? smsVerifyError;
  Object? disableError;

  final calls = <String>[];
  String? lastOtp;
  String? lastPhoneVerified;
  String? lastSmsEmail;

  @override
  Future<TwoFactorSetupApi> fetchSetup() async {
    calls.add('fetchSetup');
    final err = fetchError;
    if (err != null) throw err;
    return setup;
  }

  @override
  Future<void> confirmEnable({
    required String secret,
    required String oneTimePassword,
  }) async {
    calls.add('confirmEnable');
    lastOtp = oneTimePassword;
    final err = confirmError;
    if (err != null) throw err;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    final err = disableError;
    if (err != null) throw err;
  }

  @override
  Future<void> sendSmsCode({required String email}) async {
    calls.add('sendSmsCode');
    lastSmsEmail = email;
    final err = smsSendError;
    if (err != null) throw err;
  }

  @override
  Future<void> verifySmsCode({
    required String code,
    required String email,
    String? phone,
  }) async {
    calls.add('verifySmsCode');
    lastSmsEmail = email;
    lastPhoneVerified = phone;
    final err = smsVerifyError;
    if (err != null) throw err;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TwoFactorViewModel _build({
  required _FakeRepo repo,
  bool isHosted = false,
  bool enabled = false,
  bool verifiedPhone = false,
  String phone = '',
  String email = 'user@example.com',
}) => TwoFactorViewModel(
  repo: repo,
  isHosted: isHosted,
  email: email,
  initiallyEnabled: enabled,
  initiallyVerifiedPhone: verifiedPhone,
  initialPhone: phone,
);

AuthSession _session({
  bool isHosted = true,
  bool googleTwoFactor = false,
  bool verifiedPhone = false,
  String userEmail = 'user@example.com',
  String userPhone = '',
}) => AuthSession(
  baseUrl: 'https://test',
  isHosted: isHosted,
  accountId: 'a',
  companies: const [],
  currentCompanyId: '',
  googleTwoFactorEnabled: googleTwoFactor,
  verifiedPhoneNumber: verifiedPhone,
  userEmail: userEmail,
  userPhone: userPhone,
);

void main() {
  late _FakeRepo repo;
  setUp(() {
    repo = _FakeRepo();
  });

  group('startEnable', () {
    test('self-hosted skips phone verification and loads the QR', () async {
      final vm = _build(repo: repo);
      await vm.startEnable();
      expect(repo.calls, ['fetchSetup']);
      expect(vm.step, TwoFactorStep.qrShow);
      expect(vm.secret, 'JBSWY3DPEHPK3PXP');
      expect(vm.qrCode, 'aGVsbG8=');
    });

    test('hosted + verified phone also skips phone verification', () async {
      final vm = _build(repo: repo, isHosted: true, verifiedPhone: true);
      await vm.startEnable();
      expect(repo.calls, ['fetchSetup']);
      expect(vm.step, TwoFactorStep.qrShow);
    });

    test(
      'hosted + unverified + no phone on file stays idle with error',
      () async {
        final vm = _build(repo: repo, isHosted: true);
        await vm.startEnable();
        expect(repo.calls, isEmpty);
        expect(vm.step, TwoFactorStep.idle);
        expect(vm.errorKey, 'enter_phone_to_enable_two_factor');
      },
    );

    test('hosted + unverified + phone on file shows the phone step', () async {
      final vm = _build(repo: repo, isHosted: true, phone: '+15551234');
      await vm.startEnable();
      expect(repo.calls, isEmpty);
      expect(vm.step, TwoFactorStep.phoneEntry);
    });
  });

  group('phone + sms flow (hosted)', () {
    test('happy path: phone on file → SMS (by email) → QR', () async {
      final vm = _build(repo: repo, isHosted: true, phone: '+15551234');
      await vm.startEnable();
      expect(vm.step, TwoFactorStep.phoneEntry);
      await vm.sendSmsCode();
      expect(vm.step, TwoFactorStep.smsVerify);
      expect(repo.lastSmsEmail, 'user@example.com');

      vm.setSmsCode('000000');
      await vm.verifySmsCode();
      expect(vm.step, TwoFactorStep.qrShow);
      expect(vm.verifiedPhone, isTrue);
      expect(repo.lastPhoneVerified, '+15551234');
      expect(repo.lastSmsEmail, 'user@example.com');
      expect(repo.calls, ['sendSmsCode', 'verifySmsCode', 'fetchSetup']);
    });

    test(
      'verifySmsCode 422 keeps the step on smsVerify with fieldErrors',
      () async {
        repo.smsVerifyError = const ValidationException('bad', {
          'code': ['Invalid code'],
        });
        final vm = _build(repo: repo, isHosted: true, phone: '+1');
        await vm.startEnable();
        await vm.sendSmsCode();
        vm.setSmsCode('000000');
        await vm.verifySmsCode();
        expect(vm.step, TwoFactorStep.smsVerify);
        expect(vm.fieldErrors['code'], ['Invalid code']);
        expect(vm.verifiedPhone, isFalse);
      },
    );
  });

  group('confirmEnable', () {
    test('flips enabled=true and returns to idle on success', () async {
      final vm = _build(repo: repo);
      await vm.startEnable();
      vm.setOneTimePassword('123456');
      await vm.confirmEnable();
      expect(vm.enabled, isTrue);
      expect(vm.step, TwoFactorStep.idle);
      expect(repo.lastOtp, '123456');
      expect(
        vm.oneTimePassword,
        '',
        reason: 'OTP buffer is cleared on success',
      );
    });

    test('422 surfaces field errors and stays on qrShow', () async {
      repo.confirmError = const ValidationException('invalid', {
        'one_time_password': ['Invalid code'],
      });
      final vm = _build(repo: repo);
      await vm.startEnable();
      vm.setOneTimePassword('999999');
      await vm.confirmEnable();
      expect(vm.enabled, isFalse);
      expect(vm.step, TwoFactorStep.qrShow);
      expect(vm.fieldErrors['one_time_password'], ['Invalid code']);
    });

    test('empty OTP reaches the server (no client-side validation)', () async {
      repo.confirmError = const ValidationException('invalid', {
        'one_time_password': ['The one time password field is required.'],
      });
      final vm = _build(repo: repo);
      await vm.startEnable();
      // Don't set the OTP.
      await vm.confirmEnable();
      expect(repo.calls, ['fetchSetup', 'confirmEnable']);
      expect(vm.fieldErrors['one_time_password'], [
        'The one time password field is required.',
      ]);
    });

    test(
      'non-ApiException surfaces as errorMessage instead of bubbling',
      () async {
        repo.confirmError = StateError('unexpected');
        final vm = _build(repo: repo);
        await vm.startEnable();
        vm.setOneTimePassword('123456');
        await vm.confirmEnable();
        expect(vm.enabled, isFalse);
        expect(vm.errorMessage, contains('unexpected'));
      },
    );
  });

  group('disable', () {
    test('flips enabled=false on success', () async {
      final vm = _build(repo: repo, enabled: true);
      await vm.disable();
      expect(vm.enabled, isFalse);
      expect(vm.step, TwoFactorStep.idle);
      expect(vm.needsPassword, isFalse);
    });

    test('preserves enabled=true on failure and surfaces message', () async {
      repo.disableError = const ServerException(500, 'oops');
      final vm = _build(repo: repo, enabled: true);
      await vm.disable();
      expect(vm.enabled, isTrue);
      expect(vm.errorMessage, 'oops');
    });

    test(
      'PasswordRequiredException flips needsPassword without an error toast',
      () async {
        repo.disableError = const PasswordRequiredException();
        final vm = _build(repo: repo, enabled: true);
        await vm.disable();
        expect(vm.needsPassword, isTrue);
        expect(vm.enabled, isTrue, reason: '2FA stays on until retry succeeds');
        expect(
          vm.errorMessage,
          isNull,
          reason: 'no toast — screen prompts for the password',
        );
      },
    );

    test('successful retry after password supplied flips enabled', () async {
      repo.disableError = const PasswordRequiredException();
      final vm = _build(repo: repo, enabled: true);
      await vm.disable();
      expect(vm.needsPassword, isTrue);

      repo.disableError = null;
      await vm.disable();
      expect(vm.enabled, isFalse);
      expect(vm.needsPassword, isFalse);
    });

    test(
      'non-ApiException surfaces as errorMessage instead of bubbling',
      () async {
        repo.disableError = StateError('unexpected');
        final vm = _build(repo: repo, enabled: true);
        await vm.disable();
        expect(vm.enabled, isTrue);
        expect(vm.errorMessage, contains('unexpected'));
      },
    );
  });

  group('syncFromSession', () {
    test('idle + flag flipped on server picks up the new value', () async {
      final vm = _build(repo: repo);
      vm.syncFromSession(_session(googleTwoFactor: true));
      expect(vm.enabled, isTrue);
    });

    test('mid-flow (qrShow) is a no-op — does not yank state', () async {
      final vm = _build(repo: repo);
      await vm.startEnable();
      expect(vm.step, TwoFactorStep.qrShow);
      vm.syncFromSession(_session(googleTwoFactor: true));
      expect(vm.enabled, isFalse, reason: 'mid-flow sync is ignored');
      expect(vm.step, TwoFactorStep.qrShow);
    });

    test('no-op when session matches current state (no notify)', () async {
      final vm = _build(repo: repo, enabled: true);
      var notified = false;
      vm.addListener(() => notified = true);
      vm.syncFromSession(_session(googleTwoFactor: true));
      expect(notified, isFalse);
    });

    test(
      'idle picks up a phone saved later — unblocks the enable flow',
      () async {
        // Hosted user opens 2FA with no phone on file → blocked at idle.
        final vm = _build(repo: repo, isHosted: true);
        await vm.startEnable();
        expect(vm.step, TwoFactorStep.idle);
        expect(vm.errorKey, 'enter_phone_to_enable_two_factor');

        // They set + save a phone in Details; the refreshed session flows in.
        vm.syncFromSession(_session(userPhone: '+15551234'));
        expect(vm.phone, '+15551234');

        // Enable now advances to the SMS step instead of re-blocking.
        await vm.startEnable();
        expect(vm.step, TwoFactorStep.phoneEntry);
      },
    );
  });

  test('cancel drops in-progress QR state and returns to idle', () async {
    final vm = _build(repo: repo);
    await vm.startEnable();
    vm.setOneTimePassword('123456');
    expect(vm.step, TwoFactorStep.qrShow);

    vm.cancel();
    expect(vm.step, TwoFactorStep.idle);
    expect(vm.oneTimePassword, '');
    expect(vm.qrCode, '');
  });
}
