import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/view_models/task_edit_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/edit/task_edit_times_section.dart';
import 'package:admin/utils/formatting.dart';

/// Form body for the Task edit / create screen. Composes the identity
/// fields, the time-log section (`TaskEditTimesSection`), and the custom
/// fields panel. Renders the invoiced-lockout banner at the top when
/// `vm.draft.isInvoiced`.
class TaskEditLayout extends StatelessWidget {
  const TaskEditLayout({super.key, required this.vm});

  final TaskEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final locked = vm.draft.isInvoiced;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(InSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (locked) ...[
                    _LockoutBanner(),
                    const SizedBox(height: InSpacing.lg),
                  ],
                  _IdentitySection(vm: vm, locked: locked),
                  const SizedBox(height: InSpacing.lg),
                  TaskEditTimesSection(vm: vm, locked: locked),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LockoutBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.all(InSpacing.md),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: tokens.ink),
          const SizedBox(width: InSpacing.sm),
          Expanded(
            child: Text(
              context.tr('task_invoiced_locked'),
              style: TextStyle(color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.vm, required this.locked});
  final TaskEditViewModel vm;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      padding: const EdgeInsets.all(InSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: vm.draft.description,
            enabled: !locked,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: context.tr('description')),
            onChanged: vm.setDescription,
          ),
          const SizedBox(height: InSpacing.md),
          TextFormField(
            initialValue: vm.draft.clientId,
            enabled: !locked,
            decoration: InputDecoration(labelText: context.tr('client')),
            onChanged: vm.setClientId,
          ),
          const SizedBox(height: InSpacing.md),
          TextFormField(
            initialValue: vm.draft.statusId,
            enabled: !locked,
            decoration: InputDecoration(labelText: context.tr('status')),
            onChanged: vm.setStatusId,
          ),
          const SizedBox(height: InSpacing.md),
          TextFormField(
            initialValue: decimalInputText(vm.draft.rate),
            enabled: !locked,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: context.tr('rate')),
            onChanged: vm.setRate,
          ),
        ],
      ),
    );
  }
}
