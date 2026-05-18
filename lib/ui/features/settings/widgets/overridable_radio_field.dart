import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';

/// Radio-group counterpart to [OverridableDropdownField]. Use for any
/// two-choice (occasionally up to ~4) settings field bound to a single key —
/// a radio group keeps both options visible instead of hiding one behind a
/// dropdown tap. Reading + writing stays on the caller via [value] /
/// [onChanged], same shape as [OverridableDropdownField], so freezed
/// `copyWith` calls keep their types.
///
/// `RadioGroup` is safe here: the field renders inside the scrollable
/// `SettingsFormShell`, not a `showModalBottomSheet`. The mid-frame-mutation
/// crash that makes `entity_sort_filter_sheet.dart` /
/// `tax_category_dialog.dart` hand-roll a plain selectable list only bites
/// inside modal sheets whose size-listening layout re-enters.
class OverridableRadioField<T> extends StatelessWidget {
  const OverridableRadioField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String apiKey;
  final T? value;
  final List<({T value, String label})> options;

  /// `null` disables the group (mirrors the `OverridableDropdownField`
  /// contract — greys out the field and ignores taps).
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IgnorePointer(
          // `RadioGroup.onChanged` is non-nullable; mirror the
          // `OverridableDropdownField` "null disables" contract by ignoring
          // taps and dimming instead.
          ignoring: onChanged == null,
          child: Opacity(
            opacity: onChanged == null ? 0.5 : 1.0,
            child: RadioGroup<T>(
              groupValue: value,
              onChanged: onChanged ?? (_) {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in options)
                    Flexible(
                      child: RadioListTile<T>(
                        value: o.value,
                        title: Text(o.label),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          // Standalone error rendering: `RadioListTile` carries no
          // `InputDecoration` slot. Styling matches the Material default
          // `InputDecoration.errorText` (12pt, colorScheme.error), same as
          // `OverridableSwitchField`.
          Padding(
            padding: EdgeInsets.only(
              left: InSpacing.md(context),
              top: InSpacing.xs,
            ),
            child: Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );

    return OverridableField.bind(
      apiKey: apiKey,
      label: label,
      // Seed the override with the currently displayed value so the radio
      // stays on the same option when the user toggles the checkbox on.
      cascadedValueOnEnable: () => value?.toString(),
      child: field,
    );
  }
}
