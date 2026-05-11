import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/locale_controller.dart';
import '../../../../app/services.dart';
import '../../../../app/theme_controller.dart';
import '../../../../l10n/supported_locales.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resyncing = false;
  bool _signingOut = false;

  Future<void> _onForceResync() async {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null) return;
    setState(() => _resyncing = true);
    try {
      await services.clients.refreshAll(companyId: companyId, full: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resync complete')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resync failed: $e')));
    } finally {
      if (mounted) setState(() => _resyncing = false);
    }
  }

  Future<void> _onSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your locally cached data will be cleared. Any unsynced edits '
          'should be synced first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _signingOut = true);
    await context.read<Services>().auth.logout();
    // The router's redirect notices auth.credentials = null and pushes us
    // to /login automatically; no imperative navigation needed.
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (session != null)
            _AccountTile(
              email: '',
              companyName: session.currentCompany?.displayName ?? '—',
            ),
          const Divider(height: 1),
          _ThemeTile(controller: services.theme),
          const Divider(height: 1),
          _LocaleTile(controller: services.locale),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Force full resync'),
            subtitle: const Text(
              'Re-download all clients from the server. Use this if the '
              'local cache feels out of date.',
            ),
            trailing: _resyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _resyncing ? null : _onForceResync,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About / Diagnostics'),
            subtitle: const Text(
              'App + server versions, sync stats. Useful for support tickets.',
            ),
            onTap: () => context.go('/settings/diagnostics'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Sign out',
              style: TextStyle(color: Colors.redAccent),
            ),
            enabled: !_signingOut,
            onTap: _signingOut ? null : _onSignOut,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.email, required this.companyName});
  final String email;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(companyName),
      subtitle: email.isEmpty ? null : Text(email),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.controller});
  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mode = controller.value;
        return ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Theme'),
          subtitle: Text(_label(mode)),
          trailing: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.set(s.first),
          ),
        );
      },
    );
  }

  String _label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Match system',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({required this.controller});
  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.value;
        return ListTile(
          leading: const Icon(Icons.translate_outlined),
          title: const Text('Language'),
          subtitle: Text(current == null ? 'Match system' : _label(current)),
          trailing: PopupMenuButton<Locale?>(
            tooltip: 'Choose language',
            initialValue: current,
            onSelected: controller.set,
            itemBuilder: (context) => [
              const PopupMenuItem<Locale?>(
                value: null,
                child: Text('Match system'),
              ),
              const PopupMenuDivider(),
              for (final l in kSupportedLocales)
                PopupMenuItem<Locale?>(value: l, child: Text(_label(l))),
            ],
            child: const Icon(Icons.arrow_drop_down),
          ),
        );
      },
    );
  }

  static String _label(Locale locale) {
    // Short, human-recognizable labels — we'd swap to `tr('lang_en')` etc.
    // once UI strings start using `context.tr(...)`.
    const labels = {
      'en': 'English',
      'en_AU': 'English (Australia)',
      'en_GB': 'English (UK)',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'nl': 'Nederlands',
      'pt_BR': 'Português (Brasil)',
      'ja': '日本語',
      'zh_CN': '中文 (简体)',
    };
    return labels[localeKey(locale)] ?? localeKey(locale);
  }
}
