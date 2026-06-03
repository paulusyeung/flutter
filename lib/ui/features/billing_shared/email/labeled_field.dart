import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// A form control with its label rendered *above* the field (12px muted
/// label + the child below) — the clean "label-above-field" list look used
/// by both email surfaces.
///
/// Lifted out of `billing_doc_email_sheet.dart` so the bottom sheet and the
/// full-screen [BillingDocEmailScreen] share one definition and stay
/// visually identical.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: tokens.ink3),
          ),
        ),
        child,
      ],
    );
  }
}
