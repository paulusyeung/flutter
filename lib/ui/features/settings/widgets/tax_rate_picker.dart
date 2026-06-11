import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/domain/tax_rate.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/utils/formatting.dart';

/// One default-tax-rate row on Settings → Tax Settings. Picks a [TaxRate]
/// from the bundled list (`services.taxRates`) and writes BOTH the name and
/// the percentage to `tax_name<slot>` / `tax_rate<slot>` atomically — the
/// settings fields store the pair denormalized, so picking a rate updates
/// the two settings keys together.
///
/// Strict-pick: there's no free-text creation. Legacy admin-portal's
/// `TaxRateDropdown` and React's `<Selector>` both render a non-editable
/// dropdown; the entity-create path lives on the Tax Rates settings page
/// (out of scope here).
///
/// Override semantics match the rest of the cascade-aware form: at client /
/// group scope the row wraps in [OverridableField.bindInline] with a paired
/// binding (see [overrideBinding]). The override is keyed off
/// `tax_name<slot>`, but because name and rate are denormalized as a pair,
/// toggling the override off clears BOTH `tax_name<slot>` and
/// `tax_rate<slot>` (so no stale rate is left dangling at client/group
/// scope), and toggling it on seeds both from the inherited company default.
class TaxRatePicker extends StatelessWidget {
  const TaxRatePicker({super.key, required this.slot, required this.label});

  /// Tax slot (1-3) — selects which `tax_name<N>`/`tax_rate<N>` settings
  /// pair this picker drives.
  final int slot;

  /// Rendered row label, e.g. "Default Tax Rate 1".
  final String label;

  String get _nameKey => 'tax_name$slot';

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final host = context.watch<SettingsDraftHost>();
    // Read company-level context (id, decimal separator) via `companyContext`
    // so the picker works at client scope, where `host.draft` is null.
    final ctx = host.companyContext;
    final useComma = ctx?.useCommaAsDecimalPlace ?? false;

    final currentName = _readName(host.settings, slot);
    final currentRate = _readRate(host.settings, slot);

