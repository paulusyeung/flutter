import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/env.dart';
import '../../app/version.dart';
import '../models/api/login_response_api_model.dart';
import 'api_exception.dart';

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
