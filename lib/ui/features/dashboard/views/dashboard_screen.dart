import 'package:flutter/material.dart';

import '../../../core/adaptive.dart';
import '../../shell/widgets/app_drawer.dart';

/// Dashboard placeholder. Charts and aggregates land in a later milestone;
/// the route exists in M1 so the shell has more than one branch.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: const Text('Dashboard'),
            leading: wide ? null : const DrawerHamburger(),
          ),
          body: const Center(child: Text('Dashboard (later milestone)')),
        );
      },
    );
  }
}
