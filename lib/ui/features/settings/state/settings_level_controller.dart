import 'package:flutter/foundation.dart';

/// The level at which a settings page is currently editing.
///
/// At [SettingsLevel.company] every field is "set" — the form renders
/// without override checkboxes. At [SettingsLevel.group] / [SettingsLevel.client]
/// each field on the entity's own `settings` blob may be `null` (meaning
/// "inherit from the parent in the cascade"); the form wraps each field in
/// an [OverridableField] that exposes a checkbox to toggle the override.
///
/// Mirrors React's `useCurrentSettingsLevel()` hook
/// (`react/src/common/hooks/useCurrentSettingsLevel.ts`).
enum SettingsLevel {
  company,

  /// Reserved for group-scope cascade — wire when group editing ships. The
  /// override widgets already accept this value; no surface in the UI yet.
  group,

  client,
}

/// Cheap [ChangeNotifier] holding the current settings-edit level and the
/// id of the entity being edited (null at company level). Provided at the
/// settings shell root via `provider` so any settings page can read it.
///
/// Today the company and client paths are reachable from the UI (sidebar
/// scope switch); the group path exists so the override widgets compile
/// and will render correctly when group editing surfaces a selector.
class SettingsLevelController extends ChangeNotifier {
  SettingsLevel _level = SettingsLevel.company;
  String? _targetId;
  String? _targetName;

  SettingsLevel get level => _level;
  String? get targetId => _targetId;

  /// Human-readable name of the entity being edited (the client display name
  /// at client level, group name at group level). Carried for the scope
  /// banner so it can render without re-watching the entity.
  String? get targetName => _targetName;

  bool get isCompany => _level == SettingsLevel.company;
  bool get isGroup => _level == SettingsLevel.group;
  bool get isClient => _level == SettingsLevel.client;

  void setLevel(SettingsLevel level, {String? targetId, String? targetName}) {
    if (_level == level && _targetId == targetId && _targetName == targetName) {
      return;
    }
    _level = level;
    _targetId = targetId;
    _targetName = targetName;
    notifyListeners();
  }

  void reset() {
    if (_level == SettingsLevel.company &&
        _targetId == null &&
        _targetName == null) {
      return;
    }
    _level = SettingsLevel.company;
    _targetId = null;
    _targetName = null;
    notifyListeners();
  }
}
