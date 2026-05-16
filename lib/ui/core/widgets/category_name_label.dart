import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Resolves the expense-category name from the local Drift cache and
/// renders it as a `Text`. Falls back to the raw `categoryId` while the
/// watch is empty (first sync hasn't landed) or when the category isn't
/// in the cache.
///
/// Mirrors `VendorNameLabel` — Drift dedupes identical watch queries so
/// N rows for the same category share one underlying subscription.
class CategoryNameLabel extends StatelessWidget {
  const CategoryNameLabel({
    super.key,
    required this.categoryId,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.link = false,
  });

  final String categoryId;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  /// When true the resolved name renders as a hover-underlined link to
  /// the expense category's full-screen view. Off by default.
  final bool link;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    if (categoryId.isEmpty) {
      return Text(
        '—',
        style: style ?? TextStyle(fontSize: 13, color: tokens.ink3),
      );
    }
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return _text(context, categoryId);
    }
    return StreamBuilder<ExpenseCategory?>(
      stream: services.expenseCategories.watch(
        companyId: companyId,
        id: categoryId,
      ),
      builder: (context, snapshot) {
        final category = snapshot.data;
        final name = category == null || category.name.isEmpty
            ? categoryId
            : category.name;
        return _text(context, name);
      },
    );
  }

  Widget _text(BuildContext context, String text) => linkOrText(
    link: link,
    label: text,
    onTap: link
        ? () => goEntityFullDetail(
            context,
            '/settings/expense_categories',
            categoryId,
          )
        : null,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
  );
}
