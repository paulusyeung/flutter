import 'dart:convert';

import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Minimal HTML scaffold seeded by the "Blank" start-from option. Mirrors
/// React's blank design (`<ninja>` is the line-item injection point the
/// server understands).
const String kBlankDesignBody =
    '<html>\n\t<head>\n\t</head>\n\t<body>\n\t\t<ninja>\n\n\t\t</ninja>\n\t</body>\n</html>\n';

/// Drives `/settings/invoice_design/custom_designs` create + edit.
/// Optimistic — `save()` lands the draft in Drift via the repo; the
/// outbox handles the server round-trip. Mirrors
/// [TaskStatusEditViewModel].
class DesignEditViewModel extends GenericEditViewModel<Design> {
  DesignEditViewModel({
    required this.repo,
    required this.companyId,
    Design? existing,
  }) : super(initialDraft: existing ?? _emptyDesign(), original: existing);

  final DesignRepository repo;
  final String companyId;

  /// Document types a custom design can be bound to. Matches the current
  /// product (React `CustomDesign` EntityType union); the wire stores these
  /// comma-joined in `Design.entities`.
  static const supportedEntities = <String>[
    'invoice',
    'quote',
    'credit',
    'purchase_order',
  ];

  /// Bumped every time the *whole template* is replaced wholesale
  /// (`loadFrom` / `loadBlankScaffold` / `importFromJson` / `reset`). The
  /// per-section code editors key their reseed off this instead of
  /// `original?.id` — for a brand-new design `original` is null and never
  /// changes, so a Start-from selection would otherwise leave the editors
  /// showing stale empty text. Per-keystroke setters do NOT bump it.
  int get seedRevision => _seedRevision;
  int _seedRevision = 0;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty || templateIsNonEmpty;
  }

  /// True when any template section has content. Drives the "discard current
  /// HTML?" confirm before a Start-from overwrites the draft.
  bool get templateIsNonEmpty {
    final t = draft.template;
    return t.body.isNotEmpty ||
        t.header.isNotEmpty ||
        t.footer.isNotEmpty ||
        t.includes.isNotEmpty ||
        t.product.isNotEmpty ||
        t.task.isNotEmpty;
  }

  @override
  Future<Design> performSave() async {
    if (isCreate) {
      return repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, design: draft);
    return draft;
  }

  void resetToEmpty() {
    reset(emptyDraft: _emptyDesign());
    _seedRevision++;
  }

  void setName(String v) => updateDraft(draft.copyWith(name: v));

  void toggleEntity(String entity, bool selected) {
    final next = List<String>.from(draft.entities)..remove(entity);
    if (selected) next.add(entity);
    updateDraft(draft.copyWith(entities: next));
  }

  void setBody(String v) =>
      updateDraft(draft.copyWith(template: draft.template.copyWith(body: v)));
  void setHeader(String v) =>
      updateDraft(draft.copyWith(template: draft.template.copyWith(header: v)));
  void setFooter(String v) =>
      updateDraft(draft.copyWith(template: draft.template.copyWith(footer: v)));
  void setIncludes(String v) => updateDraft(
    draft.copyWith(template: draft.template.copyWith(includes: v)),
  );
  void setProduct(String v) => updateDraft(
    draft.copyWith(template: draft.template.copyWith(product: v)),
  );
  void setTask(String v) =>
      updateDraft(draft.copyWith(template: draft.template.copyWith(task: v)));

  /// Seed name / entities / template from an existing design (the
  /// "duplicate / new from existing" / "Edit a copy" flow) while keeping the
  /// current id so the save still targets this draft. Always lands as a
  /// **custom, non-template** design even when the source is a built-in —
  /// otherwise the saved row and the `/preview` payload would carry the
  /// source's `is_custom:false` / `is_template:true` flags.
  void loadFrom(Design source) {
    updateDraft(
      draft.copyWith(
        name: draft.name.isEmpty ? source.name : draft.name,
        entities: List<String>.from(source.entities),
        template: source.template,
        isCustom: true,
        isTemplate: false,
      ),
    );
    _seedRevision++;
  }

  /// "Blank" start-from option: a minimal valid HTML scaffold.
  void loadBlankScaffold() {
    updateDraft(
      draft.copyWith(
        template: const DesignTemplate(body: kBlankDesignBody),
        isCustom: true,
        isTemplate: false,
      ),
    );
    _seedRevision++;
  }

  /// Seed the draft from exported design JSON (the [DesignPayload.toApiJson]
  /// shape produced by Export). Returns an error string on malformed input,
  /// or null on success. Keeps the current id so Save targets this draft.
  String? importFromJson(String raw) {
    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return 'invalid_json';
    }
    if (parsed is! Map) return 'invalid_json';
    final map = parsed.cast<String, dynamic>();
    // `design` block may be nested (our export) or the whole thing may be a
    // bare template map; accept both.
    final designBlock = map['design'];
    final tmplSrc = designBlock is Map
        ? designBlock.cast<String, dynamic>()
        : map.cast<String, dynamic>();
    String s(String k) => (tmplSrc[k] ?? '').toString();
    final entitiesRaw = map['entities'];
    final entities = entitiesRaw is List
        ? entitiesRaw.map((e) => e.toString()).toList()
        : entitiesRaw is String
        ? entitiesRaw.split(',').where((e) => e.isNotEmpty).toList()
        : <String>[];
    updateDraft(
      draft.copyWith(
        name: (map['name'] ?? draft.name).toString(),
        entities: entities.isEmpty ? draft.entities : entities,
        template: DesignTemplate(
          body: s('body'),
          header: s('header'),
          footer: s('footer'),
          includes: s('includes'),
          product: s('product'),
          task: s('task'),
        ),
        isCustom: true,
        isTemplate: false,
      ),
    );
    _seedRevision++;
    return null;
  }
}

Design _emptyDesign() => Design(
  id: '',
  name: '',
  isCustom: true,
  isActive: true,
  isTemplate: false,
  isFree: false,
  entities: const <String>[],
  template: const DesignTemplate(),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
