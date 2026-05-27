import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import 'package:admin/data/services/api_exception.dart';
import 'package:admin/utils/formatting.dart';

/// State for an entity edit or create screen. Holds the in-progress draft in
/// memory, exposes dirty / saving flags, surfaces validation errors per-field,
/// and serializes the final save through a subclass-supplied [performSave].
///
/// Concrete subclasses (`ClientEditViewModel`, `ProductEditViewModel`, …)
/// supply:
///   * the empty-draft factory (passed as `initialDraft` when creating)
///   * the per-field setters (which call [updateDraft])
///   * [performSave] — runs the repo create/save call and returns the saved
///     entity (with tmp id for new rows) on success
///   * [draftIsNonEmpty] — used by the create-mode dirty check; defaults to
///     `true` so a brand-new screen is treated as dirty
abstract class GenericEditViewModel<T> extends ChangeNotifier {
  GenericEditViewModel({
    required T initialDraft,
    T? original,
    bool useCommaAsDecimalPlace = false,
  })  : _original = original,
        _draft = initialDraft,
        _useCommaAsDecimalPlace = useCommaAsDecimalPlace;

  final T? _original;
  T _draft;

  /// Honors the company's `useCommaAsDecimalPlace` setting for [setDec].
  /// Without this, a user with that setting enabled typing `1,5` gets the
  /// comma stripped by [parseDecimal]'s regex and stored as `15` — a silent
  /// 10× corruption. Subclasses thread the company setting via `super`.
  final bool _useCommaAsDecimalPlace;

  T get draft => _draft;
  T? get original => _original;

  /// True when this VM is for a brand-new entity (no existing row).
  bool get isCreate => _original == null;

  /// Latches true the moment [performSave] succeeds, so a just-saved form
  /// is not "dirty" — otherwise the post-save navigation (`onSaved` →
  /// `context.go`/`context.pop`) trips the unsaved-changes guard and pops a
  /// spurious "Discard changes?" right after the user pressed Save. In
  /// create mode `_original` stays null (and `isCreate` must keep reflecting
  /// that), and in edit mode `_original` is never rebased, so neither side
  /// of [isDirty] would otherwise clear on save. Any later edit re-arms it
  /// via [updateDraft]; [reset] clears it too.
  bool _savedClean = false;

  /// True when the user has actually changed something. The discard prompt
  /// uses this to decide whether to ask. For create mode, falls back to
  /// [draftIsNonEmpty] so an untouched empty screen doesn't ask to discard.
  /// A successful save clears it until the next edit.
  bool get isDirty {
    if (_savedClean) return false;
    final orig = _original;
    if (orig == null) return draftIsNonEmpty();
    return _draft != orig;
  }

  /// Override per entity. Default is `true` so subclasses that don't care
  /// always treat create-mode as dirty.
  @protected
  bool draftIsNonEmpty() => true;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _submitError;

  /// Non-422 error message (network, 5xx). 422 errors land in [fieldErrors].
  String? get submitError => _submitError;

  Map<String, List<String>> _fieldErrors = const {};

