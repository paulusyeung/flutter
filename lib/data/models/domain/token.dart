import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/token_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'token.freezed.dart';

/// Length of the suffix the server appends when masking a token. Confirmed
/// in admin-portal v1 (`lib/data/models/token_model.dart:96`).
const String _kMaskSuffix = 'xxxxxxxxxxx';
const int _kRawSecretPrefixLength = 10;

/// Domain `Token` (wire entity: `token` / `company_token`). Settings-area
/// entity reached via Settings → Integrations → API Tokens. Bundled on
/// `/refresh?first_load=true` via `tokens_hashed`.
///
/// The server returns the **raw bearer secret** in [token] only on the
/// create response; every subsequent payload returns a masked form. We
/// never round-trip the masked value back to the server (see [toApiJson]).
@freezed
abstract class Token with _$Token {
  const Token._();

  const factory Token({
    required String id,
    required String userId,
    required String token,
    required String name,
    required bool isSystem,
    required bool isDeleted,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    @Default(false) bool isDirty,
  }) = _Token;

  factory Token.fromApi(TokenApi a) => Token(
    id: a.id,
    userId: a.userId,
    token: a.token,
    name: a.name,
    isSystem: a.isSystem,
    isDeleted: a.isDeleted,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
  );

  /// `true` when [token] is the server's `<prefix>xxxxxxxxxxx` masked form
  /// — i.e. anything except the one-shot value returned on create.
  bool get isMasked =>
      token.length >= _kRawSecretPrefixLength + _kMaskSuffix.length &&
      token.endsWith(_kMaskSuffix);

  /// User-facing hint for the list page: `<first 10 chars>…`. Falls back to
  /// the bare token for short values (shouldn't happen with real server
  /// data, but defends against synthetic test rows).
  String get tokenHint => token.length >= _kRawSecretPrefixLength
      ? '${token.substring(0, _kRawSecretPrefixLength)}…'
      : token;

  /// Send-shape used by the outbox.
  ///
  /// **Never echoes the masked `token` back to the server.** The server
  /// mints the secret on create (we don't supply one) and ignores any
  /// `token` field on update (the masked string would be garbage to it).
  /// The joined `user_id` is read-only — owning user comes from the
  /// session, not the payload.
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = TokenApi(
      id: id,
      name: name,
      isSystem: isSystem,
      isDeleted: isDeleted,
      updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
      archivedAt:
          archivedAt == null ? 0 : archivedAt!.millisecondsSinceEpoch ~/ 1000,
    ).toJson();
    if (!preserveTempId && id.startsWith('tmp_')) {
      json.remove('id');
    }
    // `token` and `user_id` are read-only on this surface — strip them
    // from every outgoing payload.
    json.remove('token');
    json.remove('user_id');
    return json;
  }
}
