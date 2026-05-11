import 'package:flutter/material.dart';

/// Placeholder Settings screen. Theme toggle, locale picker, sign-out,
/// diagnostics, and outbox screen entry land in M1.11.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings (M1.11)')),
    );
  }
}
