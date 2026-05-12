import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Surface the sync layer cares about:
///   * a stream that fires when the device transitions **into** an online
///     state (so listeners don't churn on going-offline events), and
///   * a one-shot [isOnline] read used by the company-switch dialog to
///     decide whether to silently drain or prompt the user.
///
/// "Online" = any [ConnectivityResult] other than [ConnectivityResult.none].
/// Mobile / wifi / ethernet / vpn / other are treated the same: the sync
/// layer just needs the radio up; the request itself fails and retries via
/// the outbox if the link is flaky.
///
/// Use [ConnectivityWatcher.live] in production, [ConnectivityWatcher.fixed]
/// in tests where you want a deterministic state without the
/// `connectivity_plus` platform channel.
abstract class ConnectivityWatcher {
  ConnectivityWatcher();

  factory ConnectivityWatcher.live() = _LiveConnectivityWatcher;

  /// Test-only — always reports [online], emits one fake transition if the
  /// listener subscribes while [online] is true (so wiring-up code can be
  /// exercised), and never emits otherwise.
  factory ConnectivityWatcher.fixed({required bool online}) =
      _FixedConnectivityWatcher;

  Future<bool> get isOnline;

  Stream<void> get onOnline;
}

class _LiveConnectivityWatcher extends ConnectivityWatcher {
  _LiveConnectivityWatcher({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<void> get onOnline {
    var wasOnline = false;
    return _connectivity.onConnectivityChanged
        .map(_anyOnline)
        .where((online) {
          final transitioned = online && !wasOnline;
          wasOnline = online;
          return transitioned;
        })
        .map((_) {});
  }

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _anyOnline(results);
  }

  static bool _anyOnline(List<ConnectivityResult> results) {
    for (final r in results) {
      if (r != ConnectivityResult.none) return true;
    }
    return false;
  }
}

class _FixedConnectivityWatcher extends ConnectivityWatcher {
  _FixedConnectivityWatcher({required this.online});

  final bool online;

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<void> get onOnline => const Stream<void>.empty();
}
