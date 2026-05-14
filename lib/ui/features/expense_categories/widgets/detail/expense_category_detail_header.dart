import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';
import 'package:admin/utils/formatting.dart';

/// Per-entity header for the ExpenseCategory detail screen. Maps the
/// category's domain fields into the shared [EntityDetailHeader] slots —
/// no `#number` subtitle, no extra status pills (categories carry only the
/// standard archived/deleted/dirty trio, which the host already renders).
class ExpenseCategoryDetailHeader extends StatelessWidget {
  const ExpenseCategoryDetailHeader({
    super.key,
    required this.category,
    this.formatter,
  });

  final ExpenseCategory category;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    return EntityDetailHeader(
      seedForAvatar: category.name.isEmpty ? category.id : category.name,
      displayName: category.name.isEmpty
          ? context.tr('no_name_fallback')
          : category.name,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      isDeleted: category.isDeleted,
      isArchived: category.archivedAt != null,
      isDirty: category.isDirty,
      formatter: formatter,
    );
  }
}
