import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';
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
    this.debounce,
  });

  final String label;
  final String apiKey;
  final SettingsRead? read;
  final SettingsWrite? write;
  final bool enabled;

  /// Override [MarkdownTextField]'s default 300 ms quiet period before edits
  /// are flushed. Templates & Reminders tightens this to ~150 ms so the
  /// downstream preview debounce (~400 ms) doesn't compound into a sluggish
  /// keystroke-to-preview path.
  final Duration? debounce;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final binding = settingsBindingOf(apiKey);
    final readFn = read ?? binding.read;
    final writeFn = write ?? binding.write;
    final value = readFn(host.settings) ?? '';
    final overridden = host.isOverridden(apiKey);
    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    // Always pass `enabled: enabled` straight through. At group/client level
    // when the override is off, OverridableField owns the disabled visual
    // (IgnorePointer + Opacity 0.65); doubling that up with the editor's own
    // disabled overlay would compound to ~0.36 alpha and crush legibility.
    final editor = MarkdownTextField(
      label: label,
      initialValue: value,
      enabled: enabled,
      externalValueKey: Object.hash(apiKey, value, overridden),
      debounce: debounce ?? const Duration(milliseconds: 300),
      onChanged: (v) {
        // See OverridableTextField: at cascade scope an empty edit removes the
        // override (null) instead of persisting '', which the server treats as
        // inherit and would silently diverge from the rendered PDF/email (L12).
        final value = host.isCascadeScope && v.isEmpty ? null : v;
        host.updateSettings((s) => writeFn(s, value));
      },
    );

    final field = errorText == null
        ? editor
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              editor,
              Padding(
                padding: const EdgeInsets.only(top: InSpacing.xs, left: 2),
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
      cascadedValueOnEnable: () => readFn(host.settings) ?? '',
      child: field,
    );
  }
}
