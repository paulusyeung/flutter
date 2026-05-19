import 'package:web/web.dart' as web;

import 'package:admin/data/services/token_storage.dart';

/// Web production token store. No Keychain equivalent exists in the browser;
/// per the locked product decision (CLAUDE.md § Web) the auth token lives in
/// `window.localStorage`, scoped to the app origin. Survives reload and tab
/// close (unlike `sessionStorage`), which `restore()` relies on.
class LocalStorageTokenStorage implements TokenStorage {
  const LocalStorageTokenStorage();

  @override
  Future<String?> read(String key) async =>
      web.window.localStorage.getItem(key);

  @override
  Future<void> write(String key, String value) async =>
      web.window.localStorage.setItem(key, value);

  @override
  Future<void> delete(String key) async =>
      web.window.localStorage.removeItem(key);
}

TokenStorage defaultTokenStorage() => const LocalStorageTokenStorage();
