import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/shell/widgets/health_check_dialog.dart';
import 'package:admin/ui/features/shell/widgets/keyboard_shortcuts_dialog.dart';

/// Opens the themed About dialog. Hand-rolled rather than Flutter's built-in
/// `showAboutDialog` so it matches the rest of the app's `InTheme` look.
/// "View Licenses" still pushes Flutter's bundled `LicensePage`, which is the
/// right tool for that subpage.
Future<void> showAppAboutDialog(BuildContext context) async {
  final services = context.read<Services>();
  final session = services.auth.session.value;
  PackageInfo? info;
  try {
    info = await PackageInfo.fromPlatform();
  } catch (_) {
    info = null;
  }
  if (!context.mounted) return;
  // Capture the caller's context for the Health Check chain so the
  // re-open survives popping the About dialog (the builder's `ctx`
  // unmounts on pop).
  final outerContext = context;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _AboutDialog(
      info: info,
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
    required this.info,
    required this.userEmail,
    required this.onShowHealthCheck,
    required this.onShowKeyboardShortcuts,
  });

  final PackageInfo? info;
  final String? userEmail;
  final VoidCallback? onShowHealthCheck;
  final VoidCallback onShowKeyboardShortcuts;

  String _versionLine() {
    if (info == null) return '—';
    final v = info!.version;
    final b = info!.buildNumber;
    return b.isEmpty ? v : '$v ($b)';
  }

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
            Text(
              _versionLine(),
              style: TextStyle(fontSize: 13, color: tokens.ink3),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LicensePage(
                    applicationName: 'Invoice Ninja',
                    applicationVersion: _versionLine(),
                  ),
                ),
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
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }
}
