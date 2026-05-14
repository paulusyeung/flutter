import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardened [FlutterSecureStorage] used by every secure-store call site
/// (auth tokens here, the SQLCipher DB key in `app_database.dart`).
///
/// Pinned options:
/// * iOS / macOS: `KeychainAccessibility.first_unlock_this_device`. Items
///   are bound to the device that wrote them — they don't sync to iCloud
///   Keychain or transfer to other devices the user owns. The package
///   default (`unlocked`) would let the auth token / DB key sync to a
///   less-trusted secondary device.
/// * Android: defaults are fine in v10.x — the package migrates from
///   `EncryptedSharedPreferences` (now deprecated) to its own AES-GCM
///   cipher on first access. Don't pass `encryptedSharedPreferences:`;
///   the parameter is deprecated and will be removed in v11.
///
/// Both call sites MUST use this instance — using the bare
/// `FlutterSecureStorage()` constructor lands items in a different
/// keychain compartment, which means a future read with the hardened
/// options won't find them.
const FlutterSecureStorage kSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

/// Thin abstraction over the platform's secure store. The production
/// implementation wraps [FlutterSecureStorage]; tests use
/// [InMemoryTokenStorage] without needing platform channels.
abstract class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? backend])
    : _backend = backend ?? kSecureStorage;

  final FlutterSecureStorage _backend;

  @override
  Future<String?> read(String key) => _backend.read(key: key);

  @override
  Future<void> write(String key, String value) async {
    try {
      await _backend.write(key: key, value: value);
    } on PlatformException catch (e) {
      // errSecDuplicateItem (-25299) on macOS: a previous build wrote this
      // key under different accessibility (e.g. the package default
      // `kSecAttrAccessibleWhenUnlocked` before kSecureStorage pinned
      // `first_unlock_this_device`). The plugin's `containsKey` query is
      // accessibility-scoped and misses the orphan, so it falls through to
      // SecItemAdd, which trips the (class, account, service) uniqueness
      // constraint. Delete the orphan and retry once — mirrors the parallel
      // shim in `_getOrCreateDbKey` (lib/data/db/app_database.dart).
      if (e.code == '-25299' ||
          (e.message?.contains('already exists in the keychain') ?? false)) {
        await _backend.delete(key: key);
        await _backend.write(key: key, value: value);
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> delete(String key) => _backend.delete(key: key);
}

class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);
}
