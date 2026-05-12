import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Thin wrapper over [EntityDetailHeader] — uses `productKey` as the
/// display name (falling back to the generic `no_name_fallback`) and
/// renders no `#<number>` subtitle (products don't carry a separate
/// number field).
class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({super.key, required this.product, this.formatter});

  final Product product;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeader(
      seedForAvatar: product.id,
      displayName: product.productKey.isEmpty
          ? context.tr('no_name_fallback')
          : product.productKey,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isDeleted: product.isDeleted,
      isArchived: product.archivedAt != null,
      isDirty: product.isDirty,
      formatter: formatter,
    );
  }
}
