import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';

/// Country picker for the vendor edit screen. Backed by the cached statics
/// `services.statics.countries`. Users see country names; the underlying
/// value bound to the VM is the country **id**. Mirror of
/// `ClientEditCountryField`.
class VendorEditCountryField extends StatelessWidget {
  const VendorEditCountryField({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// Country id (server id, e.g. `"840"` for US).
  final String initial;

  /// Fired with the selected country id (or `''` when cleared).
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final countries = statics.countries.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final current = statics.country(initial);

    return SearchableDropdownField<Country>(
      label: context.tr('country'),
      items: countries,
      initialValue: current,
      displayString: (c) => c.name,
      idOf: (c) => c.id,
      onChanged: (c) => onChanged(c?.id ?? ''),
    );
  }
}
