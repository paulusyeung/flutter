import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/shell/widgets/about_dialog.dart';
import 'package:admin/ui/features/shell/widgets/contact_us_dialog.dart';

const String _kForumUrl = 'https://forum.invoiceninja.com';
const String _kDocsBaseUrl = 'https://invoiceninja.github.io/en';

/// Row of icon buttons pinned to the bottom of the sidebar: Contact Us,
/// Support Forum, User Guide, About. Visual language matches
/// `SidebarNavItem` — `InkWell` + `Padding` over `tokens.ink3` icons rather
/// than the default Material `IconButton` ripple, which doesn't appear
/// anywhere else in the rail.
///
/// Wrapped in `SafeArea(top: false)` so the row clears the iPhone home
/// indicator / Android gesture bar on the drawer; the safe-area inset is
/// zero on the persistent desktop rail.
class SidebarFooterActions extends StatelessWidget {
  const SidebarFooterActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FooterAction(
              icon: Icons.mail_outline,
              tooltipKey: 'contact_us',
              onTap: () => showContactUsDialog(context),
            ),
            _FooterAction(
              icon: Icons.forum_outlined,
              tooltipKey: 'support_forum',
              onTap: () => _openExternal(context, _kForumUrl),
            ),
            _FooterAction(
              icon: Icons.help_outline,
              tooltipKey: 'user_guide',
              onTap: () => _openExternal(
                context,
                userGuideUrl(GoRouterState.of(context).matchedLocation),
              ),
            ),
            _FooterAction(
              icon: Icons.info_outline,
              tooltipKey: 'about',
              onTap: () => showAppAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pure-function URL mapping: matched route → docs sub-path. Extracted so the
/// table can be unit-tested without pumping a widget tree.
@visibleForTesting
String userGuideUrl(String location) {
  if (location.startsWith('/clients')) return '$_kDocsBaseUrl/clients';
  if (location.startsWith('/dashboard')) return '$_kDocsBaseUrl/user-guide';
  if (location.startsWith('/settings/company_details')) {
    return '$_kDocsBaseUrl/basic-settings';
  }
  if (location.startsWith('/settings')) {
    return '$_kDocsBaseUrl/advanced-settings';
  }
  return _kDocsBaseUrl;
}

Future<void> _openExternal(BuildContext context, String url) async {
  // Capture the messenger + localized string pre-await so the error toast
  // survives any context disposal (e.g. drawer pop) during the launch handshake.
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
    /* fall through to error toast */
  }
  if (messenger == null) return;
  // messenger.context is the ScaffoldMessengerState's element context — it's
  // still mounted (we'd have early-returned otherwise) and Notify only
  // consults `context` as a fallback when `messenger` is null.
  // ignore: use_build_context_synchronously
  Notify.error(messenger.context, errorMessage, messenger: messenger);
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.tooltipKey,
    required this.onTap,
  });

  final IconData icon;
  final String tooltipKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Tooltip(
      message: context.tr(tooltipKey),
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(InRadii.r2),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: tokens.ink3),
          ),
        ),
      ),
    );
  }
}
