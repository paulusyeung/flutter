import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/domain/entity_type.dart';

/// Zero-chrome widget that records "the user looked at this entity" into
/// [Services.recentlyViewed], then renders [child] untouched.
///
/// Dropped into the shared [EntityDetailHeaderHost] (and the billing-doc
/// detail headers, which don't use that host) so every entity detail screen
/// feeds the command palette's "Recent" group from one place. Records on
/// first build and again whenever the (type, id) pair changes — the same
/// header instance is reused as the master-detail pane pages between rows,
/// so a plain `initState` would miss prev/next navigation. The controller
/// de-dupes + debounces, so re-recording the same entity on rebuild is cheap.
class RecentVisitRecorder extends StatefulWidget {
  const RecentVisitRecorder({
    super.key,
    required this.type,
    required this.id,
    required this.label,
    required this.child,
  });

  final EntityType type;
  final String id;
  final String label;
  final Widget child;

  @override
  State<RecentVisitRecorder> createState() => _RecentVisitRecorderState();
}

class _RecentVisitRecorderState extends State<RecentVisitRecorder> {
  @override
  void initState() {
    super.initState();
    _record();
  }

  @override
  void didUpdateWidget(RecentVisitRecorder old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type ||
        old.id != widget.id ||
        old.label != widget.label) {
      _record();
    }
  }

  void _record() {
    if (widget.id.isEmpty) return;
    // Post-frame: recording mutates the controller (notifyListeners), which
    // must not run during this subtree's build/layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<Services>().recentlyViewed.record(
        type: widget.type,
        id: widget.id,
        label: widget.label,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
