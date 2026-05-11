import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

class UserDetailsPreferencesScreen extends StatelessWidget {
  const UserDetailsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = Breakpoints.isWide(constraints);
        return Scaffold(
          drawer: wide ? null : const AppDrawer(),
          appBar: AppBar(
            title: Text(context.tr('preferences')),
            leading: wide ? null : const DrawerHamburger(),
            automaticallyImplyLeading: !wide,
          ),
          body: ListView(
            children: [
              _ThemeTile(controller: services.theme),
              const Divider(height: 1),
              _LocaleTile(controller: services.locale),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
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
          title: Text(context.tr('theme')),
          subtitle: Text(_label(context, mode)),
          trailing: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(context.tr('auto')),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(context.tr('light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(context.tr('dark')),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.set(s.first),
          ),
        );
      },
    );
  }

  String _label(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.system => context.tr('match_system'),
    ThemeMode.light => context.tr('light'),
    ThemeMode.dark => context.tr('dark'),
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
          title: Text(context.tr('language')),
          subtitle: Text(
            current == null ? context.tr('match_system') : _label(current),
          ),
          trailing: PopupMenuButton<Locale?>(
            tooltip: context.tr('choose_language'),
            initialValue: current,
            onSelected: controller.set,
            itemBuilder: (context) => [
              PopupMenuItem<Locale?>(
                value: null,
                child: Text(context.tr('match_system')),
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
