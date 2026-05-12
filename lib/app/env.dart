import 'dart:io' show Platform;

/// Build-time + runtime configuration.
///
/// Values that vary by build flavor (hosted vs self-hosted, demo mode) are
/// passed via `--dart-define` and read here. Defaults are safe for local
/// development.
class Env {
  Env._();

  /// Hosted Invoice Ninja API base URL — used when the user picks "Hosted" on
  /// the login screen.
  static const String hostedApiUrl = String.fromEnvironment(
    'IN_HOSTED_API_URL',
    defaultValue: 'https://invoicing.co',
  );

  /// X-API-SECRET injected on hosted builds. Empty on self-hosted.
  static const String hostedApiSecret = String.fromEnvironment(
    'IN_HOSTED_API_SECRET',
  );

  /// Demo mode short-circuits all non-GET requests with a friendly toast.
  /// See `web_client.dart:31,266` in admin-portal for the precedent.
  static const bool demoMode = bool.fromEnvironment('IN_DEMO_MODE');

  /// Dev-only login pre-fill. Consumed by `LoginViewModel` under `kDebugMode`
  /// so release builds never ship pre-filled credentials. Typical usage:
  /// `flutter run --dart-define-from-file=dev.json` with a gitignored
  /// `dev.json` (see `dev.json.example`).
  static const String devEmail = String.fromEnvironment('IN_DEV_EMAIL');
  static const String devPassword = String.fromEnvironment('IN_DEV_PASSWORD');

  /// `X-CLIENT-PLATFORM` header value. Expands as we add platforms.
  static String get clientPlatform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
