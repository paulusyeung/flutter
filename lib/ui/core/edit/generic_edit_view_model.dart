import 'package:flutter/foundation.dart';

import 'package:admin/data/services/api_exception.dart';

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
  GenericEditViewModel({required T initialDraft, T? original})
    : _original = original,
      _draft = initialDraft;

  final T? _original;
  T _draft;

  T get draft => _draft;
  T? get original => _original;

  /// True when this VM is for a brand-new entity (no existing row).
  bool get isCreate => _original == null;

  /// True when the user has actually changed something. The discard prompt
  /// uses this to decide whether to ask. For create mode, falls back to
  /// [draftIsNonEmpty] so an untouched empty screen doesn't ask to discard.
  bool get isDirty {
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

  /// Replace the working draft and notify. Per-field setters in subclasses
  /// route through here.
  @protected
  void updateDraft(T next) {
    _draft = next;
    notifyListeners();
  }

  /// Restore the draft to the loaded original (or [emptyDraft] in create
  /// mode) and clear all errors. Called by the unsaved-changes guard after
  /// the user picks Discard.
  void reset({required T emptyDraft}) {
    _draft = _original ?? emptyDraft;
    _submitError = null;
    _fieldErrors = const {};
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
  Future<T?> save() async {
    if (_isSaving) return null;
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      return await performSave();
    } on ValidationException catch (e) {
      _fieldErrors = Map.unmodifiable(e.fieldErrors);
      // Also stash the top-level message so a screen with no per-field
      // mapping still has something to show.
      _submitError = e.fieldErrors.isEmpty ? e.message : null;
      return null;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
