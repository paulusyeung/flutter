import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_number_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// PHP date-format reference linked from the entity tabs. The variable
/// `{\$date:<format>}` uses PHP's `date()` syntax server-side.
const _kPhpDateFormatsUrl = 'https://www.php.net/manual/en/datetime.format.php';

/// Body reused for every per-entity tab on the Generated Numbers settings
/// page. Renders one [FormSection] with:
///   1. Pattern text field bound to `<entity>_number_pattern`.
///   2. Counter integer field bound to `<entity>_number_counter`.
///   3. A row of clickable variable chips that splice the corresponding
///      `{$token}` into the pattern field at the current caret position.
///   4. A "View date formats" link to PHP's `date()` reference.
///
/// The exact chip set depends on the entity:
///   * Always: counter, year, date:Y-m-d, user_id, user_custom1-4.
///   * [showClientTokens]: client_counter, group_counter, client_number,
///     client_id_number, client_custom1-4.
///   * [showVendorTokens]: vendor_number, vendor_id_number,
///     vendor_custom1-4.
///
/// Mounted by `GeneratedNumbersShell` inside a `CascadeTabbedSettingsShell`,
/// so `SettingsDraftHost` is already supplied via Provider.
class GeneratedNumbersEntityBody extends StatelessWidget {
  const GeneratedNumbersEntityBody({
    super.key,
    required this.patternKey,
    required this.counterKey,
    required this.titleKey,
    required this.showClientTokens,
    required this.showVendorTokens,
  });

  /// `apiKey` for the pattern field (e.g. `'invoice_number_pattern'`).
  final String patternKey;

  /// `apiKey` for the counter field (e.g. `'invoice_number_counter'`).
  final String counterKey;

  /// Localization key for the section title (matches the tab label, e.g.
  /// `'invoices'`).
  final String titleKey;

  /// Show the client / group token chips. Set on tabs whose entity carries a
  /// client reference (invoices, quotes, credits, payments, recurring
  /// invoices, projects).
  final bool showClientTokens;

  /// Show the vendor token chips. Set on tabs whose entity carries a vendor
  /// reference (expenses, recurring expenses, purchase orders).
  final bool showVendorTokens;

