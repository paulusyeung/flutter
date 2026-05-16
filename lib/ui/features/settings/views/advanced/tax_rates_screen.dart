import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/tax_rate.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_list_scaffold.dart';

/// Search keys exported for the settings sidebar search. Colocated with the
/// screen so adding / renaming a field updates both ends in one place.
const kTaxRatesSearchKeys = <String>[
  'tax_rates',
  'name',
  'rate',
];

/// `/settings/tax_rates` — manage the company's tax-rate registry. Tap a
/// row to edit; tap "+ New tax rate" to create. The per-company *default*
/// rate pickers live on the Tax Settings screen; this screen manages the
/// underlying list those pickers choose from.
class TaxRatesScreen extends StatelessWidget {
  const TaxRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.taxRates;

    return SettingsEntityListScaffold<TaxRate>(
      titleKey: 'tax_rates',
      sectionTitleKey: 'tax_rates',
      newRoute: '/settings/tax_rates/new',
      newLabelKey: 'new_tax_rate',
      emptyIcon: Icons.percent_outlined,
      emptyTitleKey: 'no_tax_rates',
      emptyHintKey: 'no_tax_rates_hint',
      refreshAll: () async {
        if (companyId.isEmpty) return;
        await repo.refreshAll(companyId: companyId);
      },
      stream: ({required includeArchived}) =>
          repo.watchAll(companyId: companyId),
      isArchivedOf: (t) => t.archivedAt != null,
      isDeletedOf: (t) => t.isDeleted,
      rowBuilder: (t) => _TaxRateRow(key: ValueKey(t.id), rate: t),
    );
  }
}

class _TaxRateRow extends StatelessWidget {
  const _TaxRateRow({required this.rate, super.key});

  final TaxRate rate;

  @override
  Widget build(BuildContext context) {
    final displayName =
        rate.name.trim().isEmpty ? context.tr('untitled') : rate.name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(displayName),
          subtitle: Text('${rate.rate}%'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/settings/tax_rates/${rate.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
