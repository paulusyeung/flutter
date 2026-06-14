import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Bridges native OAuth-return deep links into the in-app router.
///
/// After the user consents in the system browser, the backend redirects to the
/// app's custom scheme (e.g. `invoiceninja://calendar_connection/complete?…`
/// carrying the one-time `handoff`). The OS delivers that URI here; we translate
/// it into a [GoRouter] navigation to `/calendar_connection/complete` so a
/// single completion screen handles web (full-page redirect) and native (deep
/// link) identically. Covers cold-start (the launching link) and warm (stream)
/// deliveries.
///
/// No-op on web, where the OAuth return is an ordinary route load — there is no
/// custom-scheme hop to intercept.
class CalendarDeepLinks {
  CalendarDeepLinks(this._router) {
    if (kIsWeb) return;
    try {
      final links = AppLinks();
      _sub = links.uriLinkStream.listen(_handle, onError: (_) {});
      // Cold start: the deep link that launched the app, if any.
      unawaited(
        links
            .getInitialLink()
            .then((uri) {
              if (uri != null) _handle(uri);
            })
            .catchError((_) {}),
      );
    } catch (_) {
      // Deep links are a convenience; never let init crash app boot.
    }
  }

  final GoRouter _router;
  StreamSubscription<Uri>? _sub;

  static bool _isCalendarComplete(Uri uri) {
    // Custom scheme: invoiceninja://calendar_connection/complete
    if (uri.host == 'calendar_connection') {
      return uri.path == '/complete' || uri.path == '/complete/';
    }
    // Defensive: a future universal-link form ".../calendar_connection/complete".
    return uri.path.endsWith('/calendar_connection/complete');
  }

  void _handle(Uri uri) {
    if (!_isCalendarComplete(uri)) return;
    final target = Uri(
      path: '/calendar_connection/complete',
      queryParameters: uri.queryParameters.isEmpty ? null : uri.queryParameters,
    );
    _router.go(target.toString());
  }

  void dispose() {
    unawaited(_sub?.cancel());
  }
}
