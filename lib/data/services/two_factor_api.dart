import 'package:admin/data/models/api/two_factor_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// HTTP-only wrapper for the Invoice Ninja 2FA setup endpoints.
///
/// Mirrors `admin-portal/lib/data/repositories/settings_repository.dart` and
/// the React client at `src/pages/settings/user/components/TwoFactorAuthentication.tsx`:
///   * `GET    /api/v1/settings/enable_two_factor`   → fetch QR + secret
///   * `POST   /api/v1/settings/enable_two_factor`   → confirm with `{ secret, one_time_password }`
///   * `POST   /api/v1/settings/disable_two_factor`  → turn it off
///   * `POST   /api/v1/sms_reset`                    → send phone-verify SMS
///   * `POST   /api/v1/sms_reset/confirm`            → verify the SMS code
///
/// These calls are interactive — the response feeds the next UI step — so
/// they go through [ApiClient.getOne] / [ApiClient.postJson] directly rather
/// than the outbox pipeline.
class TwoFactorApi {
  TwoFactorApi(this._api);

  final ApiClient _api;

  /// Fetch the QR code + TOTP secret to display to the user. Server returns
  /// `{ "data": { "qrCode": "...", "secret": "..." } }` so we unwrap one level.
  Future<TwoFactorSetupApi> fetchSetup() async {
    final raw = await _api.getOne('/api/v1/settings/enable_two_factor');
    if (raw is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected /settings/enable_two_factor response: ${raw.runtimeType}',
      );
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected /settings/enable_two_factor payload: '
        '`data` field missing or wrong shape',
      );
    }
    return TwoFactorSetupApi.fromJson(data);
  }

  /// Confirm the QR pairing. Body matches admin-portal:
  ///   `{ "secret": "[from fetchSetup]", "one_time_password": "[6 digits]" }`
  /// Server validates the OTP against the secret and flips
  /// `google_2fa_secret` to true on the user record.
  Future<void> confirmEnable({
    required String secret,
    required String oneTimePassword,
  }) async {
    await _api.postJson(
      '/api/v1/settings/enable_two_factor',
      body: {'secret': secret, 'one_time_password': oneTimePassword},
    );
  }

  /// Turn 2FA off. Server requires the user's password (sent as the
  /// `X-API-PASSWORD-BASE64` header by [ApiClient]); without it the server
  /// returns 412. Caller is responsible for ensuring [PasswordCache] is
  /// populated before invoking — [ApiClient.postJson] throws
  /// [PasswordRequiredException] when it isn't, which the UI catches to prompt.
  ///
  /// Mirrors admin-portal's `SettingsRepository.disableTwoFactor`
  /// (`admin-portal/lib/data/repositories/settings_repository.dart:254-267`,
  /// `redux/settings/settings_middleware.dart:288-309`).
  Future<void> disable() async {
    await _api.postJson(
      '/api/v1/settings/disable_two_factor',
      body: const {},
      requiresPassword: true,
    );
  }

  /// Send the phone-verification SMS (hosted gating before enable). The server
  /// looks the user up by `email` and texts the phone already on their record —
  /// matching React's flow — so the phone must be saved in User Details first.
  /// Body is `{ "email": ... }` (the server's `Generate2faRequest` requires it).
  Future<void> sendSmsCode({required String email}) async {
    await _api.postJson('/api/v1/sms_reset', body: {'email': email});
  }

  /// Verify the SMS code. `?validate_only=true` tells the server to flip
  /// `verified_phone_number = true` (the phone-verify path); WITHOUT it the
  /// server's `confirm2faResetCode` *disables* 2FA instead. Body carries both
  /// `code` and `email` (the server's `Confirm2faRequest` requires both).
  Future<void> verifySmsCode({
    required String code,
    required String email,
  }) async {
    await _api.postJson(
      '/api/v1/sms_reset/confirm',
      query: const {'validate_only': 'true'},
      body: {'code': code, 'email': email},
    );
  }
}
