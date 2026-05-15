import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';

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
class MasterDetailLayout extends StatelessWidget {
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

  bool get _hasPane => rightPane != null;
  bool get _isFullScreen => viewMode == 'full';

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isSlideOver(context);

    // Narrow viewport: full-page navigation, exactly today's behavior.
    // The list is wrapped in `Offstage` so its State survives a
    // resize back to wide.
    if (!isWide) {
      if (!_hasPane) return list;
      return Stack(
        children: [
          Offstage(offstage: true, child: list),
          _PaneRoot(
            basePath: basePath,
            isFullScreen: true,
            child: rightPane!,
          ),
        ],
      );
    }

    // Wide viewport. Always render the list full-width; the pane (if
    // any) floats on top via Stack. Both the slide-over pane and the
    // full-screen pane variants render in the tree (one offstage)
    // so the user's edit form state survives a mode toggle.
    return Stack(
      children: [
        // List always full-width. Offstage in full-screen mode so it
        // doesn't waste paint cycles, but mounted so its State stays
        // alive when the user collapses back to slide-over.
        Offstage(offstage: _hasPane && _isFullScreen, child: list),

        // Slide-over pane — only built when there's a route's worth
        // of content AND we're not in full-screen mode.
        if (_hasPane && !_isFullScreen)
          _SlideOverPane(
            basePath: basePath,
            child: rightPane!,
          ),

        // Full-screen pane — covers the entire layout when active.
        if (_hasPane && _isFullScreen)
          Positioned.fill(
            child: _PaneRoot(
              basePath: basePath,
              isFullScreen: true,
              child: rightPane!,
            ),
          ),
      ],
    );
  }
}

// ─── Slide-over pane ─────────────────────────────────────────────────────

/// The right-pinned floating pane. Top-aligned below the list's
/// AppBar so the user can still see the search field / sort controls
/// while a row is open. Animated entry on first appearance; subsequent
/// content swaps within the pane are instant (different rows) or
/// cross-faded (detail ↔ edit).
class _SlideOverPane extends StatefulWidget {
  const _SlideOverPane({required this.basePath, required this.child});

  final String basePath;
  final Widget child;

  @override
  State<_SlideOverPane> createState() => _SlideOverPaneState();
}

class _SlideOverPaneState extends State<_SlideOverPane> {
  // Skip the slide-in animation on first build so deep-link cold
  // starts (e.g. `/transactions/tx_42`) materialise the pane in
  // place rather than animating from off-screen.
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _firstBuild = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paneWidth = _paneWidth(context);
    final topInset = kToolbarHeight + MediaQuery.paddingOf(context).top;

    return Positioned(
      // Start below the list's AppBar so the search field / sort /
      // filter chips on the AppBar's right side stay accessible
      // while a row is open. Slack uses this pattern for thread
      // sidebars.
      top: topInset,
      right: 0,
      bottom: 0,
      width: paneWidth,
      // The pane slides from off-screen-right (1, 0) to its final
      // position (0, 0) on first appearance. `_firstBuild` short-
      // circuits the animation when the widget is built with the
      // pane already open (cold load).
      child: AnimatedSlide(
        offset: _firstBuild ? Offset.zero : Offset.zero,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<double>(
          // Drives the slide-in tween on first appearance only.
          // After the first frame, `_firstBuild` flips false and the
          // tween snaps to 0 — but it's already 0, so no animation.
          tween: Tween<double>(
            begin: _firstBuild ? 0.0 : 1.0,
            end: 0.0,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (ctx, t, child) => FractionalTranslation(
            translation: Offset(t, 0),
            child: child,
          ),
          child: Material(
            elevation: 8,
            color: context.inTheme.bg,
            child: _PaneRoot(
              basePath: widget.basePath,
              isFullScreen: false,
              child: widget.child,
            ),
          ),
        ),
      ),
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
///   * `AnimatedSwitcher` for detail ↔ edit cross-fade (keyed on
///     navigation kind, NOT on the full URL — clicking through
///     different rows in detail mode swaps content instantly).
class _PaneRoot extends StatelessWidget {
  const _PaneRoot({
    required this.basePath,
    required this.isFullScreen,
    required this.child,
  });

  final String basePath;
  final bool isFullScreen;
  final Widget child;

  /// `'detail'` / `'edit'` / `'create'` — used as the AnimatedSwitcher
  /// key so the cross-fade only fires on detail ↔ edit transitions
  /// within the same row, not when the user clicks through different
  /// rows in detail mode.
  String _navKind(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.endsWith('/edit')) return 'edit';
    if (loc.endsWith('/new')) return 'create';
    return 'detail';
  }

  @override
  Widget build(BuildContext context) {
    return MasterDetailPaneScope(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              GoRouter.of(context).go(basePath),
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            container: true,
            label: context.tr('pane_opened'),
            child: Stack(
              children: [
                // The embedded screen content. AnimatedSwitcher only
                // re-keys on nav-kind changes (detail ↔ edit) so
                // row-to-row navigation doesn't drag through a 200 ms
                // fade.
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_navKind(context)),
                      child: child,
                    ),
                  ),
                ),
                // Floating close + full-screen toggle. Pinned to the
                // top-right with a small backdrop so the icons read
                // against any embedded chrome.
                Positioned(
                  top: 4,
                  right: 4,
                  child: _PaneActionsRow(
                    basePath: basePath,
                    isFullScreen: isFullScreen,
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
    required this.basePath,
    required this.isFullScreen,
  });

  final String basePath;
  final bool isFullScreen;

  void _toggleFullScreen(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final params = Map<String, String>.from(uri.queryParameters);
    if (isFullScreen) {
      params.remove('view');
    } else {
      params['view'] = 'full';
    }
    final next = uri.replace(
      queryParameters: params.isEmpty ? null : params,
    );
    GoRouter.of(context).go(next.toString());
  }

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
              onPressed: () => _toggleFullScreen(context),
              splashRadius: 18,
            ),
            IconButton(
              tooltip: context.tr('close'),
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => GoRouter.of(context).go(basePath),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
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
