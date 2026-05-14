import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

const String _kReferralBaseUrl = 'https://app.invoicing.co/#/register?rc=';
const String _kReferralLearnMoreUrl = 'https://invoiceninja.com/referrals/';

/// Account Management → Referral Program. Hosted-only display screen:
/// shows the user's referral URL (tap-to-copy) and per-plan referral counts
/// pulled from `AuthSession.referralCode` / `referralMeta`. Self-hosted
/// sessions get an `EmptyState` explaining why the feature is unavailable.
class AccountManagementReferralProgramScreen extends StatelessWidget {
  const AccountManagementReferralProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session.value;
    return SettingsScreenScaffold(
      titleKey: 'referral_program',
      body: !(session?.isHosted ?? false)
          ? EmptyState(
              icon: Icons.public,
              title: context.tr('referral_program'),
            )
          : _ReferralBody(
              code: session!.referralCode,
              meta: session.referralMeta,
            ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.code, required this.meta});

  final String code;
  final Map<String, int> meta;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final url = '$_kReferralBaseUrl$code';
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('referral_code'),
          spacing: 0,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link, color: tokens.ink2),
              title: SelectableText(
                url,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.ink,
                ),
              ),
              trailing: Icon(Icons.content_copy, color: tokens.ink3),
              onTap: () => _copyUrl(context, url),
            ),
          ],
        ),
        if (meta.isNotEmpty)
          FormSection(
            title: context.tr('referral_program'),
            spacing: 0,
            children: [
              for (final entry in meta.entries)
                _StatRow(planKey: entry.key, count: entry.value),
            ],
          ),
        Padding(
          padding: EdgeInsets.only(top: InSpacing.lg(context)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
              onPressed: () => _openExternal(context, _kReferralLearnMoreUrl),
              child: Text(context.tr('learn_more')),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    final copiedText = context.tr('copied_to_clipboard').replaceAll(
      ':value',
      url,
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    Notify.success(context, copiedText);
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final loc = Localization.of(context);
    final errorMessage =
        loc?.lookup('failed_to_open_url') ?? 'failed_to_open_url';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {
      /* fall through */
    }
    if (messenger == null) return;
    // ignore: use_build_context_synchronously
    Notify.error(messenger.context, errorMessage, messenger: messenger);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.planKey, required this.count});

  final String planKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(planKey),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
