import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/domain/design_block_layout.dart';
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
        : a.entities
              .split(',')
              .where((e) => e.isNotEmpty)
              .toList(growable: false),
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
    @Default(<DesignBlock>[]) List<DesignBlock> blocks,
    DocumentSettings? documentSettings,
  }) = _DesignTemplate;

  factory DesignTemplate.fromApi(DesignTemplateApi a) => DesignTemplate(
    body: a.body,
    header: a.header,
    footer: a.footer,
    includes: a.includes,
    product: a.product,
    task: a.task,
    blocks: a.blocks.map(DesignBlock.fromApi).toList(growable: false),
    documentSettings: a.documentSettings == null
        ? null
        : DocumentSettings.fromApi(a.documentSettings!),
  );
}

extension DesignTemplateApiMapper on DesignTemplate {
  /// Round-trip back to the API shape for outbox payloads. Blocks are
  /// projected through [annotateBlocksAsApi] so each block carries the
  /// `rowAlign` / `rowWidth` / `colStart` / `colSpan` fields the
  /// server-side HTML generator needs to place them in flex rows.
  /// Legacy designs (empty blocks) emit `blocks: []` unchanged.
  DesignTemplateApi toApi() => DesignTemplateApi(
    body: body,
    header: header,
    footer: footer,
    includes: includes,
    product: product,
    task: task,
    blocks: annotateBlocksAsApi(blocks),
    documentSettings: documentSettings?.toApi(),
  );
}

/// A single WYSIWYG canvas block. `properties` stays a typed-loose
/// `Map<String, dynamic>` — the React schema is `Record<string, any>` with
/// only TypeScript hints, so block renderers and property panels read keys
/// directly. Use `DesignBlock.locked == true` to suppress drag/resize.
@freezed
abstract class DesignBlock with _$DesignBlock {
  const factory DesignBlock({
    required String id,
    required String type,
    required GridPosition gridPosition,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
    @Default(false) bool locked,
  }) = _DesignBlock;

  factory DesignBlock.fromApi(DesignBlockApi a) => DesignBlock(
    id: a.id,
    type: a.type,
    gridPosition: GridPosition.fromApi(a.gridPosition),
    properties: a.properties == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(a.properties!),
    locked: a.locked ?? false,
  );
}

extension DesignBlockApiMapper on DesignBlock {
  DesignBlockApi toApi() => DesignBlockApi(
    id: id,
    type: type,
    gridPosition: gridPosition.toApi(),
    properties: properties.isEmpty
        ? null
        : Map<String, dynamic>.from(properties),
    locked: locked ? true : null,
  );
}

/// `x` 0..=11 column index, `w` 1..=12 column span. `y` and `h` are row
/// indices (unbounded).
@freezed
abstract class GridPosition with _$GridPosition {
  const factory GridPosition({
    required int x,
    required int y,
    required int w,
    required int h,
  }) = _GridPosition;

  factory GridPosition.fromApi(GridPositionApi a) =>
      GridPosition(x: a.x, y: a.y, w: a.w, h: a.h);
}

extension GridPositionApiMapper on GridPosition {
  GridPositionApi toApi() => GridPositionApi(x: x, y: y, w: w, h: h);
}

/// Per-template document-level settings, seeded from `company.settings` and
/// overridable per design. All fields are required once present.
@freezed
abstract class DocumentSettings with _$DocumentSettings {
  const factory DocumentSettings({
    @Default('portrait') String pageLayout,
    @Default('A4') String pageSize,
    @Default(16) int globalFontSize,
    @Default('Roboto') String primaryFont,
    @Default('Roboto') String secondaryFont,
    @Default(false) bool showPaidStamp,
    @Default(false) bool showShippingAddress,
    @Default(false) bool embedDocuments,
    @Default(false) bool hideEmptyColumns,
    @Default(false) bool pageNumbering,
    @Default(0) int pageMarginTop,
    @Default(0) int pageMarginRight,
    @Default(0) int pageMarginBottom,
    @Default(0) int pageMarginLeft,
    @Default(30) int pagePaddingTop,
    @Default(30) int pagePaddingRight,
    @Default(30) int pagePaddingBottom,
    @Default(30) int pagePaddingLeft,
  }) = _DocumentSettings;

  factory DocumentSettings.fromApi(DocumentSettingsApi a) => DocumentSettings(
    pageLayout: a.pageLayout,
    pageSize: a.pageSize,
    globalFontSize: a.globalFontSize,
    primaryFont: a.primaryFont,
    secondaryFont: a.secondaryFont,
    showPaidStamp: a.showPaidStamp,
    showShippingAddress: a.showShippingAddress,
    embedDocuments: a.embedDocuments,
    hideEmptyColumns: a.hideEmptyColumns,
    pageNumbering: a.pageNumbering,
    pageMarginTop: a.pageMarginTop,
    pageMarginRight: a.pageMarginRight,
    pageMarginBottom: a.pageMarginBottom,
    pageMarginLeft: a.pageMarginLeft,
    pagePaddingTop: a.pagePaddingTop,
    pagePaddingRight: a.pagePaddingRight,
    pagePaddingBottom: a.pagePaddingBottom,
    pagePaddingLeft: a.pagePaddingLeft,
  );
}

extension DocumentSettingsApiMapper on DocumentSettings {
  DocumentSettingsApi toApi() => DocumentSettingsApi(
    pageLayout: pageLayout,
    pageSize: pageSize,
    globalFontSize: globalFontSize,
    primaryFont: primaryFont,
    secondaryFont: secondaryFont,
    showPaidStamp: showPaidStamp,
    showShippingAddress: showShippingAddress,
    embedDocuments: embedDocuments,
    hideEmptyColumns: hideEmptyColumns,
    pageNumbering: pageNumbering,
    pageMarginTop: pageMarginTop,
    pageMarginRight: pageMarginRight,
    pageMarginBottom: pageMarginBottom,
    pageMarginLeft: pageMarginLeft,
    pagePaddingTop: pagePaddingTop,
    pagePaddingRight: pagePaddingRight,
    pagePaddingBottom: pagePaddingBottom,
    pagePaddingLeft: pagePaddingLeft,
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
