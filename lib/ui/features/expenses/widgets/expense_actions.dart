import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Action set surfaced for an expense. Mirrors `ProjectAction` — wired
/// branches do work; placeholder branches (`invoiceExpense`, `addToInvoice`,
/// `runTemplate`) render disabled with a "coming soon" tooltip until
/// Invoice ships in a follow-up PR.
enum ExpenseAction {
  edit,
  clone,
  cloneToRecurring,
  invoiceExpense,
  addToInvoice,
  runTemplate,
  addComment,
  archive,
  restore,
  delete,
  purge,
}

class ExpenseActions {
  ExpenseActions._();

  static List<EntityActionItem<ExpenseAction>> itemsFor(
    BuildContext context,
    Expense expense,
    void Function(ExpenseAction) onTap,
  ) {
    final canArchive = expense.archivedAt == null && !expense.isDeleted;
    final canRestore = expense.archivedAt != null || expense.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;
    final canPurge = (me?.isAdmin ?? false) || (me?.isOwner ?? false);

    return [
      editActionItem(
        context: context,
        kind: ExpenseAction.edit,
        onTap: () => onTap(ExpenseAction.edit),
      ),
      EntityActionItem(
        kind: ExpenseAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_expense'),
        enabled: true,
        onTap: () => onTap(ExpenseAction.clone),
      ),
      EntityActionItem(
        kind: ExpenseAction.cloneToRecurring,
        icon: Icons.event_repeat_outlined,
        label: context.tr('clone_to_recurring'),
        enabled: true,
        onTap: () => onTap(ExpenseAction.cloneToRecurring),
      ),
      EntityActionItem.disabled(
        kind: ExpenseAction.invoiceExpense,
        icon: Icons.outbox_outlined,
        label: context.tr('invoice_expense'),
      ),
      EntityActionItem.disabled(
        kind: ExpenseAction.addToInvoice,
        icon: Icons.playlist_add_outlined,
        label: context.tr('add_to_invoice'),
      ),
      EntityActionItem.disabled(
        kind: ExpenseAction.runTemplate,
        icon: Icons.auto_awesome_outlined,
        label: context.tr('run_template'),
      ),
      EntityActionItem(
        kind: ExpenseAction.addComment,
        icon: Icons.chat_bubble_outline,
        label: context.tr('add_comment'),
        enabled: true,
        onTap: () => onTap(ExpenseAction.addComment),
      ),
      ?archiveActionItem(
        context: context,
        kind: ExpenseAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(ExpenseAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: ExpenseAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(ExpenseAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: ExpenseAction.delete,
        canDelete: !expense.isDeleted,
        onTap: () => onTap(ExpenseAction.delete),
      ),
      ?purgeActionItem(
        context: context,
        kind: ExpenseAction.purge,
        canPurge: canPurge,
        onTap: () => onTap(ExpenseAction.purge),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Expense expense,
    ExpenseAction action,
  ) async {
    switch (action) {
      case ExpenseAction.edit:
        context.go('/expenses/${expense.id}/edit');
      case ExpenseAction.clone:
        final draft = expense.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          invoiceId: '',
          paymentDate: null,
          paymentTypeId: '',
          transactionReference: '',
          transactionId: '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/expenses/new', extra: draft);
      case ExpenseAction.cloneToRecurring:
        // Recurring Expense lands later in this PR / a follow-up. Hand the
        // draft over via `state.extra` so the recurring create form can
        // seed itself the same way Product's clone path does.
        final draft = expense.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          invoiceId: '',
          paymentDate: null,
          paymentTypeId: '',
          transactionReference: '',
          transactionId: '',
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/recurring_expenses/new', extra: draft);
      case ExpenseAction.addComment:
        await _promptAddComment(context, services, companyId, expense);
      case ExpenseAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'expense',
          op: () =>
              services.expenses.archive(companyId: companyId, id: expense.id),
        );
      case ExpenseAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'expense',
          op: () =>
              services.expenses.restore(companyId: companyId, id: expense.id),
        );
      case ExpenseAction.delete:
        if (expense.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'expense',
          op: () =>
              services.expenses.delete(companyId: companyId, id: expense.id),
        );
      case ExpenseAction.purge:
        if (expense.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.purge(
          context: context,
          wireName: 'expense',
          op: () =>
              services.expenses.purge(companyId: companyId, id: expense.id),
        );
        if (context.mounted) context.go('/expenses');
      case ExpenseAction.invoiceExpense:
      case ExpenseAction.addToInvoice:
      case ExpenseAction.runTemplate:
        // Placeholders — the action items render disabled with a
        // `coming_soon` tooltip via `EntityDetailActionsRow`; the switch
        // branches exist so future wiring is mechanical.
        break;
    }
  }
}

Future<void> _promptAddComment(
  BuildContext context,
  Services services,
  String companyId,
  Expense expense,
) async {
  final controller = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(ctx.tr('add_comment')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: ctx.tr('notes')),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 40),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.tr('cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: () =>
                    Navigator.of(ctx).pop(controller.text.trim()),
                child: Text(ctx.tr('save')),
              ),
            ],
          ),
        ],
      );
    },
  );
  if (text == null || text.isEmpty) return;
  await services.expenses.addComment(
    companyId: companyId,
    expenseId: expense.id,
    text: text,
  );
}
