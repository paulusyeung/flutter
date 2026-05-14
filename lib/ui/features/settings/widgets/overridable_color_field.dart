import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/projects/widgets/edit/color_field.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Cascade-aware wrapper around [ColorField]. Bound to a single
/// `company.settings.*` color key (`primary_color`, `secondary_color`).
///
/// At company scope the field renders unwrapped; at group/client scope
/// the override checkbox gates editing. Mirrors the structure of
/// [OverridableSwitchField] / [OverridableSearchableDropdownField].
class OverridableColorField extends StatelessWidget {
  const OverridableColorField({
    super.key,
    required this.label,
    required this.apiKey,
  });

  final String label;
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    final binding = settingsBindingOf(apiKey);
    final host = context.watch<SettingsDraftHost>();
    final value = binding.read(host.settings) ?? '';

    final field = ColorField(
      initial: value,
      onChanged: (v) =>
          host.updateSettings((s) => binding.write(s, v.isEmpty ? null : v)),
    );

    return OverridableField.bind(
      apiKey: apiKey,
      label: label,
      cascadedValueOnEnable: () => value.isEmpty ? null : value,
      child: field,
    );
  }
}
