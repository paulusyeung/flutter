import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/recurring_frequency.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_text_field.dart';
import 'package:admin/ui/features/payment_links/view_models/payment_link_edit_view_model.dart';

const _kRefundOrTrialSeconds = <int>[
  0,
  86400,
  172800,
  259200,
  604800,
  1209600,
  2592000,
  5184000,
];

const _kAutoBillOptions = <String, String>{
  '': 'off',
  'always': 'always',
  'optout': 'optout',
  'optin': 'optin',
  'off': 'off',
};

/// Second tab of the Payment Link edit screen — frequency, auto-bill,
/// promo, the toggles, and the conditional fields (refund period when
/// cancellation is on, trial duration when trials are on, max seats when
/// per-seat is on). Conditional sections animate in/out via
/// [AnimatedCrossFade] — mirrors the recurring-expense edit pattern.
class PaymentLinkSettingsTab extends StatelessWidget {
  const PaymentLinkSettingsTab({super.key, required this.vm});

  final PaymentLinkEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('frequency'),
          children: [
            _FrequencyDropdown(vm: vm),
            _RemainingCyclesDropdown(vm: vm),
            _AutoBillDropdown(vm: vm),
          ],
        ),
        FormSection(
          title: context.tr('price'),
          children: [
            SettingsTextField(
              initialValue: _decimalText(vm.draft.price.toString()),
              labelKey: 'price',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: vm.setPrice,
              externalSyncKey: vm.original?.id,
            ),
            SettingsTextField(
              initialValue: vm.draft.promoCode,
              labelKey: 'promo_code',
              onChanged: vm.setPromoCode,
              externalSyncKey: vm.original?.id,
            ),
            _PromoDiscountRow(vm: vm),
          ],
        ),
        FormSection(
          title: context.tr('settings'),
          children: [
            _BoolDropdown(
              labelKey: 'registration_required',
              value: vm.draft.registrationRequired,
              onChanged: vm.setRegistrationRequired,
            ),
            _BoolDropdown(
              labelKey: 'use_inventory_management',
              value: vm.draft.useInventoryManagement,
              onChanged: vm.setUseInventoryManagement,
            ),
            SettingsTextField(
              initialValue: vm.draft.webhookConfiguration.returnUrl,
              labelKey: 'return_url',
              onChanged: vm.setReturnUrl,
              externalSyncKey: vm.original?.id,
            ),
            _BoolDropdown(
              labelKey: 'allow_query_overrides',
              value: vm.draft.allowQueryOverrides,
              onChanged: vm.setAllowQueryOverrides,
            ),
            _BoolDropdown(
              labelKey: 'allow_plan_changes',
              value: vm.draft.allowPlanChanges,
              onChanged: vm.setAllowPlanChanges,
            ),
            _BoolDropdown(
              labelKey: 'allow_cancellation',
              value: vm.draft.allowCancellation,
              onChanged: vm.setAllowCancellation,
            ),
            _ConditionalSlot(
              visible: vm.draft.allowCancellation,
              child: _DurationDropdown(
                labelKey: 'refund_period',
                value: vm.draft.refundPeriod,
                onChanged: vm.setRefundPeriod,
              ),
            ),
            _BoolDropdown(
              labelKey: 'trial_enabled',
              value: vm.draft.trialEnabled,
              onChanged: vm.setTrialEnabled,
            ),
            _ConditionalSlot(
              visible: vm.draft.trialEnabled,
              child: _DurationDropdown(
                labelKey: 'trial_duration',
                value: vm.draft.trialDuration,
                onChanged: vm.setTrialDuration,
              ),
            ),
            _BoolDropdown(
              labelKey: 'per_seat_enabled',
              value: vm.draft.perSeatEnabled,
              onChanged: vm.setPerSeatEnabled,
            ),
            _ConditionalSlot(
              visible: vm.draft.perSeatEnabled,
              child: SettingsTextField(
                initialValue: vm.draft.maxSeatsLimit == 0
                    ? ''
                    : '${vm.draft.maxSeatsLimit}',
                labelKey: 'max_seats_limit',
                keyboardType: TextInputType.number,
                onChanged: vm.setMaxSeatsLimit,
                externalSyncKey: vm.original?.id,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Decimal field: empty for zero (per CLAUDE.md § Forms § Empty for blank).
String _decimalText(String raw) {
  if (raw.isEmpty || raw == '0' || raw == '0.0') return '';
  return raw;
}

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({required this.vm});
  final PaymentLinkEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final selected = vm.draft.frequencyId;
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text(context.tr('once'))),
      for (final id in kRecurringFrequencyOrdered)
        DropdownMenuItem(
          value: id,
          child: Text(context.tr(kRecurringFrequencyLabelKey[id]!)),
        ),
    ];
    return DropdownButtonFormField<String>(
      initialValue:
          items.any((m) => m.value == selected) ? selected : '',
      items: items,
      decoration: InputDecoration(labelText: context.tr('frequency')),
      onChanged: (v) => vm.setFrequencyId(v ?? ''),
    );
  }
}

