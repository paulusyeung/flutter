import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';

/// Single-line text input for settings-CRUD edit screens
/// (payment_terms, task_statuses, group_settings, …). Replaces the
/// hand-rolled `_NameField` / `_NumDaysField` `StatefulWidget`s that used
/// to appear identical in every screen.
///
/// Solves the long-standing resync gap: the underlying
/// `TextEditingController` reseeds whenever [externalSyncKey] changes, so
/// an external draft mutation (e.g. the unsaved-changes-guard's Discard
/// path or a deferred-load arrival) repopulates the field instead of
/// silently keeping the stale typed value. Same trick as
/// `OverridableTextField` + `MarkdownTextField`'s `externalValueKey`.
///
/// Pressing Enter submits the surrounding [FormSaveScope] when present
/// — per CLAUDE.md § Forms § Enter to save.
class SettingsTextField extends StatefulWidget {
  const SettingsTextField({
    super.key,
    required this.initialValue,
    required this.labelKey,
    required this.onChanged,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textInputAction = TextInputAction.done,
    this.externalSyncKey,
  });

  final String initialValue;

  /// Localization key for the field's floating label.
  final String labelKey;

  final ValueChanged<String> onChanged;
  final String? errorText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;

  /// When this value changes between rebuilds, the internal controller
  /// reseeds from [initialValue]. Pass the loaded entity's id (or
  /// `vm.original?.id`) so reopening a different row repopulates the
  /// field — null on create routes is also fine (single-create lifetime
  /// never triggers reseed).
  final Object? externalSyncKey;

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void didUpdateWidget(covariant SettingsTextField old) {
    super.didUpdateWidget(old);
    // Reseed when the caller signals a fresh draft. Compare `initialValue`
    // too so a same-key but materially different reset still flushes.
    if (old.externalSyncKey != widget.externalSyncKey &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = FormSaveScope.maybeOf(context);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: context.tr(widget.labelKey),
        errorText: widget.errorText,
      ),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }
}
