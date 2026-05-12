import 'package:flutter/foundation.dart';

import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/data/repositories/two_factor_repository.dart';
import 'package:admin/data/services/api_exception.dart';

/// Drives the 2FA settings screen.
///
/// State machine — only one section of the UI renders at a time, picked by
/// [TwoFactorStep]:
///
///   idle           shows status + Enable/Disable button (initial)
///   phoneEntry     (hosted, !verifiedPhoneNumber) phone field + Send Code
///   smsVerify      (hosted) sms code field + Verify + Resend
///   qrLoading      fetching the QR / secret from the server
///   qrShow         QR image + secret + OTP input + Confirm
///   disabling      POST disable_two_factor in flight
///
/// Errors:
///   * [fieldErrors] holds 422 `errors.<fieldName>` lists so the screen can
///     bind them inline to the matching `_InField`.
///   * [errorMessage] / [errorKey] is the toast-level message for everything
///     else.
enum TwoFactorStep { idle, phoneEntry, smsVerify, qrLoading, qrShow, disabling }

class TwoFactorViewModel extends ChangeNotifier {
  TwoFactorViewModel({
    required this.repo,
    required this.isHosted,
    required bool initiallyEnabled,
    required bool initiallyVerifiedPhone,
    String initialPhone = '',
  }) : _enabled = initiallyEnabled,
       _verifiedPhone = initiallyVerifiedPhone,
       phone = initialPhone;

  final TwoFactorRepository repo;
  final bool isHosted;

  // Live, screen-driven state.
  bool _enabled;
  bool get enabled => _enabled;

  bool _verifiedPhone;
  bool get verifiedPhone => _verifiedPhone;

  TwoFactorStep _step = TwoFactorStep.idle;
  TwoFactorStep get step => _step;

  bool _busy = false;
  bool get busy => _busy;

  /// Set by [disable] when the server / [ApiClient] reports the password
  /// cache is empty. The screen reads this immediately after `disable()` to
  /// decide whether to prompt for the password and retry. Reset on every
  /// call to `disable()`.
  bool _needsPassword = false;
  bool get needsPassword => _needsPassword;

  // Form fields.
  String phone;
  String smsCode = '';
  String oneTimePassword = '';

  // Server-supplied QR data — populated on the qrLoading → qrShow transition.
  String qrCodeBase64 = '';
  String secret = '';

  // Errors.
  Map<String, List<String>> _fieldErrors = const {};
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  String? _errorKey;
  String? get errorKey => _errorKey;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setError({String? key, String? message}) {
    _errorKey = key;
    _errorMessage = message;
  }

  void _clearError() {
    _errorKey = null;
    _errorMessage = null;
    _fieldErrors = const {};
  }

  void setPhone(String value) {
    phone = value.trim();
  }

  void setSmsCode(String value) {
    smsCode = value.trim();
  }

  void setOneTimePassword(String value) {
    oneTimePassword = value.trim();
  }

  /// User tapped "Enable 2FA" on the idle screen.
  ///
  /// Self-hosted, or hosted with a verified phone, jumps straight to the
  /// QR-fetch step. Hosted-without-phone-verified shows the phone field.
  Future<void> startEnable() async {
    if (_busy) return;
    _clearError();
    if (isHosted && !_verifiedPhone) {
      _step = TwoFactorStep.phoneEntry;
      notifyListeners();
      return;
    }
    await _loadQr();
  }

