import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/env.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/version.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/shell/widgets/health_check_dialog.dart';
import 'package:admin/ui/features/shell/widgets/keyboard_shortcuts_dialog.dart';

/// Pushes Flutter's bundled `LicensePage`. Modal sub-flow (not page
/// navigation) — see the routing rule in `docs/architecture.md` § Navigation.
Future<void> showAppLicensePage(BuildContext context, String version) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LicensePage(
        applicationName: 'Invoice Ninja',
        applicationVersion: version,
      ),
    ),
  );
}

/// Opens the themed About dialog. Hand-rolled rather than Flutter's built-in
/// `showAboutDialog` so it matches the rest of the app's `InTheme` look.
/// "View Licenses" still pushes Flutter's bundled `LicensePage`, which is the
/// right tool for that subpage.
Future<void> showAppAboutDialog(BuildContext context) async {
  final services = context.read<Services>();
  final session = services.auth.session.value;
  // Capture the caller's context for the Health Check chain so the
  // re-open survives popping the About dialog (the builder's `ctx`
  // unmounts on pop).
  final outerContext = context;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _AboutDialog(
      serverVersion: services.serverVersion,
      userEmail: session?.userEmail,
      onShowHealthCheck: _canShowHealthCheck(session)
          ? () {
              Navigator.of(ctx).pop();
              if (outerContext.mounted) {
                showHealthCheckDialog(outerContext);
              }
            }
          : null,
      onShowKeyboardShortcuts: () {
        Navigator.of(ctx).pop();
        if (outerContext.mounted) {
          showKeyboardShortcutsDialog(outerContext);
        }
      },
      onShowDebugPanel: () {
        Navigator.of(ctx).pop();
        services.debugPanelRevealed.value = true;
      },
    ),
  );
}

/// Self-hosted admins/owners only; `kDebugMode` lets devs probe against the
/// demo server without flipping a build flag.
bool _canShowHealthCheck(AuthSession? s) {
  if (s == null) return false;
  final me = s.currentCompany;
  if (me == null) return false;
  if (!(me.isAdmin || me.isOwner)) return false;
  return !s.isHosted || kDebugMode;
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({
    required this.serverVersion,
    required this.userEmail,
    required this.onShowHealthCheck,
    required this.onShowKeyboardShortcuts,
    required this.onShowDebugPanel,
  });

  final ValueListenable<String?> serverVersion;
  final String? userEmail;
  final VoidCallback? onShowHealthCheck;
  final VoidCallback onShowKeyboardShortcuts;
  final VoidCallback onShowDebugPanel;

  /// Combined `v<server>-<platformLetter><clientBuild>` label (see
  /// [AppVersion.versionLabel]). [server] is the live `x-app-version` value.
  String _versionLabel(String? server) => AppVersion.versionLabel(
    serverVersion: server,
    platformLetter: Env.platformLetter,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return AlertDialog(
      title: Text(context.tr('about')),
      content: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invoice Ninja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 2),
            ValueListenableBuilder<String?>(
              valueListenable: serverVersion,
              builder: (context, server, _) => Text(
                _versionLabel(server),
                style: TextStyle(fontSize: 13, color: tokens.ink3),
              ),
            ),
            if (userEmail != null && userEmail!.isNotEmpty) ...[
              SizedBox(height: InSpacing.md(context)),
              Text(
                userEmail!,
                style: TextStyle(fontSize: 12, color: tokens.ink3),
              ),
            ],
            SizedBox(height: InSpacing.md(context)),
            LinkText(
              label: context.tr('view_licenses'),
              style: const TextStyle(fontSize: 12),
              color: tokens.accent,
              onTap: () => showAppLicensePage(
                context,
                _versionLabel(serverVersion.value),
              ),
            ),
            SizedBox(height: InSpacing.md(context)),
            Text(
              '© ${DateTime.now().year} Invoice Ninja',
              style: TextStyle(fontSize: 11, color: tokens.ink4),
            ),
          ],
        ),
      ),
      actions: [
        if (onShowHealthCheck != null)
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: onShowHealthCheck,
            child: Text(context.tr('health_check')),
          ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: onShowKeyboardShortcuts,
          child: Text(context.tr('keyboard_shortcuts')),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: onShowDebugPanel,
          child: Text(context.tr('debug_panel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }
}
