import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
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
      onPressed: () => openDashboardSettingsPopover(context, vm: vm),
    );
  }
}

/// Opens the dashboard settings popover (currency + include-drafts) anchored
/// to whichever widget [context] points at. Shared by the wide TopBar button
/// and the dashboard's mobile AppBar icon so the menu positioning stays
/// consistent across breakpoints.
Future<void> openDashboardSettingsPopover(
  BuildContext context, {
  required DashboardViewModel vm,
}) async {
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
      PopupMenuItem<void>(enabled: false, child: DashboardSettingsForm(vm: vm)),
    ],
  );
}

/// Currency dropdown + include-drafts toggle, rendered in a TopBar popover on
/// desktop and a bottom sheet on mobile. Both share this widget body.
class DashboardSettingsForm extends StatelessWidget {
  const DashboardSettingsForm({super.key, required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final allLabel = context.tr('all_currencies');
    // "All currencies" is always first; the rest sort alphabetically so the
    // filtered list reads naturally as the user types.
    final options = <_CurrencyOption>[
      _CurrencyOption(id: kDashboardCurrencyAll, name: allLabel),
      ...vm.availableCurrencies.entries
          .map(
            (e) => _CurrencyOption(
              id: int.tryParse(e.key) ?? kDashboardCurrencyAll,
              name: e.value,
            ),
          )
          .where((o) => o.id != kDashboardCurrencyAll)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    ];
    final selected = options.firstWhere(
      (o) => o.id == vm.filter.currencyId,
      orElse: () => options.first,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Padding(
        padding: EdgeInsets.all(InSpacing.lg(context)),
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
            SearchableDropdownField<_CurrencyOption>(
              label: context.tr('currency'),
              items: options,
              initialValue: selected,
              displayString: (o) => o.name,
              idOf: (o) => o.id.toString(),
              onChanged: (o) => vm.setCurrency(o?.id ?? kDashboardCurrencyAll),
            ),
            SizedBox(height: InSpacing.md(context)),
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

class _CurrencyOption {
  const _CurrencyOption({required this.id, required this.name});

  final int id;
  final String name;
}
