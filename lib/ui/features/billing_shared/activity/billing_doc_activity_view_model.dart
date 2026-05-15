import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/outbox_dao.dart';
import 'package:admin/data/models/domain/activity.dart';
import 'package:admin/data/services/activities_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// State for any billing-doc Activity tab. Entity-agnostic — pass the
/// `entityWireName` (`'invoice'` / `'quote'` / `'credit'` /
/// `'purchase_order'` / `'recurring_invoice'`) and `entityId`. Two slices
/// feed the UI:
///
/// 1. **Synced activities** — fetched from `POST /api/v1/activities/entity`
///    on first observation and again whenever the pending outbox drains.
/// 2. **Pending mutations** — outbox rows for `addComment` on this entity,
///    streamed so the UI can render optimistic "syncing…" entries above
///    the synced list.
class BillingDocActivityViewModel extends ChangeNotifier {
  BillingDocActivityViewModel({
    required this.api,
    required this.outbox,
    required this.companyId,
    required this.entityWireName,
    required this.entityId,
  }) {
    pending = outbox.watchPendingForEntity(
      companyId: companyId,
      entityType: entityWireName,
      entityId: entityId,
      kind: MutationKind.addComment,
    );
    _pendingSub = pending.listen(_onPendingTick);
  }

  final ActivitiesApi api;
  final OutboxDao outbox;
  final String companyId;
  final String entityWireName;
  final String entityId;

  late final Stream<List<OutboxRow>> pending;
  StreamSubscription<List<OutboxRow>>? _pendingSub;

  List<Activity> _activities = const [];
  List<Activity> get activities => _activities;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _error;
  Object? get error => _error;

  bool _started = false;
  int _lastPendingCount = 0;

  /// Idempotent. Call from the view's `initState` (or first build) — the
  /// initial fetch only runs once; subsequent calls are no-ops.
  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await api.fetchForEntity(
        entity: entityWireName,
        entityId: entityId,
      );
      final mapped = raw.map(Activity.fromApi).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _activities = mapped;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onPendingTick(List<OutboxRow> rows) {
    final count = rows.length;
    // A pending row just landed in the synced state — refetch so the
    // server-confirmed activity replaces the optimistic entry. Skip the
    // first emission (rows is whatever the DB held when we subscribed).
    if (_started && !_isLoading && _lastPendingCount > 0 && count == 0) {
      unawaited(refresh());
    }
    _lastPendingCount = count;
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    super.dispose();
  }
}
