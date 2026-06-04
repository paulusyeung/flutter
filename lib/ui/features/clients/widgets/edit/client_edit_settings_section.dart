import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/industry.dart';
import 'package:admin/data/models/value/language.dart';
import 'package:admin/data/models/value/size.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_edit_field.dart';
import 'package:admin/ui/core/widgets/labeled_switch_group.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/clients/view_models/client_edit_view_model.dart';
import 'package:admin/ui/features/clients/widgets/edit/client_edit_field_pair.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';

/// Per-client "Settings" card on the edit screen — the cascade overrides
/// (currency / language / payment terms / task rate) plus classification,
/// company size, industry, e-invoice routing, and the tax flags. Mirrors the
/// React edit "Additional Info → Settings / Classify" sub-tabs.
///
/// Currency / language / payment_terms live in the `settings` cascade (see
/// `Client.toApiJson`): clearing a picker removes the override so the client
/// inherits the company/group value. The pickers are type-to-search because
/// the currency / language lists run past ~20 entries (Forms rule).
class ClientEditSettingsSection extends StatelessWidget {
  const ClientEditSettingsSection({super.key, required this.vm});

  final ClientEditViewModel vm;

  /// Server `classification` enum (React parity). Labels resolve via `tr`.
  static const List<String> _classifications = [
    'individual',
    'business',
    'company',
    'partnership',
    'trust',
    'charity',
    'government',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final draft = vm.draft;
    final statics = context.read<Services>().statics;

    List<T> sorted<T>(Iterable<T> items, String Function(T) name) =>
        items.toList()..sort(
          (a, b) => name(a).toLowerCase().compareTo(name(b).toLowerCase()),
        );

    final currencies = sorted<Currency>(
      statics.currencies.values,
      (c) => c.name,
    );
    final languages = sorted<Language>(statics.languages.values, (l) => l.name);
    final industries = sorted<Industry>(
      statics.industries.values,
      (i) => i.name,
    );
    final sizes = sorted<Size>(statics.sizes.values, (s) => s.name);

    // `default_task_rate` is stored as a num (see `setDefaultTaskRate`); show a
    // whole number without a trailing `.0`, and tolerate a legacy string value.
    final taskRateRaw = draft.settings?['default_task_rate'];
    final taskRate = taskRateRaw == null
        ? ''
        : (taskRateRaw is num && taskRateRaw % 1 == 0
              ? taskRateRaw.toInt().toString()
              : taskRateRaw.toString());

    return DashboardCardShell(
      title: context.tr('settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientEditFieldPair(
            left: SearchableDropdownField<Currency>(
              label: context.tr('currency'),
              items: currencies,
              initialValue: statics.currency(draft.currencyId),
              displayString: (c) => c.name,
              idOf: (c) => c.id,
              onChanged: (c) => vm.setCurrencyId(c?.id ?? ''),
            ),
            right: SearchableDropdownField<Language>(
              label: context.tr('language'),
              items: languages,
              initialValue: statics.language(draft.languageId),
              displayString: (l) => l.name,
              idOf: (l) => l.id,
              onChanged: (l) => vm.setLanguageId(l?.id ?? ''),
            ),
          ),
          ClientEditFieldPair(
            left: EntityEditField(
              label: context.tr('payment_terms'),
              initial: draft.paymentTerms,
              keyboardType: TextInputType.number,
              onChanged: vm.setPaymentTerms,
            ),
            right: EntityEditField(
              label: context.tr('task_rate'),
              initial: taskRate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: vm.setDefaultTaskRate,
            ),
          ),
          ClientEditFieldPair(
            left: SearchableDropdownField<Industry>(
              label: context.tr('industry'),
              items: industries,
              initialValue: statics.industry(draft.industryId),
              displayString: (i) => i.name,
              idOf: (i) => i.id,
              onChanged: (i) => vm.setIndustryId(i?.id ?? ''),
            ),
            right: SearchableDropdownField<Size>(
              label: context.tr('size_id'),
              items: sizes,
              initialValue: statics.size(draft.sizeId),
              displayString: (s) => s.name,
              idOf: (s) => s.id,
              onChanged: (s) => vm.setSizeId(s?.id ?? ''),
            ),
          ),
          ClientEditFieldPair(
            left: SearchableDropdownField<String>(
              label: context.tr('classification'),
              items: _classifications,
              initialValue: draft.classification.isEmpty
                  ? null
                  : draft.classification,
              displayString: (v) => context.tr(v),
              idOf: (v) => v,
              onChanged: (v) => vm.setClassification(v ?? ''),
            ),
            right: EntityEditField(
              label: context.tr('routing_id'),
              initial: draft.routingId,
              onChanged: vm.setRoutingId,
            ),
          ),
          SizedBox(height: InSpacing.sm),
          LabeledSwitchGroup(
            items: [
              LabeledSwitchItem(
                label: context.tr('tax_exempt'),
                value: draft.isTaxExempt,
                onChanged: vm.setIsTaxExempt,
              ),
              LabeledSwitchItem(
                label: context.tr('valid_vat_number'),
                value: draft.hasValidVatNumber,
                onChanged: vm.setHasValidVatNumber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
