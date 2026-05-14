import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_edit_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Limits & Fees tab — per-payment-type editor. The user picks the active
/// payment type from a chip selector and the per-type form sits below.
class GatewayLimitsFeesTab extends StatefulWidget {
  const GatewayLimitsFeesTab({super.key, required this.vm});

  final CompanyGatewayEditViewModel vm;

  @override
  State<GatewayLimitsFeesTab> createState() => _GatewayLimitsFeesTabState();
}

class _GatewayLimitsFeesTabState extends State<GatewayLimitsFeesTab> {
  String? _activeTypeId;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final draft = widget.vm.draft;
    final enabledTypeIds = draft.feesAndLimits.entries
        .where((e) => e.value.isEnabled)
        .map((e) => e.key)
        .toList();

    if (enabledTypeIds.isEmpty) {
      return SettingsFormShell(
        child: Center(
          child: Text(
            context.tr('no_payment_types_enabled'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final active =
        _activeTypeId != null && enabledTypeIds.contains(_activeTypeId)
        ? _activeTypeId!
        : enabledTypeIds.first;
    final fees = draft.feesAndLimits[active] ?? const FeesAndLimits();

    return SettingsFormShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: InSpacing.sm,
            runSpacing: InSpacing.sm,
            children: [
              for (final id in enabledTypeIds)
                ChoiceChip(
                  label: Text(_typeLabel(context, statics, id)),
                  selected: id == active,
                  onSelected: (_) => setState(() => _activeTypeId = id),
                ),
            ],
          ),
          const SizedBox(height: InSpacing.lg),
          _LimitsAndFeesEditor(vm: widget.vm, typeId: active, fees: fees),
        ],
      ),
    );
  }

  /// Localized name for a gateway type id. See the matching helper on
  /// `GatewaySettingsTab` — same fallback chain.
  String _typeLabel(
    BuildContext context,
    StaticsRepository statics,
    String typeId,
  ) {
    final type = statics.gatewayType(typeId);
    if (type == null) return 'type $typeId';
    return context.tr(type.name);
  }
}

class _LimitsAndFeesEditor extends StatelessWidget {
  const _LimitsAndFeesEditor({
    required this.vm,
    required this.typeId,
    required this.fees,
  });

  final CompanyGatewayEditViewModel vm;
  final String typeId;
  final FeesAndLimits fees;

  @override
  Widget build(BuildContext context) {
    final minEnabled = fees.minLimit != kGatewayLimitDisabled;
    final maxEnabled = fees.maxLimit != kGatewayLimitDisabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection(
          title: context.tr('limits'),
          children: [
            SwitchListTile(
              title: Text(context.tr('enable_min')),
              value: minEnabled,
              onChanged: (v) => vm.updateFees(
                typeId,
                fees.copyWith(minLimit: v ? 0 : kGatewayLimitDisabled),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (minEnabled)
              TextFormField(
                initialValue: fees.minLimit.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: context.tr('min_limit')),
                onChanged: (v) {
                  final parsed = double.tryParse(v) ?? 0;
                  vm.updateFees(typeId, fees.copyWith(minLimit: parsed));
                },
              ),
            SwitchListTile(
              title: Text(context.tr('enable_max')),
              value: maxEnabled,
              onChanged: (v) => vm.updateFees(
                typeId,
                fees.copyWith(maxLimit: v ? 0 : kGatewayLimitDisabled),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (maxEnabled)
              TextFormField(
                initialValue: fees.maxLimit.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: context.tr('max_limit')),
                onChanged: (v) {
                  final parsed = double.tryParse(v) ?? 0;
                  vm.updateFees(typeId, fees.copyWith(maxLimit: parsed));
                },
              ),
          ],
        ),
        FormSection(
          title: context.tr('fees'),
          children: [
            TextFormField(
              initialValue: fees.feeAmount == 0
                  ? ''
                  : fees.feeAmount.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: context.tr('fee_amount')),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                vm.updateFees(typeId, fees.copyWith(feeAmount: parsed));
              },
            ),
            TextFormField(
              initialValue: fees.feePercent == 0
                  ? ''
                  : fees.feePercent.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: context.tr('fee_percent')),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                vm.updateFees(typeId, fees.copyWith(feePercent: parsed));
              },
            ),
            TextFormField(
              initialValue: fees.feeCap == 0 ? '' : fees.feeCap.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: context.tr('fee_cap')),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                vm.updateFees(typeId, fees.copyWith(feeCap: parsed));
              },
            ),
            SwitchListTile(
              title: Text(context.tr('adjust_fee_percent')),
              value: fees.adjustFeePercent,
              onChanged: (v) =>
                  vm.updateFees(typeId, fees.copyWith(adjustFeePercent: v)),
              contentPadding: EdgeInsets.zero,
            ),
            _FeePreview(fees: fees),
          ],
        ),
      ],
    );
  }
}

/// Live preview: "On a $100 payment: total $X, fee $Y".
class _FeePreview extends StatelessWidget {
  const _FeePreview({required this.fees});
  final FeesAndLimits fees;

  @override
  Widget build(BuildContext context) {
    const sample = 100.0;
    var fee = fees.feeAmount + (sample * fees.feePercent / 100.0);
    if (fees.feeCap > 0 && fee > fees.feeCap) fee = fees.feeCap;
    final total = sample + fee;
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.only(top: InSpacing.md),
      child: Text(
        context.tr('fees_sample', {
          'amount': '\$${sample.toStringAsFixed(0)}',
          'total': '\$${total.toStringAsFixed(2)}',
          'fee': '\$${fee.toStringAsFixed(2)}',
        }),
        style: TextStyle(color: tokens.ink2),
      ),
    );
  }
}
