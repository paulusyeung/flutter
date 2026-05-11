import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/datetime_format.dart';
import 'package:admin/data/models/value/industry.dart';
import 'package:admin/data/models/value/size.dart';
import 'package:admin/data/services/statics_service.dart';

final _log = Logger('StaticsRepository');

/// Loads + caches `/api/v1/statics`. The cache is a single JSON blob in
/// Drift's `statics` table; typed lookups (`currency`, `country`,
/// `dateFormat`) are parsed lazily into immutable maps the first time
/// they're requested after a reload.
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
  Map<String, Currency>? _currencies;
  Map<String, Country>? _countries;
  Map<String, DatetimeFormat>? _dateFormats;
  Map<String, Size>? _sizes;
  Map<String, Industry>? _industries;

  /// Refresh the cache if it's empty or older than [_ttl]. Idempotent and
  /// cheap to call from app start + post-login.
  Future<void> ensureLoaded({bool force = false}) async {
    final cached = await _db.staticsDao.read();
    final nowMs = _now().millisecondsSinceEpoch;
    if (!force &&
        cached != null &&
        nowMs - cached.fetchedAt < _ttl.inMilliseconds) {
      _setMemo(jsonDecode(cached.payload) as Map<String, dynamic>);
      return;
    }
    try {
      final fresh = await _service.fetch();
      await _db.staticsDao.write(payload: jsonEncode(fresh), fetchedAt: nowMs);
      _setMemo(fresh);
    } catch (e, st) {
      _log.warning('statics refresh failed; using stale cache if any', e, st);
      if (cached != null) {
        _setMemo(jsonDecode(cached.payload) as Map<String, dynamic>);
      }
    }
  }

  void _setMemo(Map<String, dynamic> blob) {
    _memo = blob;
    // Invalidate the typed views so the next read reparses.
    _currencies = null;
    _countries = null;
    _dateFormats = null;
    _sizes = null;
    _industries = null;
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

  /// Typed currency / country / date-format maps, keyed by string id. Empty
  /// until [ensureLoaded] completes.
  Map<String, Currency> get currencies =>
      _currencies ??= _parseMap('currencies', Currency.fromMap);

  Map<String, Country> get countries =>
      _countries ??= _parseMap('countries', Country.fromMap);

  Map<String, DatetimeFormat> get dateFormats =>
      _dateFormats ??= _parseMap('date_formats', DatetimeFormat.fromMap);

  Map<String, Size> get sizes => _sizes ??= _parseMap('sizes', Size.fromMap);

  Map<String, Industry> get industries =>
      _industries ??= _parseMap('industries', Industry.fromMap);

  Currency? currency(String id) => currencies[id];
  Country? country(String id) => countries[id];
  DatetimeFormat? dateFormat(String id) => dateFormats[id];
  Size? size(String id) => sizes[id];
  Industry? industry(String id) => industries[id];

  Map<String, T> _parseMap<T>(
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final m = _memo;
    if (m == null) return const {};
    final arr = m[key];
    if (arr is! List) {
      _log.warning(
        'statics["$key"] missing or not a list; top-level keys=${m.keys.toList()}',
      );
      return const {};
    }
    final out = <String, T>{};
    for (final item in arr) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) out[id] = parse(item);
      }
    }
    return out;
  }
}
