import 'dart:async';

import 'package:flutter/foundation.dart';

/// Read-only entity-detail ViewModel. Subscribes to the repo's watch stream
/// (concrete subclasses provide the stream factory) and exposes the latest
/// value through [item]. Anything that mutates the row — a synced edit, a
/// server refresh, an `applyDeleteResponse` — propagates to the UI here.
///
/// Concrete subclasses (`ClientDetailViewModel`, `ProductDetailViewModel`,
/// …) only supply:
///   * a constructor that builds the repo watch stream and forwards it to
///     [bindStream]
///   * any entity-specific helpers (e.g. derived display strings)
abstract class GenericDetailViewModel<T> extends ChangeNotifier {
  GenericDetailViewModel();

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
