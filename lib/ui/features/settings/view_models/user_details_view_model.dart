import 'dart:async';

import 'package:logging/logging.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

final _log = Logger('UserDetailsViewModel');

/// Backs the Settings > User Details tabbed shell. Loads the auth user via
/// [UserRepository], tracks a [User] draft, and saves through the outbox.
///
/// Implements [SettingsDraftHost] for compatibility with the existing
/// [TabbedSettingsShell] / [SettingsPageScaffold] machinery. The
/// Company/CompanySettings surface is unused — `User Details` doesn't reach
/// for the override widgets (the tab bodies use plain `TextField`s,
/// `SearchableDropdownField`s, etc.) — so the stubs return empty / no-op.
class UserDetailsViewModel extends SettingsDraftHost {
  UserDetailsViewModel({
    required this.repo,
    required this.auth,
    required this.companyId,
  }) : userId = auth.session.value?.userId ?? '';

  final UserRepository repo;
  final AuthRepository auth;
  final String companyId;
  final String userId;

  User? _initial;
  User? _draft;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  Map<String, List<String>> _fieldErrors = const {};
  StreamSubscription<User?>? _watchSub;

  @override
  bool get isLoaded => _loaded;

  @override
  bool get draftReady => _draft != null;

  @override
  bool get isSaving => _isSaving;

  @override
  String? get submitError => _submitError;

  @override
  String? get loadError => _loadError;

  @override
  bool get isDirty => _initial != null && _draft != _initial;

  @override
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// Snapshot of the in-progress edit. Tab bodies bind to this directly.
  User? get user => _draft;

  /// Loaded baseline (last server state). Used by the diff-view tabs (Connect)
  /// that render server status rather than draft fields.
  User? get initial => _initial;

  @override
  Future<void> load() async {
    if (_watchSub != null) return;
    if (userId.isEmpty || companyId.isEmpty) {
      _loadError = 'Missing session — please sign in again';
      _loaded = true;
      notifyListeners();
      return;
    }
    _watchSub = repo
        .watch(companyId: companyId, userId: userId)
        .listen(
          _onRowEmitted,
          onError: (Object e, StackTrace st) {
            _log.warning('watch stream errored for user=$userId', e, st);
            _loadError = e.toString();
            _initial = const User();
            _draft = const User();
            _loaded = true;
            notifyListeners();
          },
        );
    // Pull `/api/v1/users/{id}?include=company_user` so the row is in Drift
    // before the user can edit anything. Without this the draft stays as
    // `const User()` (id == ''), and Save enqueues an outbox row with an
    // empty entityId that routes to `/api/v1/users/` → 404 "Method not
    // supported for this route".
    unawaited(
      repo.refresh(companyId: companyId, userId: userId).catchError((
        Object e,
        StackTrace st,
      ) {
        _log.warning('refresh failed for user=$userId', e, st);
      }),
    );
  }

  void _onRowEmitted(User? row) {
    final next = row ?? const User();
    if (!_loaded) {
      _initial = next;
      _draft = next;
      _loaded = true;
      notifyListeners();
      return;
    }
    final wasDirty = isDirty;
    _initial = next;
    if (!wasDirty) _draft = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    super.dispose();
  }

  // -- Typed field setters used by tab bodies --------------------------------

  void updateUser(User Function(User draft) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = edit(draft);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  void updateCompanyUserSettings(
    CompanyUserSettings Function(CompanyUserSettings settings) edit,
  ) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.copyWith(
      companyUserSettings: edit(draft.companyUserSettings),
    );
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  /// Replace the per-event notifications list. Pass the canonical wire format
  /// (`['invoice_sent_user', 'payment_success_all', ...]` or one of the master
  /// codes `'all_notifications'` / `'all_user_notifications'`).
  void setNotificationsEmail(List<String> codes) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.copyWith(notificationsEmail: codes);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  /// Stash the pending-new-password the dispatcher will send under the
  /// `password` key. Cleared after a successful save.
  String? _pendingPassword;
  void setPendingPassword(String? value) {
    _pendingPassword = (value != null && value.isEmpty) ? null : value;
    notifyListeners();
  }

  bool get hasPendingPassword => _pendingPassword != null;

  // -- Save ------------------------------------------------------------------

  @override
  void reset() {
    final initial = _initial;
    if (initial == null) return;
    _draft = initial;
    _submitError = null;
    _fieldErrors = const {};
    _pendingPassword = null;
    notifyListeners();
  }

  @override
  Future<User?> save() async {
    final draft = _draft;
    if (draft == null || _isSaving) return null;
    // Refuse to enqueue with a missing id — the dispatcher would route to
    // `/api/v1/users/` and the server would 404. Surface a clear error so
    // the user retries (likely after `refresh` lands the row).
    if (draft.id.isEmpty) {
      _submitError = 'User record not loaded yet';
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final body = _buildBody(draft);
      await repo.enqueueUpdate(
        companyId: companyId,
        draft: draft,
        body: body,
        requiresPassword: _pendingPassword != null,
      );
      _initial = draft;
      _pendingPassword = null;
      return draft;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Build the PUT body. Serializes the entire draft user back to the
  /// `/api/v1/users/{id}` shape so fields we don't edit (oauth/2fa flags,
  /// permissions, etc.) round-trip untouched. Empty `language_id` is
  /// stripped — Laravel rejects `""` cast to the language foreign key.
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
      draft: _draft ?? const User(),
      body: <String, dynamic>{'_action': action},
    );
  }

  // -- 422 → tab-jump --------------------------------------------------------

  /// Per-tab field-key mapping. Used by [TabbedSettingsShell] to jump to the
  /// offending tab when a 422 arrives. Keep in sync with the field surface
  /// each tab body actually renders — missing keys just stay put.
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

  /// Returns the slug of the first tab carrying a field error, or null when
  /// there are no errors (or none are mapped).
  String? tabSlugForFirstError() {
    if (_fieldErrors.isEmpty) return null;
    for (final key in _fieldErrors.keys) {
      final slug = _fieldKeyToTabSlug[key];
      if (slug != null) return slug;
    }
    return null;
  }

  // -- SettingsDraftHost stubs (unused; see class doc) -----------------------

  @override
  CompanySettings get settings => const CompanySettings();

  @override
  CompanySettings get draftSettings => const CompanySettings();

  @override
  Company? get draft => null;

  @override
  void updateSettings(CompanySettings Function(CompanySettings p1) edit) {}

  @override
  void updateCompany(Company Function(Company p1) edit) {}

  @override
  bool isOverridden(String apiKey) => false;

  @override
  void setOverride({
    required String apiKey,
    required bool enabled,
    String? cascadedValue,
  }) {}
}
