import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/gateway.dart';
import 'package:admin/domain/gateway_constants.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/gateways/widgets/gateway_logo.dart';

/// Per-gateway visual-size override for the picker tile. Default is 96 px;
/// icon-only marks (Rotessa R, CBA PowerBoard diamond, Custom wallet) fill
/// a 96×96 box with solid pixels and visually outweigh the wordmark logos,
/// which are wide-and-short and end up at ~96 × 20-30 px after
/// `BoxFit.contain`. Shrinking the icon-only renders to ~64 px puts them
/// in roughly the same visual area as a typical wordmark. Mirrors the
/// React app's `gatewaysStyles` width-override array in `Create.tsx:51-61`.
const Map<String, double> _kPickerLogoSizeByKey = <String, double>{
  kGatewayRotessa: 64,
  kGatewayCbaPowerboard: 64,
  kGatewayCustom: 64,
};

/// Grid of selectable gateway providers. Drives the create flow: until the
/// user picks one, the edit screen renders this in place of the tabs.
class GatewayTypePicker extends StatefulWidget {
  const GatewayTypePicker({super.key, required this.onSelected});

  /// Called with the chosen `Gateway.id` (the same value stored on
  /// `CompanyGateway.gatewayKey`).
  final ValueChanged<String> onSelected;

  @override
  State<GatewayTypePicker> createState() => _GatewayTypePickerState();
}

class _GatewayTypePickerState extends State<GatewayTypePicker> {
  bool _warming = false;

  @override
  void initState() {
    super.initState();
    final statics = context.read<Services>().statics;
    if (statics.gateways.isEmpty) {
      _warming = true;
      statics.ensureLoaded().then((_) {
        if (mounted) setState(() => _warming = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final providers = statics.gateways.values.where((g) => g.isVisible).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (_warming && providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: InSpacing.md(context)),
            Text(context.tr('loading_gateway_types')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('select_a_gateway'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: InSpacing.md(context)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: InSpacing.md(context),
              crossAxisSpacing: InSpacing.md(context),
              childAspectRatio: 1.15,
            ),
            itemCount: providers.length,
            itemBuilder: (context, i) => _GatewayCard(
              gateway: providers[i],
              onTap: () => widget.onSelected(providers[i].id),
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayCard extends StatelessWidget {
  const _GatewayCard({required this.gateway, required this.onTap});
  final Gateway gateway;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Padding(
          padding: EdgeInsets.all(InSpacing.md(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GatewayLogo(
                gatewayKey: gateway.id,
                size: _kPickerLogoSizeByKey[gateway.id] ?? 96,
                fallbackColor: tokens.ink3,
              ),
              SizedBox(height: InSpacing.md(context)),
              Text(
                gateway.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
