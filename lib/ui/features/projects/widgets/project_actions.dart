import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/billing/line_item_type.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/standard_entity_action_items.dart';
import 'package:admin/ui/core/detail/standard_entity_actions.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart';
import 'package:admin/ui/features/invoices/view_models/invoice_edit_view_model.dart';
import 'package:admin/ui/features/invoices/widgets/detail/run_template_dialog.dart';
import 'package:admin/ui/features/quotes/view_models/quote_edit_view_model.dart';

/// Action set surfaced for a project. Mirrors `ProductAction` — all
/// branches are wired.
enum ProjectAction {
  edit,
  newGroup,
  newTask,
  newInvoice,
  newQuote,
  newExpense,
  invoiceProject,
  runTemplate,
  clone,
  archive,
  restore,
  delete,
}

class ProjectActions {
  ProjectActions._();

  /// Actions the old admin-portal hid on a brand-new (unsaved) record.
  /// Fed to `filterForEditScreen` so the create screen drops clone /
  /// archive / restore / delete.
  static bool isLifecycle(ProjectAction action) {
    switch (action) {
      case ProjectAction.clone:
      case ProjectAction.archive:
      case ProjectAction.restore:
      case ProjectAction.delete:
        return true;
      default:
        return false;
    }
  }

  static List<EntityActionItem<ProjectAction>> itemsFor(
    BuildContext context,
    Project project,
    void Function(ProjectAction) onTap,
  ) {
    final canArchive = project.archivedAt == null && !project.isDeleted;
    final canRestore = project.archivedAt != null || project.isDeleted;
    final me = context.read<Services>().auth.session.value?.currentCompany;

    return [
      editActionItem(
        context: context,
        kind: ProjectAction.edit,
        onTap: () => onTap(ProjectAction.edit),
      ),
      // Wired in Phase 3.5 via the Tasks card "Add task" affordance, but
      // also surfaced here so the action menu mirrors React/admin-portal.
      // The four "New X" items collapse into one fly-out submenu (like
      // Client) so they stop burying the rest of the actions menu.
      if ((me?.moduleEnabled(EntityType.task) ?? false) ||
          (me?.moduleEnabled(EntityType.invoice) ?? false) ||
          (me?.moduleEnabled(EntityType.quote) ?? false) ||
          (me?.moduleEnabled(EntityType.expense) ?? false))
        newGroupActionItem(
          context: context,
          kind: ProjectAction.newGroup,
          children: [
            if (me?.moduleEnabled(EntityType.task) ?? false)
              EntityActionItem(
                kind: ProjectAction.newTask,
                icon: Icons.task_outlined,
                label: context.tr('new_task'),
                enabled: true,
                onTap: () => onTap(ProjectAction.newTask),
              ),
            if (me?.moduleEnabled(EntityType.invoice) ?? false)
              EntityActionItem(
                kind: ProjectAction.newInvoice,
                icon: Icons.receipt_long_outlined,
                label: context.tr('new_invoice'),
                enabled: !project.id.startsWith('tmp_'),
                onTap: () => onTap(ProjectAction.newInvoice),
              ),
            if (me?.moduleEnabled(EntityType.quote) ?? false)
              EntityActionItem(
                kind: ProjectAction.newQuote,
                icon: Icons.request_quote_outlined,
                label: context.tr('new_quote'),
                enabled: !project.id.startsWith('tmp_'),
                onTap: () => onTap(ProjectAction.newQuote),
              ),
            if (me?.moduleEnabled(EntityType.expense) ?? false)
              EntityActionItem(
                kind: ProjectAction.newExpense,
                icon: Icons.account_balance_wallet_outlined,
                label: context.tr('new_expense'),
                enabled: !project.id.startsWith('tmp_'),
                onTap: () => onTap(ProjectAction.newExpense),
              ),
          ],
        ),
      if (me?.moduleEnabled(EntityType.invoice) ?? false)
        EntityActionItem(
          kind: ProjectAction.invoiceProject,
          icon: Icons.outbox_outlined,
          label: context.tr('invoice_project'),
          enabled: !project.id.startsWith('tmp_'),
          onTap: () => onTap(ProjectAction.invoiceProject),
        ),
      EntityActionItem(
        kind: ProjectAction.runTemplate,
        icon: Icons.auto_awesome_outlined,
        label: context.tr('run_template'),
        enabled: !project.id.startsWith('tmp_'),
        onTap: () => onTap(ProjectAction.runTemplate),
      ),
      EntityActionItem(
        kind: ProjectAction.clone,
        icon: Icons.copy_outlined,
        label: context.tr('clone_project'),
        enabled: true,
        onTap: () => onTap(ProjectAction.clone),
      ),
      ?archiveActionItem(
        context: context,
        kind: ProjectAction.archive,
        canArchive: canArchive,
        onTap: () => onTap(ProjectAction.archive),
      ),
      ?restoreActionItem(
        context: context,
        kind: ProjectAction.restore,
        canRestore: canRestore,
        onTap: () => onTap(ProjectAction.restore),
      ),
      ?deleteActionItem(
        context: context,
        kind: ProjectAction.delete,
        canDelete: !project.isDeleted,
        onTap: () => onTap(ProjectAction.delete),
      ),
    ];
  }

