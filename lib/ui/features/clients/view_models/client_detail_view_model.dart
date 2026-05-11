import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/repositories/client_repository.dart';

/// State for the read-only Client detail screen.
///
/// Subscribes to [ClientRepository.watch] so anything that mutates the row
/// (a synced edit, a server refresh, an `applyDeleteResponse`) propagates
/// straight to the screen. Also nudges [ClientRepository.ensureLoaded] on
/// open so a deep-linked URL works even if the list hasn't been visited.
class ClientDetailViewModel extends ChangeNotifier {
  ClientDetailViewModel({
    required this.repo,
    required this.companyId,
    required this.id,
  }) {
    _subscribe();
  }

  final ClientRepository repo;
  final String companyId;
  final String id;

  Client? _client;
  Client? get client => _client;

  bool _isResolving = true;
  bool get isResolving => _isResolving;

  StreamSubscription<Client?>? _sub;

  void _subscribe() {
    _sub = repo.watch(companyId: companyId, id: id).listen((c) {
      _client = c;
      _isResolving = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
