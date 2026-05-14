import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Standard "labeled text field bound to one settings key" used across the
/// Company Details tabs. Handles the [OverridableField] wrapper at
/// group/client level transparently.
///
/// `apiKey` is the snake_case server field name. By default the field looks
/// up its `read`/`write` projection from [settingsBindingOf]; pass explicit
/// closures only when binding to something outside `vm.settings` that still
/// has the same `String?` shape (rare — most non-settings fields are wired
/// directly on the views).
class OverridableTextField extends StatefulWidget {
  const OverridableTextField({
    super.key,
    required this.label,
    required this.apiKey,
    this.read,
    this.write,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String apiKey;
  final SettingsRead? read;
  final SettingsWrite? write;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<OverridableTextField> createState() => _OverridableTextFieldState();
}

class _OverridableTextFieldState extends State<OverridableTextField> {
  late final TextEditingController _controller;
  late final SettingsRead _read;
  late final SettingsWrite _write;

  @override
  void initState() {
    super.initState();
    final binding = settingsBindingOf(widget.apiKey);
    _read = widget.read ?? binding.read;
    _write = widget.write ?? binding.write;
    final host = context.read<SettingsDraftHost>();
    _controller = TextEditingController(text: _read(host.settings) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `watch` so this widget rebuilds when the host mutates the field
    // externally (override-checkbox toggle, programmatic resets). Without it
    // the disabled state and inherited-placeholder text never update.
    final host = context.watch<SettingsDraftHost>();

    // Keep the controller in sync with host-side mutations. If the controller
    // text already matches the host (user just typed), this is a no-op; if
    // the host was updated by something else (override toggle), this pulls
    // the new value in and parks the cursor at the end.
    final hostValue = _read(host.settings) ?? '';
    if (_controller.text != hostValue) {
      _controller.value = TextEditingValue(
        text: hostValue,
        selection: TextSelection.collapsed(offset: hostValue.length),
      );
    }

    // Enter on a single-line field submits the surrounding form via
    // FormSaveScope. Multi-line fields keep Enter for newlines.
    final isSingleLine = widget.maxLines == 1;
    final scope = isSingleLine ? FormSaveScope.maybeOf(context) : null;
    final errors = host.fieldErrors[widget.apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;
    final field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textInputAction: isSingleLine
          ? TextInputAction.done
          : TextInputAction.newline,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: errorText,
      ),
      onChanged: (v) => host.updateSettings((s) => _write(s, v)),
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
    return OverridableField.bind(
      apiKey: widget.apiKey,
      label: widget.label,
      cascadedValueOnEnable: () => _read(host.settings) ?? '',
      child: field,
    );
  }
}