    return StreamBuilder<List<TaxRate>>(
      stream: services.taxRates.watchAll(companyId: ctx?.id ?? ''),
      builder: (context, snap) {
        final rates = snap.data ?? const <TaxRate>[];
        if (rates.isEmpty) {
          return _EmptyRatesRow(label: label, slot: slot);
        }

        final sorted = [...rates]..sort((a, b) => a.name.compareTo(b.name));

        // Match the current name+rate pair against the bundled list.
        TaxRate? selected;
        for (final r in sorted) {
          if (r.name == currentName && (r.rate - currentRate).abs() < 0.0001) {
            selected = r;
            break;
          }
        }
        // If the settings carry a value not in the bundled list (a legacy
        // hand-entered rate), pass a synthetic [TaxRate] as `initialValue`
        // so the user still sees what's stored. The synthetic is NOT added
        // to `items`, so it disappears from the dropdown once the user picks
        // a real bundled rate. `SearchableDropdownField` tolerates an
        // `initialValue` not present in `items`.
        if (selected == null && (currentName?.isNotEmpty ?? false)) {
          selected = TaxRate(
            id: '__current__',
            name: currentName!,
            rate: currentRate,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            archivedAt: null,
            isDeleted: false,
          );
        }

        final errors = host.fieldErrors[_nameKey];
        final errorText = (errors != null && errors.isNotEmpty)
            ? errors.first
            : null;

        final field = SearchableDropdownField<TaxRate>(
          label: label,
          items: sorted,
          initialValue: selected,
          displayString: (r) =>
              '${r.name} (${rateInputText(r.rate, useCommaAsDecimalPlace: useComma, blankZero: false)}%)',
          idOf: (r) => '${r.name}|${r.rate}',
          onChanged: (r) {
            // Clear sentinel by scope (see SettingsDraftHost.isCascadeScope):
            // company scope writes '' / 0 — the server's own cleared state —
            // so the clear survives the rawSettings PUT merge (a typed null
            // is omitted by toJson and resurrects from the raw snapshot);
            // cascade scope writes null/null so the override pair is removed
            // rather than left as a phantom 0%-tax override.
            final cascade = host.isCascadeScope;
            host.updateSettings(
              (s) => _writePair(
                s,
                slot,
                name: r?.name ?? (cascade ? null : ''),
                rate: r?.rate ?? (cascade ? null : 0),
              ),
            );
          },
          errorText: errorText,
        );

        return OverridableField.bindInline(
          apiKey: _nameKey,
          label: label,
          // Paired binding: the checkbox is keyed on `tax_name<slot>`, but
          // name and rate move together, so toggling the override OFF must
          // clear BOTH keys — a plain `tax_name` binding would null the name
          // and leave `tax_rate<slot>` overriding on its own. Seed the rate
          // from the value displayed at build time.
          binding: overrideBinding(slot, currentRate),
          cascadedValueOnEnable: () => currentName,
          child: field,
        );
      },
    );
  }

  static String? _readName(CompanySettings s, int slot) {
    switch (slot) {
      case 1:
        return s.taxName1;
      case 2:
        return s.taxName2;
      case 3:
        return s.taxName3;
    }
    return null;
  }

  static double _readRate(CompanySettings s, int slot) {
    switch (slot) {
      case 1:
        return s.taxRate1 ?? 0;
      case 2:
        return s.taxRate2 ?? 0;
      case 3:
        return s.taxRate3 ?? 0;
    }
    return 0;
  }

  static CompanySettings _writePair(
    CompanySettings s,
    int slot, {
    required String? name,
    required double? rate,
  }) {
    switch (slot) {
      case 1:
        return s.copyWith(taxName1: name, taxRate1: rate);
      case 2:
        return s.copyWith(taxName2: name, taxRate2: rate);
      case 3:
        return s.copyWith(taxName3: name, taxRate3: rate);
    }
    return s;
  }

  /// Override binding for the name/rate *pair*, consumed by
  /// [OverridableField.bindInline]. The single `tax_name<slot>` checkbox
  /// drives both keys: clearing the override (`value == null`) nulls the name
  /// AND the rate; enabling it seeds both from the inherited default
  /// ([seedRate] is the cascaded rate captured at build time). Without this,
  /// the generic 1:1 `tax_name<slot>` binding would leave `tax_rate<slot>`
  /// overriding on its own at client/group scope.
  @visibleForTesting
  static SettingsBinding overrideBinding(int slot, double seedRate) => (
    read: (s) => _readName(s, slot),
    write: (s, v) => v == null
        ? _writePair(s, slot, name: null, rate: null)
        : _writePair(s, slot, name: v, rate: seedRate),
  );
}

/// Inline empty-state shown above the picker when no tax rates exist for
/// the active company. Disabled placeholder text-field plus a hint line so
/// the page still scans as a form row (rather than a missing widget).
class _EmptyRatesRow extends StatelessWidget {
  const _EmptyRatesRow({required this.label, required this.slot});

  final String label;

  /// Tax slot (1-3). Drives the slot-specific `tax_name<N>` override key so
  /// the right cascade override is toggled when there's more than one picker
  /// on the screen, and the paired-clear binding nulls the matching rate.
  final int slot;

  String get _nameKey => 'tax_name$slot';

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<SettingsLevelController>();
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: context.tr('no_tax_rates_yet'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: InSpacing.xs),
          child: Text(
            context.tr('no_tax_rates_yet_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );

    if (scope.isCompany) return body;

    // At client/group scope: keep the override checkbox visible so the user
    // still understands the field exists even though it has nothing to pick.
    // Same paired binding as the populated picker so an inherited legacy
    // name/rate pair clears together if the override is toggled off.
    return OverridableField.bindInline(
      apiKey: _nameKey,
      label: label,
      binding: TaxRatePicker.overrideBinding(slot, 0),
      cascadedValueOnEnable: () => null,
      child: body,
    );
  }
}
