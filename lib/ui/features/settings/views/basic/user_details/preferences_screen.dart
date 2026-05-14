import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';

class UserDetailsPreferencesScreen extends StatelessWidget {
  const UserDetailsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return SettingsScreenScaffold(
      titleKey: 'preferences',
      body: SettingsFormShell(
        sections: [
          FormSection(
            title: context.tr('preferences'),
            spacing: 0,
            children: [
              ThemeTile(controller: services.theme),
              const Divider(height: 1),
              _LocaleTile(controller: services.locale),
            ],
          ),
        ],
      ),
    );
  }
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