  /// Hosted phone-entry step → send SMS code. Validates non-empty locally so
  /// we don't hit the server with an obviously bad request.
  Future<void> sendSmsCode() async {
    if (_busy) return;
    if (phone.isEmpty) {
      _setError(key: 'enter_phone_number');
      notifyListeners();
      return;
    }
    _busy = true;
    _clearError();
    notifyListeners();
    try {
      await repo.sendSmsCode(phone: phone);
      _step = TwoFactorStep.smsVerify;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _setError(message: e.message);
    } on ApiException catch (e) {
      _setError(message: e.message);
    } catch (e) {
      _setError(message: e.toString());
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// SMS-verify step → confirm code, on success transition into qrLoading.
  Future<void> verifySmsCode() async {
    if (_busy) return;
    if (smsCode.isEmpty) {
      _setError(key: 'enter_sms_code');
      notifyListeners();
      return;
    }
    _busy = true;
    _clearError();
    notifyListeners();
    try {
      await repo.verifySmsCode(code: smsCode, phone: phone);
      _verifiedPhone = true;
      await _loadQr();
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _setError(message: e.message);
      _busy = false;
      notifyListeners();
    } on ApiException catch (e) {
      _setError(message: e.message);
      _busy = false;
      notifyListeners();
    } catch (e) {
      _setError(message: e.toString());
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _loadQr() async {
    _busy = true;
    _step = TwoFactorStep.qrLoading;
    notifyListeners();
    try {
      final setup = await repo.fetchSetup();
      qrCodeBase64 = setup.qrCode;
      secret = setup.secret;
      _step = TwoFactorStep.qrShow;
    } on ApiException catch (e) {
      _setError(message: e.message);
      _step = TwoFactorStep.idle;
    } catch (e) {
      _setError(message: e.toString());
      _step = TwoFactorStep.idle;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// QR step → confirm enablement with the 6-digit code.
  ///
  /// No client-side empty-OTP check — the server returns a localized 422
  /// (`errors.one_time_password = [...]`) when the field is missing, and the
  /// screen binds those messages inline to the input. A locally-emitted
  /// "Required" string would never be translated.
  Future<void> confirmEnable() async {
    if (_busy) return;
    _busy = true;
    _clearError();
    notifyListeners();
    try {
      await repo.confirmEnable(
        secret: secret,
        oneTimePassword: oneTimePassword,
      );
      _enabled = true;
      _step = TwoFactorStep.idle;
      oneTimePassword = '';
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _setError(message: e.message);
    } on ApiException catch (e) {
      _setError(message: e.message);
    } catch (e) {
      _setError(message: e.toString());
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Disable 2FA. Caller is responsible for confirming via dialog first.
  ///
  /// On [PasswordRequiredException] (no password in the cache), sets
  /// [needsPassword] = true and returns without an error message — the screen
  /// re-prompts and calls `disable()` again with a populated cache.
  Future<void> disable() async {
    if (_busy) return;
    _needsPassword = false;
    _busy = true;
    _step = TwoFactorStep.disabling;
    _clearError();
    notifyListeners();
    try {
      await repo.disable();
      _enabled = false;
    } on PasswordRequiredException {
      _needsPassword = true;
    } on ApiException catch (e) {
      _setError(message: e.message);
    } catch (e) {
      _setError(message: e.toString());
    } finally {
      _step = TwoFactorStep.idle;
      _busy = false;
      notifyListeners();
    }
  }

  /// Pick up new session-level 2FA flags (e.g. after a cold-start
  /// `/refresh` lands, or another device flips the bit). No-op when the
  /// user is mid-flow — yanking state out from under an in-progress enable
  /// would be confusing.
  void syncFromSession(AuthSession session) {
    if (_step != TwoFactorStep.idle) return;
    final newEnabled = session.googleTwoFactorEnabled;
    final newVerifiedPhone = session.verifiedPhoneNumber;
    if (newEnabled == _enabled && newVerifiedPhone == _verifiedPhone) return;
    _enabled = newEnabled;
    _verifiedPhone = newVerifiedPhone;
    notifyListeners();
  }

  /// Back out to the status screen. Cheap — drops the in-progress QR/secret
  /// values so a second enable attempt starts from scratch.
  void cancel() {
    if (_busy) return;
    _step = TwoFactorStep.idle;
    smsCode = '';
    oneTimePassword = '';
    qrCodeBase64 = '';
    secret = '';
    _clearError();
    notifyListeners();
  }
}
