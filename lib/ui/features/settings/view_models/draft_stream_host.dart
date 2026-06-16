import 'dart:async';

import 'package:logging/logging.dart';

import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

final _log = Logger('DraftStreamHost');

/// Generic lifecycle base for any settings VM that edits a single entity
/// streamed from a repository — currently [SettingsDraftViewModel]
/// (Company drafts) and [UserDetailsViewModel] (User drafts). Both used
/// to re-implement the same six mechanics: state slots, lifecycle
/// getters, idempotent load() with stream-listen + onError baseline,
/// dirty-preserving refresh on subsequent emissions, dispose() canceling
/// the sub, reset() restoring from baseline, and save() with
/// isSaving/error plumbing.
///
/// Subclasses implement the entity-specific hooks: [emptyValue],
/// [createWatch], [kickRefresh], [performSave]. Optional hooks
/// ([preLoadError], [preSaveError], [onSaveSuccess], [onReset]) handle
/// per-screen edge cases without growing the base shape.
///
/// `ClientSettingsDraftViewModel` is intentionally not a subclass — it
/// uses a different state model (company-defaults overlay + sparse
/// CompanySettings draft, not a single typed row), so trying to share
/// the lifecycle would force every concept into a Procrustean bed.
abstract class DraftStreamHost<T> extends SettingsDraftHost {
  T? _initial;
  T? _draft;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  Map<String, List<String>> _fieldErrors = const {};
  StreamSubscription<T?>? _watchSub;
  bool _disposed = false;

  // -- Hooks for subclasses --------------------------------------------------

  /// Value used as a fallback when the watch stream emits null (entity
  /// not found locally yet) or errors out. Conventionally a `const`
  /// default-constructed instance, e.g. `const Company()` / `const User()`.
  T get emptyValue;

  /// Open the watch stream this VM subscribes to. Called exactly once per
  /// load() — the base owns the subscription's lifetime.
  Stream<T?> createWatch();

  /// Fire-and-forget background refresh kicked off after subscribing.
  /// Result lands via the watch stream; failures should be swallowed
  /// (logged inside the implementation) so they don't block the
  /// spinner-clearing first emission.
  Future<void> kickRefresh();

  /// Persist the current draft. Returns the saved entity on success.
  /// Throws on failure — the base catches [ValidationException] (populates
  /// [fieldErrors] + [submitError]) and any other [Exception] (populates
  /// [submitError] only).
  Future<T> performSave(T draft);

  /// Pre-load gate. Returning a non-null string aborts the load: the
  /// stream isn't opened, [isLoaded] flips to true, and [loadError] is
  /// set to the returned message. Use for missing-prerequisite cases
  /// (e.g. UserDetails needs a non-empty userId + companyId).
  String? preLoadError() => null;

  /// Pre-save gate. Returning a non-null string aborts the save: no
  /// network call is made, [submitError] is set to the returned message.
  /// Use for must-have-loaded-row-first checks.
  String? preSaveError(T draft) => null;

  /// Called after [performSave] returns successfully. Use to clear
  /// transient state piggy-backed onto the draft (e.g. UserDetails's
  /// `_pendingPassword`). The base has already updated `_initial`.
  void onSaveSuccess(T saved) {}

  /// Called after [reset] has restored the draft to the baseline but
  /// before [notifyListeners]. Use to clear transient per-edit state.
  void onReset() {}

  // -- Protected helpers for subclasses --------------------------------------

  /// Current draft. Subclasses typically expose this through their own
  /// typed getter (e.g. `Company? get draft => draftValue`).
  T? get draftValue => _draft;

  /// Last-loaded baseline.
  T? get initialValue => _initial;

  /// Apply a [freezed] copyWith to the draft, clear stale field errors,
  /// and notify. Subclasses use this from every field setter so the
  /// "clear field errors on first edit after save" rule lives in one
  /// place.
  void updateDraft(T Function(T draft) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = edit(draft);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  // -- SettingsDraftHost lifecycle surface -----------------------------------

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
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  @override
  bool get isDirty => _initial != null && _draft != _initial;

  @override
  Future<void> load() async {
    if (_watchSub != null) return;
    final preflight = preLoadError();
    if (preflight != null) {
      _loadError = preflight;
      _loaded = true;
      notifyListeners();
      return;
    }
    _watchSub = createWatch().listen(
      _onRowEmitted,
      onError: (Object e, StackTrace st) {
        if (_disposed) return;
        _log.warning('watch stream errored', e, st);
        _loadError = e.toString();
        _initial = emptyValue;
        _draft = emptyValue;
        _loaded = true;
        notifyListeners();
      },
    );
    unawaited(kickRefresh());
  }

  void _onRowEmitted(T? row) {
    if (_disposed) return;
    final next = row ?? emptyValue;
    if (!_loaded) {
      _initial = next;
      _draft = next;
      _loaded = true;
      notifyListeners();
      return;
    }
    // Already showing data — refresh emission. Update the baseline but
    // preserve the user's in-progress edit if any. The dirty diff just
    // gets recomputed against the new baseline so saving still works.
    final wasDirty = isDirty;
    _initial = next;
    if (!wasDirty) _draft = next;
    notifyListeners();
  }

  @override
  void dispose() {
    // Set before super.dispose() so the guarded async callbacks below
    // (watch emission / onError, and save()'s finally that can run after the
    // host is disposed mid-`await performSave` on a company switch) short-
    // circuit instead of calling notifyListeners() on a disposed notifier (L11).
    _disposed = true;
    _watchSub?.cancel();
    super.dispose();
  }

  @override
  void reset() {
    final initial = _initial;
    if (initial == null) return;
    _draft = initial;
    _submitError = null;
    _fieldErrors = const {};
    onReset();
    notifyListeners();
  }

  @override
  Future<T?> save() async {
    final draft = _draft;
    if (draft == null || _isSaving) return null;
    final preflight = preSaveError(draft);
    if (preflight != null) {
      _submitError = preflight;
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final saved = await performSave(draft);
      _initial = saved;
      onSaveSuccess(saved);
      return saved;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _submitError = e.message;
      return null;
    } catch (e) {
      // Strip the runtime-type prefix that `ApiException.toString()` adds
      // (e.g. "ServerException: Connection lost") so the inline submit
      // error renders the bare message.
      _submitError = e is ApiException ? e.message : e.toString();
      return null;
    } finally {
      _isSaving = false;
      // The host may have been disposed during `await performSave` (a company
      // switch through the settings host swaps the VM out). The save itself
      // still completed correctly; just don't notify a disposed notifier (L11).
      if (!_disposed) notifyListeners();
    }
  }
}
