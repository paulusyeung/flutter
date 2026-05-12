import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

final _log = Logger('SettingsDraftViewModel');

/// Public host interface consumed by widgets that bind to a settings draft
/// (`OverridableTextField`, `OverridableMarkdownField`, future settings-bound
/// widgets) and by the surrounding [SettingsPageScaffold] (load, dirty,
/// save lifecycle). Widgets read this off
/// `context.{read,watch}<SettingsDraftHost>` so they're decoupled from the
/// concrete VM type.
///
/// Extends [ChangeNotifier] so concrete subclasses inherit the
/// add/remove-listener machinery without separately mixing it in. Both the
/// company-scoped ([SettingsDraftViewModel]) and the client-scoped
/// (`ClientSettingsDraftViewModel`) VMs subclass it.
abstract class SettingsDraftHost extends ChangeNotifier {
  // -- Field surface (read/write via SettingsBinding) ----------------------
  CompanySettings get settings;
  Company? get draft;
  void updateSettings(CompanySettings Function(CompanySettings) edit);
  void updateCompany(Company Function(Company) edit);
  bool isOverridden(String apiKey);
  void setOverride({
    required String apiKey,
    required bool enabled,
    String? cascadedValue,
  });

  /// Per-field validation errors, keyed by apiKey. Populated by [save] when
  /// the server returns 422; cleared on the next edit. Empty by default.
  Map<String, List<String>> get fieldErrors;

  // -- Lifecycle surface (consumed by SettingsPageScaffold) ----------------

  /// True once the initial load has resolved.
  bool get isLoaded;

  /// True when the draft has diverged from the loaded baseline.
  bool get isDirty;

  /// True while a [save] call is in flight.
  bool get isSaving;

  /// Non-null when the initial load failed. The page renders a banner above
  /// the body so the user can still see whatever subset of the draft loaded.
  String? get loadError;

  /// Non-null when the most recent [save] threw. Surfaced as the detail line
  /// in the "save failed" toast.
  String? get submitError;

  /// Restore the draft to the last-loaded baseline. Called from the
  /// unsaved-changes guard's Discard path.
  void reset();

  /// Persist the draft. Returns non-null on success (the saved entity, type
  /// is intentionally [Object] so different backings can return whatever they
  /// like) and null on failure — `runSettingsSave` distinguishes the two
  /// without caring about the concrete return type.
  Future<Object?> save();
}

/// Base ChangeNotifier for any settings page that edits a [Company] draft.
/// Owns the lifecycle (load/watch/seed/dirty-preserve/reset/save), the
/// load/submit error surface, and the table-driven override path.
///
/// New settings pages plug in by extending this with a one-line subclass.
/// Each page keeps its own subclass type so Provider lookups stay typed
/// and each page's draft is naturally scoped to its mount lifecycle.
class SettingsDraftViewModel extends SettingsDraftHost {
  SettingsDraftViewModel({required this.repo, required this.companyId});

  final CompanyRepository repo;
  final String companyId;

  Company? _initial;
  Company? _draft;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  Map<String, List<String>> _fieldErrors = const {};
  StreamSubscription<Company?>? _watchSub;

  /// True once [load] has resolved with a company row.
  @override
  bool get isLoaded => _loaded;

  /// Snapshot of the in-progress edit. Null until [load] resolves.
  @override
  Company? get draft => _draft;

  @override
  bool get isSaving => _isSaving;
  @override
  String? get submitError => _submitError;

  /// Non-null when [load] threw. The UI surfaces this as a banner so the
  /// page can still render the (possibly partial) draft and the user/dev
  /// can see what went wrong instead of staring at a perpetual spinner.
  @override
  String? get loadError => _loadError;

  /// True when the draft has diverged from the loaded state.
  @override
  bool get isDirty => _initial != null && _draft != _initial;

  @override
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  /// Convenience for forms that just need the typed settings without
  /// null-checking [draft] every time.
  @override
  CompanySettings get settings => _draft?.settings ?? const CompanySettings();

  /// Page-overridable lookup of the apiKey → binding table. The default
  /// returns the global [settingsBindings] map; pages with private bindings
  /// can override and merge in their own entries.
  @protected
  Map<String, SettingsBinding> bindings() => settingsBindings();

