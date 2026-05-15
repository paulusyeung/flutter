import 'package:admin/data/models/domain/user.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/ui/features/settings/view_models/draft_stream_host.dart';

/// Backs the Settings > User Details tabbed shell. Loads the auth user via
/// [UserRepository], tracks a [User] draft, and saves through the outbox.
///
/// Implements [SettingsDraftHost] (via [DraftStreamHost]) for compatibility
/// with the existing [TabbedSettingsShell] / [SettingsPageScaffold]
/// machinery. The cascade methods on [SettingsDraftHost] default to no-ops,
/// so this VM doesn't have to stub them — User Details doesn't use the
/// override widgets.
class UserDetailsViewModel extends DraftStreamHost<User> {
  UserDetailsViewModel({
    required this.repo,
    required this.auth,
    required this.companyId,
  }) : userId = auth.session.value?.userId ?? '';

  final UserRepository repo;
  final AuthRepository auth;
  final String companyId;
  final String userId;

  String? _pendingPassword;

  // -- DraftStreamHost glue --------------------------------------------------

  @override
  User get emptyValue => const User();

  @override
  Stream<User?> createWatch() =>
      repo.watch(companyId: companyId, id: userId);

  /// Pull a fresh server snapshot via `/api/v1/refresh` so the auth user
  /// row is the latest version in Drift before the user can edit
  /// anything. `_persistAndActivate` writes the `users` table from the
  /// refresh envelope's `data[N].user` block — without this round-trip
  /// the draft would stay as whatever was persisted at login (still fine
  /// to edit, but possibly stale). We deliberately avoid
  /// `GET /api/v1/users/{id}` because the server gates it with a 412
  /// password check; `/refresh` carries the full user record password-
  /// free.
  @override
  Future<void> kickRefresh() async {
    try {
      await auth.refresh();
    } catch (_) {
      // Swallow — failures are non-fatal; the watch stream already
      // surfaced whatever was last persisted.
    }
  }

  @override
  String? preLoadError() {
    if (userId.isEmpty || companyId.isEmpty) {
      return 'Missing session — please sign in again';
    }
    return null;
  }

  @override
  String? preSaveError(User draft) {
    // Refuse to enqueue with a missing id — the dispatcher would route
    // to `/api/v1/users/` and the server would 404. Surface a clear
    // error so the user retries (likely after `refresh` lands the row).
    if (draft.id.isEmpty) return 'User record not loaded yet';
    return null;
  }

  @override
  Future<User> performSave(User draft) async {
    final body = _buildBody(draft);
    await repo.enqueueUpdate(
      companyId: companyId,
      draft: draft,
      body: body,
      requiresPassword: _pendingPassword != null,
    );
    return draft;
  }

  @override
  void onSaveSuccess(User saved) {
    _pendingPassword = null;
  }

  @override
  void onReset() {
    _pendingPassword = null;
  }

  // -- Public user-specific surface ------------------------------------------

  /// Snapshot of the in-progress edit. Tab bodies bind to this directly.
  User? get user => draftValue;

  /// Loaded baseline (last server state). Used by the diff-view tabs
  /// (Connect) that render server status rather than draft fields.
  User? get initial => initialValue;

  void updateUser(User Function(User draft) edit) => updateDraft(edit);

  void updateCompanyUserSettings(
    CompanyUserSettings Function(CompanyUserSettings settings) edit,
  ) {
    updateDraft(
      (u) => u.copyWith(companyUserSettings: edit(u.companyUserSettings)),
    );
  }

  /// Replace the per-event notifications list. Pass the canonical wire
  /// format (`['invoice_sent_user', 'payment_success_all', ...]` or one
  /// of the master codes `'all_notifications'` /
  /// `'all_user_notifications'`).
  void setNotificationsEmail(List<String> codes) {
    updateDraft((u) => u.copyWith(notificationsEmail: codes));
  }

  /// Stash the pending-new-password the dispatcher will send under the
  /// `password` key. Cleared after a successful save.
  void setPendingPassword(String? value) {
    _pendingPassword = (value != null && value.isEmpty) ? null : value;
    notifyListeners();
  }

  bool get hasPendingPassword => _pendingPassword != null;

  /// Build the PUT body. Serializes the entire draft user back to the
  /// `/api/v1/users/{id}` shape so fields we don't edit (oauth/2fa
  /// flags, permissions, etc.) round-trip untouched. Empty `language_id`
  /// is stripped — Laravel rejects `""` cast to the language foreign
  /// key.
  Map<String, dynamic> _buildBody(User draft) {
    final body = Map<String, dynamic>.from(draft.toApi().toJson());
    if (draft.languageId.isEmpty) body.remove('language_id');
    final password = _pendingPassword;
    if (password != null) body['password'] = password;
    return body;
  }

  /// Enqueue a disconnect action. The dispatcher routes by the payload's
  /// `_action` key — see [UserSyncDispatcher].
  Future<void> enqueueDisconnect({required String action}) {
    return repo.enqueueUpdate(
      companyId: companyId,
      draft: draftValue ?? const User(),
      body: <String, dynamic>{'_action': action},
    );
  }

  // -- 422 → tab-jump --------------------------------------------------------

  /// Per-tab field-key mapping. Used by [TabbedSettingsShell] to jump to
  /// the offending tab when a 422 arrives. Keep in sync with the field
  /// surface each tab body actually renders — missing keys just stay
  /// put.
  static const Map<String, String> _fieldKeyToTabSlug = <String, String>{
    'first_name': '',
    'last_name': '',
    'email': '',
    'phone': '',
    'signature': '',
    'language_id': '',
    'password': 'password',
    'accent_color': 'preferences',
    'notifications': 'notifications',
    'notifications.email': 'notifications',
  };

  /// Returns the slug of the first tab carrying a field error, or null
  /// when there are no errors (or none are mapped).
  String? tabSlugForFirstError() {
    if (fieldErrors.isEmpty) return null;
    for (final key in fieldErrors.keys) {
      final slug = _fieldKeyToTabSlug[key];
      if (slug != null) return slug;
    }
    return null;
  }
}
