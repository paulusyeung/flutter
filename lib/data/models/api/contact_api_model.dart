import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_api_model.freezed.dart';
part 'contact_api_model.g.dart';

/// Raw JSON shape of a `client.contacts[]` entry as returned by the server.
///
/// Field names mirror the server keys exactly so `fromJson` is mechanical.
/// Map to the cleaner [Contact] domain type before exposing to ViewModels.
@freezed
abstract class ContactApi with _$ContactApi {
  const factory ContactApi({
    @Default('') String id,
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @Default('') String email,
    @Default('') String phone,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'send_email') @Default(true) bool sendEmail,
    @JsonKey(name: 'cc_only') @Default(false) bool ccOnly,
    @JsonKey(name: 'is_locked') @Default(false) bool isLocked,
    @JsonKey(name: 'can_sign') @Default(false) bool canSign,
    @Default('') String password,
    @JsonKey(name: 'contact_key') @Default('') String contactKey,
    @Default('') String link,
    @JsonKey(name: 'last_login') @Default(0) int lastLogin,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _ContactApi;

  factory ContactApi.fromJson(Map<String, dynamic> json) =>
      _$ContactApiFromJson(json);
}
