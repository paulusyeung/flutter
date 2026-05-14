import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_api_model.freezed.dart';
part 'design_api_model.g.dart';

/// HTML template payload nested under `design.design` on each Design row.
/// Mirrors the server contract: six raw HTML strings the PDF renderer
/// concatenates (`includes` CSS, `header`, `body`, `product`, `task`,
/// `footer`).
///
/// `body` is the only required section for `is_template = true` rows;
/// non-template designs carry every section.
@freezed
abstract class DesignTemplateApi with _$DesignTemplateApi {
  const factory DesignTemplateApi({
    @Default('') String body,
    @Default('') String header,
    @Default('') String footer,
    @Default('') String includes,
    @Default('') String product,
    @Default('') String task,
  }) = _DesignTemplateApi;

  factory DesignTemplateApi.fromJson(Map<String, dynamic> json) =>
      _$DesignTemplateApiFromJson(json);
}

/// Raw JSON shape of a design row as returned by `/api/v1/designs` and
/// bundled in `data[N].company.designs` on `/login`/`/refresh`.
///
/// `entities` is a comma-separated string on the wire (e.g. `"invoice,quote"`)
/// — not a JSON array. Domain projection ([Design]) splits on `,`.
@freezed
abstract class DesignApi with _$DesignApi {
  const factory DesignApi({
    @Default('') String id,
    @Default('') String name,
    @JsonKey(name: 'is_custom') @Default(false) bool isCustom,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_template') @Default(false) bool isTemplate,
    @JsonKey(name: 'is_free') @Default(true) bool isFree,
    @Default('') String entities,
    @Default(DesignTemplateApi()) DesignTemplateApi design,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _DesignApi;

  factory DesignApi.fromJson(Map<String, dynamic> json) =>
      _$DesignApiFromJson(json);
}

/// `GET /designs` response envelope.
@freezed
abstract class DesignListApi with _$DesignListApi {
  const factory DesignListApi({@Default(<DesignApi>[]) List<DesignApi> data}) =
      _DesignListApi;

  factory DesignListApi.fromJson(Map<String, dynamic> json) =>
      _$DesignListApiFromJson(json);
}

/// `POST/PUT /designs/{id}` single-item envelope.
@freezed
abstract class DesignItemApi with _$DesignItemApi {
  const factory DesignItemApi({required DesignApi data}) = _DesignItemApi;

  factory DesignItemApi.fromJson(Map<String, dynamic> json) =>
      _$DesignItemApiFromJson(json);
}
