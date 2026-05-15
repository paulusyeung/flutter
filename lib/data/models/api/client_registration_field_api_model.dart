import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_registration_field_api_model.freezed.dart';
part 'client_registration_field_api_model.g.dart';

/// One entry in `company.client_registration_fields` — drives whether a
/// per-field input on the public `/client/register` form is hidden, optional,
/// or required. Field keys come from a fixed catalog (`kClientRegistrationFieldKeys`).
@freezed
abstract class ClientRegistrationFieldApi with _$ClientRegistrationFieldApi {
  @JsonSerializable(includeIfNull: false)
  const factory ClientRegistrationFieldApi({
    @Default('') String key,
    @Default(false) bool required,
    @Default(true) bool visible,
  }) = _ClientRegistrationFieldApi;

  factory ClientRegistrationFieldApi.fromJson(Map<String, dynamic> json) =>
      _$ClientRegistrationFieldApiFromJson(json);
}
