import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
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

  /// Animated close hook bound by the layout's State in `initState`.
  /// Called by list tiles via [MasterDetailNavScope.requestClose] so
  /// row-click-deselect plays the same slide-out as the X button —
  /// the URL only changes after the reverse animation finishes.
  Future<void> Function()? closePane;

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

  /// Close the pane from a descendant (e.g. a list tile's
  /// click-to-deselect). Runs the layout's animated close when hosted
  /// inside a master-detail pane; falls back to plain
  /// `GoRouter.go(basePath)` otherwise (narrow viewports, tests).
  static void requestClose(
    BuildContext context, {
    required String basePath,
  }) {
    final close = maybeOf(context)?.closePane;
    if (close != null) {
      close();
    } else {
      GoRouter.of(context).go(basePath);
    }
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

/// Entities whose Edit / Create screens default to the slide-over
/// sidebar panel instead of the full-width editor. These have narrow
/// forms that work well alongside the master table; *every other*
/// entity opens Edit / Create full-width on desktop.
///
/// The full-screen choice is deliberately **never remembered** — neither
/// across an app restart nor row-to-row within a session. The user's
/// explicit F-key / expand toggle ([_toggleFullScreenInUrl]) only
/// rewrites the current URL; the next screen resolves fresh from this
/// table.
const Set<String> _kEditDefaultsToSlide = <String>{
  '/products',
  '/transactions',
  '/payments',
};

/// Whether navigating to [basePath]'s Edit / Create route opens a
/// **full-width** editor (vs. the slide-over panel). Single source of truth
/// shared by [_MasterDetailLayoutState._resolveDesiredMode] and the route
/// block's selected-row suppression (`router.dart`) — a full-width editor
/// covers the list, so the row must not paint "selected" on the way there.
bool editOpensFullWidth(String basePath) =>
    !_kEditDefaultsToSlide.contains(basePath);

class _MasterDetailLayoutState extends State<MasterDetailLayout>
    with TickerProviderStateMixin {
  final MasterDetailNavController _navController =
      MasterDetailNavController();

  /// Tracks whether we've already fired the sticky-mode redirect for
  /// the *current* (basePath, selectedId) tuple. Reset whenever either
  /// changes so each new pane entry gets one redirect attempt — without
  /// this we'd loop redirecting forever on every rebuild.
  String? _lastRedirectKey;

  /// Drives the slide-over's IN / OUT translate. `0` = pane fully
  /// off-screen to the right (or unmounted); `1` = docked. Created in
  /// [initState] (not a lazy field) so the Ticker is never built during
  /// dispose.
  late final AnimationController _slide;
  late final Animation<Offset> _slideOffset;

  /// Drives the slide-over ⇄ full-screen geometry. `0` = slide-over
  /// rect pinned to the right edge; `1` = the pane fills the layout
  /// area. The expand / collapse toggle animates this; row-to-row and
  /// fresh opens snap it.
  late final AnimationController _expand;
  late final Animation<double> _expandCurve;

  /// First-paint flag. Cold-start with a deep-linked pane URL
  /// (`/transactions/tx_42` on app launch) snaps the pane open without
  /// animating — the user didn't click anything, so the slide-in would
  /// feel unmotivated. Subsequent opens animate.
  bool _didFirstSync = false;

  bool get _hasPane => widget.rightPane != null;
  bool get _isFullScreen => widget.viewMode == 'full';

  /// Whether the pane should be **docked** (`_slide` at 1) vs
  /// translated off-screen (0). True whenever a pane exists on a wide
  /// viewport — deliberately independent of full-screen: [_expand]
  /// (not [_slide]) owns the slide-over ⇄ full-screen geometry, so
  /// entering full-screen must NOT slide the (single, unified) pane
  /// away.
  bool _shouldPaneBeDocked() =>
      Breakpoints.isSlideOver(context) && _hasPane;

  /// Resolve the desired pane mode (`'full'` or `'slide'`) for the
  /// current URL. The redirect logic in [_buildTree] uses this to
  /// decide whether to snap the URL into `?view=full` after the user
  /// opens a row.
  ///
  /// Per-screen-type default (the choice is never remembered — see
  /// [_kEditDefaultsToSlide]):
  ///   - **Edit / Create** (`/edit`, `/new`): full-width on desktop for
  ///     every entity *except* [_kEditDefaultsToSlide] (products, bank
  ///     transactions, payments), whose narrow forms stay in the sidebar
  ///     panel.
  ///   - **Detail**: the sidebar preview.
  ///
  /// An explicit `?view=full` (in-cell link, or the user's F-toggle /
  /// expand button for this exact screen) still wins for that URL only.
  String _resolveDesiredMode(String matchedLocation) {
    final isEditOrNew = matchedLocation.endsWith('/edit') ||
        matchedLocation.endsWith('/new');
    if (isEditOrNew) {
      return editOpensFullWidth(widget.basePath) ? 'full' : 'slide';
    }
    return 'slide';
  }

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slide,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandCurve = CurvedAnimation(
      parent: _expand,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Hand the animated-close path to the controller so list-tile
    // clicks can request a slide-out via `MasterDetailNavScope.
    // requestClose` (matches the X / Esc behavior).
    _navController.closePane = _closePaneAnimated;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reconcile the open/close translate here. `_expand` (slide ⇄
    // full geometry) is NOT synced from didChangeDependencies: a `?view`
    // toggle changes the GoRouterState inherited dependency, so this
    // fires on the same frame as didUpdateWidget — and a null-oldWidget
    // `_syncExpand` would snap `_expand` to the target, clobbering the
    // forward()/reverse() the didUpdateWidget path just started. Cold
    // start is handled by _syncSlideVisibility's first-sync snap;
    // every later change goes through didUpdateWidget's _syncExpand.
    _syncSlideVisibility();
  }

  @override
  void didUpdateWidget(MasterDetailLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sticky-mode writes are explicit — they only fire from
    // [_toggleFullScreenInUrl]. URL changes here (opening a row,
    // clicking the X, switching entities) reflect routing state and
    // must NOT overwrite the user's last toggle preference, or
    // clicking a fresh row would clobber the sticky map back to null.
    _syncSlideVisibility();
    _syncExpand(oldWidget);
  }

  @override
  void dispose() {
    _slide.dispose();
    _expand.dispose();
    super.dispose();
  }

  /// Reconcile the pane's dock/undock translate ([_slide]) with the
  /// current URL + viewport. Called from both [didChangeDependencies]
  /// (viewport resize) and [didUpdateWidget] (URL change). Geometry
  /// (slide-over ⇄ full-screen) is handled separately by [_syncExpand].
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
    final shouldBeDocked = _shouldPaneBeDocked();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!_didFirstSync) {
      // Cold start — snap regardless of state. Animations are reserved
      // for transitions, not initial paint. A deep link to `?view=full`
      // opens full with no grow.
      _didFirstSync = true;
      _slide.value = shouldBeDocked ? 1 : 0;
      _expand.value = _isFullScreen ? 1 : 0;
      return;
    }
    if (shouldBeDocked && _slide.value < 1) {
      if (reduceMotion) {
        _slide.value = 1;
      } else {
        _slide.forward();
      }
    } else if (!shouldBeDocked && _slide.value > 0) {
      _slide.value = 0;
    }
  }

  /// Reconcile the slide-over ⇄ full-screen geometry animation
  /// ([_expand]) with the current URL.
  ///
  /// Snap (no animation) on a fresh open, a close, a viewport resize,
  /// or a row-to-row / content change — only **animate** when the pane
  /// stays mounted and `viewMode` flips (the user pressed the expand /
  /// collapse control, or an auto edit-default promoted the route).
  /// Cold start is handled by [_syncSlideVisibility]'s first-sync snap.
  void _syncExpand(MasterDetailLayout? oldWidget) {
    if (!_didFirstSync) return; // first-sync snap owns the initial value
    final target = _isFullScreen ? 1.0 : 0.0;
    final modeFlip = oldWidget != null &&
        oldWidget.rightPane != null &&
        widget.rightPane != null &&
        oldWidget.viewMode != widget.viewMode;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (modeFlip && !reduceMotion) {
      if (target == 1.0) {
        _expand.forward();
      } else {
        _expand.reverse();
      }
    } else if (_expand.value != target && !_expand.isAnimating) {
      // Defense-in-depth: never hard-snap while a grow/shrink is in
      // flight, so a stray non-flip caller can't clobber the animation.
      _expand.value = target;
    }
  }

  /// User-initiated close. Runs the slide-out animation while the
  /// pane is still mounted (URL hasn't changed yet), then navigates.
  /// If the user navigated away mid-animation (e.g. clicked another
  /// row), skip the final `go(basePath)` so we don't clobber their
  /// new destination.
  Future<void> _closePaneAnimated() async {
    final fromLoc = GoRouterState.of(context).matchedLocation;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!reduceMotion && _slide.status != AnimationStatus.dismissed) {
      await _slide.reverse();
    }
    if (!mounted) return;
    final nowLoc = GoRouterState.of(context).matchedLocation;
    // User navigated somewhere else mid-animation (e.g. clicked a
    // different row) — their navigation wins; don't clobber it by
    // forcing back to the bare list.
    if (nowLoc != fromLoc) return;
    if (nowLoc == widget.basePath) return; // already where we'd go
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

    // Forget the last promoted location as soon as the pane closes, so
    // re-opening the *same* edit URL (edit a row, close, edit it again)
    // gets a fresh promotion attempt instead of being deduped into the
    // slide-over. The redirect block below is a no-op without a pane, so
    // clearing here has no other side effect; a successful promotion
    // keeps the pane mounted (`_hasPane` stays true) so it never loops.
    if (!_hasPane) _lastRedirectKey = null;

    // Desired-mode redirect: every URL with a pane gets one chance to
    // be promoted to full-screen, based on the per-screen-type default
    // (Edit / Create default to full for every entity except products
    // and bank transactions — see [_resolveDesiredMode] and
    // [_kEditDefaultsToSlide]).
    //
    // Dedup key is `matchedLocation` rather than `(basePath, :id)` so
    // detail (`/clients/c_42`) and edit (`/clients/c_42/edit`) are
    // independent — the redirect re-evaluates when the user clicks
    // Edit, picking up the edit-defaults-to-full rule even when the
    // detail already settled. Cross-entity nav lives in a different
    // State, so no cross-entity leak.
    if (isWide && _hasPane && widget.viewMode == null) {
      final loc = GoRouterState.of(context).matchedLocation;
      if (_lastRedirectKey != loc) {
        _lastRedirectKey = loc;
        if (_resolveDesiredMode(loc) == 'full') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _toggleFullScreenInUrl(
              context,
              isFullScreen: false,
            );
          });
        }
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

    // Wide viewport. The list always renders full-width; a single
    // pane floats on top via a Stack and animates its geometry between
    // the slide-over rect (pinned to the right edge) and the
    // full-screen rect (fills the layout area) via [_expand]. Only ONE
    // `_PaneRoot` (it carries the Navigator's GlobalKey) is ever
    // mounted, so the edit-form State survives the grow / shrink and
    // there is no key collision. The list stays painted until the pane
    // is fully settled full-screen AND docked, so it is visibly
    // revealed as the pane grows, shrinks, or slides away on close.
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: Listenable.merge([_slide, _expand]),
          builder: (context, _) {
            final t = _expandCurve.value;
            // Hide the list only while the full-screen pane fully
            // covers it. The moment a close starts (`_slide` reverses
            // below 1) the table must paint underneath so it's
            // revealed as the pane slides away — not pop in after.
            final listHidden = _hasPane &&
                _isFullScreen &&
                _expand.status == AnimationStatus.completed &&
                _slide.value >= 1;
            return Stack(
              children: [
                Positioned.fill(
                  child: Offstage(
                    offstage: listHidden,
                    child: widget.list,
                  ),
                ),
                if (_hasPane)
                  Positioned(
                    left: _lerp(
                      constraints.maxWidth - _paneWidth(context),
                      0,
                      t,
                    ),
                    // Full height in both states (safe-area inset only;
                    // 0 on desktop) so the expand reads as a clean
                    // horizontal widen to fill the whole screen.
                    top: MediaQuery.paddingOf(context).top,
                    width: _lerp(
                      _paneWidth(context),
                      constraints.maxWidth,
                      t,
                    ),
                    bottom: 0,
                    child: SlideTransition(
                      position: _slideOffset,
                      child: Material(
                        elevation: _lerp(8, 0, t),
                        color: context.inTheme.bg,
                        child: _PaneRoot(
                          basePath: widget.basePath,
                          isFullScreen: _isFullScreen,
                          navController: _navController,
                          onClose: _closePaneAnimated,
                          child: widget.rightPane!,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Pane root (chrome + a11y + keyboard + content swap) ────────────────

/// Common chrome wrapped around either the slide-over pane or the
/// full-screen pane:
///   * [MasterDetailPaneScope] — suppresses the embedded screen's
///     outer `Scaffold` / `AppBar` AND publishes the close + full-
///     screen icons so the screen renders them inline in its own
///     header strip. Both slide-over and full-screen variants use
///     this path; the embedded scaffold's inline header reserves a
///     slot for them.
///   * `CallbackShortcuts` + autofocus so Esc / F / J / K work.
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
    // Preserve the current screen mode while keyboard-stepping rows: if
    // we're on an edit form, the next/prev row should open its edit
    // form too (not silently flip to the read-only detail screen).
    // `uri.replace(path:)` already carries the `?view` query param.
    final isEdit = uri.path.endsWith('/edit');
    final newPath = isEdit
        ? '$basePath/$targetId/edit'
        : '$basePath/$targetId';
    final next = uri.replace(path: newPath);
    GoRouter.of(context).go(next.toString());
  }

  @override
  Widget build(BuildContext context) {
    // Edit / create forms vs the read-only detail screen. Used only for
    // the screen-reader announcement (no visible verb in the chrome).
    final path = GoRouterState.of(context).uri.path;
    final isEditing = path.endsWith('/edit') || path.endsWith('/new');
    final actionsRow = _PaneActionsRow(
      basePath: basePath,
      isFullScreen: isFullScreen,
      onClose: () => _close(context),
    );
    // Publish the actions row through the scope so the embedded
    // screen's inline header places the close / full-screen-toggle
    // chrome next to its own actions (Edit / Archive / Save). One
    // unified pane handles both slide-over and full-screen, so this
    // single path always supplies the chrome.
    return MasterDetailPaneScope(
      paneActions: actionsRow,
      // Single-key pane shortcuts (F / J / K / ↑ / ↓ / Esc). Routed
      // through Shortcuts + Actions rather than a bare CallbackShortcuts
      // so they can stand down while a text input has focus — otherwise
      // typing `f` in the embedded edit form would toggle full-screen
      // instead of inserting the letter. `_PaneAction` is *disabled*
      // (not merely no-op) when an EditableText is focused, which makes
      // ShortcutManager return KeyEventResult.ignored so the keystroke
      // falls through to the field. See the plan write-up for the
      // Flutter-source rationale (consumesKey defaults to true).
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): _PaneCloseIntent(),
          SingleActivator(LogicalKeyboardKey.keyF):
              _PaneToggleFullScreenIntent(),
          SingleActivator(LogicalKeyboardKey.keyJ): _PaneNextIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown): _PaneNextIntent(),
          SingleActivator(LogicalKeyboardKey.keyK): _PanePrevIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): _PanePrevIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _PaneCloseIntent: _PaneAction<_PaneCloseIntent>(
              onInvoke: (_) {
                _close(context);
                return null;
              },
            ),
            _PaneToggleFullScreenIntent:
                _PaneAction<_PaneToggleFullScreenIntent>(
              onInvoke: (_) {
                _toggleFullScreenInUrl(context, isFullScreen: isFullScreen);
                return null;
              },
            ),
            _PaneNextIntent: _PaneAction<_PaneNextIntent>(
              onInvoke: (_) {
                _navigateRelative(context, navController.nextId());
                return null;
              },
            ),
            _PanePrevIntent: _PaneAction<_PanePrevIntent>(
              onInvoke: (_) {
                _navigateRelative(context, navController.prevId());
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Semantics(
              container: true,
              label: context.tr(
                isEditing ? 'editing_pane_opened' : 'viewing_pane_opened',
              ),
              // The embedded screen content. Mounted directly — no
              // AnimatedSwitcher (see class-level doc for why) and no
              // floating chrome overlay (the embedded scaffold owns
              // the inline header that hosts our pane actions).
              child: child,
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
    required this.onClose,
  });

  final String basePath;
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
/// pane's `F` keyboard shortcut, the `open_in_full` / `close_fullscreen`
/// icon button, and the automatic screen-type-default redirect — all
/// must produce identical URLs.
///
/// The choice is **not** remembered: it only rewrites the current URL
/// for this exact screen. There is no per-entity stickiness, and the
/// `view` param is stripped before the route is persisted (see
/// `NavStatePersister`), so the next screen / next launch always
/// resolves fresh from [_resolveDesiredMode].
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

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _paneWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.45).clamp(440.0, 560.0);
}

/// [InheritedWidget] published by `_PaneRoot` so embedded scaffolds
/// (`EntityDetailScaffold`, `EntityEditScaffold`, …) can both detect
/// that they're rendered inside a master-detail pane and read the
/// chrome they're expected to surface — the X + full-screen toggle
/// icons. When the scope is present:
///   * Scaffolds suppress their outer `Scaffold` + `AppBar` (see
///     [isInPane]).
///   * Scaffolds append [paneActions] to the right end of their inline
///     header row so the icons live in the same strip as Save / Edit
///     and don't float on top of the screen's content (see
///     [paneActionsOf]).
class MasterDetailPaneScope extends InheritedWidget {
  const MasterDetailPaneScope({
    super.key,
    this.paneActions,
    required super.child,
  });

  /// The X + full-screen toggle row that embedded scaffolds should
  /// place at the trailing end of their inline header. Always supplied
  /// by `_PaneRoot` (one unified pane covers both slide-over and
  /// full-screen); nullable only for scopes constructed without it.
  final Widget? paneActions;

  static bool isInPane(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MasterDetailPaneScope>() !=
      null;

  static Widget? paneActionsOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MasterDetailPaneScope>()
      ?.paneActions;

  @override
  bool updateShouldNotify(MasterDetailPaneScope oldWidget) =>
      paneActions != oldWidget.paneActions;
}

// ─── Pane keyboard shortcuts ─────────────────────────────────────────────

/// True when the primary focus is a text input. Single-key pane
/// shortcuts (F / J / K / arrows / Esc) stand down in that case so the
/// keystroke reaches the field — typing `f` in the embedded edit form
/// must insert `f`, not toggle full-screen.
bool _textInputHasFocus() {
  final w = FocusManager.instance.primaryFocus?.context?.widget;
  return w is EditableText;
}

class _PaneCloseIntent extends Intent {
  const _PaneCloseIntent();
}

class _PaneToggleFullScreenIntent extends Intent {
  const _PaneToggleFullScreenIntent();
}

class _PaneNextIntent extends Intent {
  const _PaneNextIntent();
}

class _PanePrevIntent extends Intent {
  const _PanePrevIntent();
}

/// A pane shortcut action that is *disabled* — not merely a no-op —
/// while a text input has focus. Disabling is what matters:
/// `ShortcutManager.handleKeypress` only returns `KeyEventResult.ignored`
/// (letting the key fall through to the field) when the action is not
/// enabled. `Action.consumesKey` defaults to `true`, so a guard that
/// only no-ops in `onInvoke` would still report the key as handled and
/// swallow it. `consumesKey` is overridden too as belt-and-braces.
class _PaneAction<T extends Intent> extends CallbackAction<T> {
  _PaneAction({required super.onInvoke});

  @override
  bool isEnabled(T intent) => !_textInputHasFocus();

  @override
  bool consumesKey(T intent) => !_textInputHasFocus();
}
