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
    _dispose ??= context.read<Services>().unsavedChangesGuard.register(
      isDirty: widget.isDirty,
      source: widget.source,
      onDiscard: widget.onDiscard,
    );
  }

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