  @override
  Widget build(BuildContext context) {
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr(titleKey),
          children: [
            _PatternField(apiKey: patternKey),
            OverridableNumberField(
              label: context.tr('number_counter'),
              apiKey: counterKey,
              integerOnly: true,
            ),
            _VariableChips(
              patternKey: patternKey,
              showClientTokens: showClientTokens,
              showVendorTokens: showVendorTokens,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: LinkText(
                label: context.tr('view_date_formats'),
                color: context.inTheme.accent,
                onTap: () =>
                    unawaited(launchUrl(Uri.parse(_kPhpDateFormatsUrl))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pattern field for the Generated Numbers entity tabs. Mirrors
/// [OverridableTextField] but exposes its [TextEditingController] via the
/// `_PatternControllerScope` inherited widget so the sibling variable
/// chips can splice tokens at the caret without reaching across widgets.
class _PatternField extends StatefulWidget {
  const _PatternField({required this.apiKey});

  final String apiKey;

  @override
  State<_PatternField> createState() => _PatternFieldState();
}

class _PatternFieldState extends State<_PatternField> {
  late final TextEditingController _controller;
  late final SettingsBinding _binding;

  @override
  void initState() {
    super.initState();
    _binding = settingsBindingOf(widget.apiKey);
    final host = context.read<SettingsDraftHost>();
    _controller = TextEditingController(
      text: _binding.read(host.settings) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final hostValue = _binding.read(host.settings) ?? '';
    // Pull host-side changes (override toggle, programmatic reset) into the
    // controller — but skip when the user is actively typing (controller +
    // host already in sync). Same idea as OverridableTextField.
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
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: context.tr('number_pattern'),
        errorText: errorText,
      ),
      onChanged: (v) =>
          host.updateSettings((s) => _binding.write(s, v.isEmpty ? null : v)),
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
    return _PatternControllerScope(
      controller: _controller,
      onTokenSpliced: (newValue) => host.updateSettings(
        (s) => _binding.write(s, newValue.isEmpty ? null : newValue),
      ),
      child: OverridableField.bind(
        apiKey: widget.apiKey,
        label: context.tr('number_pattern'),
        cascadedValueOnEnable: () => _binding.read(host.settings) ?? '',
        child: field,
      ),
    );
  }
}

/// Inherited bridge between [_PatternField] and the sibling
/// [_VariableChips]. Chips pull the live `TextEditingController` off this
/// scope to splice tokens at the current selection without reaching for
/// `GlobalKey`s.
class _PatternControllerScope extends InheritedWidget {
  const _PatternControllerScope({
    required this.controller,
    required this.onTokenSpliced,
    required super.child,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTokenSpliced;

  static _PatternControllerScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PatternControllerScope>();
  }

  @override
  bool updateShouldNotify(_PatternControllerScope oldWidget) =>
      !identical(controller, oldWidget.controller) ||
      !identical(onTokenSpliced, oldWidget.onTokenSpliced);
}

/// Wrap of clickable chips that splice variable tokens into the pattern
/// field at the current caret position. Resolves the controller via
/// [_PatternControllerScope]; if the scope is missing (would only happen
/// in tests rendering this widget standalone) the chip taps no-op.
class _VariableChips extends StatelessWidget {
  const _VariableChips({
    required this.patternKey,
    required this.showClientTokens,
    required this.showVendorTokens,
  });

  final String patternKey;
  final bool showClientTokens;
  final bool showVendorTokens;

  @override
  Widget build(BuildContext context) {
    final tokens = <_TokenSpec>[
      const _TokenSpec(token: 'counter', labelKey: 'counter'),
      if (showClientTokens) ...const [
        _TokenSpec(token: 'client_counter', labelKey: 'client_counter'),
        _TokenSpec(token: 'group_counter', labelKey: 'group_counter'),
      ],
      const _TokenSpec(token: 'year', labelKey: 'year'),
      const _TokenSpec(token: 'date:Y-m-d', labelKey: 'date'),
      if (showClientTokens) ...const [
        _TokenSpec(token: 'client_number', labelKey: 'client_number'),
        _TokenSpec(token: 'client_id_number', labelKey: 'client_id_number'),
        _TokenSpec(token: 'client_custom1', labelKey: 'client_custom1'),
        _TokenSpec(token: 'client_custom2', labelKey: 'client_custom2'),
        _TokenSpec(token: 'client_custom3', labelKey: 'client_custom3'),
        _TokenSpec(token: 'client_custom4', labelKey: 'client_custom4'),
      ],
      if (showVendorTokens) ...const [
        _TokenSpec(token: 'vendor_number', labelKey: 'vendor_number'),
        _TokenSpec(token: 'vendor_id_number', labelKey: 'vendor_id_number'),
        _TokenSpec(token: 'vendor_custom1', labelKey: 'vendor_custom1'),
        _TokenSpec(token: 'vendor_custom2', labelKey: 'vendor_custom2'),
        _TokenSpec(token: 'vendor_custom3', labelKey: 'vendor_custom3'),
        _TokenSpec(token: 'vendor_custom4', labelKey: 'vendor_custom4'),
      ],
      const _TokenSpec(token: 'user_id', labelKey: 'user_id'),
      const _TokenSpec(token: 'user_custom1', labelKey: 'user_custom1'),
      const _TokenSpec(token: 'user_custom2', labelKey: 'user_custom2'),
      const _TokenSpec(token: 'user_custom3', labelKey: 'user_custom3'),
      const _TokenSpec(token: 'user_custom4', labelKey: 'user_custom4'),
    ];
    return Wrap(
      spacing: InSpacing.md(context),
      runSpacing: InSpacing.sm,
      children: [
        for (final spec in tokens)
          ActionChip(
            label: Text('\${${spec.token}}'),
            tooltip: context.tr(spec.labelKey),
            onPressed: () => _insertToken(context, spec.token),
          ),
      ],
    );
  }

  void _insertToken(BuildContext context, String token) {
    final scope = _PatternControllerScope.maybeOf(context);
    if (scope == null) return;
    final controller = scope.controller;
    final insertion = '{\$$token}';
    final selection = controller.selection;
    final text = controller.text;
    // If the field has never had focus / there's no valid selection, append
    // the token to the end. Otherwise splice at the caret (replacing the
    // selected range if any).
    final hasValidSelection = selection.start >= 0 && selection.end >= 0;
    final start = hasValidSelection ? selection.start : text.length;
    final end = hasValidSelection ? selection.end : text.length;
    final newText = text.replaceRange(start, end, insertion);
    final newOffset = start + insertion.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    scope.onTokenSpliced(newText);
  }
}

/// One row of the variable picker. `token` is the bare PHP token without the
/// `{$…}` braces (e.g. `'counter'`, `'date:Y-m-d'`); `labelKey` is the
/// translation key for the chip's tooltip.
class _TokenSpec {
  const _TokenSpec({required this.token, required this.labelKey});

  final String token;
  final String labelKey;
}
