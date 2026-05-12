import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

final _log = Logger('ClientSettingsDraftViewModel');

/// Settings draft scoped to a single client. Mirrors
/// [SettingsDraftViewModel]'s public surface ([SettingsDraftHost]) so the
/// existing `OverridableField` widgets and `SettingsPageScaffold` bind
/// against it without caring whether the editor is company- or
/// client-scoped.
///
/// Two slots of state:
/// * `_companyDefaults` — the company-level settings JSON, snapshotted at
///   load. Drives the cascaded value the bound widgets render when the
///   user hasn't overridden a key (the "inherited" placeholder).
/// * `_draft` — the sparse client overrides as a typed [CompanySettings].
///   Every field that's `null` here means "inherit from the company
///   cascade." Saving only emits the non-null entries.
///
/// `host.settings` returns the merged view so `_read(host.settings)` in a
/// bound widget always reflects the *effective* value, while
/// [isOverridden] reads directly from `_draft` so the override checkbox
/// state is independent of the company default.
class ClientSettingsDraftViewModel extends SettingsDraftHost {
  ClientSettingsDraftViewModel({
    required this.repo,
    required this.db,
    required this.companyId,
    required this.clientId,
  });

  final ClientRepository repo;
  final AppDatabase db;
  final String companyId;
  final String clientId;

  Map<String, dynamic> _companyDefaults = const {};
  CompanySettings _initial = const CompanySettingsApi();
  CompanySettings _draft = const CompanySettingsApi();
  Client? _client;
  bool _loaded = false;
  bool _isSaving = false;
  String? _submitError;
  String? _loadError;
  Map<String, List<String>> _fieldErrors = const {};
  StreamSubscription<Client?>? _clientSub;
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

  /// Merged view: company defaults overlaid with the client's overrides.
  /// Widgets read this through `host.settings` so an un-overridden field
  /// shows the inherited value (greyed by [OverridableField]); the user
  /// sees what would apply if they don't opt in.
  @override
  CompanySettings get settings {
    final merged = <String, dynamic>{..._companyDefaults};
    final draftJson = _draft.toJson();
    draftJson.forEach((key, value) {
      if (value != null) merged[key] = value;
    });
    return CompanySettingsApi.fromJson(merged);
  }

  /// Client scope has no Company draft — the top-level Company fields
  /// (size_id, name on the Company row, etc.) don't apply per-client.
  @override
  Company? get draft => null;

  @override
  void updateSettings(CompanySettings Function(CompanySettings) edit) {
    // The widget's binding closure is shaped `(s) => s.copyWith(field: v)`.
    // Applying it to `_draft` (the sparse override blob) writes the field
    // on `_draft` while leaving other null fields null. Override-state for
    // the edited field is already on — `OverridableField`'s
    // `IgnorePointer` would have blocked the edit otherwise.
    _draft = edit(_draft);
    if (_fieldErrors.isNotEmpty) _fieldErrors = const {};
    notifyListeners();
  }

  @override
  void updateCompany(Company Function(Company) edit) {
    // Intentional no-op: top-level Company fields aren't editable at the
    // client level. Bindings on those fields render company-only and
    // never reach this VM.
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

  /// Load company defaults and subscribe to the client. Idempotent —
  /// repeat calls are a no-op after the first.
  Future<void> load() async {
    if (_clientSub != null) return;
    final companyRow = await db.companiesDao.byId(companyId);
    if (companyRow != null && companyRow.settings.isNotEmpty) {
      final decoded = jsonDecode(companyRow.settings);
      if (decoded is Map<String, dynamic>) {
        _companyDefaults = decoded;
      }
    }
    _clientSub = repo
        .watch(companyId: companyId, id: clientId)
        .listen(
          _onRowEmitted,
          onError: (Object e, StackTrace st) {
            _log.warning('client watch errored for $clientId', e, st);
            if (_disposed) return;
            _loadError = e.toString();
            _loaded = true;
            notifyListeners();
          },
        );
  }

  void _onRowEmitted(Client? client) {
    if (_disposed) return;
    _client = client;
    final raw = client?.settings ?? const <String, dynamic>{};
    final next = CompanySettingsApi.fromJson(raw);
    if (!_loaded) {
      _initial = next;
      _draft = next;
      _loaded = true;
      notifyListeners();
      return;
    }
    // Already showing data — preserve the user's in-progress edit if any
    // (matches the company-scoped VM's refresh semantics).
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
  Future<Client?> save() async {
    final client = _client;
    if (client == null || _isSaving) return null;
    _isSaving = true;
    _submitError = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      final json = _draft.toJson()..removeWhere((_, v) => v == null);
      final next = client.copyWith(settings: json.isEmpty ? null : json);
      await repo.save(companyId: companyId, client: next);
      _initial = _draft;
      return next;
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

  @override
  void dispose() {
    _disposed = true;
    _clientSub?.cancel();
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
