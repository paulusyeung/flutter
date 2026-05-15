import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';

/// One named markdown section (terms / footer / public notes / private
/// notes). The host (typically the Invoice edit screen's Notes tab)
/// composes any subset of these.
///
/// Each section can optionally surface a "Save as default" button that
/// hands the current value back to the host, which is expected to persist
/// it on the company's settings cascade. Hide via `onSaveAsDefault: null`.
class MarkdownNotesField extends StatelessWidget {
  const MarkdownNotesField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onSaveAsDefault,
    this.externalValueKey,
    this.height = 180,
  });

  /// Localized label shown above the editor.
  final String label;

  /// Current markdown content. Empty string for no value.
  final String value;

  /// Fired on debounced edit. The host writes this back into its draft.
  final ValueChanged<String> onChanged;

  /// Optional. When provided, a "Save as default" button surfaces beside
  /// the label and fires this callback with the current [value] (i.e.
  /// the host should persist it to `company.settings.<key>`).
  final VoidCallback? onSaveAsDefault;

  /// Bump to force a reseed (e.g. after the host loaded a draft from
  /// the server and the editor is already mounted).
  final Object? externalValueKey;

  /// Editor body height.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.inTheme.ink,
                  ),
                ),
              ),
              if (onSaveAsDefault != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(64, 32)),
                  onPressed: onSaveAsDefault,
                  child: Text(context.tr('save_as_default')),
                ),
            ],
          ),
        ),
        MarkdownTextField(
          initialValue: value,
          onChanged: onChanged,
          label: label,
          height: height,
          externalValueKey: externalValueKey,
        ),
      ],
    );
  }
}
