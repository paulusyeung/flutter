import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_api_model.freezed.dart';
part 'document_api_model.g.dart';

/// Wire shape of an attachment record. Embedded as a JSON array on every
/// entity that supports documents (Company, Client, Product, …) — the
/// server's `documents` field has the same shape regardless of parent.
///
/// Only the fields the UI surfaces are modeled — the server sends a dozen
/// more (width / height / preview / parent_* / disk) that aren't useful
/// today. Add them here when a feature actually needs them.
@freezed
abstract class DocumentApi with _$DocumentApi {
  @JsonSerializable(includeIfNull: false)
  const factory DocumentApi({
    @Default('') String id,
    @Default('') String name,
    @Default('') String hash,
    @Default('') String type,
    @Default('') String url,
    @Default(0) int size,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
  }) = _DocumentApi;

  factory DocumentApi.fromJson(Map<String, dynamic> json) =>
      _$DocumentApiFromJson(json);
}
