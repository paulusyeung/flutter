import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../db/app_database.dart';
import '../services/statics_service.dart';

final _log = Logger('StaticsRepository');

/// Loads + caches `/api/v1/statics`. The cache is a single JSON blob in
/// Drift's `statics` table; lookups are keyed `(map, id)` so a screen can
/// e.g. read a currency name without reparsing the entire blob each time.
class StaticsRepository {
  StaticsRepository({
    required AppDatabase db,
    required StaticsService service,
    Duration ttl = const Duration(days: 7),
    DateTime Function()? now,
  }) : _db = db,
       _service = service,
       _ttl = ttl,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final StaticsService _service;
  final Duration _ttl;
  final DateTime Function() _now;

  Map<String, dynamic>? _memo;

  /// Refresh the cache if it's empty or older than [_ttl]. Idempotent and
  /// cheap to call from app start + post-login.
  Future<void> ensureLoaded({bool force = false}) async {
    final cached = await _db.staticsDao.read();
    final nowMs = _now().millisecondsSinceEpoch;
    if (!force &&
        cached != null &&
        nowMs - cached.fetchedAt < _ttl.inMilliseconds) {
      _memo = jsonDecode(cached.payload) as Map<String, dynamic>;
      return;
    }
    try {
      final fresh = await _service.fetch();
      await _db.staticsDao.write(payload: jsonEncode(fresh), fetchedAt: nowMs);
      _memo = fresh;
    } catch (e, st) {
      _log.warning('statics refresh failed; using stale cache if any', e, st);
      if (cached != null) {
        _memo = jsonDecode(cached.payload) as Map<String, dynamic>;
      }
    }
  }

  /// Get one entry from a top-level array (e.g. `currencies`) by `id`.
  /// Returns null if the bundle isn't loaded or the id is missing.
  Map<String, dynamic>? entry(String mapName, String id) {
    final m = _memo;
    if (m == null) return null;
    final arr = m[mapName];
    if (arr is! List) return null;
    for (final item in arr) {
      if (item is Map<String, dynamic> && item['id']?.toString() == id) {
        return item;
      }
    }
    return null;
  }

  /// Convenience: currency symbol for the given id.
  String? currencySymbol(String currencyId) =>
      entry('currencies', currencyId)?['symbol']?.toString();
}
