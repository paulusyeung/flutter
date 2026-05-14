import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';

/// Owns the lifecycle of a settings ViewModel that is tied to the active
/// company: builds the VM with the current `auth.session.currentCompanyId`,
/// listens for company switches, and disposes + rebuilds the VM against the
/// new tenant id when the user picks a different company.
///
/// The old draft is intentionally discarded on switch — it belongs to the
/// previous tenant and would be invalid against the new one's id. The
/// company picker is responsible for gating the switch on a confirm-discard
/// dialog (`UnsavedChangesGuard.confirmIfDirty`); by the time this listener
/// fires the user has already opted in to losing the draft.
///
/// `create` should also kick off any one-shot `load()` the VM needs so the
/// helper doesn't have to know about a specific lifecycle method. The
/// callback runs once on init and once per company switch.
///
/// Both [CascadeSettingsScaffold] and `CompanyDetailsShell` use this helper.
/// New custom shells (Email Settings, Online Payments, Tax Settings, …)
/// should reach for this rather than re-rolling the listener inline.
class SettingsCompanyScopedHost<V extends ChangeNotifier>
    extends StatefulWidget {
  const SettingsCompanyScopedHost({
    super.key,
    required this.create,
    required this.builder,
  });

  /// Builds the VM for the supplied company id. Called once on init and
  /// again on every session-driven company switch. Implementations should
  /// also kick off any required `load()` here.
  final V Function(String companyId) create;

  /// Renders the current VM. Re-runs when [create] returns a fresh VM
  /// after a company switch.
  final Widget Function(BuildContext context, V vm) builder;

  @override
  State<SettingsCompanyScopedHost<V>> createState() =>
      _SettingsCompanyScopedHostState<V>();
}

class _SettingsCompanyScopedHostState<V extends ChangeNotifier>
    extends State<SettingsCompanyScopedHost<V>> {
  late final Services _services;
  late V _vm;
  String _currentCompanyId = '';

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _currentCompanyId = _services.auth.session.value?.currentCompanyId ?? '';
    _vm = widget.create(_currentCompanyId);
    _services.auth.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    final next = _services.auth.session.value?.currentCompanyId ?? '';
    if (next == _currentCompanyId) return;
    setState(() {
      _vm.dispose();
      _currentCompanyId = next;
      _vm = widget.create(_currentCompanyId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _vm);
}
