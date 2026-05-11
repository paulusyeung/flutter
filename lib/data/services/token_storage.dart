import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      : _backend = backend ?? const FlutterSecureStorage();

  final FlutterSecureStorage _backend;

  @override
  Future<String?> read(String key) => _backend.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _backend.write(key: key, value: value);

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
