import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';

/// Standard "labeled text field bound to one settings key" used across the
/// Company Details tabs. Handles the [OverridableField] wrapper at
/// group/client level transparently.
///
/// `apiKey` is the snake_case server field name. By default the field looks
/// up its `read`/`write` projection from [settingsBindingOf]; pass explicit
/// closures only when binding to something outside `vm.settings` (e.g. a
/// dynamic switch over `customValue<n>`).
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
    final vm = context.read<CompanyDetailsViewModel>();
    _controller = TextEditingController(text: _read(vm) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `watch` so this widget rebuilds when the VM mutates the field
    // externally (override-checkbox toggle, programmatic resets). Without it
    // the disabled state and inherited-placeholder text never update.
    final vm = context.watch<CompanyDetailsViewModel>();
    final level = context.watch<SettingsLevelController>().level;

    // Keep the controller in sync with VM-side mutations. If the controller
    // text already matches the VM (user just typed), this is a no-op; if
    // the VM was updated by something else (override toggle), this pulls
    // the new value in and parks the cursor at the end.
    final vmValue = _read(vm) ?? '';
    if (_controller.text != vmValue) {
      _controller.value = TextEditingValue(
        text: vmValue,
        selection: TextSelection.collapsed(offset: vmValue.length),
      );
    }

    final field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (v) => _write(vm, v),
    );
    if (level == SettingsLevel.company) return field;
    return OverridableField(
      label: widget.label,
      isOverridden: vm.isOverridden(widget.apiKey),
      onOverrideToggle: (on) => vm.setOverride(
        apiKey: widget.apiKey,
        enabled: on,
        cascadedValue: on ? (_read(vm) ?? '') : null,
      ),
      child: field,
    );
  }
}
