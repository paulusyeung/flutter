import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';

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
  await showDialog<void>(
    context: context,
    builder: (ctx) => _AboutDialog(info: info, userEmail: session?.userEmail),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({required this.info, required this.userEmail});

  final PackageInfo? info;
  final String? userEmail;

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
            Text(
              '© ${DateTime.now().year} Invoice Ninja',
              style: TextStyle(fontSize: 11, color: tokens.ink4),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LicensePage(
                applicationName: 'Invoice Ninja',
                applicationVersion: _versionLine(),
              ),
            ),
          ),
          child: Text(context.tr('view_licenses')),
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
