import 'dart:io' show Platform;

/// Build-time + runtime configuration.
///
/// Values that vary by build flavor (hosted vs self-hosted, demo mode, Sentry
/// DSN) are passed via `--dart-define` and read here. Defaults are safe for
/// local development.
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

  /// Sentry DSN. Empty disables Sentry (the default in dev).
  static const String sentryDsn = String.fromEnvironment('IN_SENTRY_DSN');

  /// Demo mode short-circuits all non-GET requests with a friendly toast.
  /// See `web_client.dart:31,266` in admin-portal for the precedent.
  static const bool demoMode = bool.fromEnvironment('IN_DEMO_MODE');

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
