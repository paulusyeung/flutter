import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/gateway.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/gateways/oauth_setup_launcher.dart';
import 'package:admin/ui/features/gateways/widgets/gateway_logo.dart';

/// Setup card shown on the Credentials tab for OAuth-driven gateways. Hits
/// `/api/v1/one_time_token` to mint a hash, then launches the per-provider
/// signup URL in the system browser. The user completes setup on the web;
/// the row updates on the next sync.
///
/// Phase 2 doesn't yet wire up a deep-link callback handler — the user
/// returns to the app manually and the list refreshes. Phase 3 will fold
/// that in (custom URL scheme + GoRouter route on the callback).
class OAuthStubCard extends StatefulWidget {
  const OAuthStubCard({super.key, required this.gateway});

  final Gateway gateway;

  @override
  State<OAuthStubCard> createState() => _OAuthStubCardState();
}

class _OAuthStubCardState extends State<OAuthStubCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.all(InSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(InSpacing.xl),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(InRadii.r3),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GatewayLogo(
              gatewayKey: widget.gateway.id,
              size: 64,
              fallbackColor: tokens.ink3,
            ),
            const SizedBox(height: InSpacing.md),
            Text(
              widget.gateway.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: InSpacing.lg),
            Text(
              context.tr('oauth_gateway_stub_body', {
                'name': widget.gateway.name,
              }),
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.ink2),
            ),
            const SizedBox(height: InSpacing.xl),
            Wrap(
              spacing: InSpacing.md,
              runSpacing: InSpacing.md,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  onPressed: _busy ? null : () => _launchSetup(context),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.open_in_new, size: 18),
                  label: Text(context.tr('gateway_setup')),
                ),
                if (widget.gateway.siteUrl.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    onPressed: () =>
                        openExternal(Uri.parse(widget.gateway.siteUrl)),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(context.tr('learn_more')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSetup(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final services = context.read<Services>();
      final session = services.auth.session.value;
      if (session == null) return;
      final hash = await services.companyGateways.requestOAuthSetupHash();
      final url = buildOAuthSetupUrl(
        gatewayKey: widget.gateway.id,
        baseUrl: session.baseUrl,
        hash: hash,
      );
      if (url == null) {
        if (context.mounted) {
          Notify.error(context, 'No setup URL for ${widget.gateway.name}');
        }
        return;
      }
      final ok = await openExternal(url);
      if (!ok && context.mounted) {
        Notify.error(context, context.tr('failed_to_open_url'));
      }
    } catch (e) {
      if (context.mounted) Notify.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
