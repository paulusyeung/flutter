import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_field_bindings.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Predefined Custom Labels — the React `defaultLabels` list. Each value is a
/// localization key (e.g. `'invoice'` → "Invoice"); selecting one from the
/// dropdown adds a new overridable row backed by `settings.translations[key]`.
/// Users can also add free-form keys (`Add Custom`) and country aliases
/// (`Add Country`, key prefix `country_<id>`).
const kCustomLabelKeys = <String>[
  'address1',
  'address2',
  'amount',
  'balance',
  'country',
  'credit',
  'credit_card',
  'date',
  'description',
  'details',
  'discount',
  'due_date',
  'email',
  'from',
  'hours',
  'id_number',
  'invoice',
  'item',
  'line_total',
  'paid_to_date',
  'partial_due',
  'payment_date',
  'phone',
  'po_number',
  'product',
  'products',
  'quantity',
  'quote',
  'rate',
  'service',
  'statement',
  'subtotal',
  'surcharge',
  'tax',
  'taxes',
  'terms',
  'to',
  'total',
  'unit_cost',
  'valid_until',
  'vat_number',
  'website',
];

/// Localization "Custom Labels" tab — field labels surfaced by the in-app
/// search. Just the section heading: the search-hit handler routes by section
/// and doesn't carry a tab slug, so per-key matches would land on the wrong
/// tab (Settings) instead of Custom Labels. If we later thread a `tabSlug`
/// through `SettingsSearchHit`, spread `kCustomLabelKeys` here too.
const kLocalizationCustomLabelsSearchKeys = <String>['custom_labels'];

const String _countryKeyPrefix = 'country_';

/// Custom Labels tab body. Lists the entity's `settings.translations` entries
/// as editable rows; the header row adds new entries via a dropdown of
/// predefined keys, an "Add Custom" dialog for free-form keys, and an
/// "Add Country" dialog that scopes the key under `country_<id>`.
///
/// Mounted by `LocalizationShell` inside `CascadeTabbedSettingsShell`; the
/// shell owns the cascade VM and provides it via Provider.
class LocalizationCustomLabelsBody extends StatelessWidget {
  const LocalizationCustomLabelsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final host = context.watch<SettingsDraftHost>();
    final translations = _readTranslations(host.settings);
    final existingKeys = translations.keys.toList()
      ..sort((a, b) {
        // Country rows sink below predefined / custom rows so the predefined
        // ones stay at the top.
        final aCountry = a.startsWith(_countryKeyPrefix);
        final bCountry = b.startsWith(_countryKeyPrefix);
        if (aCountry != bCountry) return aCountry ? 1 : -1;
        return a.compareTo(b);
      });

    final available = kCustomLabelKeys
        .where((k) => !translations.containsKey(k))
        .toList();

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('custom_labels'),
          children: [
            // Key ties the dropdown's internal state to the current
            // translations-count: after the user picks a label and we mutate
            // the map, the row remounts so the dropdown clears its visible
            // selection (which is no longer in `available`).
            _AddRow(
              key: ValueKey('add_row_${existingKeys.length}'),
              host: host,
              services: services,
              available: available,
            ),
            if (existingKeys.isEmpty)
              _EmptyState()
            else
              for (final key in existingKeys)
                _TranslationRow(
                  key: ValueKey('translation_$key'),
                  translationKey: key,
                  displayLabel: _resolveLabel(context, services, key),
                  onRemove: () => _removeLabel(host, key),
                ),
          ],
        ),
      ],
    );
  }

  static String _resolveLabel(
    BuildContext context,
    Services services,
    String key,
  ) {
    if (key.startsWith(_countryKeyPrefix)) {
      final id = key.substring(_countryKeyPrefix.length);
      final country = services.statics.country(id);
      return country?.name ?? key;
    }
    return context.tr(key);
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    super.key,
    required this.host,
    required this.services,
    required this.available,
  });

  final SettingsDraftHost host;
  final Services services;
  final List<String> available;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SearchableDropdownField<String>(
            label: context.tr('add_label'),
            items: available,
            initialValue: null,
            displayString: (k) => context.tr(k),
            idOf: (k) => k,
            onChanged: (k) {
              if (k == null) return;
              _addLabel(host, k);
            },
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => _openCustomDialog(context),
          icon: const Icon(Icons.add),
          label: Text(context.tr('add_custom')),
        ),
        SizedBox(width: InSpacing.md(context)),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => _openCountryDialog(context),
          icon: const Icon(Icons.public_outlined),
          label: Text(context.tr('add_country')),
        ),
      ],
    );
  }

  Future<void> _openCustomDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final key = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('add_custom')),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: dialogContext.tr('property_name'),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.tr('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(dialogContext.tr('add')),
            ),
          ],
        ),
      );
      if (key == null || key.isEmpty) return;
      _addLabel(host, key);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openCountryDialog(BuildContext context) async {
    final countries = services.statics.countries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final country = await showDialog<Country>(
      context: context,
      builder: (dialogContext) => _AddCountryDialog(countries: countries),
    );
    if (country == null) return;
    _addLabel(host, '$_countryKeyPrefix${country.id}');
  }
}

