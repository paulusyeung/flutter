import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/dialogs/discard_changes_dialog.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_scope.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Top-level chrome for any settings page backed by a
/// [SettingsDraftViewModel] subclass (or any [SettingsDraftHost]
/// implementation). Wires:
///
/// * `MultiProvider` exposing the VM as both `ChangeNotifierProvider<V>` and
///   `Provider<SettingsDraftHost>` (so override widgets bind via the
///   interface).
/// * `UnsavedChangesScope` + `PopScope` with the discard-on-exit dialog.
/// * `SettingsScreenScaffold` with title, Save button (state-driven from
///   the VM), caller's `extraActions`, and optional `bottom` (e.g. a
///   [TabBar] for tabbed pages).
/// * Spinner while loading; the inline [_LoadErrorBanner] above the body
///   when `viewModel.loadError` is set.
/// * `FormSaveScope` wrapping the body so Enter on single-line fields fires
///   the same save callback the Save button uses.
/// * Success / error toast via [Notify] on save.
///
/// The [SettingsLevelController] is read from the ambient `Provider` chain
/// (mounted once in `main.dart` and held on `Services.settingsLevel`), not
/// created per-page — that's the only way the override widgets and the
/// scope banner can stay in sync with a level set by another part of the
/// app (e.g. the client-detail "Settings" action).
///
/// New settings pages compose: own a VM, build a body widget, return
/// `SettingsPageScaffold(titleKey: …, viewModel: vm, body: …)`. The tabbed
/// case (Company Details) supplies `bottom: TabBar(…)` and `body:
/// TabBarView(…)` — the scaffold is shape-agnostic.
class SettingsPageScaffold<V extends SettingsDraftHost>
    extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.titleKey,
    required this.viewModel,
    required this.body,
    this.bottom,
    this.extraActions = const <Widget>[],
  });

  /// Localization key for the AppBar title.
  final String titleKey;

  /// Per-page view-model. Caller owns lifecycle — the scaffold takes it
  /// by `Provider.value` and never disposes it.
  final V viewModel;

  /// Page body. Receives access to `viewModel` (typed) and
  /// `SettingsDraftHost` via Provider. Wrap form content in
  /// [SettingsFormShell] for the standard padding + width constraints.
  final Widget body;

  /// Optional AppBar bottom (typically a [TabBar] for tabbed pages).
  final PreferredSizeWidget? bottom;

  /// Additional AppBar action widgets rendered to the right of the Save
  /// button.
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<V>.value(value: viewModel),
        // Expose the same VM as the abstract host so override widgets bind
        // via the interface, not the concrete subclass type. Skip when V
        // already IS the host (CascadeSettingsScaffold's case) — registering
        // the same provider type twice just shadows the outer.
        if (V != SettingsDraftHost)
          ChangeNotifierProvider<SettingsDraftHost>.value(value: viewModel),
      ],
      child: _SettingsPageBody(
        titleKey: titleKey,
        viewModel: viewModel,
        body: body,
        bottom: bottom,
        extraActions: extraActions,
      ),
    );
  }
}

class _SettingsPageBody extends StatelessWidget {
  const _SettingsPageBody({
    required this.titleKey,
    required this.viewModel,
    required this.body,
    required this.bottom,
    required this.extraActions,
  });

  final String titleKey;
  final SettingsDraftHost viewModel;
  final Widget body;
  final PreferredSizeWidget? bottom;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      isDirty: () => viewModel.isDirty,
      source: viewModel,
      onDiscard: viewModel.reset,
      child: ListenableBuilder(
        // PopScope.canPop is read at frame-build time, so the scope needs
        // to rebuild whenever the dirty state flips. Listen against the VM
        // directly rather than `context.watch` so the rest of the chrome
        // doesn't rebuild on every notify.
        listenable: viewModel,
        builder: (context, _) {
          return PopScope(
            canPop: !viewModel.isDirty,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              if (!viewModel.isDirty) return;
              final discard = await showDiscardChangesDialog(context);
              if (!discard) return;
              viewModel.reset();
              if (!context.mounted) return;
              await Navigator.of(context).maybePop();
            },
            child: SettingsScreenScaffold(
              titleKey: titleKey,
              actions: [
                _SaveButton(viewModel: viewModel),
                const SizedBox(width: 8),
                ...extraActions,
              ],
              bottom: bottom,
              body: ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) {
                  // Hold the spinner until the draft is ready too. Each
                  // `SettingsDraftViewModel` flips `isLoaded=true` on the
                  // first stream emission but the typed `draft` doesn't
                  // populate for one more frame on the very first paint of
                  // a tabbed shell — without this guard each tab body had
                  // to repeat `if (vm.draft == null) return SizedBox`.
                  // Non-`SettingsDraftViewModel` hosts (e.g. the client
                  // variant) skip this check.
                  final draftReady =
                      viewModel is! SettingsDraftViewModel ||
                      (viewModel as SettingsDraftViewModel).draft != null;
                  if (!viewModel.isLoaded || !draftReady) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final err = viewModel.loadError;
                  final canSave = viewModel.isDirty && !viewModel.isSaving;
                  final wrapped = FormSaveScope(
                    enabled: canSave,
                    onSubmit: () => runSettingsSave(context, viewModel),
                    child: body,
                  );
                  if (err != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoadErrorBanner(message: err),
                        Expanded(child: wrapped),
                      ],
                    );
                  }
                  return wrapped;
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Save the [viewModel]'s draft and surface the outcome as a [Notify] toast.
/// Shared by the Save button and `FormSaveScope.onSubmit` so Enter and tap
/// take the same path.
@visibleForTesting
Future<void> runSettingsSave(
  BuildContext context,
  SettingsDraftHost viewModel,
) async {
  final successText = context.tr('saved_settings');
  final errorFallback = context.tr('error_refresh_page');
  final result = await viewModel.save();
  if (!context.mounted) return;
  if (result != null) {
    Notify.success(context, successText);
    return;
  }
  // The VM stashes the raw exception text on `submitError`; surface it as
  // the detail line so the user (or dev tester) sees what actually broke
  // instead of a generic banner.
  Notify.error(context, errorFallback, detail: viewModel.submitError);
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.viewModel});

  final SettingsDraftHost viewModel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final canSave = viewModel.isDirty && !viewModel.isSaving;
        return TextButton(
          onPressed: canSave ? () => runSettingsSave(context, viewModel) : null,
          style: TextButton.styleFrom(foregroundColor: tokens.accent),
          child: viewModel.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('save')),
        );
      },
    );
  }
}

/// Inline error banner shown above the body when `viewModel.loadError` is
/// set. The form below it still renders against whatever subset of the
/// settings the typed parse could recover, so the user can read + edit the
/// parts that work while the developer chases down the bad field.
class _LoadErrorBanner extends StatelessWidget {
  const _LoadErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('error_refresh_page'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SelectableText(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: context.tr('copy'),
              color: theme.colorScheme.onErrorContainer,
              onPressed: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final copiedText = context.tr('copied_to_clipboard');
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    Notify.success(context, copiedText);
  }
}
