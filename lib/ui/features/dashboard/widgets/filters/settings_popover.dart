import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';

/// Ghost-style button in the dashboard TopBar that opens a popover containing
/// [DashboardSettingsForm] (currency + include-drafts).
class DashboardSettingsButton extends StatelessWidget {
  const DashboardSettingsButton({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink2,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
          side: BorderSide(color: tokens.border),
        ),
      ),
      icon: const Icon(Icons.settings_outlined, size: 14),
      label: Text(context.tr('settings'), style: const TextStyle(fontSize: 13)),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? const Size(160, 32);
    await showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          child: DashboardSettingsForm(vm: vm),
        ),
      ],
    );
  }
}

/// Currency dropdown + include-drafts toggle, rendered in a TopBar popover on
/// desktop and a bottom sheet on mobile. Both share this widget body.
class DashboardSettingsForm extends StatelessWidget {
  const DashboardSettingsForm({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final currencies = vm.availableCurrencies;
    final dropdownItems = <DropdownMenuItem<int>>[
      DropdownMenuItem(
        value: kDashboardCurrencyAll,
        child: Text(context.tr('all_currencies')),
      ),
      for (final entry in currencies.entries)
        DropdownMenuItem(
          value: int.tryParse(entry.key) ?? kDashboardCurrencyAll,
          child: Text(entry.value),
        ),
    ];
    final selectedValue =
        dropdownItems.any((item) => item.value == vm.filter.currencyId)
        ? vm.filter.currencyId
        : kDashboardCurrencyAll;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.all(InSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('currency'),
              style: TextStyle(
                fontSize: 11.5,
                color: tokens.ink3,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              initialValue: selectedValue,
              isExpanded: true,
              items: dropdownItems,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(InRadii.r2),
                  borderSide: BorderSide(color: tokens.border),
                ),
              ),
              onChanged: (value) {
                if (value != null) vm.setCurrency(value);
              },
            ),
            const SizedBox(height: InSpacing.md),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: vm.filter.includeDrafts,
              onChanged: vm.setIncludeDrafts,
              title: Text(context.tr('include_drafts')),
              subtitle: Text(
                context.tr('count_unsent_in_totals'),
                style: TextStyle(fontSize: 11, color: tokens.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
