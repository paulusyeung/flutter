import 'package:admin/data/models/api/two_factor_api_model.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/two_factor_api.dart';

/// Thin coordinator over [TwoFactorApi] that updates [AuthRepository.session]
/// after a successful enable/disable so the rest of the app reacts without
/// waiting for the next `/refresh`. Held as a separate class so the
/// [TwoFactorViewModel] tests can stub a fake repository.
class TwoFactorRepository {
  TwoFactorRepository({required TwoFactorApi api, required AuthRepository auth})
    : _api = api,
      _auth = auth;

  final TwoFactorApi _api;
  final AuthRepository _auth;

  Future<TwoFactorSetupApi> fetchSetup() => _api.fetchSetup();

  /// Confirm enablement. On success, flip the in-memory session flag so the
  /// UI flips to the "enabled" branch on the next rebuild, then kick off a
  /// background `/refresh` to pick up anything else the server changed.
  Future<void> confirmEnable({
    required String secret,
    required String oneTimePassword,
  }) async {
    await _api.confirmEnable(
      secret: secret,
      oneTimePassword: oneTimePassword,
    );
    _auth.markTwoFactorEnabled(true);
    // Fire-and-forget — UI already reflects the flip. If the refresh fails
    // (offline, transient 5xx) the next foreground action will retry.
    _refreshInBackground();
  }

  Future<void> disable() async {
    await _api.disable();
    _auth.markTwoFactorEnabled(false);
    _refreshInBackground();
  }

  Future<void> sendSmsCode({required String phone}) =>
      _api.sendSmsCode(phone: phone);

  Future<void> verifySmsCode({
    required String code,
    String? phone,
  }) async {
    await _api.verifySmsCode(code: code);
    _auth.markPhoneVerified(phone: phone);
  }

  void _refreshInBackground() {
    _auth.refreshSession().ignore();
  }
}
