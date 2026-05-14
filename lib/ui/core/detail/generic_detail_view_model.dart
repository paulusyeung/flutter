import 'dart:async';

import 'package:flutter/foundation.dart';

/// Read-only entity-detail ViewModel. Subscribes to a repo watch stream and
/// exposes the latest value through [item]. Anything that mutates the row —
/// a synced edit, a server refresh, an `applyDeleteResponse` — propagates to
/// the UI here.
///
/// Two ways to use it:
///
///  * **Plain entities** — instantiate directly (or via a typedef alias) and
///    pass the watch stream to [GenericDetailViewModel.bound]. The default
///    for an entity with no screen-specific derived state.
///
///  * **Entities with derived state** — subclass and add entity-specific
///    getters; the subclass constructor still forwards the watch stream to
///    [bindStream]. `ClientDetailViewModel` is the reference.
class GenericDetailViewModel<T> extends ChangeNotifier {
  GenericDetailViewModel();

  /// Subscribe the VM to [stream]. Equivalent to `GenericDetailViewModel()
  /// ..bindStream(stream)` — exists so screens can express the wiring as one
  /// expression in `initState`.
  GenericDetailViewModel.bound(Stream<T?> stream) {
    bindStream(stream);
  }

  T? _item;
  T? get item => _item;

  bool _isResolving = true;
  bool get isResolving => _isResolving;

  StreamSubscription<T?>? _sub;

  /// Subscribe to [stream]. Replaces any prior subscription. Each emission
  /// updates [item] and clears [isResolving].
  @protected
  void bindStream(Stream<T?> stream) {
    _sub?.cancel();
    _isResolving = true;
    _sub = stream.listen((value) {
      _item = value;
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
