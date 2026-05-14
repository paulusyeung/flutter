import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';

/// Dropdown counterpart to `OverridableTextField`. Renders a
/// [DropdownButtonFormField] bound to a single settings key and wraps it
/// in [OverridableField] at group/client level so the user can opt in to
/// overriding the cascaded value.
///
/// Use this on any settings page that exposes a dropdown bound to a
/// `String?` (or other `T?`) settings field — currency, language,
/// country, date format, etc. Reading + writing the field stays on the
/// caller via [value] / [onChanged] (the same shape settings dropdowns
/// already use), so freezed `copyWith` calls keep their types.
class OverridableDropdownField<T> extends StatelessWidget {
  const OverridableDropdownField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String apiKey;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    // Guard against value-not-in-items: DropdownButtonFormField throws if
    // `value` isn't one of the item values. This happens transiently
    // before statics finish loading; show null until items are ready.
    final effective = items.any((i) => i.value == value) ? value : null;
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;
    final field = DropdownButtonFormField<T>(
      initialValue: effective,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: items,
      onChanged: onChanged,
    );
    return OverridableField.bind(
      apiKey: apiKey,
      label: label,
      // Seed the override with the currently displayed value (the cascaded
      // company default) so the dropdown stays on the same option when the
      // user toggles the checkbox on.
      cascadedValueOnEnable: () => value?.toString(),
      child: field,
    );
  }
}
