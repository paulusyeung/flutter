import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/data/models/value/date.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/utils/formatting.dart';

/// Date-only counterpart of [OverridableTextField]. The settings cascade
/// stores the value as an ISO `"YYYY-MM-DD"` string (matches the
/// server's `date_format` wire shape and the [Date] type's `toIso()`).
/// Empty string means "no value" / "inherit from parent."
///
/// The display uses [Formatter.date] so the user sees their company's
/// configured format; the stored value stays ISO so the cascade stays
/// portable across company date-format choices.
class OverridableDateField extends StatelessWidget {
  const OverridableDateField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.formatter,
    this.read,
    this.write,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final String apiKey;

  /// User's company-scoped [Formatter] — used for the display string.
  /// Storage stays ISO regardless. Pass `services.formatterFor(companyId)`.
  final Formatter formatter;
  final SettingsRead? read;
  final SettingsWrite? write;
  final bool enabled;

  /// `showDatePicker` bounds. Default to 1900-2100 — matches `flutter`'s
  /// default scaffold.
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final binding = settingsBindingOf(apiKey);
    final readFn = read ?? binding.read;
    final writeFn = write ?? binding.write;

    final host = context.watch<SettingsDraftHost>();
    final raw = readFn(host.settings) ?? '';
    final parsed = Date.tryParse(raw);
    final display = parsed == null ? '' : formatter.date(parsed.toIso());
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    final field = InkWell(
      onTap: !enabled
          ? null
          : () async {
              final initial = parsed?.toDateTime() ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: firstDate ?? DateTime(1900),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked == null) return;
              final iso = Date(picked.year, picked.month, picked.day).toIso();
              host.updateSettings((s) => writeFn(s, iso));
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(display.isEmpty ? ' ' : display),
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
