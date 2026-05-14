import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the group_settings edit + create screen. Optimistic — `save()`
/// lands the draft in Drift via the repo and the outbox handles the
/// server round-trip.
class GroupSettingEditViewModel extends GenericEditViewModel<GroupSetting> {
  GroupSettingEditViewModel({
    required this.repo,
    required this.companyId,
    GroupSetting? existing,
  }) : super(initialDraft: existing ?? _emptyGroup(), original: existing);

  final GroupSettingRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty || (d.settings?.isNotEmpty ?? false);
  }

  @override
  Future<GroupSetting> performSave() async {
    if (isCreate) {
      return await repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, group: draft);
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: _emptyGroup());

  void setName(String v) => updateDraft(draft.copyWith(name: v));

  /// Set / clear a cascade override (e.g. `currency_id`). Passing null or
  /// '' removes the key — the group will inherit from company.
  void setCascadeOverride(String key, String? value) =>
      updateDraft(draft.withCascadeOverride(key, value));
}

GroupSetting _emptyGroup() => GroupSetting(
  id: '',
  name: '',
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
