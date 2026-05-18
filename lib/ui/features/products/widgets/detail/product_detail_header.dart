import 'package:flutter/widgets.dart';

import 'package:admin/data/models/domain/product.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header_host.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity wrapper over [EntityDetailHeaderHost]. Uses `productKey` as
/// the display name (falling back to `no_name_fallback`) and renders no
/// `#<number>` subtitle — products don't carry a separate number field.
class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({super.key, required this.product, this.formatter});

  final Product product;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeaderHost<Product>(
      entity: product,
      entityType: EntityType.product,
      recordId: product.id,
      formatter: formatter,
      project: (context, p) => EntityHeaderFields(
        seedForAvatar: p.id,
        displayName: p.productKey.isEmpty
            ? context.tr('no_name_fallback')
            : p.productKey,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        isDeleted: p.isDeleted,
        isArchived: p.archivedAt != null,
        isDirty: p.isDirty,
      ),
    );
  }
}
