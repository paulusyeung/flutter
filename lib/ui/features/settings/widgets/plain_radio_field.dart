import 'package:flutter/material.dart';

/// Non-cascade sibling of `OverridableRadioField`
/// (`overridable_radio_field.dart`). A plain two-choice (occasionally up to
/// ~4) radio group for a top-level `company.*` field that is NOT part of the
/// settings cascade — keeps both options visible instead of hiding one behind
/// a dropdown tap, per the design system's "two-choice → radio" rule.
///
/// Reading + writing stays on the caller via [value] / [onChanged], the same
/// shape as `OverridableRadioField` minus the override checkbox and the
/// field-error slot. Used by Product Settings ("Convert to") and Expense
/// Settings ("Enter taxes"). For a cascade-bound settings key, use
/// `OverridableRadioField` instead.
class PlainRadioField<T> extends StatelessWidget {
  const PlainRadioField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        RadioGroup<T>(
          groupValue: value,
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final o in options)
                RadioListTile<T>(
                  value: o.value,
                  title: Text(o.label),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
