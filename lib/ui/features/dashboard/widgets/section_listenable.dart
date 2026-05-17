import 'package:flutter/widgets.dart';

/// Rebuilds [build] only when [listenable] notifies — used to bind each
/// dashboard card/KPI/chart to its own per-section notifier so a single
/// section's stream emission rebuilds just that widget, not the whole
/// dashboard (perf plan 4.5). Cross-cutting chrome still rides the global
/// VM notify.
///
/// Shared by both the wide (`dashboard_screen.dart`) and mobile
/// (`mobile_dashboard_body.dart`) layouts — previously duplicated as a
/// private `_section` in each (perf plan 6A).
Widget sectionListenable(Listenable listenable, Widget Function() build) =>
    ListenableBuilder(listenable: listenable, builder: (_, _) => build());
