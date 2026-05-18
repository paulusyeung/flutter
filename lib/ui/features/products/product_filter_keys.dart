import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/ui/core/list/search/custom_field_filter_key.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the products list's search field:
/// lifecycle state plus the shared custom-field filters (`product1..4`
/// labels). Free-text search already covers `product_key`/`notes`.
List<FilterKey> buildProductFilterKeys({Company? company}) => <FilterKey>[
      const IsFilterKey(),
      for (var i = 1; i <= 4; i++)
        CustomFieldFilterKey(
          columnIndex: i,
          configuredLabel: company?.customFieldLabel('product$i') ?? '',
        ),
    ];
