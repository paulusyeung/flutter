import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

final _log = Logger('BiometricService');

/// Thin abstraction over `local_auth` so the auth/lock layer can fake it in
/// tests. Mirrors admin-portal's behavior: a `PlatformException` (cancelled,
/// not enrolled, locked out) is treated as "not authenticated" rather than
/// surfaced — callers decide what to do next.
abstract class BiometricService {
  /// True when the device reports both `canCheckBiometrics` and
  /// `isDeviceSupported`. The User Details toggle hides itself when this
  /// returns false, and the lock screen's auto-prompt short-circuits.
  Future<bool> isAvailable();

  /// Show the FaceID/TouchID prompt. Returns true on success, false on
  /// cancel / no biometrics enrolled / OS-revoked authentication.
  Future<bool> authenticate({required String reason});
}

/// Web has no `local_auth` implementation (no FaceID/TouchID/Windows Hello
/// equivalent reachable from a browser). [isAvailable] returns false so the
/// User Details toggle hides itself and the lock screen's auto-prompt
/// short-circuits — identical to a native device with no enrolled
/// biometrics. Selected via `kIsWeb` in `Services.build`.
class WebBiometricService implements BiometricService {
  const WebBiometricService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? backend])
    : _auth = backend ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e, st) {
      _log.fine('isAvailable() failed', e, st);
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e, st) {
      _log.fine('authenticate() failed', e, st);
      return false;
    }
  }
}
