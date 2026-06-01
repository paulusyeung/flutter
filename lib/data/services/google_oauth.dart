import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:admin/app/env.dart';

/// Google sign-in for the Invoice Ninja API (`/api/v1/oauth_login`).
///
/// Mirrors `admin-portal/lib/utils/oauth.dart` (the working Android/iOS
/// implementation) 1:1, with one deliberate change: the Android
/// `serverClientId` comes from [Env.googleServerClientId] (a per-build
/// dart-define) instead of a hardcoded constant — a client ID is bound to a
/// specific OAuth project + app package/bundle, so it cannot be shared
/// across apps.
///
/// We deliberately ride v7's "access token" path instead of the new
/// "id token" path: the backend's `getTokenResponse(id_token)` route rejects
/// v7-issued JWTs, while `harvestUser(access_token)` (Google's userinfo
/// endpoint) keeps working unchanged. So this returns
/// `(idToken: '', accessToken)` and [AuthService.oauthLogin] omits the empty
/// `id_token` from the request body so Laravel's
/// `request()->has('id_token')` returns false and execution falls into the
/// access-token branch.
class GoogleOAuth {
  GoogleOAuth._();

  static bool _initialized = false;

  /// Android needs a configured server client ID (Credential Manager can't
  /// resolve it from `google-services.json`); iOS resolves its own from
  /// `Info.plist`/`GoogleService-Info.plist`, so it's enabled there
  /// regardless. Web/desktop are out of scope (login is hosted-only).
  static bool get isEnabled {
    if (kIsWeb) return false;
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) return Env.googleServerClientId.isNotEmpty;
    return false;
  }

  static Future<void> init() async {
    if (_initialized) {
      return;
    }
    if (!kIsWeb && Platform.isAndroid) {
      await GoogleSignIn.instance.initialize(
        serverClientId: Env.googleServerClientId,
      );
    } else {
      await GoogleSignIn.instance.initialize();
    }
    _initialized = true;
  }

  /// Interactive sign-in. Invokes [callback] with `(idToken, accessToken)`;
  /// `idToken` is always empty (see class doc — we ride the access-token
  /// path). Returns true when a non-empty access token was obtained.
  static Future<bool> signIn(
    void Function(String idToken, String accessToken) callback,
  ) async {
    await init();

    final account = await _interactiveAuthenticate();
    if (account == null) {
      callback('', '');
      return false;
    }

    final accessToken = await _resolveAccessToken(account);
    callback('', accessToken);
    return accessToken.isNotEmpty;
  }

  static Future<void> signOut() async {
    await init();
    await GoogleSignIn.instance.signOut();
  }

  static Future<void> disconnect() async {
    await init();
    await GoogleSignIn.instance.disconnect();
  }

  static const _scopes = ['email', 'profile'];

  static Future<GoogleSignInAccount?> _interactiveAuthenticate() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      debugPrint('## authenticate() not supported on this platform');
      return null;
    }
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint('## authenticate failed: ${e.code}');
      return null;
    }
  }

  static Future<String> _resolveAccessToken(GoogleSignInAccount account) async {
    final silent = await account.authorizationClient.authorizationForScopes(
      _scopes,
    );
    if (silent != null) {
      return silent.accessToken;
    }

    try {
      final interactive = await account.authorizationClient.authorizeScopes(
        _scopes,
      );
      return interactive.accessToken;
    } on GoogleSignInException catch (e) {
      debugPrint('## authorizeScopes failed: ${e.code}');
      return '';
    }
  }
}
