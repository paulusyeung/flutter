import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../app/services.dart';
import '../../../../app/version.dart';

/// Diagnostics: app + server version, active company, sync state. Includes a
/// "Copy diagnostics" button that snapshots everything to the clipboard so
/// support tickets carry the same data we'd ask for over email.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      appBar: AppBar(title: const Text('About / Diagnostics')),
      body: ValueListenableBuilder<String?>(
        valueListenable: services.serverVersion,
        builder: (context, serverVersion, _) {
          final session = services.auth.session.value;
          final companyId = session?.currentCompanyId ?? '';
          return StreamBuilder<int>(
            stream: services.db.outboxDao.watchPendingCount(
              companyId: companyId,
            ),
            builder: (context, pendingSnap) {
              return StreamBuilder<int>(
                stream: services.db.outboxDao.watchDeadCount(
                  companyId: companyId,
                ),
                builder: (context, deadSnap) {
                  final pending = pendingSnap.data ?? 0;
                  final dead = deadSnap.data ?? 0;
                  final rows = <(String, String)>[
                    (
                      'App version',
                      '${_packageInfo?.version ?? '?'} (${_packageInfo?.buildNumber ?? '?'})',
                    ),
                    ('Client version constant', AppVersion.kClientVersion),
                    ('Min server version', AppVersion.kMinServerVersion),
                    ('Server URL', session?.baseUrl ?? '—'),
                    ('Server version', serverVersion ?? 'not yet seen'),
                    ('Hosted', (session?.isHosted ?? false) ? 'yes' : 'no'),
                    ('Account id', session?.accountId ?? '—'),
                    ('Company', session?.currentCompany?.displayName ?? '—'),
                    ('Company id', session?.currentCompanyId ?? '—'),
                    ('Pending outbox rows', '$pending'),
                    ('Dead outbox rows', '$dead'),
                  ];
                  return ListView(
                    children: [
                      for (final row in rows)
                        ListTile(
                          dense: true,
                          title: Text(row.$1),
                          subtitle: SelectableText(row.$2),
                        ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy diagnostics'),
                          onPressed: () => _copy(rows),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _copy(List<(String, String)> rows) async {
    final text = rows.map((r) => '${r.$1}: ${r.$2}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}
