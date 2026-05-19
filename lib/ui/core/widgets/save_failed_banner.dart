import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Top-of-form banner that surfaces when a save was rejected — either by
/// the server (a 422 / dead outbox row) or by client-side [validate]
/// (`vm.localValidationOnly`, no row ever written). Renders nothing when
/// the VM has no pending field errors. Pair with `EntityEditField` (or any
/// field that reads `vm.fieldErrorFor(apiKey)`) which already surfaces the
/// per-field text. The local-only case shows softer copy and hides the
/// "Discard failed save" action (there is no outbox row to discard).
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
        // A client-side validation block never wrote a local row or an
        // outbox mutation, so the server-rejection framing + the "discard
        // failed save" affordance (which deletes a dead outbox row) make no
        // sense. Use softer copy and drop the button. A real server 422 —
        // including a fresh in-session one with no dead-row id yet — keeps
        // both; the screen's discard handler does the fallback dao lookup.
        final localOnly = vm.localValidationOnly;
        return Material(
          color: tokens.overdueSoft,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: InSpacing.lg(context),
              vertical: InSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: tokens.overdue),
                const SizedBox(width: InSpacing.sm),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      context.tr(
                        localOnly
                            ? 'please_fix_highlighted_fields'
                            : 'save_rejected_banner',
                      ),
                      style: TextStyle(color: tokens.ink2, fontSize: 13),
                    ),
                  ),
                ),
                if (!localOnly) ...[
                  const SizedBox(width: InSpacing.sm),
                  TextButton(
                    onPressed: onDiscard,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      foregroundColor: tokens.overdue,
                    ),
                    child: Text(context.tr('discard_failed_save')),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
