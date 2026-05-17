import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:admin/app/env.dart';
import 'package:admin/app/version.dart';
import 'package:admin/data/models/api/login_response_api_model.dart';
import 'package:admin/data/services/api_exception.dart';

/// Auth endpoints don't fit through [ApiClient] because they're called before
/// we have a token. This service speaks to `/api/v1/login` and
/// `/api/v1/reset_password` directly, with the standard non-token headers.
///
/// Mirrors `admin-portal/lib/redux/auth/auth_middleware.dart:102-120` for the
/// login response envelope and the headers we send.
class AuthService {
  AuthService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// POST `/api/v1/login`. The request body matches the existing app:
  ///   { email, password, one_time_password? }
  ///
  /// Returns the parsed [LoginResponseApi]. Throws an [ApiException] subtype
  /// on non-2xx so the UI can surface the right error path.
  Future<LoginResponseApi> login({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String? oneTimePassword,
  }) async {
    final response = await _http.post(
      Uri.parse(baseUrl).resolve('/api/v1/login'),
      headers: _headers(isHosted: isHosted, contentTypeJson: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        if (oneTimePassword != null && oneTimePassword.isNotEmpty)
          'one_time_password': oneTimePassword,
      }),
    );
    _raiseIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponseApi.fromJson(json);
  }

  /// POST `/api/v1/oauth_login`. Used by third-party OAuth flows (Sign in
  /// with Apple, etc.). The request body mirrors admin-portal's:
  ///   { provider, access_token, email, auth_code, id_token }
  ///
  /// Returns the same [LoginResponseApi] envelope as a regular login, so the
  /// caller can drop it into [AuthRepository] alongside `login()` with no
  /// extra plumbing.
  Future<LoginResponseApi> oauthLogin({
    required String baseUrl,
    required bool isHosted,
    required String provider,
    String? idToken,
    String? authCode,
    String? accessToken,
    String? email,
  }) async {
    final response = await _http.post(
      Uri.parse(baseUrl).resolve('/api/v1/oauth_login'),
      headers: _headers(isHosted: isHosted, contentTypeJson: true),
      body: jsonEncode({
        'provider': provider,
        if (accessToken != null) 'access_token': accessToken,
        if (email != null) 'email': email,
        if (authCode != null) 'auth_code': authCode,
        // Send id_token only when populated. The server's Laravel
        // `request()->has('id_token')` returns true for an empty string too,
        // so an absent key is the only way to route the Google flow (which
        // carries access_token, no id_token) through the access-token branch
        // instead of the JWT branch. Mirrors admin-portal's auth_repository.
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
      }),
    );
    _raiseIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponseApi.fromJson(json);
  }

  /// POST `/api/v1/signup`. Native account creation. Mirrors admin-portal's
  /// `AuthRepository.signUp` — the native body carries no Cloudflare
  /// Turnstile token (that's a web-frontend bot mitigation; the API doesn't
  /// require it for native clients). Returns the same [LoginResponseApi]
  /// envelope as `login()`, so the caller drops it into [AuthRepository]
  /// alongside `login()` with no extra plumbing.
  Future<LoginResponseApi> signup({
    required String baseUrl,
    required bool isHosted,
    required String email,
    required String password,
    String referralCode = '',
  }) async {
    final response = await _http.post(
      Uri.parse(baseUrl).resolve('/api/v1/signup?rc=$referralCode'),
      headers: _headers(isHosted: isHosted, contentTypeJson: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'terms_of_service': true,
        'privacy_policy': true,
        'token_name': '${Env.clientPlatform}_client',
        'platform': Env.clientPlatform,
      }),
    );
    _raiseIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponseApi.fromJson(json);
  }

  /// POST `/api/v1/reset_password`. The server mails the user a reset link;
  /// the client only needs to know if the request was accepted.
  Future<void> recoverPassword({
    required String baseUrl,
    required bool isHosted,
    required String email,
  }) async {
    final response = await _http.post(
      Uri.parse(baseUrl).resolve('/api/v1/reset_password'),
      headers: _headers(isHosted: isHosted, contentTypeJson: true),
      body: jsonEncode({'email': email}),
    );
    _raiseIfError(response);
  }

  Map<String, String> _headers({
    required bool isHosted,
    bool contentTypeJson = false,
  }) {
    return {
      'Accept': 'application/json',
      if (contentTypeJson) 'Content-Type': 'application/json; charset=UTF-8',
      'X-CLIENT-PLATFORM': Env.clientPlatform,
      'X-CLIENT-VERSION': AppVersion.kClientVersion,
      'X-Requested-With': 'com.invoiceninja.admin',
      if (isHosted && Env.hostedApiSecret.isNotEmpty)
        'X-API-SECRET': Env.hostedApiSecret,
    };
  }

  void _raiseIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      /* non-JSON body */
    }
    final message =
        json?['message']?.toString() ??
        response.reasonPhrase ??
        'HTTP ${response.statusCode}';
    switch (response.statusCode) {
      case 401:
      case 403:
        throw UnauthorizedException(message);
      case 422:
        final raw = json?['errors'];
        final fieldErrors = <String, List<String>>{};
        if (raw is Map<String, dynamic>) {
          for (final entry in raw.entries) {
            final v = entry.value;
            if (v is List) {
              fieldErrors[entry.key] = v.map((e) => e.toString()).toList();
            }
          }
        }
        throw ValidationException(message, fieldErrors);
      default:
        throw ServerException(response.statusCode, message);
    }
  }
}
