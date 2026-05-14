import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';

/// Searchable counterpart to `OverridableDropdownField`. Use this on settings
/// pages whenever the bound list is long enough that scroll-hunting is
/// annoying (countries, currencies, languages, industries — anything past
/// ~20 options).
///
/// Same cascade-override semantics as `OverridableDropdownField`: the field
/// is bound to a single settings key (`apiKey`), surfaces 422 field errors
/// from the host, and at group/client level wraps in [OverridableField] so
/// the user can opt in to overriding the cascaded value.
///
/// Value type is `String?` (the settings-key id). `T` is the rich item
/// shape (Currency, Language, Country, …) — needed for `displayString` /
/// `idOf`. The widget translates between the two.
class OverridableSearchableDropdownField<T extends Object>
    extends StatelessWidget {
  const OverridableSearchableDropdownField({
    super.key,
    required this.label,
    required this.apiKey,
    required this.value,
    required this.items,
    required this.displayString,
    required this.idOf,
    required this.onChanged,
    this.emptyHintKey,
  });

  final String label;
  final String apiKey;

  /// Current selection as the settings-key id (or `null` when unset).
  final String? value;

  /// Pre-sorted list of selectable items.
  final List<T> items;

  /// Visible label for a given item.
  final String Function(T) displayString;

  /// Stable id for a given item (matched against [value]).
  final String Function(T) idOf;

  /// Fires with the new id (or `null` when cleared).
  final ValueChanged<String?> onChanged;

  /// Localization key for the placeholder while [items] is empty (statics
  /// still loading). Forwarded to [SearchableDropdownField.emptyHintKey].
  final String? emptyHintKey;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final level = context.watch<SettingsLevelController>().level;

    T? selected;
    for (final item in items) {
      if (idOf(item) == value) {
        selected = item;
        break;
      }
    }

    final errors = host.fieldErrors[apiKey];
    final errorText = (errors != null && errors.isNotEmpty)
        ? errors.first
        : null;

    final field = SearchableDropdownField<T>(
      label: label,
      items: items,
      initialValue: selected,
      displayString: displayString,
      idOf: idOf,
      onChanged: (item) => onChanged(item == null ? null : idOf(item)),
      emptyHintKey: emptyHintKey,
      errorText: errorText,
    );

    if (level == SettingsLevel.company) return field;
    return OverridableField(
      label: label,
      isOverridden: host.isOverridden(apiKey),
      onOverrideToggle: (on) => host.setOverride(
        apiKey: apiKey,
        enabled: on,
        // Seed the override with the currently displayed value (the
        // cascaded company default) so the picker stays on the same option
        // when the user toggles the checkbox on.
        cascadedValue: on ? value : null,
      ),
      child: field,
    );
  }
}
