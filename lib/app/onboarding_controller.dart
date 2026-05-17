import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/services/token_storage.dart';

final _log = Logger('OnboardingController');

/// Tracks whether the one-time first-run app walkthrough has been shown.
///
/// Persistence is a single flag in the platform secure store (the same
/// [TokenStorage] abstraction auth uses) — deliberately NOT a `nav_state`
/// Drift column: a schema/version bump mid-flight is risky and the local
/// flag carries no relational weight. Mirrors the construct → [restore] →
/// notify shape of the other local controllers (e.g. `ThemeController`).
///
/// `MaterialApp` doesn't bind to this; the dashboard reads [completed] on
/// first build and the Device Settings "Show app tour" tile calls [reset].
class OnboardingController extends ChangeNotifier {
  OnboardingController({required TokenStorage storage}) : _storage = storage;

  static const _key = 'invoiceninja.onboarding.v1';

  final TokenStorage _storage;

  bool _completed = false;

  /// True once the user has finished or skipped the walkthrough. Defaults to
  /// false until [restore] reads the persisted flag — a fresh install (no
  /// stored value) stays false, so the tour shows exactly once.
  bool get completed => _completed;

  /// Read the persisted flag at boot. Missing / unreadable → stays false
  /// (same as a fresh install). Never throws.
  Future<void> restore() async {
    try {
      final raw = await _storage.read(_key);
      final next = raw == 'true';
      if (next != _completed) {
        _completed = next;
        notifyListeners();
      }
    } catch (e, st) {
      _log.warning('Failed to restore onboarding flag', e, st);
    }
  }

  /// Mark the walkthrough done (finished OR skipped). Persists so it never
  /// reappears on subsequent launches.
  Future<void> markCompleted() async {
    if (_completed) return;
    _completed = true;
    notifyListeners();
    await _persist('true');
  }

  /// Re-arm the walkthrough (Device Settings → "Show app tour").
  Future<void> reset() async {
    if (!_completed) return;
    _completed = false;
    notifyListeners();
    await _persist('false');
  }

  Future<void> _persist(String value) async {
    try {
      await _storage.write(_key, value);
    } catch (e, st) {
      // In-memory state stands even if the write fails — the user still
      // sees the intended behavior until next launch.
      _log.warning('Failed to persist onboarding flag', e, st);
    }
  }
}