class _RemainingCyclesDropdown extends StatelessWidget {
  const _RemainingCyclesDropdown({required this.vm});
  final PaymentLinkEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final v = vm.draft.remainingCycles;
    final items = <DropdownMenuItem<int>>[
      DropdownMenuItem(value: -1, child: Text(context.tr('endless'))),
      for (var i = 0; i <= 36; i++)
        DropdownMenuItem(value: i, child: Text('$i')),
    ];
    return DropdownButtonFormField<int>(
      initialValue: items.any((m) => m.value == v) ? v : -1,
      items: items,
      decoration: InputDecoration(labelText: context.tr('remaining_cycles')),
      onChanged: (next) => vm.setRemainingCycles(next ?? -1),
    );
  }
}

class _AutoBillDropdown extends StatelessWidget {
  const _AutoBillDropdown({required this.vm});
  final PaymentLinkEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final v = vm.draft.autoBill;
    final items = <DropdownMenuItem<String>>[
      for (final entry in _kAutoBillOptions.entries)
        DropdownMenuItem(
          value: entry.key,
          child: Text(context.tr(entry.value)),
        ),
    ];
    return DropdownButtonFormField<String>(
      initialValue: items.any((m) => m.value == v) ? v : '',
      items: items,
      decoration: InputDecoration(labelText: context.tr('auto_bill')),
      onChanged: (next) => vm.setAutoBill(next ?? ''),
    );
  }
}

class _DurationDropdown extends StatelessWidget {
  const _DurationDropdown({
    required this.labelKey,
    required this.value,
    required this.onChanged,
  });

  final String labelKey;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int>>[
      for (final secs in _kRefundOrTrialSeconds)
        DropdownMenuItem(
          value: secs,
          child: Text(
            secs == 0
                ? context.tr('disabled')
                : _formatDays(context, secs ~/ 86400),
          ),
        ),
    ];
    return DropdownButtonFormField<int>(
      initialValue: items.any((m) => m.value == value) ? value : 0,
      items: items,
      decoration: InputDecoration(labelText: context.tr(labelKey)),
      onChanged: (next) => onChanged(next ?? 0),
    );
  }

  String _formatDays(BuildContext context, int days) {
    if (days <= 1) return '$days ${context.tr('day')}';
    return '$days ${context.tr('days')}';
  }
}

class _PromoDiscountRow extends StatelessWidget {
  const _PromoDiscountRow({required this.vm});
  final PaymentLinkEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<bool>(
            initialValue: vm.draft.isAmountDiscount,
            items: [
              DropdownMenuItem(
                value: true,
                child: Text(context.tr('amount')),
              ),
              DropdownMenuItem(
                value: false,
                child: Text(context.tr('percent')),
              ),
            ],
            decoration: InputDecoration(labelText: context.tr('type')),
            onChanged: (v) => vm.setIsAmountDiscount(v ?? true),
          ),
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: SettingsTextField(
            initialValue: _decimalText(vm.draft.promoDiscount.toString()),
            labelKey: 'promo_discount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: vm.setPromoDiscount,
            externalSyncKey: vm.original?.id,
          ),
        ),
      ],
    );
  }
}

class _BoolDropdown extends StatelessWidget {
  const _BoolDropdown({
    required this.labelKey,
    required this.value,
    required this.onChanged,
  });

  final String labelKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<bool>(
      initialValue: value,
      items: [
        DropdownMenuItem(value: true, child: Text(context.tr('enabled'))),
        DropdownMenuItem(value: false, child: Text(context.tr('disabled'))),
      ],
      decoration: InputDecoration(labelText: context.tr(labelKey)),
      onChanged: (v) => onChanged(v ?? false),
    );
  }
}

class _ConditionalSlot extends StatelessWidget {
  const _ConditionalSlot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 150),
      crossFadeState: visible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: child,
      secondChild: const SizedBox.shrink(),
    );
  }
}
