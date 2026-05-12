import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/shell/widgets/about_dialog.dart';
import 'package:admin/ui/features/shell/widgets/contact_us_dialog.dart';

const String _kForumUrl = 'https://forum.invoiceninja.com';
const String _kDocsBaseUrl = 'https://invoiceninja.github.io/en';

/// Bottom row pinned to the sidebar: Contact Us, Support Forum, User Guide,
/// About — and, on the wide layout, the collapse toggle pinned right with a
/// vertical divider between the two groups. When the wide sidebar is
/// collapsed to a 64-px rail (`compact: true`), only the toggle remains;
/// the four help/info actions hide entirely.
///
/// Visual language matches `SidebarNavItem` — `InkWell` + `Padding` over
/// `tokens.ink3` icons rather than the default Material `IconButton` ripple,
/// which doesn't appear anywhere else in the rail.
///
/// Wrapped in `SafeArea(top: false)` so the row clears the iPhone home
/// indicator / Android gesture bar on the drawer; the safe-area inset is
/// zero on the persistent desktop rail.
class SidebarFooterActions extends StatelessWidget {
  const SidebarFooterActions({
    this.compact = false,
    this.showCollapseToggle = false,
    super.key,
  });

  /// Hides the four help/info actions when true — only the collapse toggle
  /// remains (and only if [showCollapseToggle] is also true).
  final bool compact;

  /// Whether the collapse toggle is part of this row. False inside `AppDrawer`,
  /// which can't collapse; true on the persistent wide rail.
  final bool showCollapseToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final actions = <Widget>[
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
    ];

    final Widget body;
    if (showCollapseToggle && compact) {
      // Collapsed wide rail: only the expand toggle, centered.
      body = const Center(child: _CollapseToggleButton(collapsed: true));
    } else if (showCollapseToggle) {
      // Expanded wide rail: 4 actions, vertical divider, collapse toggle.
      body = Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(width: 1, height: 24, color: tokens.border),
          ),
          const _CollapseToggleButton(collapsed: false),
        ],
      );
    } else {
      // Drawer: 4 actions, no toggle.
      body = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      );
    }

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: body,
      ),
    );
  }
}

/// Flips `Services.sidebar` between collapsed and expanded. Shares the
/// footer row with the help/info actions when expanded; sits alone when
/// the rail is collapsed.
class _CollapseToggleButton extends StatelessWidget {
  const _CollapseToggleButton({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Tooltip(
      message: context.tr(collapsed ? 'show_sidebar' : 'hide_sidebar'),
      waitDuration: const Duration(milliseconds: 600),
      child: IconButton(
        // The theme sets `IconButton.minimumSize = Size.fromHeight(44)` via
        // the surrounding button defaults; without these overrides the
        // toggle balloons inside this tight footer.
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(
          collapsed ? Icons.chevron_right : Icons.chevron_left,
          size: 18,
          color: tokens.ink3,
        ),
        onPressed: () => context.read<Services>().sidebar.toggle(),
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