  /// Subscribe to Drift and kick off a background server refresh. The shell
  /// calls this on mount.
  ///
  /// First emission seeds `_initial` + `_draft` + flips `_loaded` so the
  /// spinner clears. Subsequent emissions (after the background refresh
  /// upserts a fresh row) update `_initial` only — if the user is mid-edit
  /// (`isDirty`), we don't clobber their `_draft`; the dirty diff just gets
  /// recomputed against the new baseline so saving still works.
  ///
  /// The subscription is single-fire safe: re-entry is a no-op. The repo's
  /// `watch` resolves through `id_remap` so the stream survives any future
  /// id swap.
  Future<void> load() async {
    if (_watchSub != null) return;
    _watchSub = repo
        .watch(companyId)
        .listen(
          _onRowEmitted,
          onError: (Object e, StackTrace st) {
            _log.warning(
              'watch stream errored for companyId=$companyId',
              e,
              st,
            );
            _loadError = e.toString();
            _initial = const Company();
            _draft = const Company();
            _loaded = true;
            notifyListeners();
          },
        );
    // Background refresh from the server. Result lands via the watch
    // stream above; failures are logged inside `repo.refresh` and don't
    // affect the spinner-clearing first emission.
    unawaited(repo.refresh(companyId));
  }

  void _onRowEmitted(Company? row) {
    final next = row ?? const Company();
    if (!_loaded) {
      _initial = next;
      _draft = next;
      _loaded = true;
      notifyListeners();
      return;
    }
    // Already showing data — this is a refresh emission. Update the
    // baseline; preserve the user's in-progress edit if any.
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

  /// Apply a freezed copyWith to the settings blob. The UI calls this from
  /// every field's `onChanged`:
  ///
  /// ```dart
  /// vm.updateSettings((s) => s.copyWith(name: value));
  /// ```
  @override
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.copyWith(settings: edit(draft.settings));
    // First edit after a failed save clears stale field errors. Cheaper
    // than tracking which field was just edited; the only regression is
    // that fixing field A clears the error on field B, which is rare and
    // recoverable on the next save attempt.
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  /// Apply a freezed copyWith to the top-level company (size_id, industry_id,
  /// custom_fields, etc.).
  @override
  void updateCompany(Company Function(Company) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = edit(draft);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  /// True when the entity's *own* settings have a non-null value for the
  /// given API key. Used by [OverridableField] to decide whether the field
  /// is currently overriding the cascaded default.
  ///
  /// At company level this is always treated as `true` by the wrapper, so
  /// callers don't need to special-case the level.
  @override
  bool isOverridden(String apiKey) {
    final json = _draft?.settings.toJson() ?? const <String, dynamic>{};
    return json.containsKey(apiKey) && json[apiKey] != null;
  }

  /// Toggle an override for the given API key. On enable, callers pass the
  /// cascaded default (so the field starts populated); on disable the field
  /// is cleared to null. The set of writable keys is whatever's registered
  /// in [settingsBindings] (or the page-specific [bindings] override) — the
  /// lookup throws [StateError] on a typo so missing bindings fail loudly.
  @override
  void setOverride({
    required String apiKey,
    required bool enabled,
    String? cascadedValue,
  }) {
    final draft = _draft;
    if (draft == null) return;
    final value = enabled ? cascadedValue : null;
    final binding = bindings()[apiKey];
    if (binding == null) {
      throw StateError(
        'Unknown settings binding "$apiKey" — add it to settings_field_bindings.dart',
      );
    }
    _draft = draft.copyWith(settings: binding.write(draft.settings, value));
    notifyListeners();
  }

  /// Restore the draft to the last-loaded baseline and clear any submit
  /// error. Called by the unsaved-changes guard after the user picks Discard
  /// from a navigation prompt — without it the dirty draft would re-appear
  /// the next time the screen rebuilds (the shell stays mounted across tab
  /// switches in another branch).
  @override
  void reset() {
    final initial = _initial;
    if (initial == null) return;
    _draft = initial;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  /// Persist the draft. Returns the saved [Company] on success, null on
  /// failure. The view uses the return value to decide whether to clear
  /// dirty state and pop.
  ///
  /// `fieldErrors` is populated from [ValidationException.fieldErrors] when
  /// a save throws synchronously. Today `repo.updateCompany` enqueues the
  /// mutation and returns, so most 422s surface asynchronously from the
  /// outbox dispatcher — the `on ValidationException` branch is in place
  /// for when a future change pipes the dispatcher's validation failures
  /// back here.
  @override
  Future<Company?> save() async {
    final draft = _draft;
    if (draft == null || _isSaving) return null;
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      await repo.updateCompany(draft: draft);
      _initial = draft;
      return draft;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _submitError = e.message;
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
