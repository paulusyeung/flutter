import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/project_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the Project edit + create screen. Optimistic — `save()` lands the
/// draft in Drift via the repo, returns the saved entity, and the outbox
/// handles the server round-trip.
class ProjectEditViewModel extends GenericEditViewModel<Project> {
  ProjectEditViewModel({
    required this.repo,
    required this.companyId,
    Project? existing,
    Project? cloneFrom,
    super.sync,
    super.connectivity,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? _emptyProject(),
         original: existing,
         companyId: companyId,
       );

  final ProjectRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty ||
        d.clientId.isNotEmpty ||
        d.dueDate != null ||
        d.budgetedHours != 0 ||
        d.taskRate != Decimal.zero ||
        d.publicNotes.isNotEmpty ||
        d.privateNotes.isNotEmpty;
  }

  @override
  Future<SaveResult<Project>> performSave() async {
    if (isCreate) {
      final result = await repo.create(
        companyId: companyId,
        draft: draft,
        existingTempId: recoveryTempId,
      );
      rememberCreateTempId(result.entity.id);
      return result;
    }
    return repo.save(companyId: companyId, project: draft);
  }

  void resetToEmpty() => reset(emptyDraft: _emptyProject());

  // ── Field setters ──────────────────────────────────────────────────

  void setName(String v) => updateDraft(draft.copyWith(name: v));
  void setNumber(String v) => updateDraft(draft.copyWith(number: v));
  void setClientId(String v) => updateDraft(draft.copyWith(clientId: v));
  void setAssignedUserId(String v) =>
      updateDraft(draft.copyWith(assignedUserId: v));
  void setDueDate(Date? d) => updateDraft(draft.copyWith(dueDate: d));
  void setBudgetedHours(String input) => updateDraft(
    draft.copyWith(budgetedHours: double.tryParse(input.trim()) ?? 0.0),
  );
  void setTaskRate(String input) => updateDraft(
    draft.copyWith(taskRate: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setColor(String v) => updateDraft(draft.copyWith(color: v));
  void setPublicNotes(String v) => updateDraft(draft.copyWith(publicNotes: v));
  void setPrivateNotes(String v) =>
      updateDraft(draft.copyWith(privateNotes: v));
  void setCustomValue1(String v) =>
      updateDraft(draft.copyWith(customValue1: v));
  void setCustomValue2(String v) =>
      updateDraft(draft.copyWith(customValue2: v));
  void setCustomValue3(String v) =>
      updateDraft(draft.copyWith(customValue3: v));
  void setCustomValue4(String v) =>
      updateDraft(draft.copyWith(customValue4: v));
}

Project _emptyProject() => Project(
  id: '',
  userId: '',
  assignedUserId: '',
  clientId: '',
  number: '',
  name: '',
  taskRate: Decimal.zero,
  dueDate: null,
  privateNotes: '',
  publicNotes: '',
  budgetedHours: 0.0,
  currentHours: 0.0,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  color: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
