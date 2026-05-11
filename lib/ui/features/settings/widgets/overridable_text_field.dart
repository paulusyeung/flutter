import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';

/// Standard "labeled text field bound to one settings key" used across the
/// Company Details tabs. Handles the [OverridableField] wrapper at
/// group/client level transparently.
///
/// `apiKey` is the snake_case server field name. `read` and `write` project
/// the typed settings into a `String?` and back via freezed `copyWith` —
/// every call site is a single line because of how trivial these projections
/// are; bundling them into a closure keeps the field widget agnostic of
/// which key it's editing.
class OverridableTextField extends StatefulWidget {
  const OverridableTextField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.read,
    required this.write,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String apiKey;
  final String? Function(CompanyDetailsViewModel) read;
  final void Function(CompanyDetailsViewModel, String) write;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<OverridableTextField> createState() => _OverridableTextFieldState();
}

class _OverridableTextFieldState extends State<OverridableTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CompanyDetailsViewModel>();
    _controller = TextEditingController(text: widget.read(vm) ?? '');
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
    final vmValue = widget.read(vm) ?? '';
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
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => widget.write(vm, v),
    );
    if (level == SettingsLevel.company) return field;
    return OverridableField(
      label: widget.label,
      isOverridden: vm.isOverridden(widget.apiKey),
      onOverrideToggle: (on) => vm.setOverride(
        apiKey: widget.apiKey,
        enabled: on,
        cascadedValue: on ? (widget.read(vm) ?? '') : null,
      ),
      child: field,
    );
  }
}
