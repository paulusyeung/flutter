import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
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
    super.sync,
    super.connectivity,
  }) : super(
         initialDraft: existing ?? _emptyGroup(),
         original: existing,
         companyId: companyId,
       );

  final GroupSettingRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.name.isNotEmpty || (d.settings?.isNotEmpty ?? false);
  }

  @override
  Future<SaveResult<GroupSetting>> performSave() async {
    if (isCreate) {
      final result = await repo.create(
        companyId: companyId,
        draft: draft,
        existingTempId: recoveryTempId,
      );
      rememberCreateTempId(result.entity.id);
      return result;
    }
    return repo.save(companyId: companyId, group: draft);
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
