import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Centered, scrolling, max-width-constrained body for any settings page.
/// Pass [sections] for the standard "list of [FormSection] cards" layout
/// (covers ~every settings page) — the shell wraps them in a stretched
/// [Column] for you. Pass [child] for the rare custom body that isn't a
/// section list.
class SettingsFormShell extends StatelessWidget {
  const SettingsFormShell({
    super.key,
    this.child,
    this.sections,
    this.maxWidth = 720,
  }) : assert(
         child != null || sections != null,
         'Provide either child or sections',
       ),
       assert(
         child == null || sections == null,
         'Provide child or sections, not both',
       );

  final Widget? child;
  final List<Widget>? sections;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final body = sections != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections!,
          )
        : child!;
    return ListView(
      padding: const EdgeInsets.all(InSpacing.xl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: body,
          ),
        ),
      ],
    );
  }
}
