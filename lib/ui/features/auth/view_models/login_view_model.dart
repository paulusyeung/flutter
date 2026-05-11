import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:admin/app/env.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/api_exception.dart';

/// Which credential flow the user picked. The two paths share most state
/// (hosted toggle, base URL) but call different repository methods on submit.
enum LoginMethod { email, apple }

/// State machine for the login screen.
///
/// The view binds to this and surfaces:
///   * the hosted/self-hosted toggle,
///   * the email/Apple method toggle,
///   * the URL field (only when self-hosted),
///   * loading / error / success states.
///
/// The OTP field is always rendered in the view; we send it only when
/// non-empty, so there is no `requiresOtp` flag here.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this.auth});

  final AuthRepository auth;

  /// True = use `Env.hostedApiUrl`; false = use [urlOverride].
  bool isHosted = true;

  /// Which sign-in flow the user picked.
  LoginMethod method = LoginMethod.email;

  String urlOverride = '';
  String email = '';
  String password = '';
  String oneTimePassword = '';

  bool _busy = false;
  bool get busy => _busy;

  // Localization key for the current error message. When set, the view
  // resolves it via `context.tr(errorKey!, errorParams)`. A null `errorKey`
  // with a non-null `errorMessage` means the message came back from the
  // server pre-formatted (validation / API messages) and is shown as-is.
  String? _errorKey;
  String? get errorKey => _errorKey;
  Map<String, String> _errorParams = const {};
  Map<String, String> get errorParams => _errorParams;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setError({String? key, Map<String, String>? params, String? message}) {
    _errorKey = key;
    _errorParams = params ?? const {};
    _errorMessage = message;
  }

  void _clearError() {
    _errorKey = null;
    _errorParams = const {};
    _errorMessage = null;
  }

  Map<String, List<String>> _fieldErrors = const {};
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  void setHosted(bool value) {
    if (isHosted == value) return;
    isHosted = value;
    // Self-hosted servers don't broker Apple sign-in — snap back to email.
    if (!value && method != LoginMethod.email) {
      method = LoginMethod.email;
    }
    notifyListeners();
  }

  void setMethod(LoginMethod value) {
    if (method == value) return;
    method = value;
    notifyListeners();
  }

  void setUrlOverride(String value) {
    urlOverride = value.trim();
  }

  void setEmail(String value) {
    email = value.trim();
  }

  void setPassword(String value) {
    password = value;
  }

  void setOneTimePassword(String value) {
    oneTimePassword = value.trim();
  }

  /// Validate the self-hosted URL before we POST credentials to it.
  /// Returns the resolved base URL on success, or sets an inline error and
  /// returns null. Hosted builds skip the check (URL is a compile-time const).
  ///
  /// Why: without this, `urlOverride` accepts any string and the app will
  /// happily send the user's password to e.g. `http://attacker.local`.
  String? _checkedBaseUrl() {
    if (isHosted) return Env.hostedApiUrl;
    final raw = urlOverride;
    final uri = raw.isEmpty ? null : Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      _setError(key: 'invalid_url');
      return null;
    }
    final scheme = uri.scheme.toLowerCase();
    // Allow http only in debug builds so local dev against an unencrypted
    // server still works; release requires https.
    if (scheme == 'https' || (scheme == 'http' && kDebugMode)) return raw;
    _setError(key: 'invalid_url');
    return null;
  }

  /// Email + password (+ optional OTP). Hot path.
  Future<bool> submit() async {
    if (_busy) return false;
    _busy = true;
    _clearError();
    _fieldErrors = const {};
    notifyListeners();
    final baseUrl = _checkedBaseUrl();
    if (baseUrl == null) {
      _busy = false;
      notifyListeners();
      return false;
    }
    try {
      await auth.login(
        baseUrl: baseUrl,
        isHosted: isHosted,
        email: email,
        password: password,
        oneTimePassword: oneTimePassword.isEmpty ? null : oneTimePassword,
      );
      return true;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _setError(message: e.message);
      return false;
    } on UnauthorizedException catch (e) {
      _setError(message: e.message);
      return false;
    } on NetworkException catch (e) {
      _setError(
        key: 'network_error_with_message',
        params: {'message': e.message},
      );
      return false;
    } on ApiException catch (e) {
      _setError(message: e.message);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Sign in with Apple. Returns false on cancellation without setting an
  /// error message (the user just dismissed the sheet, nothing to surface).
  Future<bool> submitApple() async {
    if (_busy) return false;
    _busy = true;
    _clearError();
    _fieldErrors = const {};
    notifyListeners();
    final baseUrl = _checkedBaseUrl();
    if (baseUrl == null) {
      _busy = false;
      notifyListeners();
      return false;
    }
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      await auth.oauthLogin(
        baseUrl: baseUrl,
        isHosted: isHosted,
        provider: 'apple',
        idToken: cred.identityToken,
        authCode: cred.authorizationCode,
        email: cred.email,
      );
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return false; // sheet dismissed — no error to surface
      }
      _setError(
        key: 'apple_sign_in_failed_with_message',
        params: {'message': e.message},
      );
      return false;
    } on SignInWithAppleException catch (e) {
      _setError(
        key: 'apple_sign_in_unavailable_with_error',
        params: {'error': e.toString()},
      );
      return false;
    } on UnauthorizedException catch (e) {
      _setError(message: e.message);
      return false;
    } on NetworkException catch (e) {
      _setError(
        key: 'network_error_with_message',
        params: {'message': e.message},
      );
      return false;
    } on ApiException catch (e) {
      _setError(message: e.message);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> recover() async {
    if (email.isEmpty) {
      _setError(key: 'enter_email_first');
      notifyListeners();
      return false;
    }
    _busy = true;
    _clearError();
    notifyListeners();
    final baseUrl = _checkedBaseUrl();
    if (baseUrl == null) {
      _busy = false;
      notifyListeners();
      return false;
    }
    try {
      await auth.recoverPassword(
        baseUrl: baseUrl,
        isHosted: isHosted,
        email: email,
      );
      return true;
    } on ApiException catch (e) {
      _setError(message: e.message);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
