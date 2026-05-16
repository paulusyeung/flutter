import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:admin/app/debug_capture_store.dart';
import 'package:admin/app/env.dart';
import 'package:admin/app/version.dart';
import 'package:admin/data/services/api_credentials.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/password_cache.dart';

final _log = Logger('ApiClient');

/// Result of a `list` call — payload + the keyset cursor of the last row, so
/// the caller can advance `sync_state` after upserting.
class ApiListResult<T> {
  ApiListResult({required this.data, this.cursorUpdatedAt, this.cursorId});
  final T data;
  final int? cursorUpdatedAt;
  final String? cursorId;
}

/// Wrapper around [http.Client] that owns all cross-cutting concerns: header
/// composition, version negotiation, single-flight 401 handling, typed
/// errors, and demo-mode short-circuits.
class ApiClient {
  ApiClient({
    required ValueListenable<ApiCredentials?> credentials,
    required PasswordCache passwordCache,
    required Future<void> Function() onUnauthorized,
    ValueSetter<String>? onServerVersion,
    void Function(({String minRequired, String current}))? onClientTooOld,
    http.Client? httpClient,
    Future<dynamic> Function(String)? decoder,
    Duration decodeTimeout = const Duration(seconds: 20),
    DebugCaptureStore? debugCaptureStore,
  }) : _credentialsListenable = credentials,
       _passwordCache = passwordCache,
       _onUnauthorized = onUnauthorized,
       _onServerVersion = onServerVersion,
       _onClientTooOld = onClientTooOld,
       _http = httpClient ?? http.Client(),
       _decoder = decoder ?? _defaultDecoder,
       _decodeTimeout = decodeTimeout,
       _debugCaptureStore = debugCaptureStore;

  final ValueListenable<ApiCredentials?> _credentialsListenable;
  final PasswordCache _passwordCache;
  final Future<void> Function() _onUnauthorized;
  final ValueSetter<String>? _onServerVersion;
  final void Function(({String minRequired, String current}))? _onClientTooOld;
  final http.Client _http;
  final Future<dynamic> Function(String) _decoder;
  final Duration _decodeTimeout;
  final DebugCaptureStore? _debugCaptureStore;

  /// Coalesces concurrent 401s — every parallel caller that 401s while a
  /// logout is in flight `await`s the same future.
  Future<void>? _logoutFuture;

  ApiCredentials? get _creds => _credentialsListenable.value;

  /// GET — `path` is relative (e.g. `/api/v1/clients`).
  ///
  /// Query parameters in [query] are URL-encoded; standard list params are
  /// `page`, `per_page`, `search`, `since_updated_at`, `since_id`, plus any
  /// entity-specific filters.
  Future<ApiListResult<dynamic>> getList(
    String path, {
    required int page,
    int perPage = 50,
    String? search,
    int? sinceUpdatedAt,
    String? sinceId,
    Map<String, String> filters = const {},
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'filter': search,
      if (sinceUpdatedAt != null) 'updated_at': '$sinceUpdatedAt',
      if (sinceId != null) 'since_id': sinceId,
      ...filters,
    };
    final body = await _send(method: 'GET', path: path, query: query);
    final parsed = await _decodeBody(body);
    int? cursorAt;
    String? cursorId;
    if (parsed is Map && parsed['data'] is List) {
      final list = parsed['data'] as List;
      if (list.isNotEmpty) {
        final last = list.last;
        if (last is Map) {
          final rawAt = last['updated_at'] is int
              ? last['updated_at'] as int
              : int.tryParse('${last['updated_at']}');
          cursorAt = _sanitizeCursor(rawAt, path: path);
          cursorId = last['id']?.toString();
        }
      }
    }
    return ApiListResult(
      data: parsed,
      cursorUpdatedAt: cursorAt,
      cursorId: cursorId,
    );
  }

  // Clamp the server-supplied `updated_at` cursor to a plausible range.
  // Why: the keyset cursor is opaque to us and a buggy/malicious response
  // could pin the cursor in the year 9999 (skipping every subsequent page) or
  // hand back a negative timestamp that the server then rejects on the next
  // request. Drop the cursor in those cases — the caller will fall back to a
  // fresh paginate from the top, which is correct (just slower).
  static int? _sanitizeCursor(int? raw, {required String path}) {
    if (raw == null) return null;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const oneDaySeconds = 86400;
    final upperBound = nowSeconds + oneDaySeconds;
    if (raw < 0 || raw > upperBound) {
      _log.warning(
        'Discarding implausible updated_at cursor ($raw) from $path',
      );
      return null;
    }
    return raw;
  }

