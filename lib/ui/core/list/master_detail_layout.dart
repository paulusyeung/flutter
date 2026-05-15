import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart' show selectedIdFromRoute;
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';

/// Lightweight shared state between `MasterDetailLayout` and the list
/// scaffold mounted inside it. The list scaffold writes the visible
/// item ids + the URL-derived `selectedId` here on every rebuild; the
/// pane's keyboard shortcuts (`J` / `K` / `↓` / `↑`) read it to compute
/// the next / previous row to navigate to.
///
/// Why a controller instead of a callback: the layout doesn't have
/// access to the list's VM (the list is an opaque widget), and the
/// scaffold doesn't know about the layout's keyboard handlers. A
/// shared object pushed into the InheritedWidget tree lets each side
/// touch only what it needs.
class MasterDetailNavController {
  String? _selectedId;
  List<String> _itemIds = const <String>[];

  void update({
    required String? selectedId,
    required List<String> itemIds,
  }) {
    _selectedId = selectedId;
    _itemIds = itemIds;
  }

  String? nextId() {
    if (_itemIds.isEmpty) return null;
    if (_selectedId == null) return _itemIds.first;
    final i = _itemIds.indexOf(_selectedId!);
    if (i < 0 || i >= _itemIds.length - 1) return null;
    return _itemIds[i + 1];
  }

  String? prevId() {
    if (_itemIds.isEmpty) return null;
    if (_selectedId == null) return _itemIds.last;
    final i = _itemIds.indexOf(_selectedId!);
    if (i <= 0) return null;
    return _itemIds[i - 1];
  }
}

/// InheritedWidget that publishes the layout's
/// [MasterDetailNavController] to descendants without triggering
/// rebuilds — descendants read the controller object once and call
/// methods on it; the controller's internal state isn't observable
/// (the keyboard handlers don't need to react to changes, they just
/// need the latest value at key-press time).
class MasterDetailNavScope extends InheritedWidget {
  const MasterDetailNavScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final MasterDetailNavController controller;

  static MasterDetailNavController? maybeOf(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<MasterDetailNavScope>();
    return scope?.controller;
  }

