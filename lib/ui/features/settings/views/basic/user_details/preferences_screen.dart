import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/theme_tile.dart';

const kUserDetailsPreferencesSearchKeys = <String>[
  'preferences',
  'theme',
  'app_language',
  'accent_color',
];

/// Settings > User Details > Preferences tab body. Theme + language are
/// device-local controls (no server sync); accent colour writes through to
/// `company_user.settings.accent_color` via the shared
/// [UserDetailsViewModel], so the tab contributes to the User Details save
/// bar when the user picks a swatch.
class UserDetailsPreferencesScreen extends StatelessWidget {
  const UserDetailsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final vm = context.watch<UserDetailsViewModel>();
    final accentReady = vm.isLoaded && vm.draftReady;
    final current = vm.user?.companyUserSettings.accentColor ?? '';
    return SettingsFormShell(
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
        FormSection(
          title: context.tr('accent_color'),
          children: [
            if (!accentReady)
              const Center(child: CircularProgressIndicator())
            else ...[
              AccentSwatchGrid(
                selected: current,
                onSelected: (hex) {
                  vm.updateCompanyUserSettings(
                    (s) => s.copyWith(accentColor: hex),
                  );
                  // Flip the theme immediately so the rest of the app
                  // reflects the choice before Save round-trips. The
                  // controller drops the preview once the persisted row
                  // catches up (or the user switches company / signs out).
                  services.accentColor.setPreview(parseAccentHex(hex));
                },
              ),
              SizedBox(height: InSpacing.md(context)),
              if (current.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('reset')),
                    onPressed: () {
                      vm.updateCompanyUserSettings(
                        (s) => s.copyWith(accentColor: ''),
                      );
                      services.accentColor.setPreview(null);
                    },
                  ),
                ),
            ],
          ],
        ),
      ],
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
          title: Text(context.tr('app_language')),
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
