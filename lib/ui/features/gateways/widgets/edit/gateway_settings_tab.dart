import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/gateway.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Settings tab: label, token billing, per-payment-type toggles, card
/// bitmask. Rendered on both create and edit flows once a gateway type is
/// selected.
class GatewaySettingsTab extends StatelessWidget {
  const GatewaySettingsTab({
    super.key,
    required this.vm,
    required this.gateway,
  });

  final CompanyGatewayEditViewModel vm;
  final Gateway gateway;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final draft = vm.draft;
    final showTokenBilling = gateway.options.values.any(
      (o) => o.supportTokenBilling,
    );
    final hasCreditCardType = draft.feesAndLimits.containsKey('1');

    return ListView(
      padding: const EdgeInsets.all(InSpacing.lg),
      children: [
        FormSection(
          title: context.tr('identity_and_flow'),
          children: [
            TextFormField(
              initialValue: draft.label,
              decoration: InputDecoration(
                labelText: context.tr('label'),
                errorText: vm.fieldErrorFor('label'),
              ),
              onChanged: (v) => vm.mutate((g) => g.copyWith(label: v)),
            ),
            SwitchListTile(
              title: Text(context.tr('test_mode')),
              value: draft.testMode,
              onChanged: (v) => vm.mutate((g) => g.copyWith(testMode: v)),
              contentPadding: EdgeInsets.zero,
            ),
            if (showTokenBilling)
              DropdownButtonFormField<String>(
                initialValue: draft.tokenBilling,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('token_billing'),
                  errorText: vm.fieldErrorFor('token_billing'),
                ),
                items: [
                  for (final opt in kAutoBillOptions)
                    DropdownMenuItem(value: opt, child: Text(context.tr(opt))),
                ],
                onChanged: (v) {
                  if (v != null) vm.mutate((g) => g.copyWith(tokenBilling: v));
                },
              ),
          ],
        ),
        if (gateway.options.isNotEmpty)
          FormSection(
            title: context.tr('payment_methods'),
            children: [
              for (final typeId in gateway.options.keys)
                SwitchListTile(
                  title: Text(
                    statics.gatewayType(typeId)?.name ?? 'type $typeId',
                  ),
                  value: draft.feesAndLimits[typeId]?.isEnabled ?? false,
                  onChanged: (v) => vm.setTypeEnabled(typeId, v),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        if (hasCreditCardType)
          FormSection(
            title: context.tr('accepted_credit_cards'),
            children: [
              for (final bit in kCardTypeBits)
                CheckboxListTile(
                  title: Text(context.tr(kCardTypeLabelKey[bit] ?? 'card')),
                  value: draft.supportsCard(bit),
                  onChanged: (v) => vm.toggleCard(bit, selected: v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
      ],
    );
  }
}