  // Marker only — descendants treat the controller as a stable ref.
  @override
  bool updateShouldNotify(MasterDetailNavScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Slide-over master-detail used by every entity route block on wide
/// desktop windows. The list **always** renders at full width; the
/// detail / edit / create floats above it as a pane pinned to the
/// right edge — Notion / Slack-thread / iOS-Files style.
///
///   * `/<entity>`               → bare URL, no pane, list full width.
///   * `/<entity>/:id`           → list full width + detail pane on top.
///   * `/<entity>/:id/edit`      → list full width + edit pane on top.
///   * `/<entity>/new`           → list full width + create pane on top.
///   * `?view=full`              → pane fills the window, list hidden
///                                  (mounted offstage so its State
///                                  survives a toggle back).
///
/// On narrow viewports (`< Breakpoints.slideOver`) the layout falls
/// back to today's full-page navigation — same as before this widget
/// existed.
class MasterDetailLayout extends StatefulWidget {
  const MasterDetailLayout({
    super.key,
    required this.basePath,
    required this.list,
    required this.rightPane,
    this.viewMode,
  });

  /// Base entity URL — `/transactions`, `/clients`, etc. Used by the
  /// pane's close button to route back to the bare list URL.
  final String basePath;

  /// The list widget. Built once by the enclosing `ShellRoute`'s
  /// pageBuilder and reused across every child route inside this
  /// entity's branch.
  final Widget list;

  /// The active right-pane widget, or `null` for the bare list URL.
  final Widget? rightPane;

  /// `?view=full` flag from the URL. Null = slide-over. `'full'` =
  /// list hidden, pane fills window.
  final String? viewMode;

  @override
  State<MasterDetailLayout> createState() => _MasterDetailLayoutState();
}

/// Per-session memory of which view mode the user picked in each
/// entity's slide-over. Keys are entity base paths (`/transactions`,
/// `/clients`, …); values are the URL `view` param value (`'full'` or
/// `null` for slide-over).
///
/// Per-session only: this resets on app restart. Persisting it to Drift
/// is a schema bump deferred to a quieter slice — the goal here is to
/// stop the within-session annoyance of "I picked full, why is the next
/// row back to slide-over?".
final Map<String, String?> _stickyViewMode = <String, String?>{};

class _MasterDetailLayoutState extends State<MasterDetailLayout>
    with SingleTickerProviderStateMixin {
  final MasterDetailNavController _navController =
      MasterDetailNavController();

  /// Tracks whether we've already fired the sticky-mode redirect for
  /// the *current* (basePath, selectedId) tuple. Reset whenever either
  /// changes so each new pane entry gets one redirect attempt — without
  /// this we'd loop redirecting forever on every rebuild.
  String? _lastRedirectKey;

  /// Drives the slide-over's IN / OUT animation. `0` = pane is fully
  /// off-screen to the right (or unmounted); `1` = pane is docked.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slideOffset = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _slide,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  /// First-paint flag. Cold-start with a deep-linked pane URL
  /// (`/transactions/tx_42` on app launch) snaps the pane open without
  /// animating — the user didn't click anything, so the slide-in would
  /// feel unmotivated. Subsequent opens animate.
  bool _didFirstSync = false;

  bool get _hasPane => widget.rightPane != null;
  bool get _isFullScreen => widget.viewMode == 'full';

  bool _shouldSlideOverBeVisible() =>
      Breakpoints.isSlideOver(context) && _hasPane && !_isFullScreen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlideVisibility();
  }

  @override
  void didUpdateWidget(MasterDetailLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Toggle clicks rewrite the URL; stash the user's choice so the
    // *next* row they open in this entity defaults to the same mode.
    if (_hasPane) {
      _stickyViewMode[widget.basePath] = widget.viewMode;
    }
    _syncSlideVisibility();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  /// Reconcile the slide-over's animation state with the current URL +
  /// viewport. Called from both [didChangeDependencies] (viewport
  /// resize) and [didUpdateWidget] (URL change).
  ///
  /// **Snap-or-forward only.** The user-initiated close animation
  /// (X button, Esc) runs through [_closePaneAnimated] *before* the
  /// URL changes — by the time this sync sees `shouldShow == false`,
  /// the controller is already at 0. External closes (sidebar click,
  /// back button, URL bar) land here with the controller still at 1
  /// and the detail Element already torn down by go_router; snapping
  /// to 0 is the only safe option (animating would render a freshly
  /// re-mounted, empty-state widget for 220 ms — the v4 bug).
  void _syncSlideVisibility() {
    final shouldShow = _shouldSlideOverBeVisible();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!_didFirstSync) {
      // Cold start — snap regardless of state. Animations are reserved
      // for transitions, not initial paint.
      _didFirstSync = true;
      _slide.value = shouldShow ? 1 : 0;
      return;
    }
    if (shouldShow && _slide.value < 1) {
      if (reduceMotion) {
        _slide.value = 1;
      } else {
        _slide.forward();
      }
    } else if (!shouldShow && _slide.value > 0) {
      _slide.value = 0;
    }
  }

  /// User-initiated close. Runs the slide-out animation while the
  /// pane is still mounted (URL hasn't changed yet), then navigates.
  /// If the user navigated away mid-animation (e.g. clicked another
  /// row), skip the final `go(basePath)` so we don't clobber their
  /// new destination.
  Future<void> _closePaneAnimated() async {
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion && _slide.status != AnimationStatus.dismissed) {
      await _slide.reverse();
    }
    if (!mounted) return;
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc == widget.basePath) return; // already where we'd go
    GoRouter.of(context).go(widget.basePath);
  }

  @override
  Widget build(BuildContext context) {
    return MasterDetailNavScope(
      controller: _navController,
      child: _buildTree(context),
    );
  }

  Widget _buildTree(BuildContext context) {
    final isWide = Breakpoints.isSlideOver(context);

    // Sticky-mode redirect: if the user previously chose full-screen
    // for this entity in this session, opening any new row defaults to
    // full-screen too. Only fires when the URL is missing `?view=full`
    // *and* there's a pane to apply it to *and* the viewport is wide
    // enough to show the slide-over. Cross-entity nav wipes this via
    // `goEntity()` in router.dart (it strips `?view`).
    if (isWide && _hasPane && widget.viewMode == null) {
      final selectedId = selectedIdFromRoute(context);
      final redirectKey = '${widget.basePath}|$selectedId';
      if (_lastRedirectKey != redirectKey &&
          _stickyViewMode[widget.basePath] == 'full') {
        _lastRedirectKey = redirectKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _toggleFullScreenInUrl(context, isFullScreen: false);
        });
      } else if (_lastRedirectKey != redirectKey) {
        _lastRedirectKey = redirectKey;
      }
    }

    // Narrow viewport: full-page navigation, exactly today's behavior.
    // The list is wrapped in `Offstage` so its State survives a
    // resize back to wide.
    if (!isWide) {
      if (!_hasPane) return widget.list;
      return Stack(
        children: [
          Offstage(offstage: true, child: widget.list),
          _PaneRoot(
            basePath: widget.basePath,
            isFullScreen: true,
            navController: _navController,
            child: widget.rightPane!,
          ),
        ],
      );
    }

    // Wide viewport. Always render the list full-width; the pane (if
    // any) floats on top via Stack. Both the slide-over pane and the
    // full-screen pane variants render in the tree (one offstage)
    // so the user's edit form state survives a mode toggle.
    //
    // The list is wrapped in `Positioned.fill` (not just a non-
    // positioned Stack child) so it always fills the parent regardless
    // of sibling state — without it, the close-button → bare-URL
    // transition can leave the list at intrinsic width because the
    // Stack's non-positioned children path is sensitive to inherited
    // constraints.
    return Stack(
      children: [
        Positioned.fill(
          child: Offstage(
            offstage: _hasPane && _isFullScreen,
            child: widget.list,
          ),
        ),

        // Slide-over pane — mounted whenever the URL has a pane and
        // we're not in full-screen mode. The X / Esc handlers drive
        // the slide-out animation BEFORE rewriting the URL, so the
        // pane stays mounted with a live Element + State for the
        // full duration of the close.
        if (_hasPane && !_isFullScreen)
          Positioned(
            top: kToolbarHeight + MediaQuery.paddingOf(context).top,
            right: 0,
            bottom: 0,
            width: _paneWidth(context),
            child: SlideTransition(
              position: _slideOffset,
              child: Material(
                elevation: 8,
                color: context.inTheme.bg,
                child: _PaneRoot(
                  basePath: widget.basePath,
                  isFullScreen: false,
                  navController: _navController,
                  onClose: _closePaneAnimated,
                  child: widget.rightPane!,
                ),
              ),
            ),
          ),

        // Full-screen pane — covers the entire layout when active.
        if (_hasPane && _isFullScreen)
          Positioned.fill(
            child: _PaneRoot(
              basePath: widget.basePath,
              isFullScreen: true,
              navController: _navController,
              child: widget.rightPane!,
            ),
          ),
      ],
    );
  }
}

