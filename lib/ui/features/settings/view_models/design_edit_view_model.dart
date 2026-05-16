import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

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

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty ||
        d.template.body.isNotEmpty ||
        d.template.header.isNotEmpty ||
        d.template.footer.isNotEmpty ||
        d.template.includes.isNotEmpty ||
        d.template.product.isNotEmpty ||
        d.template.task.isNotEmpty;
  }

  @override
  Future<Design> performSave() async {
    if (isCreate) {
      return repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, design: draft);
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: _emptyDesign());

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
  /// "duplicate / new from existing" flow) while keeping the current id so
  /// the save still targets this draft.
  void loadFrom(Design source) {
    updateDraft(
      draft.copyWith(
        name: draft.name.isEmpty ? source.name : draft.name,
        entities: List<String>.from(source.entities),
        template: source.template,
      ),
    );
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
