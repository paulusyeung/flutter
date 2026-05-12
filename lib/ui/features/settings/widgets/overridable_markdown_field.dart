import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/widgets/markdown_text_field.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Markdown-editing counterpart to `OverridableTextField`. Same `apiKey`
/// contract — drop-in replacement for any settings text field that should
/// accept markdown (currently the invoice/quote/credit/purchase-order terms
/// & footer fields on the Defaults tab).
///
/// SuperEditor has no `TextEditingController`-style two-way binding, so this
/// widget detects external value changes (override-toggle resets the cascaded
/// value) by passing an `externalValueKey` derived from `(apiKey, value,
/// isOverridden)` down to [MarkdownTextField]. When that key changes and the
/// VM value differs from the editor's last-emitted markdown, the editor
/// reseeds its document.
class OverridableMarkdownField extends StatelessWidget {
  const OverridableMarkdownField({
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
    final host = context.watch<SettingsDraftHost>();
    final level = context.watch<SettingsLevelController>().level;
    final binding = settingsBindingOf(apiKey);
    final readFn = read ?? binding.read;
    final writeFn = write ?? binding.write;
    final value = readFn(host.settings) ?? '';
    final overridden = host.isOverridden(apiKey);

    // Always pass `enabled: enabled` straight through. At group/client level
    // when the override is off, OverridableField owns the disabled visual
    // (IgnorePointer + Opacity 0.65); doubling that up with the editor's own
    // disabled overlay would compound to ~0.36 alpha and crush legibility.
    final field = MarkdownTextField(
      label: label,
      initialValue: value,
      enabled: enabled,
      externalValueKey: Object.hash(apiKey, value, overridden),
      onChanged: (v) => host.updateSettings((s) => writeFn(s, v)),
    );

    if (level == SettingsLevel.company) return field;
    return OverridableField(
      label: label,
      isOverridden: overridden,
      onOverrideToggle: (on) => host.setOverride(
        apiKey: apiKey,
        enabled: on,
        cascadedValue: on ? value : null,
      ),
      child: field,
    );
  }
}
