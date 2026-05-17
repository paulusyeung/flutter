import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_api_model.freezed.dart';
part 'search_result_api_model.g.dart';

/// One row inside a `POST /api/v1/search` group. The response is a map of
/// `{ clients: [...], invoices: [...], settings: [...], ... }`; each entry
/// is this shape (`{name, type, id, path}`). `path` is the server-rendered
/// destination; `type` is a slash-prefixed kind (`/client`, `/invoice`) or
/// a settings slug.
@freezed
abstract class SearchResultApi with _$SearchResultApi {
  const factory SearchResultApi({
    @Default('') String name,
    @Default('') String type,
    @Default('') String id,
    @Default('') String path,
  }) = _SearchResultApi;

  factory SearchResultApi.fromJson(Map<String, dynamic> json) =>
      _$SearchResultApiFromJson(json);
}
