import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kUserDetailsConnectSearchKeys = <String>[
  'connect_google',
  'connect_microsoft',
  'connect_gmail',
  'connect_email',
  'disconnect',
];

class UserDetailsConnectScreen extends StatelessWidget {
  const UserDetailsConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailsViewModel>();
    if (!vm.isLoaded || !vm.draftReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = vm.user;
    if (user == null) return const SizedBox.shrink();

    final connected = user.oauthProviderId.isNotEmpty;
    return SettingsFormShell(
      sections: connected
          ? [_ConnectedSection(provider: user.oauthProviderId)]
          : const [_ComingSoonSection()],
    );
  }
}

/// Provider id → display label. The wire values match admin-portal's
/// `kOAuthProvider*` constants; new providers go here when the server
/// gains them.
String _providerLabel(BuildContext context, String id) {
  switch (id) {
    case 'google':
      return 'Google';
    case 'microsoft':
      return 'Microsoft';
    case 'apple':
      return 'Apple';
    default:
      return id.isEmpty ? context.tr('oauth_mail') : id;
  }
}

class _ConnectedSection extends StatelessWidget {
  const _ConnectedSection({required this.provider});
  final String provider;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailsViewModel>();
    final user = vm.user;
    final label = _providerLabel(context, provider);
    return FormSection(
      title: context.tr('oauth_mail'),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${context.tr('connected_to')}: $label',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () => _onDisconnect(context, 'disconnect_oauth'),
              child: Text(context.tr('disconnect')),
            ),
          ],
        ),
        if (user != null && user.oauthUserRefreshToken.isNotEmpty) ...[
          const SizedBox(height: InSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: InSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('send_and_receive_email'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: () => _onDisconnect(context, 'disconnect_mailer'),
                child: Text(context.tr('disconnect')),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _onDisconnect(BuildContext context, String action) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final vm = context.read<UserDetailsViewModel>();
    final successLabel = context.tr('saved_settings');
    final errorLabel = context.tr('error_refresh_page');
    try {
      await vm.enqueueDisconnect(action: action);
      if (context.mounted) Notify.success(context, successLabel);
    } catch (e) {
      if (context.mounted) {
        Notify.error(
          context,
          errorLabel,
          detail: e.toString(),
          messenger: messenger,
        );
      }
    }
  }
}

class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('oauth_mail'),
      children: [
        Row(
          children: [
            StatusPill(
              label: context.tr('coming_soon'),
              fgColor: tokens.partial,
              bgColor: tokens.partialSoft,
            ),
          ],
        ),
        const SizedBox(height: InSpacing.md),
        Text(
          context.tr('connect_oauth_coming_soon'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.ink2),
        ),
      ],
    );
  }
}
