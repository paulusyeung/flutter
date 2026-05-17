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

  /// Google OAuth Web/server client ID. Required on Android: the v7
  /// `google_sign_in` plugin routes through Credential Manager, which needs
  /// the Web OAuth client ID passed to `initialize(serverClientId:)` — it does
  /// not auto-resolve it from `google-services.json`. iOS resolves its own
  /// client ID from `Info.plist` / `GoogleService-Info.plist` and must NOT
  /// receive `serverClientId`. Empty = Google sign-in unconfigured for this
  /// build; deployments inject the real ID via
  /// `--dart-define=IN_GOOGLE_SERVER_CLIENT_ID=…` (per-app OAuth project — do
  /// not reuse another app's client ID, the bundle/package binding won't match).
  static const String googleServerClientId = String.fromEnvironment(
    'IN_GOOGLE_SERVER_CLIENT_ID',
  );

  /// Sentry DSN for remote error reporting. Empty (the default) disables
  /// Sentry entirely — deployments opt in via
  /// `--dart-define=IN_SENTRY_DSN=…` with their own Sentry project (do not
  /// hardcode another app's DSN). Also gated to release builds and the
  /// per-account `report_errors` opt-in (see `main.dart` / `sentry_gate`).
  static const String sentryDsn = String.fromEnvironment('IN_SENTRY_DSN');

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
