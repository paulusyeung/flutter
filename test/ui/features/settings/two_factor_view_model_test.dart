import 'package:admin/data/models/api/two_factor_api_model.dart';
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
  Future<void> sendSmsCode({required String phone}) async {
    calls.add('sendSmsCode');
    final err = smsSendError;
    if (err != null) throw err;
  }

  @override
  Future<void> verifySmsCode({required String code, String? phone}) async {
    calls.add('verifySmsCode');
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
}) => TwoFactorViewModel(
  repo: repo,
  isHosted: isHosted,
  initiallyEnabled: enabled,
  initiallyVerifiedPhone: verifiedPhone,
  initialPhone: phone,
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
      expect(vm.qrCodeBase64, 'aGVsbG8=');
    });

    test('hosted + verified phone also skips phone verification', () async {
      final vm = _build(repo: repo, isHosted: true, verifiedPhone: true);
      await vm.startEnable();
      expect(repo.calls, ['fetchSetup']);
      expect(vm.step, TwoFactorStep.qrShow);
    });

    test('hosted + unverified phone shows the phone entry step', () async {
      final vm = _build(repo: repo, isHosted: true);
      await vm.startEnable();
      expect(repo.calls, isEmpty);
      expect(vm.step, TwoFactorStep.phoneEntry);
    });
  });

  group('phone + sms flow (hosted)', () {
    test('rejects an empty phone with an inline error key', () async {
      final vm = _build(repo: repo, isHosted: true);
      await vm.startEnable();
      await vm.sendSmsCode();
      expect(vm.errorKey, 'enter_phone_number');
      expect(repo.calls, isEmpty);
    });

    test('happy path: phone → SMS code → QR', () async {
      final vm = _build(repo: repo, isHosted: true);
      await vm.startEnable();
      vm.setPhone('+15551234');
      await vm.sendSmsCode();
      expect(vm.step, TwoFactorStep.smsVerify);

      vm.setSmsCode('000000');
      await vm.verifySmsCode();
      expect(vm.step, TwoFactorStep.qrShow);
      expect(vm.verifiedPhone, isTrue);
      expect(repo.lastPhoneVerified, '+15551234');
      expect(repo.calls, ['sendSmsCode', 'verifySmsCode', 'fetchSetup']);
    });

    test(
      'verifySmsCode 422 keeps the step on smsVerify with fieldErrors',
      () async {
        repo.smsVerifyError = const ValidationException('bad', {
          'sms_code': ['Invalid code'],
        });
        final vm = _build(repo: repo, isHosted: true);
        await vm.startEnable();
        vm.setPhone('+1');
        await vm.sendSmsCode();
        vm.setSmsCode('000000');
        await vm.verifySmsCode();
        expect(vm.step, TwoFactorStep.smsVerify);
        expect(vm.fieldErrors['sms_code'], ['Invalid code']);
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

    test(
      'empty OTP refuses to call the server and sets inline error',
      () async {
        final vm = _build(repo: repo);
        await vm.startEnable();
        // Don't set the OTP.
        await vm.confirmEnable();
        expect(repo.calls, ['fetchSetup'], reason: 'no confirmEnable call');
        expect(vm.fieldErrors['one_time_password'], isNotEmpty);
      },
    );
  });

  group('disable', () {
    test('flips enabled=false on success', () async {
      final vm = _build(repo: repo, enabled: true);
      await vm.disable();
      expect(vm.enabled, isFalse);
      expect(vm.step, TwoFactorStep.idle);
    });

    test('preserves enabled=true on failure and surfaces message', () async {
      repo.disableError = const ServerException(500, 'oops');
      final vm = _build(repo: repo, enabled: true);
      await vm.disable();
      expect(vm.enabled, isTrue);
      expect(vm.errorMessage, 'oops');
    });
  });

  test('cancel drops in-progress QR state and returns to idle', () async {
    final vm = _build(repo: repo);
    await vm.startEnable();
    vm.setOneTimePassword('123456');
    expect(vm.step, TwoFactorStep.qrShow);

    vm.cancel();
    expect(vm.step, TwoFactorStep.idle);
    expect(vm.oneTimePassword, '');
    expect(vm.qrCodeBase64, '');
  });
}
