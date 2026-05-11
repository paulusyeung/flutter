import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

class SettingsFormShell extends StatelessWidget {
  const SettingsFormShell({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(InSpacing.xl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ],
    );
  }
}
