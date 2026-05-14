import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/views/basic/online_payments/online_payments_shell.dart';

/// Thin entry-point for the Online Payments settings page. The screen body
/// lives in [OnlinePaymentsShell] alongside the three section bodies under
/// `online_payments/`; this file stays so the existing import in
/// `settings_routes.dart` keeps working without a churn diff.
class OnlinePaymentsScreen extends StatelessWidget {
  const OnlinePaymentsScreen({super.key, this.initialTab});

  /// `:tab` path-parameter from the route. Null on the bare URL.
  final String? initialTab;

  @override
  Widget build(BuildContext context) =>
      OnlinePaymentsShell(initialTab: initialTab);
}
