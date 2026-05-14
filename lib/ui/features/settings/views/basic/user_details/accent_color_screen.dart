import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/user_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const kUserDetailsAccentColorSearchKeys = <String>['accent_color'];

/// Default accent palette. Hex values are stored as `#RRGGBB` on
/// `company_user.settings.accent_color` — same wire format admin-portal and
/// React use, so a value chosen here round-trips through both.
const _kAccentSwatches = <String>[
  '#1F2937',
  '#298AAB',
  '#16A34A',
  '#0EA5E9',
  '#6366F1',
  '#A855F7',
  '#EC4899',
  '#EF4444',
  '#F97316',
  '#F59E0B',
  '#84CC16',
  '#14B8A6',
];

class UserDetailsAccentColorScreen extends StatelessWidget {
  const UserDetailsAccentColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserDetailsViewModel>();
    if (!vm.isLoaded || !vm.draftReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = vm.user?.companyUserSettings.accentColor ?? '';
    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('accent_color'),
          children: [
            _SwatchGrid(
              selected: current,
              onSelected: (hex) => vm.updateCompanyUserSettings(
                (s) => s.copyWith(accentColor: hex),
              ),
            ),
            const SizedBox(height: InSpacing.md),
            if (current.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('reset')),
                  onPressed: () => vm.updateCompanyUserSettings(
                    (s) => s.copyWith(accentColor: ''),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: InSpacing.md,
      runSpacing: InSpacing.md,
      children: [
        for (final hex in _kAccentSwatches)
          _Swatch(
            hex: hex,
            isSelected: hex.toLowerCase() == selected.toLowerCase(),
            onTap: () => onSelected(hex),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final color = _parseHex(hex) ?? tokens.accent;
    return Tooltip(
      message: hex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(InRadii.r2),
            border: Border.all(
              color: isSelected ? tokens.ink : tokens.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 18,
                  color:
                      ThemeData.estimateBrightnessForColor(color) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                )
              : null,
        ),
      ),
    );
  }

  static Color? _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
  }
}