  static Future<void> dispatch(
    BuildContext context,
    Services services,
    String companyId,
    Project project,
    ProjectAction action,
  ) async {
    switch (action) {
      case ProjectAction.newGroup:
        break; // Submenu parent — never dispatched; children carry the action.
      case ProjectAction.edit:
        goEntityEdit(context, '/projects', project.id);
      case ProjectAction.newTask:
        context.go('/tasks/new?project=${project.id}');
      case ProjectAction.archive:
        await StandardEntityActions.archive(
          context: context,
          wireName: 'project',
          op: () =>
              services.projects.archive(companyId: companyId, id: project.id),
        );
      case ProjectAction.restore:
        await StandardEntityActions.restore(
          context: context,
          wireName: 'project',
          op: () =>
              services.projects.restore(companyId: companyId, id: project.id),
        );
      case ProjectAction.clone:
        // Strip identity-bearing fields so the create form opens with a
        // truly new draft seeded from the source project.
        final draft = project.copyWith(
          id: '',
          number: '',
          archivedAt: null,
          isDeleted: false,
          isDirty: false,
          currentHours: 0,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
        context.go('/projects/new', extra: draft);
      case ProjectAction.delete:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        await StandardEntityActions.delete(
          context: context,
          wireName: 'project',
          op: () =>
              services.projects.delete(companyId: companyId, id: project.id),
        );
      case ProjectAction.newInvoice:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/invoices/new',
          extra: emptyInvoice().copyWith(
            clientId: project.clientId,
            projectId: project.id,
          ),
        );
      case ProjectAction.newQuote:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/quotes/new',
          extra: emptyQuote().copyWith(
            clientId: project.clientId,
            projectId: project.id,
          ),
        );
      case ProjectAction.newExpense:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        context.go(
          '/expenses/new',
          extra: emptyExpense().copyWith(
            clientId: project.clientId,
            projectId: project.id,
          ),
        );
      case ProjectAction.invoiceProject:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final tasks = await services.tasks
            .watchForProject(companyId: companyId, projectId: project.id)
            .first;
        final lineItems = <LineItem>[];
        for (final t in tasks) {
          if (t.id.startsWith('tmp_')) continue;
          final seconds = t.totalDuration().inSeconds;
          if (seconds == 0) continue;
          final hours = (Decimal.fromInt(seconds) / Decimal.fromInt(3600))
              .toDecimal(scaleOnInfinitePrecision: 4);
          lineItems.add(
            emptyLineItem().copyWith(
              typeId: LineItemType.task,
              taskId: t.id,
              notes: t.description,
              quantity: hours,
              cost: t.rate,
            ),
          );
        }
        if (!context.mounted) return;
        if (lineItems.isEmpty) {
          Notify.info(context, context.tr('no_billable_tasks'));
          return;
        }
        context.go(
          '/invoices/new',
          extra: emptyInvoice().copyWith(
            clientId: project.clientId,
            projectId: project.id,
            lineItems: lineItems,
          ),
        );
      case ProjectAction.runTemplate:
        if (project.id.startsWith('tmp_')) {
          Notify.error(context, context.tr('sync_first'));
          return;
        }
        final templateId = await showRunTemplateDialog(context);
        if (templateId == null || !context.mounted) return;
        await services.projects.runTemplate(
          companyId: companyId,
          id: project.id,
          templateId: templateId,
        );
        if (!context.mounted) return;
        Notify.success(context, context.tr('template_queued'));
    }
  }
}
