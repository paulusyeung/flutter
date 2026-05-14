import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense_category.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Action set surfaced for an expense category. Mirrors the standard
/// minimum surface — edit / archive / restore / delete / purge — since
/// categories are too small to support clone or cross-entity navigation.
enum ExpenseCategoryAction { edit, archive, restore, delete, purge }

/// Single source of truth for what ExpenseCategory actions exist and what
/// they do. The list-row popup, detail header, and edit screen overflow
/// menu all consume this — mirrors `ProductActions` / `CompanyGatewayActions`.
class ExpenseCategoryActions {
  ExpenseCategoryActions._();

  static List<EntityActionItem<ExpenseCategoryAction>> itemsFor(
    BuildContext context,
    ExpenseCategory category,
    void Function(ExpenseCategoryAction) onTap,
  ) {
    final canArchive = category.archivedAt == null && !category.isDeleted;
    final canRestore = category.archivedAt != null || category.isDeleted;
    // Purge is admin/owner-only — mirrors the Product/Gateway gate so the
    // action only renders when the user could plausibly run it.
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    return [
      editActionItem(
        context: context,
        kind: ExpenseCategoryAction.edit,
        onTap: () => onTap(ExpenseCategoryAction.edit),
      ),
      ?archiveActionItem(
        context: context,
        kind: ExpenseCategoryAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(ExpenseCategoryAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: ExpenseCategoryAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(ExpenseCategoryAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: ExpenseCategoryAction.delete,
        canDelete: !category.isDeleted,
        onTap: () => onTap(ExpenseCategoryAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: ExpenseCategoryAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(ExpenseCategoryAction.purge),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    ExpenseCategory category,
    ExpenseCategoryAction action,
  ) async {
    switch (action) {
      case ExpenseCategoryAction.edit:
        context.go('/settings/expense_categories/${category.id}/edit');
      case ExpenseCategoryAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'expense_category',
          op: () => services.expenseCategories.archive(
            companyId: companyId,
            id: category.id,
          ),
        );
      case ExpenseCategoryAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'expense_category',
          op: () => services.expenseCategories.restore(
            companyId: companyId,
            id: category.id,
          ),
        );
      case ExpenseCategoryAction.delete:
        if (category.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'expense_category',
          op: () => services.expenseCategories.delete(
            companyId: companyId,
            id: category.id,
          ),
        );
      case ExpenseCategoryAction.purge:
        if (category.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.purge(
          context: context,
          wireName: 'expense_category',
          op: () => services.expenseCategories.purge(
            companyId: companyId,
            id: category.id,
          ),
        );
        // Leave the detail screen before the dispatcher hard-deletes the
        // local row; otherwise the scaffold flips to its empty state and
        // the user reads "category not found" right after purge.
        if (context.mounted) context.go('/settings/expense_categories');
    }
  }
}
