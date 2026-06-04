import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/domain/group_setting.dart';
import 'package:admin/data/repositories/group_setting_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

final _log = Logger('GroupSettingsDraftViewModel');

/// Settings draft scoped to a single group — the middle level of the
/// company → group → client cascade. A near-verbatim mirror of
/// [ClientSettingsDraftViewModel]: same [SettingsDraftHost] surface, same
/// two-slot state (company defaults + sparse override blob), so the existing
/// `OverridableField` widgets and `SettingsPageScaffold` bind against it
/// without caring whether the editor is company-, group-, or client-scoped.
///
/// Two slots of state:
/// * `_companyDefaults` — the company-level settings JSON, snapshotted at
///   load. Drives the cascaded value the bound widgets render when the group
///   hasn't overridden a key (the "inherited" placeholder).
/// * `_draft` — the sparse group overrides as a typed [CompanySettings].
///   Every field that's `null` here means "inherit from the company
///   cascade." Saving only emits the non-null entries.
class GroupSettingsDraftViewModel extends SettingsDraftHost {
  GroupSettingsDraftViewModel({
    required this.repo,
    required this.db,
    required this.companyId,
    required this.groupId,
  });

  final GroupSettingRepository repo;
  final AppDatabase db;
  final String companyId;
  final String groupId;

  Map<String, dynamic> _companyDefaults = const {};
  Company? _companyContext;
  CompanySettings _initial = const CompanySettingsApi();
  CompanySettings _draft = const CompanySettingsApi();
  GroupSetting? _group;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  Map<String, List<String>> _fieldErrors = const {};
  StreamSubscription<GroupSetting?>? _groupSub;
  bool _disposed = false;

  @override
  bool get isLoaded => _loaded;
  @override
  bool get isSaving => _isSaving;
  @override
  String? get submitError => _submitError;
  @override
  String? get loadError => _loadError;
  @override
  Map<String, List<String>> get fieldErrors => _fieldErrors;

  @override
  bool get isDirty {
    if (!_loaded) return false;
    return !_mapEq(_initial.toJson(), _draft.toJson());
  }

  /// Merged view: company defaults overlaid with the group's overrides.
  /// Widgets read this through `host.settings` so an un-overridden field
  /// shows the inherited value (greyed by [OverridableField]).
  @override
  CompanySettings get settings {
    final merged = <String, dynamic>{..._companyDefaults};
    final draftJson = _draft.toJson();
    draftJson.forEach((key, value) {
      if (value != null) merged[key] = value;
    });
    return CompanySettingsApi.fromJsonLenient(merged);
  }

  /// The group's sparse override blob — never merged.
  /// `OverridableField.bindInline` reads this to detect whether a dynamic key
  /// (e.g. `translations.<key>`) is locally overridden; using [settings] there
  /// would incorrectly report "overridden" for any key the company has set.
  @override
  CompanySettings get draftSettings => _draft;

  /// Group scope has no Company draft — the top-level Company fields don't
  /// apply per-group.
  @override
  Company? get draft => null;

  /// Sparse company context (set in [load]) so the cascade body can read
  /// company-level fields at group scope. Only the fields cascade pages
  /// consume are populated; see [load].
  @override
  Company? get companyContext => _companyContext;

  @override
  CompanySettings get initialSettings => _initial;

  @override
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    // The widget's binding closure is shaped `(s) => s.copyWith(field: v)`.
    // Applying it to `_draft` (the sparse override blob) writes the field
    // while leaving other null fields null.
    _draft = edit(_draft);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  @override
  void updateCompany(Company Function(Company) edit) {
    // Intentional no-op: top-level Company fields aren't editable at the
    // group level. Bindings on those fields render company-only and never
    // reach this VM.
  }

  @override
  bool isOverridden(String apiKey) {
    final json = _draft.toJson();
    return json.containsKey(apiKey) && json[apiKey] != null;
  }

  @override
  void setOverride({
    required String apiKey,
    required bool enabled,
    String? cascadedValue,
  }) {
    final binding = settingsBindingOf(apiKey);
    final value = enabled ? cascadedValue : null;
    _draft = binding.write(_draft, value);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  /// Load company defaults and subscribe to the group. Idempotent — repeat
  /// calls are a no-op after the first.
  @override
  Future<void> load() async {
    if (_groupSub != null) return;
    final companyRow = await db.companiesDao.byId(companyId);
    if (companyRow != null) {
      if (companyRow.settings.isNotEmpty) {
        final decoded = jsonDecode(companyRow.settings);
        if (decoded is Map<String, dynamic>) {
          _companyDefaults = decoded;
        }
      }
      // Sparse company context so the Tax Settings body can read company-level
      // fields (tax-rate slot counts, calculate-taxes flag, decimal separator)
      // at group scope, where there's no Company [draft]. Only the fields the
      // cascade body reads are populated; everything else defaults.
      _companyContext = Company(
        id: companyId,
        enabledTaxRates: companyRow.enabledTaxRates,
        enabledItemTaxRates: companyRow.enabledItemTaxRates,
        calculateTaxes: companyRow.calculateTaxes,
        useCommaAsDecimalPlace: companyRow.useCommaAsDecimalPlace,
      );
    }
    _groupSub = repo
        .watch(companyId: companyId, id: groupId)
        .listen(
          _onRowEmitted,
          onError: (Object e, StackTrace st) {
            _log.warning('group watch errored for $groupId', e, st);
            if (_disposed) return;
            _loadError = e.toString();
            _loaded = true;
            notifyListeners();
          },
        );
  }

  void _onRowEmitted(GroupSetting? group) {
    if (_disposed) return;
    _group = group;
    final raw = group?.settings ?? const <String, dynamic>{};
    final next = CompanySettingsApi.fromJsonLenient(raw);
    if (!_loaded) {
      _initial = next;
      _draft = next;
      _loaded = true;
      notifyListeners();
      return;
    }
    // Already showing data — preserve the user's in-progress edit if any
    // (matches the company-/client-scoped VM's refresh semantics).
    final wasDirty = isDirty;
    _initial = next;
    if (!wasDirty) _draft = next;
    notifyListeners();
  }

  @override
  void reset() {
    _draft = _initial;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  @override
  Future<GroupSetting?> save() async {
    final group = _group;
    if (group == null || _isSaving) return null;
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final json = _draft.toJson()..removeWhere((_, v) => v == null);
      final next = group.copyWith(settings: json.isEmpty ? null : json);
      await repo.save(companyId: companyId, group: next);
      _initial = _draft;
      return next;
    } on ValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _submitError = e.message;
      return null;
    } catch (e) {
      // Strip the runtime-type prefix that `ApiException.toString()` adds so
      // the inline submit error renders the bare message.
      _submitError = e is ApiException ? e.message : e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _groupSub?.cancel();
    super.dispose();
  }

  bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
