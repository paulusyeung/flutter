import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';
import 'package:admin/ui/features/reports/widgets/reports_body.dart';

/// Top-level Reports page reachable from the sidebar at `/reports`.
///
/// Owns the formatter (via [FormatterHostMixin]) and the
/// [ReportsViewModel]; renders [ReportsBody], which holds the toolbar,
/// the sticky chrome, and the data-table / card-list layout switch.
///
/// First-paint rule (per the plan): Clients report preselected,
/// `This year` range, EmptyState reads "Run to load Clients for This year…"
/// — Run is the primary CTA; nothing auto-fires.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with FormatterHostMixin {
  ReportsViewModel? _vm;
  String? _vmCompanyId;
  late final Services _services;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    final companyId =
        _services.auth.session.value?.currentCompanyId ?? '';
    if (companyId.isNotEmpty) {
      loadFormatter(_services, companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _services.auth.session.value;
    final companyId = session?.currentCompanyId ?? '';

    // Rebuild the VM on company switch — same pattern as the entity list
    // scaffold's lifecycle hook.
    if (_vm == null || _vmCompanyId != companyId) {
      _vm?.dispose();
      _vm = ReportsViewModel(
        repo: _services.reports,
        statics: _services.statics,
      );
      _vmCompanyId = companyId;
      if (companyId.isNotEmpty) {
        clearFormatter();
        loadFormatter(_services, companyId);
      }
    }

    return ChangeNotifierProvider<ReportsViewModel>.value(
      value: _vm!,
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('reports'))),
        body: ReportsBody(formatter: formatter),
      ),
    );
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }
}
