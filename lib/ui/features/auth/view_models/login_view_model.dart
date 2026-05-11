import 'package:flutter/foundation.dart';

import '../../../../app/env.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/api_exception.dart';

/// State machine for the login screen.
///
/// The view binds to this and surfaces:
///   * the hosted/self-hosted toggle,
///   * the URL field (only when self-hosted),
///   * an OTP field (only when the server returned `2fa-required`),
///   * loading / error / success states.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this.auth});

  final AuthRepository auth;

  /// True = use `Env.hostedApiUrl`; false = use [urlOverride].
  bool isHosted = true;
  String urlOverride = '';
  String email = '';
  String password = '';
  String oneTimePassword = '';

  bool _requiresOtp = false;
  bool get requiresOtp => _requiresOtp;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  Map<String, List<String>> _fieldErrors = const {};
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  void setHosted(bool value) {
    if (isHosted == value) return;
    isHosted = value;
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

  String get _resolvedBaseUrl => isHosted ? Env.hostedApiUrl : urlOverride;

  Future<bool> submit() async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      await auth.login(
        baseUrl: _resolvedBaseUrl,
        isHosted: isHosted,
        email: email,
        password: password,
        oneTimePassword: oneTimePassword.isEmpty ? null : oneTimePassword,
      );
      return true;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _error = e.message;
      return false;
    } on UnauthorizedException catch (e) {
      // Many servers return 401/403 with a hint when 2FA is required.
      if (e.message.toLowerCase().contains('one-time') ||
          e.message.toLowerCase().contains('2fa')) {
        _requiresOtp = true;
      }
      _error = e.message;
      return false;
    } on NetworkException catch (e) {
      _error = 'Network error: ${e.message}';
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> recover() async {
    if (email.isEmpty) {
      _error = 'Enter your email first.';
      notifyListeners();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await auth.recoverPassword(
        baseUrl: _resolvedBaseUrl,
        isHosted: isHosted,
        email: email,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