class _AddCountryDialog extends StatefulWidget {
  const _AddCountryDialog({required this.countries});

  final List<Country> countries;

  @override
  State<_AddCountryDialog> createState() => _AddCountryDialogState();
}

class _AddCountryDialogState extends State<_AddCountryDialog> {
  Country? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('add_country')),
      content: SizedBox(
        width: 360,
        child: SearchableDropdownField<Country>(
          label: context.tr('country'),
          items: widget.countries,
          initialValue: null,
          displayString: (c) => c.name,
          idOf: (c) => c.id,
          onChanged: (c) => setState(() => _selected = c),
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text(context.tr('add')),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.lg(context)),
      child: Center(
        child: Text(
          context.tr('no_custom_labels'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.inTheme.ink3),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TranslationRow extends StatefulWidget {
  const _TranslationRow({
    required super.key,
    required this.translationKey,
    required this.displayLabel,
    required this.onRemove,
  });

  final String translationKey;
  final String displayLabel;
  final VoidCallback onRemove;

  @override
  State<_TranslationRow> createState() => _TranslationRowState();
}

class _TranslationRowState extends State<_TranslationRow> {
  late final TextEditingController _controller;
  late final SettingsBinding _binding;

  @override
  void initState() {
    super.initState();
    _binding = _bindingFor(widget.translationKey);
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
    if (_controller.text != hostValue) {
      _controller.value = TextEditingValue(
        text: hostValue,
        selection: TextSelection.collapsed(offset: hostValue.length),
      );
    }

    final scope = FormSaveScope.maybeOf(context);
    final field = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: widget.displayLabel),
            onChanged: (v) => host.updateSettings((s) => _binding.write(s, v)),
            onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.tr('remove'),
          onPressed: widget.onRemove,
        ),
      ],
    );

    return OverridableField.bindInline(
      apiKey: 'translations.${widget.translationKey}',
      label: widget.displayLabel,
      binding: _binding,
      cascadedValueOnEnable: () => _binding.read(host.settings) ?? '',
      child: field,
    );
  }
}

// ── shared helpers ──────────────────────────────────────────────────────────

Map<String, String> _readTranslations(CompanySettings settings) {
  final raw = settings.translations;
  if (raw == null) return const <String, String>{};
  final out = <String, String>{};
  for (final entry in raw.entries) {
    final v = entry.value;
    if (v == null) continue;
    out[entry.key] = v.toString();
  }
  return out;
}

SettingsBinding _bindingFor(String key) => (
  read: (s) {
    final m = s.translations;
    if (m == null) return null;
    final v = m[key];
    return v?.toString();
  },
  write: (s, v) {
    final map = Map<String, dynamic>.of(s.translations ?? const {});
    if (v == null) {
      map.remove(key);
    } else {
      map[key] = v;
    }
    return s.copyWith(translations: map.isEmpty ? null : map);
  },
);

void _addLabel(SettingsDraftHost host, String key) {
  if (key.isEmpty) return;
  host.updateSettings((s) {
    final map = Map<String, dynamic>.of(s.translations ?? const {});
    if (map.containsKey(key)) return s;
    map[key] = '';
    return s.copyWith(translations: map);
  });
}

void _removeLabel(SettingsDraftHost host, String key) {
  host.updateSettings((s) {
    final map = Map<String, dynamic>.of(s.translations ?? const {});
    map.remove(key);
    return s.copyWith(translations: map.isEmpty ? null : map);
  });
}
