import 'package:flutter/widgets.dart';

/// Short-lived in-memory cache for the user's password.
///
/// Destructive server endpoints (delete, purge, password change) require
/// `X-API-PASSWORD-BASE64` per Invoice Ninja policy. The user supplies it via
/// `ConfirmPasswordSheet`; the password lives here for [ttl] so the user
/// isn't re-prompted on every following destructive action.
///
/// Cleared on logout, and on `AppLifecycleState.paused` if a
/// [PasswordCacheLifecycleObserver] is installed by the app shell. The cache
/// is in-memory only — never persisted.
class PasswordCache {
  PasswordCache({
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

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

/// Drops [PasswordCache] contents when the app is backgrounded.
///
/// Without this, a user who deletes a client and then hands their phone over
/// (or it's briefly snatched) leaves a recoverable plaintext password in
/// memory for up to the cache's full [PasswordCache.ttl]. We hook
/// `AppLifecycleState.paused` only — `inactive` fires on iOS for transient
/// events like pulling down notification center, and clearing there would
/// force a re-prompt for normal UI gestures.
class PasswordCacheLifecycleObserver with WidgetsBindingObserver {
  PasswordCacheLifecycleObserver(this._cache);

  final PasswordCache _cache;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cache.clear();
    }
  }
}
