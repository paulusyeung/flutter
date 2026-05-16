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
class MarkdownNotesField extends StatefulWidget {
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

  /// Optional. When provided, a "Save as default" button surfaces
  /// beside the label. On tap the editor is flushed synchronously
  /// (bypassing the debounce) and this callback fires with the
  /// *current* serialized markdown — the host persists it to
  /// `company.settings.<key>`. Receiving the value as a parameter
  /// (rather than reading the parent draft) removes the debounce race.
  final ValueChanged<String>? onSaveAsDefault;

  /// Bump to force a reseed (e.g. after the host loaded a draft from
  /// the server and the editor is already mounted).
  final Object? externalValueKey;

  /// Editor body height.
  final double height;

  @override
  State<MarkdownNotesField> createState() => _MarkdownNotesFieldState();
}

class _MarkdownNotesFieldState extends State<MarkdownNotesField> {
  final _controller = MarkdownFieldController();

  void _handleSaveAsDefault() {
    // Flush the editor so the just-typed value is captured even if the
    // 300 ms debounce hasn't fired yet; fall back to the parent's known
    // value when there's nothing pending.
    //
    // Side effect (intentional): flushing emits through `onChanged`,
    // which writes the value into the host's draft and marks it dirty
    // immediately — the same end state the debounce would reach ~300 ms
    // later, just sooner. A "Save as default" tap therefore also
    // commits the field into the in-progress entity edit; that's the
    // desired no-lost-edit behavior, not a bug.
    final current = _controller.flush() ?? widget.value;
    widget.onSaveAsDefault!(current);
  }

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
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.inTheme.ink,
                  ),
                ),
              ),
              if (widget.onSaveAsDefault != null)
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(64, 32)),
                  onPressed: _handleSaveAsDefault,
                  child: Text(context.tr('save_as_default')),
                ),
            ],
          ),
        ),
        MarkdownTextField(
          initialValue: widget.value,
          onChanged: widget.onChanged,
          label: widget.label,
          height: widget.height,
          externalValueKey: widget.externalValueKey,
          controller: _controller,
        ),
      ],
    );
  }
}
