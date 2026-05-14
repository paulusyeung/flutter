import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Chip-style multi-select bound to a comma-joined string — matches
/// Invoice Ninja's storage convention for fields like
/// `enabled_modules` and `notifications.email`. Empty string means "no
/// value" / "inherit from parent."
class OverridableMultiSelectField extends StatelessWidget {
  const OverridableMultiSelectField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.options,
    this.read,
    this.write,
    this.enabled = true,
  });

  final String label;
  final String apiKey;

  /// Available chips: `(value, label)`. The stored wire value is the set
  /// of selected `value`s joined with commas in the option's declaration
  /// order.
  final List<({String value, String label})> options;
  final SettingsRead? read;
  final SettingsWrite? write;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final binding = settingsBindingOf(apiKey);
    final readFn = read ?? binding.read;
    final writeFn = write ?? binding.write;

    final host = context.watch<SettingsDraftHost>();
    final raw = readFn(host.settings) ?? '';
    final selected = raw.isEmpty
        ? const <String>{}
        : raw.split(',').map((s) => s.trim()).toSet();
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    final chips = <Widget>[
      for (final option in options)
        FilterChip(
          label: Text(option.label),
          selected: selected.contains(option.value),
          onSelected: !enabled
              ? null
              : (on) {
                  final next = {...selected};
                  if (on) {
                    next.add(option.value);
                  } else {
                    next.remove(option.value);
                  }
                  // Preserve the option-declaration order in the joined
                  // wire string so the diff is stable across re-renders.
                  final ordered = [
                    for (final o in options)
                      if (next.contains(o.value)) o.value,
                  ];
                  host.updateSettings((s) => writeFn(s, ordered.join(',')));
                },
        ),
    ];

    final field = InputDecorator(
      decoration: InputDecoration(labelText: label, errorText: errorText),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
        child: Wrap(
          spacing: InSpacing.sm,
          runSpacing: InSpacing.xs,
          children: chips,
        ),
      ),
    );
    return OverridableField.bind(
      apiKey: apiKey,
      label: label,
      cascadedValueOnEnable: () => readFn(host.settings) ?? '',
      child: field,
    );
  }
}
