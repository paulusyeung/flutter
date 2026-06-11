import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';

/// Widget wrapper that registers its editor with [UnsavedChangesGuard] on
/// mount and unregisters on unmount. Use it on any screen whose ViewModel
/// exposes an `isDirty` getter — the guard's [confirmIfDirty] then includes
/// this editor in its global dirty check.
///
/// Example:
///
/// ```dart
/// UnsavedChangesScope(
///   isDirty: () => vm.isDirty,
///   source: vm,
///   onDiscard: vm.reset,
///   child: Scaffold(...),
/// );
/// ```
class UnsavedChangesScope extends StatefulWidget {
  const UnsavedChangesScope({
    required this.isDirty,
    required this.source,
    required this.child,
    this.onDiscard,
    super.key,
  });

  final bool Function() isDirty;
  final Listenable source;
  final VoidCallback? onDiscard;
  final Widget child;

  @override
  State<UnsavedChangesScope> createState() => _UnsavedChangesScopeState();
}

class _UnsavedChangesScopeState extends State<UnsavedChangesScope> {
  VoidCallback? _dispose;

  @override
  void initState() {
    super.initState();
    // Defer to didChangeDependencies so we can read Services from context.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dispose ??= _register();
  }

  @override
  void didUpdateWidget(UnsavedChangesScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The host swapped the backing VM in place (e.g.
    // `SettingsCompanyScopedHost` rebuilding its ViewModel on a company
    // switch — no key in that chain, so this State is reused). Without
    // re-registering, the guard stays bound to the DISPOSED old VM, whose
    // captured `isDirty` reads frozen-clean state: every post-swap edit
    // then discards on navigation without the "unsaved changes" prompt.
    if (!identical(oldWidget.source, widget.source)) {
      _dispose?.call();
      _dispose = _register();
    }
  }

  VoidCallback _register() =>
      context.read<Services>().unsavedChangesGuard.register(
        isDirty: widget.isDirty,
        source: widget.source,
        onDiscard: widget.onDiscard,
      );

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
