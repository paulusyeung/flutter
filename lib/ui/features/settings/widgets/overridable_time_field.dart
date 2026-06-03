import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/utils/formatting.dart';

/// Time-of-day counterpart of [OverridableTextField]. Stores `"HH:MM"`
/// in 24-hour wire form so the cascade is portable across the user's
/// 12/24-hour display preference. Display follows `TimePickerThemeData`.
/// Empty string means "no value" / "inherit from parent."
///
/// **Wire-shape note:** Invoice Ninja's current time-bearing settings
/// (e.g. `entity_send_time`) store an **integer hour**, not a string.
/// This widget targets keys with a `"HH:MM"` string shape — verify the
/// specific key before wiring. For integer-hour keys, use
/// [OverridableNumberField] with `integerOnly: true`.
class OverridableTimeField extends StatelessWidget {
  const OverridableTimeField({
    super.key,
    required this.label,
    required this.apiKey,
    this.read,
    this.write,
    this.enabled = true,
  });

  final String label;
  final String apiKey;
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
    final parsed = _parse(raw);
    // Display honors the company `military_time` setting (12h vs 24h) rather
    // than the device locale — matches the rest of the app. The stored wire
    // value below stays 24-hour regardless.
    final display = parsed == null
        ? ''
        : formatTimeOfDay(
            parsed.hour,
            parsed.minute,
            military: host.settings.militaryTime ?? false,
          );
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    final field = InkWell(
      onTap: !enabled
          ? null
          : () async {
              final initial = parsed ?? TimeOfDay.fromDateTime(DateTime.now());
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked == null) return;
              // Always 24-hour `HH:MM` wire form (portable across the user's
              // 12/24h display preference) — see the class doc.
              final wire =
                  '${picked.hour.toString().padLeft(2, '0')}:'
                  '${picked.minute.toString().padLeft(2, '0')}';
              host.updateSettings((s) => writeFn(s, wire));
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.access_time, size: 18),
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

  TimeOfDay? _parse(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}
