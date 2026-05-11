import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/features/shell/widgets/company_picker.dart';

/// Mounts a [CompanyPicker] in the right form factor for the current layout.
///
/// On wide layouts, the picker pops up as a positioned overlay anchored to
/// [anchorKey]'s render box (top-left aligned just under it). When no
/// anchorKey is provided — e.g. for the ⌘K shortcut — the picker centres
/// itself in the viewport.
///
/// On narrow layouts the picker comes up as a scrollable bottom sheet that
/// respects the on-screen keyboard.
Future<void> showCompanyPicker(BuildContext context, {GlobalKey? anchorKey}) {
  final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
  if (!isWide) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CompanyPicker(fillWidth: true),
          ),
        ),
      ),
    );
  }

  Offset? topLeft;
  Size? anchorSize;
  if (anchorKey?.currentContext != null) {
    final box = anchorKey!.currentContext!.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      topLeft = box.localToGlobal(Offset.zero);
      anchorSize = box.size;
    }
  }

  return Navigator.of(context).push(
    _CompanyPickerRoute(
      topLeft: topLeft,
      anchorSize: anchorSize,
      // Snapshot the localized "Dismiss" string at construction time —
      // PopupRoute's `barrierLabel` getter has no BuildContext.
      barrierLabelText: context.tr('dismiss'),
    ),
  );
}

class _CompanyPickerRoute extends PopupRoute<void> {
  _CompanyPickerRoute({
    this.topLeft,
    this.anchorSize,
    required this.barrierLabelText,
  });

  final Offset? topLeft;
  final Size? anchorSize;
  final String barrierLabelText;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => barrierLabelText;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _PositionedPicker(topLeft: topLeft, anchorSize: anchorSize);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

class _PositionedPicker extends StatelessWidget {
  const _PositionedPicker({required this.topLeft, required this.anchorSize});

  final Offset? topLeft;
  final Size? anchorSize;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const pickerWidth = 320.0;
    const margin = 8.0;
    double left;
    double top;
    if (topLeft != null && anchorSize != null) {
      // Align the picker's top-left with the anchor's top-left, shifted
      // right by the anchor's width so the popup sits to the right of the
      // sidebar header. Then clamp inside the viewport.
      left = topLeft!.dx + anchorSize!.width + margin;
      top = topLeft!.dy;
    } else {
      // ⌘K with no anchor — centre horizontally, offset a bit from the top.
      left = (screen.width - pickerWidth) / 2;
      top = 80;
    }
    final maxHeight = screen.height - top - margin;
    left = left.clamp(margin, screen.width - pickerWidth - margin);
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top.clamp(margin, screen.height - 160),
          width: pickerWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: const CompanyPicker(),
          ),
        ),
      ],
    );
  }
}
