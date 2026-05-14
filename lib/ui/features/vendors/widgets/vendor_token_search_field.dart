import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_list_view_model.dart';
import 'package:admin/ui/features/vendors/widgets/vendor_filter_keys.dart';

/// Thin wrapper that wires [TokenSearchField] for the vendors list. Watches
/// the current `Company` so the configured custom-field labels feed into
/// the filter keys when those land. Mirror of `ClientTokenSearchField`.
class VendorTokenSearchField extends StatelessWidget {
  const VendorTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final VendorListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, snapshot) {
        final keys = buildVendorFilterKeys(
          company: snapshot.data,
          statics: services.statics,
        );
        return TokenSearchField(
          vm: vm,
          filterKeys: keys,
          wide: wide,
          hintKey: 'search_vendors_or_filter_hint',
        );
      },
    );
  }
}
