import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/saved_view.dart';
import 'package:admin/domain/entity_type.dart';

final _log = Logger('SavedViewsRepository');

/// Current snapshot envelope version. Bumped when the snapshot's `data`
/// shape changes (e.g. adding column captures). Older rows decode through
/// the `v == null` legacy lane.
const int kSavedViewSnapshotVersion = 1;

/// Local-only saved views: named snapshots of a list screen's
/// filter+sort+search state. The repository owns serialization and the
/// "apply" path that splices a snapshot into `nav_state.filters_json` so
/// running list ViewModels (which subscribe to `navStateDao.watchCurrent`)
/// re-hydrate without explicit notification plumbing.
class SavedViewsRepository {
  SavedViewsRepository({
    required this.db,
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
  }) : _uuid = uuid,
       _now = now ?? DateTime.now;

  final AppDatabase db;
  final Uuid _uuid;
  final DateTime Function() _now;

  // ── Reads ─────────────────────────────────────────────────────────────

  /// Watch every saved view for [companyId], any entity. The sidebar
  /// consumes this and renders one item per row, grouped by entity at the
  /// UI layer.
  Stream<List<SavedView>> watchAll(String companyId) =>
      db.savedViewsDao.watchAll(companyId).map(_decodeRows);

  /// Watch saved views for a single `(companyId, entityType)`. Drives the
  /// bookmark sheet's existing-views list.
  Stream<List<SavedView>> watchForEntity(
    String companyId,
    EntityType entityType,
  ) => db.savedViewsDao
      .watchForEntity(companyId, entityType.name)
      .map(_decodeRows);

  /// The saved view (if any) whose snapshot deeply matches [currentSnapshot]
  /// for the given `(companyId, entityType)`. Emits `null` when the current
  /// list state doesn't correspond to any saved view.
  ///
  /// Exposed for the deferred "active-view indicator" — that visual lands
  /// as a one-line `StreamBuilder` once the design is ready.
  Stream<SavedView?> matchingView({
    required String companyId,
    required EntityType entityType,
    required Map<String, dynamic> currentSnapshot,
  }) {
    const eq = DeepCollectionEquality();
    return watchForEntity(companyId, entityType).map((views) {
      for (final v in views) {
        if (eq.equals(v.snapshot, currentSnapshot)) return v;
      }
      return null;
    });
  }

  // ── Writes ────────────────────────────────────────────────────────────

  Future<SavedView> create({
    required String companyId,
    required EntityType entityType,
    required String name,
    required Map<String, dynamic> snapshot,
  }) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final payload = _encode(snapshot);
    await db.savedViewsDao.insertView(
      SavedViewsCompanion(
        id: Value(id),
        companyId: Value(companyId),
        entityType: Value(entityType.name),
        name: Value(name),
        payloadJson: Value(payload),
        createdAt: Value(nowMs),
        updatedAt: Value(nowMs),
      ),
    );
    return SavedView(
      id: id,
      companyId: companyId,
      entityType: entityType,
      name: name,
      snapshot: snapshot,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
  }

  Future<void> rename({required String viewId, required String newName}) async {
    await db.savedViewsDao.updateById(
      id: viewId,
      name: newName,
      now: _now().millisecondsSinceEpoch,
    );
  }

  Future<void> updateSnapshot({
    required String viewId,
    required Map<String, dynamic> snapshot,
  }) async {
    await db.savedViewsDao.updateById(
      id: viewId,
      payloadJson: _encode(snapshot),
      now: _now().millisecondsSinceEpoch,
    );
  }

  Future<void> delete(String viewId) => db.savedViewsDao.deleteById(viewId);

  /// Apply [viewId]: splice its snapshot into `nav_state.filters_json` at
  /// `companyId → entityType.name`, then rely on `NavStateDao.watchCurrent`
  /// to drive the running list VM to re-hydrate. No-op when the row is
  /// missing (deleted between watch emission and tap).
  Future<void> apply(String viewId) async {
    final row = await db.savedViewsDao.byId(viewId);
    if (row == null) return;
    final entityType = _entityTypeOrNull(row.entityType);
    if (entityType == null) return;
    final snapshot = _decodePayload(row.payloadJson);
    if (snapshot == null) return;

    final nav = await db.navStateDao.current();
    final existing = nav?.filtersJson;
    Map<String, dynamic> doc;
    if (existing == null || existing.isEmpty) {
      doc = <String, dynamic>{};
    } else {
      try {
        final decoded = jsonDecode(existing);
        doc = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      } catch (_) {
        doc = <String, dynamic>{};
      }
    }
    final companyBlob = doc[row.companyId];
    final companyMap = companyBlob is Map<String, dynamic>
        ? Map<String, dynamic>.from(companyBlob)
        : <String, dynamic>{};
    companyMap[entityType.name] = snapshot;
    doc[row.companyId] = companyMap;

    await db.navStateDao.saveFilters(
      filtersJson: jsonEncode(doc),
      now: _now().millisecondsSinceEpoch,
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────

  /// Wrap [data] in the schema-versioned envelope. Reading code accepts
  /// both `{"v": 1, "data": {...}}` (current) and a bare `{...}` (forward-
  /// compat lane for legacy rows that never went through this encoder).
  String _encode(Map<String, dynamic> data) =>
      jsonEncode({'v': kSavedViewSnapshotVersion, 'data': data});

  /// Decode payload JSON. Returns `null` (skip) on corrupt rows so a single
  /// bad write doesn't poison the whole watch stream.
  Map<String, dynamic>? _decodePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      // Versioned envelope.
      if (decoded.containsKey('v')) {
        final inner = decoded['data'];
        if (inner is Map) return Map<String, dynamic>.from(inner);
        return null;
      }
      // Legacy / forward-compat: bare snapshot map.
      return Map<String, dynamic>.from(decoded);
    } catch (e, st) {
      _log.warning('Failed to decode saved-view payload', e, st);
      return null;
    }
  }

  EntityType? _entityTypeOrNull(String name) {
    for (final t in EntityType.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  List<SavedView> _decodeRows(List<SavedViewRow> rows) {
    final out = <SavedView>[];
    for (final row in rows) {
      final entityType = _entityTypeOrNull(row.entityType);
      if (entityType == null) {
        // Drop rows referencing entities the build no longer knows about
        // (renamed enum case, removed module). Logged but never thrown —
        // a single bad row would otherwise blank out the sidebar.
        _log.fine(
          'Skipping saved view ${row.id}: unknown entity '
          '${row.entityType}',
        );
        continue;
      }
      final snapshot = _decodePayload(row.payloadJson);
      if (snapshot == null) continue;
      out.add(
        SavedView(
          id: row.id,
          companyId: row.companyId,
          entityType: entityType,
          name: row.name,
          snapshot: snapshot,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      );
    }
    return out;
  }
}