  /// GET a single resource.
  Future<dynamic> getOne(String path) async {
    final body = await _send(method: 'GET', path: path);
    return _decodeBody(body);
  }

  /// GET with arbitrary query parameters. Used for one-shot list pulls where
  /// keyset cursor semantics (the [getList] code path) would be in the way —
  /// dashboard list cards, for example. No idempotency key, no outbox.
  Future<dynamic> getOneWithQuery(
    String path, {
    Map<String, String>? query,
  }) async {
    final body = await _send(method: 'GET', path: path, query: query);
    return _decodeBody(body);
  }

  /// POST a JSON body without outbox / idempotency-key semantics. For endpoints
  /// that are POSTs in shape but read-only in effect (e.g. the dashboard's
  /// `charts/totals_v2`, `charts/chart_summary_v2`), set [readOnly] = true so
  /// the demo-mode short-circuit doesn't reject them.
  ///
  /// If the endpoint requires the user's password (e.g. `disable_two_factor`),
  /// pass [requiresPassword] = true: same contract as [mutate] — include the
  /// `X-API-PASSWORD-BASE64` header when the cache is populated, or throw
  /// [PasswordRequiredException] so the UI can prompt and retry.
  ///
  /// 401 single-flight, version negotiation, and exception mapping all flow
  /// through `_send` — same contract as [getOne] / [mutate].
  Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool readOnly = false,
    bool requiresPassword = false,
  }) async {
    if (!readOnly && Env.demoMode) {
      throw const DemoModeException();
    }
    String? password;
    if (requiresPassword) {
      password = _passwordCache.read();
      if (password == null) {
        throw const PasswordRequiredException();
      }
    }
    final raw = await _send(
      method: 'POST',
      path: path,
      query: query,
      body: body,
      password: password,
    );
    if (raw.isEmpty) return null;
    return _decodeBody(raw);
  }

  /// POST a JSON body and return the raw response bytes. For endpoints that
  /// reply with binary content (e.g. `/api/v1/client_statement` → PDF). Sniffs
  /// the response `Content-Type` against [expectedContentType] (defaults to
  /// `application/pdf`); a 2xx with a different content type is treated as a
  /// server-side error and raised as [ServerException] with a short prefix of
  /// the body for the log, so a misrouted JSON error envelope doesn't get
  /// passed to PDF rendering. [readOnly] = true skips the demo-mode short
  /// circuit (statement fetches are reads in effect).
  Future<Uint8List> postRaw(
    String path, {
    Map<String, dynamic>? body,
    bool readOnly = false,
    String expectedContentType = 'application/pdf',
  }) async {
    if (!readOnly && Env.demoMode) {
      throw const DemoModeException();
    }
    final creds = _requireCreds();
    final uri = Uri.parse(creds.baseUrl).resolve(path);
    final headers = _buildHeaders(creds: creds, contentTypeJson: body != null);
    final encoded = body == null ? null : jsonEncode(body);
    final response = await _sendNoRedirect(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: encoded,
    );
    await _postFlight(response, creds);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final ct = response.headers['content-type'] ?? '';
      final actualType = ct.split(';').first.trim().toLowerCase();
      if (actualType != expectedContentType.toLowerCase()) {
        // Some servers reply 200 + JSON envelope for soft errors. Surface as a
        // ServerException with a short body sample so the cause is logged
        // without dumping a megabyte of PDF garbage on a real mis-shape.
        final preview = response.body.length > 200
            ? '${response.body.substring(0, 200)}…'
            : response.body;
        throw ServerException(
          response.statusCode,
          'Unexpected content-type: "$ct" (body: $preview)',
        );
      }
      return response.bodyBytes;
    }
    _raiseFromResponse(response);
  }

  /// Like [postRaw], but tuned for the queued export poll where a 2xx with a
  /// **non-binary** content-type means "job still running" (the server
  /// replies with a small JSON status envelope until the file is ready) —
  /// NOT an error. Returns [RawOrPending.pending] in that case instead of
  /// throwing, so the caller can keep polling. A 2xx with the expected
  /// binary content-type returns the bytes; any non-2xx still goes through
  /// [_raiseFromResponse] (so a real 4xx/5xx — and the 404 → ConflictException
  /// "still queued" mapping — behave exactly as everywhere else and are not
  /// swallowed as "pending").
  Future<RawOrPending> postRawOrPending(
    String path, {
    Map<String, dynamic>? body,
    bool readOnly = false,
    required String expectedContentType,
  }) async {
    if (!readOnly && Env.demoMode) {
      throw const DemoModeException();
    }
    final creds = _requireCreds();
    final uri = Uri.parse(creds.baseUrl).resolve(path);
    final headers = _buildHeaders(creds: creds, contentTypeJson: body != null);
    final encoded = body == null ? null : jsonEncode(body);
    final response = await _sendNoRedirect(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: encoded,
    );
    await _postFlight(response, creds);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final ct = response.headers['content-type'] ?? '';
      final actualType = ct.split(';').first.trim().toLowerCase();
      if (actualType == expectedContentType.toLowerCase()) {
        return RawOrPending.ready(response.bodyBytes);
      }
      // 2xx but not the binary we asked for → the export job hasn't
      // finished; the server is returning its JSON status envelope. Tell
      // the caller to keep polling rather than treating this as an error.
      return const RawOrPending.pending();
    }
    _raiseFromResponse(response);
  }

  /// POST / PUT / DELETE mutation. The caller supplies the outbox row's
  /// [idempotencyKey] so retries are safe. If the endpoint requires the user's
  /// password, [requiresPassword] makes us include it (or throws
  /// [PasswordRequiredException] when the cache is empty).
  Future<dynamic> mutate({
    required String method,
    required String path,
    required String idempotencyKey,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool requiresPassword = false,
  }) async {
    if (Env.demoMode && method.toUpperCase() != 'GET') {
      throw const DemoModeException();
    }
    String? password;
    if (requiresPassword) {
      password = _passwordCache.read();
      if (password == null) {
        throw const PasswordRequiredException();
      }
    }
    final raw = await _send(
      method: method,
      path: path,
      query: query,
      idempotencyKey: idempotencyKey,
      body: body,
      password: password,
    );
    if (raw.isEmpty) return null;
    return _decodeBody(raw);
  }

  /// Multipart upload. Shape is defined now (M1) so M2's document feature
  /// drops in without a redesign. Not exercised in M1 tests.
  Future<dynamic> uploadMultipart({
    required String path,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    required String idempotencyKey,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    if (Env.demoMode) throw const DemoModeException();
    final creds = _requireCreds();
    final uri = Uri.parse(creds.baseUrl).resolve(path);
    final req = http.MultipartRequest('POST', uri)
      ..followRedirects = false
      ..fields.addAll(fields)
      ..files.addAll(files)
      ..headers.addAll(
        _buildHeaders(creds: creds, idempotencyKey: idempotencyKey),
      );
    final streamed = await _http.send(req).timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 300 && response.statusCode < 400) {
      // Same defense as `_sendNoRedirect`: refuse redirects so the
      // multipart body + auth headers can't leak to a redirect target.
      throw ServerException(
        response.statusCode,
        'Unexpected redirect (Location: ${response.headers['location'] ?? '<none>'})',
      );
    }
    await _postFlight(response, creds);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    _raiseFromResponse(response);
  }

  /// Streams [file] to [path] as a series of `multipart/form-data` POSTs, one
  /// per `chunkBytes` slice. Each request carries the same [idempotencyKey] so
  /// a retry coalesces server-side; each chunk's query string carries
  /// `chunk_number` / `total_chunks` and (when truthy) the entries from
  /// [commonQueryTrue]. The fields in [commonFields] are sent with every
  /// chunk, plus a `metadata` JSON blob shaped like:
  ///
  /// ```json
  /// {"totalChunks": N, "currentChunk": i, "fileHash": "<sha256>",
  ///  "fileName": "<basename>", "chunkSize": <actual slice length>}
  /// ```
  ///
  /// `fileHash` is SHA-256 over `min(fileLength, chunkBytes)` bytes — for
  /// files ≤ 2 MB this covers the whole file; for larger ones, only the first
  /// chunk. Matches the React `UploadCompanyImport` shape so the server's
  /// resume / idempotency logic kicks in identically.
  ///
  /// [isCancelled] is checked between chunks; on `true` the loop bails by
  /// throwing [UploadCancelledException]. Caller should treat that as a
  /// silent stop.
  ///
  /// Returns the decoded JSON envelope of the **final** chunk's response —
  /// earlier chunks' bodies are discarded once they 2xx.
  Future<dynamic> uploadMultipartChunked({
    required String path,
    required File file,
    required Map<String, String> commonFields,
    required Map<String, String> commonQueryTrue,
    required String idempotencyKey,
    void Function(int sent, int total)? onProgress,
    bool Function()? isCancelled,
    int chunkBytes = 2 * 1024 * 1024,
    Duration timeoutPerChunk = const Duration(minutes: 2),
  }) async {
    if (Env.demoMode) throw const DemoModeException();
    final creds = _requireCreds();
    final fileName = p.basename(file.path);
    final length = await file.length();
    final total = length == 0 ? 1 : (length / chunkBytes).ceil();

    // SHA-256 over the first min(length, chunkBytes) bytes. Single read at the
    // start so we don't re-open the file once per chunk just for the hash.
    final hashBytes = await _readBytes(file, 0, math.min(length, chunkBytes));
    final fileHash = sha256.convert(hashBytes).toString();

    final queryTrue = <String, String>{
      for (final entry in commonQueryTrue.entries)
        if (entry.value == 'true') entry.key: 'true',
    };

    dynamic last;
    var sent = 0;
    onProgress?.call(0, length == 0 ? 1 : length);
    for (var i = 0; i < total; i++) {
      if (isCancelled?.call() ?? false) {
        throw const UploadCancelledException();
      }
      final start = i * chunkBytes;
      final end = math.min(start + chunkBytes, length);
      final chunk = i == 0 && length <= chunkBytes
          ? Uint8List.fromList(hashBytes)
          : await _readBytes(file, start, end);
      final metadata = jsonEncode({
        'totalChunks': total,
        'currentChunk': i,
        'fileHash': fileHash,
        'fileName': fileName,
        'chunkSize': chunk.length,
      });
      final uri = Uri.parse(creds.baseUrl).resolve(path).replace(
        queryParameters: {
          'chunk_number': '$i',
          'total_chunks': '$total',
          ...queryTrue,
        },
      );
      _log.fine('uploadMultipartChunked: chunk $i/$total ($fileName, ${chunk.length}B)');
      final req = http.MultipartRequest('POST', uri)
        ..followRedirects = false
        ..fields.addAll(commonFields)
        ..fields['metadata'] = metadata
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          chunk,
          filename: fileName,
        ))
        ..headers.addAll(
          _buildHeaders(creds: creds, idempotencyKey: idempotencyKey),
        );
      final streamed = await _http.send(req).timeout(timeoutPerChunk);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw ServerException(
          response.statusCode,
          'Unexpected redirect (Location: ${response.headers['location'] ?? '<none>'})',
        );
      }
      await _postFlight(response, creds);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _raiseFromResponse(response);
      }
      sent += chunk.length;
      onProgress?.call(sent, length == 0 ? 1 : length);
      if (i == total - 1 && response.body.isNotEmpty) {
        last = jsonDecode(response.body);
      }
    }
    return last;
  }

  /// Reads `[start, end)` from [file] into a freshly allocated [Uint8List].
  /// Streams in 64 KiB pages so a 2 MB chunk doesn't sit in two buffers
  /// concurrently when the IO buffer is bigger than the slice.
  Future<Uint8List> _readBytes(File file, int start, int end) async {
    final out = Uint8List(end - start);
    var offset = 0;
    final stream = file.openRead(start, end);
    await for (final block in stream) {
      out.setRange(offset, offset + block.length, block);
      offset += block.length;
    }
    return out;
  }

  Future<String> _send({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    String? password,
  }) async {
    final creds = _requireCreds();
    var uri = Uri.parse(creds.baseUrl).resolve(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }
    final headers = _buildHeaders(
      creds: creds,
      idempotencyKey: idempotencyKey,
      passwordBase64: password == null
          ? null
          : base64Encode(utf8.encode(password)),
      contentTypeJson: body != null,
    );
    final encoded = body == null ? null : jsonEncode(body);
    final stopwatch = Stopwatch()..start();
    final captureId = _debugCaptureStore?.beginRequest(
      method: method.toUpperCase(),
      url: uri.toString(),
      headers: headers,
      requestBody: encoded,
    );
    http.Response response;
    try {
      response = await _sendNoRedirect(
        method: method.toUpperCase(),
        uri: uri,
        headers: headers,
        body: encoded,
      );
    } catch (e) {
      _debugCaptureStore?.failRequest(
        captureId,
        duration: stopwatch.elapsed,
        error: e,
      );
      rethrow;
    }
    _debugCaptureStore?.completeRequest(
      captureId,
      statusCode: response.statusCode,
      duration: stopwatch.elapsed,
      responseBody: response.body,
      responseHeaders: response.headers,
    );
    await _postFlight(response, creds);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    _raiseFromResponse(response);
  }

  /// Send a request without following redirects. Without this guard, the
  /// default `http.Client()` follows 3xx Location headers automatically and
  /// re-sends the original headers — including `X-API-Token` and
  /// `X-API-PASSWORD-BASE64` — to the redirect target. A hostile server (or
  /// one that redirects to an attacker-controlled host the attacker holds a
  /// valid TLS cert for) could harvest the bearer token and password in one
  /// hop. The Invoice Ninja API never legitimately 3xx's, so we surface a
  /// redirect as a server error instead.
  Future<http.Response> _sendNoRedirect({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = http.Request(method, uri)
      ..followRedirects = false
      ..headers.addAll(headers);
    if (body != null) request.body = body;
    try {
      final streamed = await _http.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 300 && response.statusCode < 400) {
        // No legitimate Invoice Ninja API endpoint redirects. Either the
        // server is mis-configured or someone is trying to harvest the
        // token via a Location header. Refuse rather than chase.
        throw ServerException(
          response.statusCode,
          'Unexpected redirect (Location: ${response.headers['location'] ?? '<none>'})',
        );
      }
      return response;
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<void> _postFlight(http.Response response, ApiCredentials creds) async {
    final appVersion = response.headers['x-app-version'];
    if (appVersion != null && _onServerVersion != null) {
      _onServerVersion(appVersion);
    }
    final minClient = response.headers['x-minimum-client-version'];
    if (minClient != null &&
        _compareSemver(AppVersion.kClientVersion, minClient) < 0) {
      // Surface a global signal first so the shell can redirect to the
      // "please update" screen regardless of which screen made the call.
      _onClientTooOld?.call((
        minRequired: minClient,
        current: AppVersion.kClientVersion,
      ));
      throw ClientTooOldException(
        minRequiredVersion: minClient,
        currentVersion: AppVersion.kClientVersion,
      );
    }
    if (response.statusCode == 401) {
      // Defensive: a 401 carrying `error_type: "plan_required"` is a
      // plan-gating signal, not a logged-out signal. Surface it as such
      // before triggering the unauthorized-logout machinery. The body
      // decode is conditional on a JSON content-type so we don't waste
      // a parse on text/html error pages.
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> &&
              decoded['error_type']?.toString().toLowerCase() ==
                  'plan_required') {
            final message =
                decoded['message']?.toString() ?? 'Plan upgrade required';
            throw PlanRequiredException(message);
          }
        } on FormatException {
          /* non-JSON body — fall through to the normal 401 path */
        }
      }
      // Only force logout when the 401 belongs to the *current* credential
      // set. A request issued under a credential set that has since been
      // replaced (e.g. mid-flight when the user switched companies) can come
      // back 401 because we sent the new company's token against the old
      // company's URL — that 401 says nothing about whether the live session
      // is still valid, so swallow it instead of dropping the user back to
      // /login.
      final current = _credentialsListenable.value;
      if (current == null || current.token == creds.token) {
        await _handleUnauthorized();
      } else {
        _log.warning(
          'Discarding stale-credential 401 (request token no longer active)',
        );
      }
      throw const UnauthorizedException();
    }
  }

  Future<void> _handleUnauthorized() {
    // Coalesce parallel 401s into a single onUnauthorized call. Clear the
    // future when it completes so a subsequent session (after re-login) can
    // trigger a fresh logout if its token also goes stale.
    return _logoutFuture ??= () async {
      try {
        await _onUnauthorized();
      } catch (e, st) {
        _log.warning('onUnauthorized threw', e, st);
      }
    }().whenComplete(() => _logoutFuture = null);
  }

  Never _raiseFromResponse(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      /* non-JSON body */
    }
    final message =
        json?['message']?.toString() ?? response.reasonPhrase ?? 'HTTP $status';

    final errorType = json?['error_type']?.toString().toLowerCase();
    switch (status) {
      case 402:
        // RFC 7231 Payment Required. The cleanest signal for plan-gated
        // endpoints — when the server flips to emitting it, no further
        // client changes needed.
        throw PlanRequiredException(message);
      case 403:
        final isPasswordRequired =
            message.toLowerCase().contains('password') ||
            errorType?.contains('password') == true;
        if (isPasswordRequired) {
          throw const PasswordRequiredException();
        }
        // Authoritative plan-required signal: parallel to the password
        // sniff above, the server can mark a 403 with `error_type:
        // "plan_required"` to distinguish "you're on the wrong plan"
        // from "you're not authorized for this resource".
        if (errorType == 'plan_required') {
          throw PlanRequiredException(message);
        }
        throw ServerException(status, message);
      case 412:
        // Invoice Ninja signals "password-protected route — resend with
        // X-API-PASSWORD-BASE64" via 412 Precondition Failed (body is
        // `{"message":"Invalid Password","errors":{}}`). Matches the
        // legacy admin-portal `'$error'.contains('412')` convention; the
        // 403 branch above stays as a defensive sniff in case a future
        // server build flips back. The User Details flow specifically
        // routes around this by reading from /refresh; this mapping
        // covers any future call site that hits a password-protected
        // endpoint directly.
        throw const PasswordRequiredException();
      case 404:
        // Treated as a conflict: the entity was deleted server-side while
        // we held a pending mutation locally. The sync engine routes
        // ConflictException to ConflictResolutionSheet (delete locally /
        // recreate). Without this mapping a 404 falls into the default
        // ServerException branch, gets retried five times, and is
        // silently marked dead — the user never sees the resolution UI.
        throw ConflictException(message);
      case 409:
        throw ConflictException(message);
      case 422:
        final raw = json?['errors'];
        final fieldErrors = <String, List<String>>{};
        if (raw is Map<String, dynamic>) {
          for (final entry in raw.entries) {
            final v = entry.value;
            if (v is List) {
              fieldErrors[entry.key] = v.map((e) => e.toString()).toList();
            } else if (v is String) {
              fieldErrors[entry.key] = [v];
            }
          }
        }
        throw ValidationException(message, fieldErrors);
      case 429:
        final retryAfterHeader = response.headers['retry-after'];
        Duration? retryAfter;
        if (retryAfterHeader != null) {
          final secs = int.tryParse(retryAfterHeader);
          if (secs != null) retryAfter = Duration(seconds: secs);
        }
        throw RateLimitedException(retryAfter: retryAfter, message: message);
      default:
        if (status >= 500) throw ServerException(status, message);
        throw ServerException(status, message);
    }
  }

  Map<String, String> _buildHeaders({
    required ApiCredentials creds,
    String? idempotencyKey,
    String? passwordBase64,
    bool contentTypeJson = false,
  }) {
    return {
      'Accept': 'application/json',
      if (contentTypeJson) 'Content-Type': 'application/json; charset=UTF-8',
      'X-API-Token': creds.token,
      'X-CLIENT-PLATFORM': Env.clientPlatform,
      'X-CLIENT-VERSION': AppVersion.kClientVersion,
      'X-Requested-With': 'com.invoiceninja.admin',
      if (creds.isHosted && creds.apiSecret.isNotEmpty)
        'X-API-SECRET': creds.apiSecret,
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      if (passwordBase64 != null) 'X-API-PASSWORD-BASE64': passwordBase64,
    };
  }

  ApiCredentials _requireCreds() {
    final c = _creds;
    if (c == null || !c.isAuthenticated) {
      throw const UnauthorizedException('Not authenticated');
    }
    return c;
  }

  /// Compare two semver-ish strings (`a.b.c[-pre]`). Returns -1, 0, 1.
  static int _compareSemver(String a, String b) {
    final aParts = a.split('-').first.split('.').map(int.tryParse).toList();
    final bParts = b.split('-').first.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = (i < aParts.length ? aParts[i] : null) ?? 0;
      final bv = (i < bParts.length ? bParts[i] : null) ?? 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  // Parse a response body off the main isolate with a hard timeout.
  // Why: a pathological JSON payload (multi-MB, deeply nested) can hang the
  // worker indefinitely; without a ceiling, the calling list view spins
  // forever and the user has to kill the app.
  Future<dynamic> _decodeBody(String body) async {
    try {
      return await _decoder(body).timeout(_decodeTimeout);
    } on TimeoutException {
      throw const NetworkException('Response parse timed out');
    }
  }

  static Future<dynamic> _defaultDecoder(String body) =>
      compute(_decodeJson, body);
}

dynamic _decodeJson(String body) => jsonDecode(body);

/// Result of [ApiClient.postRawOrPending]: either the finished binary
/// ([bytes] non-null) or a "still processing, poll again" signal
/// ([isPending] true). Never both.
class RawOrPending {
  const RawOrPending.ready(this.bytes) : isPending = false;
  const RawOrPending.pending() : bytes = null, isPending = true;

  final Uint8List? bytes;
  final bool isPending;
}