// ─── Pane root (chrome + a11y + keyboard + content swap) ────────────────

/// Common chrome wrapped around either the slide-over pane or the
/// full-screen pane:
///   * `MasterDetailPaneScope` marker so the embedded screen
///     suppresses its own Scaffold / AppBar.
///   * Floating close + full-screen toggle icons in the top-right.
///   * `CallbackShortcuts` + autofocus so Esc closes the pane.
///   * `Semantics(announce:)` for screen readers.
///
/// Content swaps (detail ↔ edit, row-to-row) are instant. An
/// `AnimatedSwitcher` cross-fade isn't safe here — the [child] is the
/// Navigator from `ShellRoute.pageBuilder`, which carries a
/// `GlobalKey<NavigatorState>`. Cross-fading would mount both old and
/// new subtrees simultaneously, colliding the key.
class _PaneRoot extends StatelessWidget {
  const _PaneRoot({
    required this.basePath,
    required this.isFullScreen,
    required this.navController,
    required this.child,
    this.onClose,
  });

  final String basePath;
  final bool isFullScreen;
  final MasterDetailNavController navController;
  final Widget child;

  /// Optional close handler used by the X button and the Esc shortcut.
  /// When null (full-screen mode), close falls back to a direct
  /// `GoRouter.of(context).go(basePath)`. The slide-over passes its
  /// layout-state `_closePaneAnimated` so closing runs the slide-out
  /// animation before the URL changes.
  final VoidCallback? onClose;

