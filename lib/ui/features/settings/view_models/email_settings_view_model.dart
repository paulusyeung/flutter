import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// VM for Settings → Email Settings. Mostly inherits dirty / save / override
/// behavior from [SettingsDraftViewModel]; adds one extra knob: a one-shot
/// `sync_send_time` flag that's stashed onto the next outbox payload when
/// the user confirms "Also apply to existing entities" under the
/// `entity_send_time` dropdown.
///
/// The flag rides on a control key (`_sync_send_time`) that
/// [CompanySyncDispatcher] pops off the payload before serializing and
/// converts to a `?sync_send_time=true|false` query param on the company
/// PUT. Same precedent the dispatcher uses for the `_action: upload_logo` /
/// `upload_document` upload paths.
class EmailSettingsViewModel extends SettingsDraftViewModel {
  EmailSettingsViewModel({required super.repo, required super.companyId});

  bool _pendingSyncSendTime = false;

  /// Snapshot the user's checkbox state. Cleared on each save (success or
  /// failure) so a follow-up save without a fresh tick defaults to `false`.
  void setSyncSendTimeFlag(bool value) {
    if (_pendingSyncSendTime == value) return;
    _pendingSyncSendTime = value;
    // The CheckboxListTile renders `pendingSyncSendTime` and rebuilds only
    // on VM notify — without this the box never visibly ticked, every
    // retry-tap passed `true` again, and the flag stayed silently latched
    // (triggering the server-side bulk send-time update on the next save
    // while the UI showed it unchecked).
    notifyListeners();
  }

  /// True when the inline "Sync to existing entities" checkbox is currently
  /// ticked. Read by the body widget so the checkbox tile reflects state
  /// after a rebuild without re-creating its own listener.
  bool get pendingSyncSendTime => _pendingSyncSendTime;

  @override
  Map<String, dynamic>? extraOutboxPayload() {
    if (!_pendingSyncSendTime) return null;
    return const {'_sync_send_time': true};
  }

  @override
  Future<Company?> save() async {
    try {
      return await super.save();
    } finally {
      // One-shot — the next save without a re-tick defaults back to false.
      _pendingSyncSendTime = false;
    }
  }
}
