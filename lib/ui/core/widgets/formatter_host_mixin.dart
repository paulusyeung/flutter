import 'package:flutter/widgets.dart';

import 'package:admin/app/services.dart';
import 'package:admin/utils/formatting.dart';

/// Mixed into a [State] that needs a [Formatter] tied to the current
/// company. Holds the resolved formatter and a "loading for" company id so
/// late futures from a previous company can be ignored when the user
/// switches workspaces mid-flight.
///
/// Typical use:
///
/// ```dart
/// class _MyScreenState extends State<MyScreen> with FormatterHostMixin {
///   late final Services _services;
///   late String _companyId;
///
///   @override
///   void initState() {
///     super.initState();
///     _services = context.read<Services>();
///     _companyId = _services.auth.session.value!.currentCompanyId;
///     loadFormatter(_services, _companyId);
///   }
///
///   void _onCompanyChanged(String newId) {
///     _companyId = newId;
///     clearFormatter();
///     loadFormatter(_services, newId);
///   }
/// }
/// ```
mixin FormatterHostMixin<T extends StatefulWidget> on State<T> {
  Formatter? _formatter;
  String? _formatterLoadingFor;

  /// Resolved formatter, or null while the [formatterFor] future is in
  /// flight. Money columns typically render as `—` while null.
  Formatter? get formatter => _formatter;

  /// Kick off a `formatterFor(companyId)` future and adopt its result.
  /// Safe to call repeatedly: stale futures (where [companyId] no longer
  /// matches the in-progress request) are dropped.
  void loadFormatter(Services services, String companyId) {
    _formatterLoadingFor = companyId;
    services.formatterFor(companyId).then((f) {
      // Discard if the widget is gone or the user switched company while
      // the future was in flight — otherwise the new company would briefly
      // render with the previous company's currency settings.
      if (!mounted || _formatterLoadingFor != companyId) return;
      setState(() => _formatter = f);
    });
  }

  /// Drop the current formatter so the UI renders the `—` placeholder
  /// until a follow-up [loadFormatter] resolves. Call this before
  /// [loadFormatter] when the company id changes so the previous
  /// company's currency doesn't briefly flash on screen.
  void clearFormatter() {
    if (_formatter == null && _formatterLoadingFor == null) return;
    setState(() {
      _formatter = null;
      _formatterLoadingFor = null;
    });
  }
}
