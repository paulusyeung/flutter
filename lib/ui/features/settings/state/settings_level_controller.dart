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
enum SettingsLevel { company, group, client }

/// Cheap [ChangeNotifier] holding the current settings-edit level and the
/// id of the entity being edited (null at company level). Provided at the
/// settings shell root via `provider` so any settings page can read it.
///
/// In M1 only the company path is reachable from the UI; the group/client
/// paths exist so the override widgets compile and render correctly when
/// we surface a level selector later.
class SettingsLevelController extends ChangeNotifier {
  SettingsLevel _level = SettingsLevel.company;
  String? _targetId;

  SettingsLevel get level => _level;
  String? get targetId => _targetId;

  bool get isCompany => _level == SettingsLevel.company;
  bool get isGroup => _level == SettingsLevel.group;
  bool get isClient => _level == SettingsLevel.client;

  void setLevel(SettingsLevel level, {String? targetId}) {
    if (_level == level && _targetId == targetId) return;
    _level = level;
    _targetId = targetId;
    notifyListeners();
  }

  void reset() {
    if (_level == SettingsLevel.company && _targetId == null) return;
    _level = SettingsLevel.company;
    _targetId = null;
    notifyListeners();
  }
}
