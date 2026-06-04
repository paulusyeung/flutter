import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Three info cards for the CompanyGateway detail screen body:
///   1. Overview — label / provider / test mode / token billing.
///   2. Required fields — chips for each `require_*` toggle that's on.
///   3. Accepted payment types — chips for each enabled payment type.
class CompanyGatewayDetailCardsGrid extends StatelessWidget {
  const CompanyGatewayDetailCardsGrid({super.key, required this.gateway});

  final CompanyGateway gateway;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OverviewCard(gateway: gateway),
        _RequiredFieldsCard(gateway: gateway),
        _AcceptedTypesCard(gateway: gateway),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.gateway});
  final CompanyGateway gateway;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final providerName =
        statics.gateway(gateway.gatewayKey)?.name ?? context.tr('custom');
    return FormSection(
      title: context.tr('overview'),
      spacing: 0,
      children: [
        _KeyValue(
          labelKey: 'label',
          value: gateway.label.isEmpty ? '—' : gateway.label,
        ),
        _KeyValue(labelKey: 'gateway_type', value: providerName),
        _KeyValue(
          labelKey: 'test_mode',
          value: gateway.testMode ? context.tr('enabled') : context.tr('off'),
        ),
        _KeyValue(
          labelKey: 'token_billing',
          value: context.tr(gateway.tokenBilling),
        ),
      ],
    );
  }
}

class _RequiredFieldsCard extends StatelessWidget {
  const _RequiredFieldsCard({required this.gateway});
  final CompanyGateway gateway;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (gateway.requireClientName) _chip(context, 'client_name'),
      if (gateway.requireClientPhone) _chip(context, 'phone'),
      if (gateway.requireContactName) _chip(context, 'contact_name'),
      if (gateway.requireContactEmail) _chip(context, 'email'),
      if (gateway.requireBillingAddress) _chip(context, 'billing_address'),
      if (gateway.requireShippingAddress) _chip(context, 'shipping_address'),
      if (gateway.requirePostalCode) _chip(context, 'postal_code'),
      if (gateway.requireCvv) _chip(context, 'cvv'),
    ];
    return FormSection(
      title: context.tr('required_fields_label'),
      children: [
        if (chips.isEmpty)
          Text(context.tr('off'))
        else
          Wrap(
            spacing: InSpacing.sm,
            runSpacing: InSpacing.sm,
            children: chips,
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String labelKey) =>
      Chip(label: Text(context.tr(labelKey)));
}

class _AcceptedTypesCard extends StatelessWidget {
  const _AcceptedTypesCard({required this.gateway});
  final CompanyGateway gateway;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final enabledTypes = <String>[];
    gateway.feesAndLimits.forEach((typeId, fees) {
      if (fees.isEnabled) {
        final type = statics.gatewayType(typeId);
        // `GatewayType.name` is a localization key, not a display string —
        // see `kGatewayTypeLabelKey`. Fall back to a raw "type N" if the
        // server references an id we haven't cataloged yet.
        enabledTypes.add(type == null ? typeId : context.tr(type.name));
      }
    });
    final cards = <Widget>[
      for (final bit in kCardTypeBits)
        if (gateway.supportsCard(bit))
          Chip(label: Text(context.tr(kCardTypeLabelKey[bit] ?? 'card'))),
    ];
    return FormSection(
      title: context.tr('payment_methods'),
      children: [
        if (enabledTypes.isEmpty && cards.isEmpty)
          Text(context.tr('no_payment_types_enabled'))
        else ...[
          if (enabledTypes.isNotEmpty)
            Wrap(
              spacing: InSpacing.sm,
              runSpacing: InSpacing.sm,
              children: [
                for (final name in enabledTypes) Chip(label: Text(name)),
              ],
            ),
          if (cards.isNotEmpty) ...[
            SizedBox(height: InSpacing.md(context)),
            Text(
              context.tr('accepted_credit_cards'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: InSpacing.sm),
            Wrap(
              spacing: InSpacing.sm,
              runSpacing: InSpacing.sm,
              children: cards,
            ),
          ],
        ],
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.labelKey, required this.value});
  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
      // Narrow the label column on small widths (phones, or a narrow
      // master-detail pane) so the value keeps room. Measured off the actual
      // available width, not the whole screen.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = constraints.maxWidth < 360 ? 110.0 : 160.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  context.tr(labelKey),
                  style: TextStyle(color: tokens.ink3),
                ),
              ),
              Expanded(
                child: Text(value, style: TextStyle(color: tokens.ink)),
              ),
            ],
          );
        },
      ),
    );
  }
}
