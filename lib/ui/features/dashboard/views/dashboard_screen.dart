import 'package:flutter/material.dart';

/// Dashboard placeholder. Charts and aggregates land in a later milestone;
/// the route exists in M1 so the shell has more than one branch.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard (later milestone)')),
    );
  }
}
