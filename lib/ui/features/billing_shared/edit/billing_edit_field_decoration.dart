import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Canonical compact field decoration for the desktop billing-doc edit
/// cards. Mirrors `SearchableDropdownField`'s look (dense, md/14
/// padding, rounded outline, accent focus) so plain `TextField`s, the
/// Client/Design pickers, and `InDateField` all render at the SAME
/// height. Without this the screen mixed three field heights.
InputDecoration billingFieldDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  String? errorText,
}) {
  final theme = Theme.of(context);
  final tokens = context.inTheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(InRadii.r1),
    borderSide: BorderSide(color: tokens.border),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    labelStyle: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink3),
    floatingLabelStyle:
        theme.textTheme.bodySmall?.copyWith(color: tokens.ink2),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: InSpacing.md(context),
      vertical: 14,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(InRadii.r1),
      borderSide: BorderSide(color: tokens.accent, width: 1.5),
    ),
  );
}
