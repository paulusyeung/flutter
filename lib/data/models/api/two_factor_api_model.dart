import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_api_model.freezed.dart';
part 'two_factor_api_model.g.dart';

/// Shape of `GET /api/v1/settings/enable_two_factor`.
///
/// Server returns:
///   `{ "data": { "qrCode": "[otpauth:// URL]", "secret": "[TOTP secret]" } }`
///
/// `qrCode` is an `otpauth://totp/...` URL (Laravel `Google2FA::getQRCodeUrl`),
/// NOT an image — the screen renders it client-side with `QrImageView(data:)`
/// (qr_flutter), matching the legacy app and React (`<QRCode value={...} />`).
/// `secret` is the raw TOTP secret; we echo it back on the confirm POST so
/// the server pairs the response with the right pending key.
@freezed
abstract class TwoFactorSetupApi with _$TwoFactorSetupApi {
  const factory TwoFactorSetupApi({
    @JsonKey(name: 'qrCode') @Default('') String qrCode,
    @Default('') String secret,
  }) = _TwoFactorSetupApi;

  factory TwoFactorSetupApi.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorSetupApiFromJson(json);
}