  /// Map of `api_field_key` → list of error messages, populated when the
  /// server returns 422. Each [GenericEditField] (or any edit field) looks
  /// up its own key via [fieldErrorFor] to render an inline error.
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// First error message for [apiKey], or null. The convention is to use
  /// the snake_case API field name (the same key the server returns).
  String? fieldErrorFor(String apiKey) {
    final list = _fieldErrors[apiKey];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  bool _localValidationOnly = false;

  /// True when the current [fieldErrors] came from [validate] (a client-side
  /// block — no local write, no outbox row was ever created), rather than a
  /// server 422 / dead outbox row. The save-failed banner and the edit
  /// scaffold use this to drop the server-rejection framing and skip the
  /// dead-row lookup that only makes sense for a real sync failure.
  bool get localValidationOnly => _localValidationOnly;

  /// Synchronous pre-save validation. Return `api_field_key -> messages` to
  /// block the save *before* any local write / outbox enqueue; the map feeds
  /// the same inline-error path ([fieldErrorFor]) as a server 422. Default:
  /// no client-side validation. Subclasses with required fields override
  /// this (e.g. billing docs require a client / vendor).
  @protected
  Map<String, List<String>> validate() => const {};

  int? _deadOutboxRowId;

  /// `outbox.id` of the dead row whose 422 errors this VM is currently
  /// surfacing — set by [applyFailedSync] when the screen is reopened
  /// after a sync failure. Null otherwise. The "Discard failed save"
  /// affordance uses this to delete the right row from the outbox.
  int? get deadOutboxRowId => _deadOutboxRowId;

  /// Replay a prior sync failure on this screen. The Outbox screen's
  /// "Open" action and the edit form's `initState` use this to surface
  /// the server's 422 against the re-opened form, so the user can fix
  /// the flagged fields and re-save. Passing an empty [errors] map clears
  /// any previously-displayed errors.
  void applyFailedSync({
    required int rowId,
    required Map<String, List<String>> errors,
  }) {
    _deadOutboxRowId = rowId;
    _fieldErrors = Map.unmodifiable(errors);
    notifyListeners();
  }

  /// Clear the dead-row link + the field errors. Called after the user
  /// either fixes the bad fields and saves again, or explicitly discards.
  void clearFailedSync() {
    if (_deadOutboxRowId == null &&
        _fieldErrors.isEmpty &&
        !_localValidationOnly) {
      return;
    }
    _deadOutboxRowId = null;
    _fieldErrors = const {};
    _localValidationOnly = false;
    notifyListeners();
  }

  /// Replace the working draft and notify. Per-field setters in subclasses
  /// route through here.
  @protected
  void updateDraft(T next) {
    _draft = next;
    // A fresh edit after a save re-arms the dirty/guard machinery.
    _savedClean = false;
    notifyListeners();
  }

  /// Restore the draft to the loaded original (or [emptyDraft] in create
  /// mode) and clear all errors. Called by the unsaved-changes guard after
  /// the user picks Discard.
  void reset({required T emptyDraft}) {
    _draft = _original ?? emptyDraft;
    _savedClean = false;
    _submitError = null;
    _fieldErrors = const {};
    _localValidationOnly = false;
    notifyListeners();
  }

  /// Concrete repo call — `repo.create` for new rows, `repo.save` for
  /// existing ones. Subclasses dispatch based on [isCreate]. Returns the
  /// saved entity on success; throws on failure.
  @protected
  Future<T> performSave();

  /// Optimistic save. Returns the saved entity on success, null on
  /// failure. The view uses the return value to decide whether to pop the
  /// route. On 422, [fieldErrors] is populated and the view should stay
  /// open so the user can fix the flagged fields.
  /// Collapse the entity's per-field setters from
  /// `void setX(T v) => updateDraft(draft.copyWith(x: v))` into one-liners
  /// via [setStr] / [setBool] / [setDec] / [setInt]. Each takes a function
  /// `(T, V) -> T` that applies the new value, plus the value itself.
  /// Mirrors freezed's `copyWith` shape without the per-VM boilerplate.
  ///
  /// Numeric inputs (`setDec`, `setInt`) accept the raw `String` from a
  /// text field; failing parse falls back to zero (matches the empty-for-
  /// blank convention in CLAUDE.md § Forms).
  @protected
  void setStr(T Function(T, String) write, String v) =>
      updateDraft(write(_draft, v));

  @protected
  void setBool(T Function(T, bool) write, bool v) =>
      updateDraft(write(_draft, v));

  @protected
  void setDec(T Function(T, Decimal) write, String input) => updateDraft(
        write(
          _draft,
          parseDecimal(
                input,
                useCommaAsDecimalPlace: _useCommaAsDecimalPlace,
              ) ??
              Decimal.zero,
        ),
      );

  @protected
  void setInt(T Function(T, int) write, String input) =>
      updateDraft(write(_draft, int.tryParse(input.trim()) ?? 0));

  Map<String, String>? _pendingSaveQuery;

  /// Set by the edit scaffold immediately before triggering [save] for a
  /// SAVE-PARAM action (mark_sent / paid / cancel / …). The billing-doc
  /// `performSave` override reads it via [consumeSaveQuery] and threads it
  /// into the repo create/save call so the server performs the action as
  /// part of the same save request. Single-use: cleared by [consumeSaveQuery]
  /// and, defensively, at the end of every [save] so a later plain Enter/⌘S
  /// can never replay a stale action.
  void setPendingSaveQuery(Map<String, String>? q) => _pendingSaveQuery = q;

  /// Returns and clears the one-shot pending save-query. `performSave`
  /// overrides that support SAVE-PARAM actions call this and pass the result
  /// as the repo's `extraQuery`. Returns null when no action is pending
  /// (the normal Save / Enter path).
  @protected
  Map<String, String>? consumeSaveQuery() {
    final q = _pendingSaveQuery;
    _pendingSaveQuery = null;
    return q;
  }

  final List<void Function()> _beforeSaveHooks = [];

  /// Register a callback fired synchronously at the start of [save] before
  /// [performSave] runs. Used by inline-edit widgets (e.g. the desktop
  /// line-item table) to flush in-flight debounced text-field edits onto
  /// the draft so a Save click never loses the last few keystrokes.
  /// Returns the unregister closure — call it in `dispose`.
  VoidCallback addBeforeSaveHook(void Function() hook) {
    _beforeSaveHooks.add(hook);
    return () => _beforeSaveHooks.remove(hook);
  }

  Future<T?> save() async {
    if (_isSaving) return null;
    for (final hook in List.of(_beforeSaveHooks)) {
      hook();
    }
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    _localValidationOnly = false;
    // Note: `_deadOutboxRowId` deliberately survives `save()` entry — the
    // screen's `onSaved` callback reads it to delete the prior dead row
    // after a successful re-save. If `performSave` itself throws a 422
    // synchronously, the catch block below resets it so the late-arriving
    // `onSaveRejected` hook can pick up the *fresh* dead row id.
    notifyListeners();
    try {
      // Client-side validation runs *inside* the try so the `finally` below
      // still fires on an early return — that's what clears _pendingSaveQuery
      // (a one-shot SAVE-PARAM action) and resets _isSaving. The before-save
      // hooks above have already flushed debounced edits onto the draft, so
      // validate() sees the final draft. Don't move this before the try.
      final localErrors = validate();
      if (localErrors.isNotEmpty) {
        _fieldErrors = Map.unmodifiable(localErrors);
        _localValidationOnly = true;
        return null;
      }
      final saved = await performSave();
      // Mark the form clean so the post-save navigation doesn't trip the
      // unsaved-changes guard. Re-armed by the next [updateDraft].
      _savedClean = true;
      return saved;
    } on ValidationException catch (e) {
      _fieldErrors = Map.unmodifiable(e.fieldErrors);
      // The prior dead-row link (if any) refers to the previous failure's
      // row; this fresh failure superseded it. Drop it so the screen's
      // discard / onSaveRejected hooks act on the new row instead.
      _deadOutboxRowId = null;
      // Also stash the top-level message so a screen with no per-field
      // mapping still has something to show.
      _submitError = e.fieldErrors.isEmpty ? e.message : null;
      return null;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      // Defensively drop any pending save-query that performSave did not
      // consume (e.g. an after-save-only screen, or a non-billing entity):
      // it must never survive into a subsequent plain Save.
      _pendingSaveQuery = null;
      _isSaving = false;
      notifyListeners();
    }
  }
}
