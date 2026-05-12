import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/repositories/company_repository.dart';

final _log = Logger('CompanyDetailsViewModel');

/// State holder shared across all 6 tabs of the Company Details page.
///
/// Loads the active company via [CompanyRepository.watch] and exposes the
/// in-progress draft. Each tab mutates the draft via [updateSettings] /
/// [updateCompany]. [save] hands the draft to the repository (Drift +
/// outbox) and returns the updated [Company] on success.
class CompanyDetailsViewModel extends ChangeNotifier {
  CompanyDetailsViewModel({required this.repo, required this.companyId});

  final CompanyRepository repo;
  final String companyId;

  Company? _initial;
  Company? _draft;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  StreamSubscription<Company?>? _watchSub;

  /// True once [load] has resolved with a company row.
  bool get isLoaded => _loaded;

  /// Snapshot of the in-progress edit. Null until [load] resolves.
  Company? get draft => _draft;

  bool get isSaving => _isSaving;
  String? get submitError => _submitError;

  /// Non-null when [load] threw. The UI surfaces this as a banner so the
  /// page can still render the (possibly partial) draft and the user/dev
  /// can see what went wrong instead of staring at a perpetual spinner.
  String? get loadError => _loadError;

  /// True when the draft has diverged from the loaded state.
  bool get isDirty => _initial != null && _draft != _initial;

  /// Convenience for forms that just need the typed settings without
  /// null-checking [draft] every time.
  CompanySettings get settings => _draft?.settings ?? const CompanySettings();

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
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.copyWith(settings: edit(draft.settings));
    notifyListeners();
  }

  /// Apply a freezed copyWith to the top-level company (size_id, industry_id,
  /// custom_fields, etc.).
  void updateCompany(Company Function(Company) edit) {
    final draft = _draft;
    if (draft == null) return;
    _draft = edit(draft);
    notifyListeners();
  }

  /// True when the entity's *own* settings have a non-null value for the
  /// given API key. Used by [OverridableField] to decide whether the field
  /// is currently overriding the cascaded default.
  ///
  /// At company level this is always treated as `true` by the wrapper, so
  /// callers don't need to special-case the level.
  bool isOverridden(String apiKey) {
    final json = _draft?.settings.toJson() ?? const <String, dynamic>{};
    return json.containsKey(apiKey) && json[apiKey] != null;
  }

  /// Toggle an override for the given API key. On enable, callers pass the
  /// cascaded default (so the field starts populated); on disable the field
  /// is cleared to null. The list of writable keys is intentionally small —
  /// adding a new override path is the cost of explicitly mapping it here.
  void setOverride({
    required String apiKey,
    required bool enabled,
    Object? cascadedValue,
  }) {
    final draft = _draft;
    if (draft == null) return;
    final value = enabled ? cascadedValue : null;
    _draft = draft.copyWith(
      settings: _writeSettingsField(draft.settings, apiKey, value),
    );
    notifyListeners();
  }

  /// Restore the draft to the last-loaded baseline and clear any submit
  /// error. Called by the unsaved-changes guard after the user picks Discard
  /// from a navigation prompt — without it the dirty draft would re-appear
  /// the next time the screen rebuilds (the shell stays mounted across tab
  /// switches in another branch).
  void reset() {
    final initial = _initial;
    if (initial == null) return;
    _draft = initial;
    _submitError = null;
    notifyListeners();
  }

  /// Persist the draft. Returns the saved [Company] on success, null on
  /// failure. The view uses the return value to decide whether to clear
  /// dirty state and pop.
  Future<Company?> save() async {
    final draft = _draft;
    if (draft == null || _isSaving) return null;
    _isSaving = true;
    _submitError = null;
    notifyListeners();
    try {
      await repo.updateCompany(draft: draft);
      _initial = draft;
      return draft;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Settings has ~200 fields and freezed's `copyWith` is name-based, not
  /// key-based. The override path only writes the small set of fields the
  /// Details/Address/Defaults tabs expose; everything else is reachable via
  /// [updateSettings] with a normal `s.copyWith(...)`.
  CompanySettings _writeSettingsField(
    CompanySettings s,
    String apiKey,
    Object? value,
  ) {
    return switch (apiKey) {
      'name' => s.copyWith(name: value as String?),
      'id_number' => s.copyWith(idNumber: value as String?),
      'vat_number' => s.copyWith(vatNumber: value as String?),
      'website' => s.copyWith(website: value as String?),
      'email' => s.copyWith(email: value as String?),
      'phone' => s.copyWith(phone: value as String?),
      'qr_iban' => s.copyWith(qrIban: value as String?),
      'besr_id' => s.copyWith(besrId: value as String?),
      'classification' => s.copyWith(classification: value as String?),
      'custom_value1' => s.copyWith(customValue1: value as String?),
      'custom_value2' => s.copyWith(customValue2: value as String?),
      'custom_value3' => s.copyWith(customValue3: value as String?),
      'custom_value4' => s.copyWith(customValue4: value as String?),
      'address1' => s.copyWith(address1: value as String?),
      'address2' => s.copyWith(address2: value as String?),
      'city' => s.copyWith(city: value as String?),
      'state' => s.copyWith(state: value as String?),
      'postal_code' => s.copyWith(postalCode: value as String?),
      'country_id' => s.copyWith(countryId: value as String?),
      'company_logo' => s.copyWith(companyLogo: value as String?),
      'invoice_terms' => s.copyWith(invoiceTerms: value as String?),
      'invoice_footer' => s.copyWith(invoiceFooter: value as String?),
      'quote_terms' => s.copyWith(quoteTerms: value as String?),
      'quote_footer' => s.copyWith(quoteFooter: value as String?),
      'credit_terms' => s.copyWith(creditTerms: value as String?),
      'credit_footer' => s.copyWith(creditFooter: value as String?),
      'purchase_order_terms' => s.copyWith(
        purchaseOrderTerms: value as String?,
      ),
      'purchase_order_footer' => s.copyWith(
        purchaseOrderFooter: value as String?,
      ),
      _ => s,
    };
  }
}
