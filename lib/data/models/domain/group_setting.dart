import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/group_setting_api_model.dart';

part 'group_setting.freezed.dart';

/// Clean domain model for a group_settings row. Mirrors `Product` /
/// `Client` shape: `Group.fromApi(...)` walks the raw DTO; `_fromRow` in
/// the repository overlays the local-only `isDirty` flag.
///
/// The `settings` map is sparse — keys not present mean "inherit from
/// company." Use [withCascadeOverride] to set/clear individual keys with
/// the correct inherit-on-empty semantics.
@freezed
abstract class GroupSetting with _$GroupSetting {
  const GroupSetting._();

  const factory GroupSetting({
    required String id,
    required String name,
    required String customValue1,
    required String customValue2,
    required String customValue3,
    required String customValue4,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    // Sparse cascade overrides. Stored raw because keys vary widely;
    // the typed `CompanySettings` view is reconstructed on demand.
    Map<String, dynamic>? settings,
    @Default(false) bool isDirty,
  }) = _GroupSetting;

  /// `settings.currency_id`, or null when this group inherits from company.
  String? get currencyId => settings?['currency_id'] as String?;

  /// `settings.language_id`, or null when this group inherits from company.
  String? get languageId => settings?['language_id'] as String?;

  /// `settings.country_id`, or null when this group inherits from company.
  String? get countryId => settings?['country_id'] as String?;

  /// Return a copy with `settings[key]` set to [value], or with the key
  /// **removed** when [value] is null or empty. Removing the key is the
  /// admin-portal convention for "inherit from company" — an empty string
  /// would otherwise be an explicit override-to-blank.
  GroupSetting withCascadeOverride(String key, String? value) {
    final next = Map<String, dynamic>.from(settings ?? const {});
    if (value == null || value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(settings: next.isEmpty ? null : next);
  }

  factory GroupSetting.fromApi(GroupSettingApi a) => GroupSetting(
    id: a.id,
    name: a.name,
    customValue1: a.customValue1,
    customValue2: a.customValue2,
    customValue3: a.customValue3,
    customValue4: a.customValue4,
    updatedAt: _seconds(a.updatedAt),
    createdAt: _seconds(a.createdAt),
    archivedAt: a.archivedAt > 0 ? _seconds(a.archivedAt) : null,
    isDeleted: a.isDeleted,
    settings: a.settings,
  );
}

DateTime _seconds(int s) =>
    DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);

extension GroupSettingPayload on GroupSetting {
  /// Serialize the in-memory group back to the JSON shape the server
  /// expects. `preserveTempId` lets callers (the local Drift cache) keep
  /// the temp id; outbound `POST /group_settings` payloads drop it.
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'custom_value1': customValue1,
      'custom_value2': customValue2,
      'custom_value3': customValue3,
      'custom_value4': customValue4,
      // Only emit when the user has actually overridden something.
      if (settings != null && settings!.isNotEmpty) 'settings': settings,
    };
    return json;
  }
}
