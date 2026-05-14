import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/gateways/gateway_filter_keys.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the company-gateways list.
class CompanyGatewayTokenSearchField extends StatelessWidget {
  const CompanyGatewayTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final CompanyGatewayListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildCompanyGatewayFilterKeys(),
      wide: wide,
      hintKey: 'search_company_gateways_or_filter_hint',
    );
  }
}
