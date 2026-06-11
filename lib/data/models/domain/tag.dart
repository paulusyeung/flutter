import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/tag_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'tag.freezed.dart';

/// Clean domain model for a Tag row. Tags are scoped to a single
/// `entityType` (`task` / `project`) and attached to tasks/projects by id.
/// Managed via Settings → Tags; selected on the Task/Project edit forms.
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String entityType,
    required String name,
    // Hex string (`#RRGGBB`); empty when unset.
    required String color,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _Tag;

  factory Tag.fromApi(TagApi a, {String? entityTypeOverride}) => Tag(
    id: a.id,
    entityType: entityTypeOverride ?? normalizeTagEntityType(a.entityType),
    name: a.name,
    color: a.color ?? '',
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

/// Build a draft [Tag] for inline creation — random color, no id yet (the
/// repo mints a `tmp_` id). Local timestamps are placeholders until the
/// create response lands.
Tag newTagDraft({required String name, required String entityType}) {
  final now = DateTime.now();
  return Tag(
    id: '',
    entityType: entityType,
    name: name.trim(),
    color: randomTagColor(),
    updatedAt: now,
    createdAt: now,
    archivedAt: null,
    isDeleted: false,
  );
}

/// Random `#RRGGBB` color, mirroring React's `randomTagColor()` — keeps
/// inline-created tags visually distinct without a color-pick step.
String randomTagColor() {
  final n = Random().nextInt(0x1000000);
  return '#${n.toRadixString(16).padLeft(6, '0')}';
}

extension TagPayload on Tag {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      // `entity_type` is required on create (server normalizes the short key
      // to the FQCN) and ignored on update — harmless to always include.
      'entity_type': entityType,
      'name': name,
      // Server converts '' → null in prepareForValidation, so an empty string
      // clears the color.
      'color': color,
    };
  }
}
