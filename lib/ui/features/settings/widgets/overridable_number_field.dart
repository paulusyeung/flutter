import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/utils/formatting.dart';

/// Numeric counterpart of [OverridableTextField]. The settings cascade
/// stores everything as `String?`, so this widget round-trips
/// `parseDecimal` (per CLAUDE.md § Forms — "money is Decimal, never
/// double") and renders empty for zero (no leading `"0"` placeholder).
///
/// `integerOnly: true` switches the parser to `int.tryParse` and clamps
/// the keyboard to digits.
class OverridableNumberField extends StatefulWidget {
  const OverridableNumberField({
    super.key,
    required this.label,
    required this.apiKey,
    this.read,
    this.write,
    this.enabled = true,
    this.integerOnly = false,
  });

  final String label;
  final String apiKey;
  final SettingsRead? read;
  final SettingsWrite? write;
  final bool enabled;
  final bool integerOnly;

  @override
  State<OverridableNumberField> createState() => _OverridableNumberFieldState();
}

class _OverridableNumberFieldState extends State<OverridableNumberField> {
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
    _controller = TextEditingController(
      text: _displayFor(
        _read(host.settings),
        useComma: host.settings.useCommaAsDecimalPlace ?? false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Empty-for-zero, no scientific notation. Mirrors `Formatter.inputAmount`
  /// without taking a dependency on the currency map.
  String _displayFor(String? raw, {required bool useComma}) {
    if (raw == null || raw.isEmpty) return '';
    if (widget.integerOnly) {
      final n = int.tryParse(raw.trim());
      return n == null || n == 0 ? '' : n.toString();
    }
    final d = parseDecimal(raw, useCommaAsDecimalPlace: useComma);
    if (d == null || d == Decimal.zero) return '';
    return d.toString();
  }

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final useComma = host.settings.useCommaAsDecimalPlace ?? false;
    final hostValue = _displayFor(_read(host.settings), useComma: useComma);
    if (_controller.text != hostValue) {
      _controller.value = TextEditingValue(
        text: hostValue,
        selection: TextSelection.collapsed(offset: hostValue.length),
      );
    }

    final scope = FormSaveScope.maybeOf(context);
    final errors = host.fieldErrors[widget.apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;
    final field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.integerOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: widget.integerOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: errorText,
      ),
      onChanged: (v) {
        // Empty/unparseable input is stored as the empty string — matches
        // OverridableTextField's "absent override is empty string" wire
        // shape, so `setOverride(enabled: true)` writes a meaningful value
        // and `setOverride(enabled: false)` clears it. Decimal input is
        // canonicalized so the wire stays locale-agnostic (the server
        // expects `1.5`, never `1,5`).
        if (widget.integerOnly) {
          host.updateSettings((s) => _write(s, v));
        } else {
          final parsed = parseDecimal(v, useCommaAsDecimalPlace: useComma);
          host.updateSettings((s) => _write(s, parsed?.toString() ?? ''));
        }
      },
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
    return OverridableField.bind(
      apiKey: widget.apiKey,
      label: widget.label,
      cascadedValueOnEnable: () =>
          _displayFor(_read(host.settings), useComma: useComma),
      child: field,
    );
  }
}
