import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'design.freezed.dart';

/// Clean domain model for a Design row. Used by the Invoice Design settings
/// page's design pickers (`invoice_design_id`, `quote_design_id`, …) and
/// the upcoming Custom Designs CRUD list.
///
/// `entities` on the wire is a comma-separated string; we project it to
/// `List<String>` here so call sites can iterate without re-parsing. Re-join
/// on save (see [DesignPayload.toApiJson]).
@freezed
abstract class Design with _$Design {
  const factory Design({
    required String id,
    required String name,
    required bool isCustom,
    required bool isActive,
    required bool isTemplate,
    required bool isFree,
    required List<String> entities,
    required DesignTemplate template,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _Design;

  factory Design.fromApi(DesignApi a) => Design(
    id: a.id,
    name: a.name,
    isCustom: a.isCustom,
    isActive: a.isActive,
    isTemplate: a.isTemplate,
    isFree: a.isFree,
    entities: a.entities.isEmpty
        ? const <String>[]
        : a.entities.split(',').where((e) => e.isNotEmpty).toList(growable: false),
    template: DesignTemplate.fromApi(a.design),
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

@freezed
abstract class DesignTemplate with _$DesignTemplate {
  const factory DesignTemplate({
    @Default('') String body,
    @Default('') String header,
    @Default('') String footer,
    @Default('') String includes,
    @Default('') String product,
    @Default('') String task,
  }) = _DesignTemplate;

  factory DesignTemplate.fromApi(DesignTemplateApi a) => DesignTemplate(
    body: a.body,
    header: a.header,
    footer: a.footer,
    includes: a.includes,
    product: a.product,
    task: a.task,
  );

  /// Round-trip back to the API shape for outbox payloads.
  DesignTemplateApi toApi() => DesignTemplateApi(
    body: body,
    header: header,
    footer: footer,
    includes: includes,
    product: product,
    task: task,
  );
}

extension DesignPayload on Design {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'is_custom': isCustom,
      'is_active': isActive,
      'is_template': isTemplate,
      'is_free': isFree,
      'entities': entities.join(','),
      'design': template.toApi().toJson(),
    };
  }
}
