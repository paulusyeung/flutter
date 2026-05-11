/// Short-lived in-memory cache for the user's password.
///
/// Destructive server endpoints (delete, purge, password change) require
/// `X-API-PASSWORD-BASE64` per Invoice Ninja policy. The user supplies it via
/// `ConfirmPasswordSheet`; the password lives here for [ttl] so the user
/// isn't re-prompted on every following destructive action.
///
/// Cleared on logout. The cache is in-memory only — never persisted.
class PasswordCache {
  PasswordCache({this.ttl = const Duration(minutes: 5), DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _now;

  String? _password;
  DateTime? _expiresAt;

  void set(String password) {
    _password = password;
    _expiresAt = _now().add(ttl);
  }

  String? read() {
    final exp = _expiresAt;
    if (_password == null || exp == null) return null;
    if (_now().isAfter(exp)) {
      clear();
      return null;
    }
    return _password;
  }

  void clear() {
    _password = null;
    _expiresAt = null;
  }
}
