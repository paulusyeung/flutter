import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/membership_filter_key.dart';

/// `client:foo` — multi-valued client filter shared by every list whose
/// API endpoint honors `client_id` (invoices, quotes, credits, recurring
/// invoices, payments, expenses, projects — all confirmed working server
/// side in the May 2026 audit).
///
/// Mirrors `ProjectFilterKey` in `lib/ui/features/tasks/task_filter_keys.dart`:
/// raw value is the server client id; suggestions stream from
/// `ClientRepository.watchActiveNames` (cheap `(id, name)` projection);
/// the same stream populates an in-memory cache so chip text shows the
/// client name instead of the raw id.
///
/// Caveat (same as ProjectFilterKey): chips render synchronously, so the
/// very first paint after picking a client may show the raw id until the
/// names stream produces its next event.
class ClientFilterKey extends MembershipFilterKey {
  ClientFilterKey({required this.clients, required this.companyId}) {
    _namesSub = clients.watchActiveNames(companyId: companyId).listen((rows) {
      _names
        ..clear()
        ..addEntries(rows.map((r) => MapEntry(r.id, r.name)));
    });
  }

  final ClientRepository clients;
  final String companyId;
  final Map<String, String> _names = <String, String>{};
  StreamSubscription<List<({String id, String name})>>? _namesSub;

  @override
  String get id => 'client';

  @override
  String get serverKey => 'client_id';

  @override
  String displayLabel(BuildContext context) => context.tr('client');

  @override
  String displayValueFor(String rawValue) {
    final cached = _names[rawValue];
    if (cached != null && cached.isNotEmpty) return cached;
    return rawValue;
  }

  @override
  Stream<List<FilterValueSuggestion>> watchValueSuggestions(
    GenericListViewModel<dynamic> vm,
    BuildContext context,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return clients.watchActiveNames(companyId: companyId).map((all) {
      final filtered = q.isEmpty
          ? all.take(50)
          : all.where((c) => c.name.toLowerCase().contains(q));
      return [
        for (final c in filtered)
          FilterValueSuggestion(
            rawValue: c.id,
            displayLabel: c.name.isEmpty ? c.id : c.name,
          ),
      ];
    });
  }

  /// Release the names-cache subscription when the filter key is replaced
  /// (e.g. on company switch). `FilterKey` doesn't have a lifecycle hook
  /// today, so the subscription effectively lives until GC. Acceptable —
  /// the next instance subscribes against the new tenant's data.
  void dispose() {
    _namesSub?.cancel();
    _namesSub = null;
  }
}
