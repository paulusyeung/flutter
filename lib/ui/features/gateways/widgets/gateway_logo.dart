import 'package:flutter/material.dart';

import 'package:admin/domain/gateway_constants.dart';

/// Renders a gateway provider's bundled logo via `Image.asset`. Falls back
/// to the generic wallet icon when the gateway key isn't in
/// [kGatewayLogoByKey] (e.g. Mollie, custom gateways, or a new provider
/// the server returns before we've added a mapping) or when the asset
/// fails to decode.
///
/// Mirrors the React `GatewayTypeIcon` component
/// (`react/src/pages/clients/show/components/GatewayTypeIcon.tsx`): same
/// asset set, same hash → logo mapping, same wallet-icon fallback shape.
/// We converted the four SVG sources (Stripe, WePay, Paytrace,
/// Blockonomics) to PNG up-front so the bundle has a single raster
/// renderer and we don't need `flutter_svg` as a dep.
class GatewayLogo extends StatelessWidget {
  const GatewayLogo({
    super.key,
    required this.gatewayKey,
    this.size = 32,
    this.fallbackColor,
  });

  /// `Gateway.id` / `CompanyGateway.gatewayKey` — the 32-char hash.
  final String gatewayKey;

  /// Logical pixel edge of the icon's bounding box. Logos are rendered with
  /// `BoxFit.contain` so they preserve aspect ratio inside [size]×[size].
  final double size;

  /// Color of the fallback wallet icon when no mapping exists. Pass a token
  /// (e.g. `context.inTheme.ink3`) to align with surrounding chrome.
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final path = kGatewayLogoByKey[gatewayKey];
    if (path == null) {
      return Icon(
        Icons.account_balance_wallet_outlined,
        size: size,
        color: fallbackColor,
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.account_balance_wallet_outlined,
        size: size,
        color: fallbackColor,
      ),
    );
  }
}