  void _close(BuildContext context) {
    final handler = onClose;
    if (handler != null) {
      handler();
    } else {
      GoRouter.of(context).go(basePath);
    }
  }

  void _navigateRelative(BuildContext context, String? targetId) {
    if (targetId == null) return;
    final uri = GoRouterState.of(context).uri;
    final newPath = '$basePath/$targetId';
    final next = uri.replace(path: newPath);
    GoRouter.of(context).go(next.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MasterDetailPaneScope(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _close(context),
          const SingleActivator(LogicalKeyboardKey.keyF): () =>
              _toggleFullScreenInUrl(context, isFullScreen: isFullScreen),
          const SingleActivator(LogicalKeyboardKey.keyJ): () =>
              _navigateRelative(context, navController.nextId()),
          const SingleActivator(LogicalKeyboardKey.keyK): () =>
              _navigateRelative(context, navController.prevId()),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _navigateRelative(context, navController.nextId()),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _navigateRelative(context, navController.prevId()),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            container: true,
            label: context.tr('pane_opened'),
            child: Stack(
              children: [
                // The embedded screen content. Mounted directly — no
                // AnimatedSwitcher, see class-level doc for why.
                Positioned.fill(child: child),
                // Floating close + full-screen toggle. Pinned to the
                // top-right with a small backdrop so the icons read
                // against any embedded chrome.
                Positioned(
                  top: 4,
                  right: 4,
                  child: _PaneActionsRow(
                    isFullScreen: isFullScreen,
                    onClose: () => _close(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaneActionsRow extends StatelessWidget {
  const _PaneActionsRow({
    required this.isFullScreen,
    required this.onClose,
  });

  final bool isFullScreen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Material(
      color: tokens.bg.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isFullScreen
                  ? context.tr('exit_full_screen')
                  : context.tr('open_in_full_screen'),
              icon: Icon(
                isFullScreen
                    ? Icons.close_fullscreen
                    : Icons.open_in_full,
                size: 18,
              ),
              onPressed: () => _toggleFullScreenInUrl(
                context,
                isFullScreen: isFullScreen,
              ),
              splashRadius: 18,
            ),
            IconButton(
              tooltip: context.tr('close'),
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClose,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared URL helpers ─────────────────────────────────────────────────

/// Flip the `?view=full` query param on the active URL. Used by the
/// pane's `F` keyboard shortcut and by the `open_in_full` /
/// `close_fullscreen` icon button — both must produce identical URLs.
///
/// `Uri.replace(queryParameters: null)` *keeps* the existing query params
/// (per Dart's docs — it only "replaces" non-null fields). Pass the map
/// directly: an empty map clears the query string.
void _toggleFullScreenInUrl(
  BuildContext context, {
  required bool isFullScreen,
}) {
  final uri = GoRouterState.of(context).uri;
  final params = Map<String, String>.from(uri.queryParameters);
  if (isFullScreen) {
    params.remove('view');
  } else {
    params['view'] = 'full';
  }
  final next = uri.replace(queryParameters: params);
  GoRouter.of(context).go(next.toString());
}

// ─── Width math + pane scope marker ──────────────────────────────────────

double _paneWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.45).clamp(440.0, 560.0);
}

/// Marker [InheritedWidget] used by `EntityDetailScaffold` and
/// `EntityEditScaffold` to detect that they're rendered inside a
/// master-detail pane. When present, the scaffolds suppress their own
/// outer `Scaffold` + `AppBar` (they call
/// [MasterDetailPaneScope.isInPane]).
class MasterDetailPaneScope extends InheritedWidget {
  const MasterDetailPaneScope({super.key, required super.child});

  static bool isInPane(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MasterDetailPaneScope>() !=
      null;

  @override
  bool updateShouldNotify(MasterDetailPaneScope oldWidget) => false;
}
