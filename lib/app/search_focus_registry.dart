import 'package:flutter/widgets.dart';

/// One-slot registry of the currently-mounted token search field's
/// [FocusNode]. The global `/` shortcut in the authenticated shell reads
/// this to focus the search input on the active list screen without
/// coupling the shell to any specific list. Filled by
/// `_TokenSearchFieldState.initState` and cleared in `dispose`; `null`
/// when no list screen is mounted (e.g. on the dashboard or settings).
///
/// Plain mutable field — the `/` action runs once per keystroke and
/// reads the slot synchronously, so there is no need to notify
/// listeners on writes.
class SearchFocusRegistry {
  FocusNode? current;
}
