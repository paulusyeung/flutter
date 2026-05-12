import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Top-of-form banner that surfaces when a prior save was rejected by the
/// server (typically a 422). Renders nothing when the VM has no pending
/// field errors. Pair with `EntityEditField` (or any field that reads
/// `vm.fieldErrorFor(apiKey)`) which already surfaces the per-field text.
///
/// The "Discard failed save" action calls back into [onDiscard] so the
/// caller can delete the dead outbox row from the screen layer (where the
/// DAO is in scope) and then [GenericEditViewModel.clearFailedSync] to
/// drop the in-memory link.
class SaveFailedBanner extends StatelessWidget {
  const SaveFailedBanner({
    required this.vm,
    required this.onDiscard,
    super.key,
  });

  final GenericEditViewModel<dynamic> vm;

  /// Invoked when the user taps "Discard failed save". Should delete the
  /// dead outbox row (`vm.deadOutboxRowId`) and call [vm.clearFailedSync].
  final Future<void> Function() onDiscard;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.fieldErrors.isEmpty) return const SizedBox.shrink();
        final tokens = context.inTheme;
        return Material(
          color: tokens.overdueSoft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: InSpacing.lg,
              vertical: InSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: tokens.overdue),
                const SizedBox(width: InSpacing.sm),
                Expanded(
                  child: Text(
                    context.tr('save_rejected_banner'),
                    style: TextStyle(color: tokens.ink2, fontSize: 13),
                  ),
                ),
                const SizedBox(width: InSpacing.sm),
                // The Discard button appears for any populated fieldErrors —
                // even when the VM hasn't yet loaded a dead-row id (fresh
                // 422 in the same session). The screen's discard handler
                // does the fallback dao lookup if needed.
                TextButton(
                  onPressed: onDiscard,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 36),
                    foregroundColor: tokens.overdue,
                  ),
                  child: Text(context.tr('discard_failed_save')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
