import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/data/static/built_in_designs_catalog.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Cascade-aware design picker for `company.settings.*_design_id` keys.
///
/// Items merge the bundled `Design` list (when wired) with the [kBuiltInDesigns]
/// catalog. For v1 only the built-ins are shown; the bundled entity stack is a
/// follow-up.
///
/// When [allowBlank] is true (used for the optional pickers — delivery_note,
/// statement, payment_receipt, payment_refund) the user can clear the field
/// to fall back to the server default; a trailing "Clear" icon button is added
/// next to the dropdown.
class OverridableDesignPicker extends StatelessWidget {
  const OverridableDesignPicker({
    super.key,
    required this.label,
    required this.apiKey,
    this.allowBlank = false,
  });

  final String label;
  final String apiKey;
  final bool allowBlank;

  @override
  Widget build(BuildContext context) {
    final binding = settingsBindingOf(apiKey);
    final host = context.watch<SettingsDraftHost>();
    final value = binding.read(host.settings);

    // For v1 use the static built-in catalog. When the Design entity bundle
    // wiring lands, merge `repo.watchAll(companyId)` into this list and dedupe
    // by id. The picker is otherwise unchanged.
    final items = <BuiltInDesign>[
      if (allowBlank)
        const (id: '', name: '—', isFree: true),
      ...kBuiltInDesigns,
    ];

    final field = OverridableSearchableDropdownField<BuiltInDesign>(
      label: label,
      apiKey: apiKey,
      value: value,
      items: items,
      displayString: (d) => d.name,
      idOf: (d) => d.id,
      onChanged: (id) => host.updateSettings(
        (s) => binding.write(s, (id == null || id.isEmpty) ? null : id),
      ),
    );

    // OverridableSearchableDropdownField already wraps in `OverridableField.bind`.
    return field;
  }
}

/// Convenience wrapper if the caller wants the picker without the auto-
/// wrapping (rare). The straight-through `OverridableDesignPicker` covers
/// every callsite today; this exists so the lint-checker future-proofs the
/// API.
@visibleForTesting
Widget rawDesignPicker({
  required String apiKey,
  required String label,
  required SettingsDraftHost host,
  bool allowBlank = false,
}) {
  final binding = settingsBindingOf(apiKey);
  final value = binding.read(host.settings);
  final items = <BuiltInDesign>[
    if (allowBlank) const (id: '', name: '—', isFree: true),
    ...kBuiltInDesigns,
  ];
  return OverridableField.bind(
    apiKey: apiKey,
    label: label,
    cascadedValueOnEnable: () => value,
    child: OverridableSearchableDropdownField<BuiltInDesign>(
      label: label,
      apiKey: apiKey,
      value: value,
      items: items,
      displayString: (d) => d.name,
      idOf: (d) => d.id,
      onChanged: (id) =>
          host.updateSettings((s) => binding.write(s, id?.isEmpty ?? true ? null : id)),
    ),
  );
}
