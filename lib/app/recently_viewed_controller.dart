import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/recent_record.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/domain/entity_type.dart';

final _log = Logger('RecentlyViewedController');

/// Owns the "recently-viewed entities" list backing the command palette's
/// "Recent" group.
///
/// Company-scoped, same contract as [NavHistoryController]: the list clears
/// when the active company changes or on logout — you must not be able to
/// jump back into another company's records. Persists to the single-row
/// `nav_state.recent_entities_json` (partial write, same pattern as
/// [SidebarController]) so recents survive an app restart for the company the
/// user left off in. Writes are debounced — opening a detail screen is a hot
/// path and we don't want a DB round-trip per navigation.
class RecentlyViewedController extends ChangeNotifier {
  RecentlyViewedController({
    required AppDatabase db,
    required ValueListenable<AuthSession?> session,
    this.maxEntries = 12,
    DateTime Function()? now,
    Duration persistDebounce = const Duration(milliseconds: 400),
  })  : _db = db,
        _session = session,
        _now = now ?? DateTime.now,
        _persistDebounce = persistDebounce {
    _lastCompanyId = _session.value?.currentCompanyId;
    _session.addListener(_onSession);
  }

  final AppDatabase _db;
  final ValueListenable<AuthSession?> _session;
  final DateTime Function() _now;
  final Duration _persistDebounce;

  /// Cap on retained entries so the blob (and the palette list) stay small.
  final int maxEntries;

  final List<RecentRecord> _items = <RecentRecord>[];
  String? _lastCompanyId;
  Timer? _persistTimer;

  /// Newest first.
  List<RecentRecord> get items => List.unmodifiable(_items);

  /// Load the persisted list on launch. Best-effort: a malformed/legacy blob
  /// yields an empty list rather than throwing into boot.
  Future<void> restore() async {
    try {
      final raw = (await _db.navStateDao.current())?.recentEntitiesJson;
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _items
        ..clear()
        ..addAll(
          decoded
              .map(RecentRecord.tryFromJson)
              .whereType<RecentRecord>()
              .take(maxEntries),
        );
      notifyListeners();
    } catch (e, st) {
      _log.warning('Failed to restore recently-viewed', e, st);
    }
  }

  /// Record (or refresh) a visited entity. De-dupes by (type, id): an
  /// already-present entity moves to the front with a fresh timestamp +
  /// the latest label (names change). No-ops on an empty id.
  void record({
    required EntityType type,
    required String id,
    required String label,
  }) {
    if (id.isEmpty) return;
    final entry = RecentRecord(
      type: type,
      id: id,
      label: label,
      viewedAt: _now(),
    );
    _items.removeWhere(entry.sameEntity);
    _items.insert(0, entry);
    if (_items.length > maxEntries) {
      _items.removeRange(maxEntries, _items.length);
    }
    notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persist);
  }

  Future<void> _persist() async {
    try {
      await _db.navStateDao.saveRecentEntities(
        recentEntitiesJson: _items.isEmpty
            ? null
            : jsonEncode(_items.map((r) => r.toJson()).toList()),
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      // A failed write doesn't roll back the in-memory list — the user still
      // sees their recents until next launch.
      _log.warning('Failed to persist recently-viewed', e, st);
    }
  }

  void _onSession() {
    final companyId = _session.value?.currentCompanyId;
    if (companyId == _lastCompanyId) return;
    _lastCompanyId = companyId;
    if (_items.isEmpty) {
      // Still flush so a stale blob from the previous company can't resurface
      // on the next restart while this company is active.
      _schedulePersist();
      return;
    }
    _items.clear();
    notifyListeners();
    _schedulePersist();
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _session.removeListener(_onSession);
    super.dispose();
  }
}
