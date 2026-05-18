import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// Handle the host can pass into [MarkdownTextField] to force the
/// editor to serialize + emit its current content immediately,
/// bypassing the debounce. Used before actions that read the parent's
/// draft synchronously (e.g. "Save as default"), so the just-typed
/// value is captured rather than the last debounced one.
///
/// Mirrors the `LineItemTableDesktopController` flush pattern.
class MarkdownFieldController {
  String? Function()? _flushHandler;

  // ignore: use_setters_to_change_properties
  void _attach(String? Function() handler) {
    _flushHandler = handler;
  }

  void _detach(String? Function() handler) {
    if (identical(_flushHandler, handler)) _flushHandler = null;
  }

  /// Cancel any pending debounce, serialize the document now, emit it
  /// through the field's `onChanged`, and return the serialized
  /// markdown. Returns null when the field isn't mounted or there's
  /// nothing to flush (the caller should fall back to its known value).
  String? flush() => _flushHandler?.call();
}

/// A reusable WYSIWYG markdown editor. Loads from a raw markdown string,
/// edits via [SuperEditor], serializes back to markdown on changes (debounced),
/// and emits the new markdown through [onChanged].
///
/// Bound to a one-way data flow: parent owns the truth and feeds [initialValue]
/// + [externalValueKey]; when the key changes and the new value differs from
/// the editor's serialized state, the document is reseeded. SuperEditor exposes
/// no `TextEditingController`-style two-way binding, so [externalValueKey] is
/// how callers force a reseed (e.g. when an override toggle resets the field
/// to a cascaded parent value).
class MarkdownTextField extends StatefulWidget {
  const MarkdownTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.showLabel = true,
    this.height = 200,
    this.expand = false,
    this.enabled = true,
    this.readOnly = false,
    this.externalValueKey,
    this.focusNode,
    this.controller,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Starting markdown content. Null and empty are equivalent.
  final String? initialValue;

  /// Fired with the serialized markdown after [debounce] of no further edits.
  /// Also flushed synchronously when focus leaves the editor.
  final ValueChanged<String> onChanged;

  /// Visible label above the editor frame.
  final String label;

  /// When false the label row is not rendered (the host already labels the
  /// field — e.g. a `TabBar` tab name). The string is still used elsewhere
  /// (placeholder/semantics). Defaults to true.
  final bool showLabel;

  /// Fixed height of the editor's scroll viewport. Content beyond this scrolls
  /// inside the editor. Ignored when [expand] is true.
  final double height;

  /// When true the editor fills its parent's available height (the parent must
  /// supply a bounded height) instead of using the fixed [height]. Used inside
  /// the desktop notes pane so the textarea reaches the bottom of the panel
  /// rather than leaving dead space below it.
  final bool expand;

  /// When false, paints a disabled overlay and ignores input. The toolbar is
  /// hidden.
  final bool enabled;

  /// When true, the editor is interactive (selection works) but no edits are
  /// permitted. Currently treated the same as `!enabled` — kept distinct so a
  /// future "preview but copy-paste" mode can be added without API churn.
  final bool readOnly;

  /// Bump to force the editor to reseed its document from [initialValue].
  /// Hash of `(apiKey, value, isOverridden)` works well for the overridable
  /// settings pattern.
  final Object? externalValueKey;

  /// Optional focus node for tab-order chaining.
  final FocusNode? focusNode;

  /// Optional handle the host uses to force an immediate serialize +
  /// emit (see [MarkdownFieldController]).
  final MarkdownFieldController? controller;

  /// Quiet period before the serialized markdown is emitted to [onChanged].
  /// Keystroke-rate edits get coalesced into a single VM write.
  final Duration debounce;

  @override
  State<MarkdownTextField> createState() => _MarkdownTextFieldState();
}

class _MarkdownTextFieldState extends State<MarkdownTextField> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;

  Timer? _debounce;
  String _lastEmitted = '';
  bool _isApplyingExternal = false;
  // When false, the heavy editing `SuperEditor` (which attaches an IME
  // client) is replaced by a read-only `SuperReader` (no IME). Only the
  // focused field mounts a `SuperEditor`, so at most one IME input is ever
  // registered — screens that show many markdown fields at once (Defaults'
  // 8 fields, the invoice notes TabBarView's 4) no longer collide on the
  // null IME input id, and `ExcludeFocus` around the readers keeps the
  // focus-traversal policy from probing unlaid-out reader render boxes.
  bool _editing = false;
  // `_seedDocument` is called from both `initState` and `didUpdateWidget` —
  // this flag tells it whether the late-initialized fields below carry a
  // previous-generation document/composer that needs tearing down.
  bool _initialized = false;
  // True when this widget created its own FocusNode and is therefore
  // responsible for disposing it. False when a caller-owned node was passed
  // in via `widget.focusNode`.
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);
    _seedDocument(widget.initialValue ?? '');
    widget.controller?._attach(_flushNow);
  }

  /// Cancel the debounce, serialize now, emit if changed, return the
  /// markdown. Wired to [MarkdownFieldController.flush].
  String _flushNow() {
    _debounce?.cancel();
    _debounce = null;
    final md = serializeDocumentToMarkdown(_document);
    if (md != _lastEmitted) {
      _lastEmitted = md;
      widget.onChanged(md);
    }
    return md;
  }

  @override
  void didUpdateWidget(covariant MarkdownTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(_flushNow);
      widget.controller?._attach(_flushNow);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      } else {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      }
      _focusNode.addListener(_onFocusChanged);
    }

    // Reseed only when the parent signals that the underlying value changed
    // from somewhere other than our own emission (e.g. override toggle).
    // The `_lastEmitted` guard prevents echoing our own writes back through
    // the document.
    if (widget.externalValueKey != oldWidget.externalValueKey) {
      final next = widget.initialValue ?? '';
      if (next != _lastEmitted) {
        _seedDocument(next);
      }
    }
  }

  @override
  void dispose() {
    // Capture any pending debounced emit BEFORE teardown, then schedule it
    // on a microtask. Calling `widget.onChanged` synchronously here would
    // call the parent VM's `notifyListeners`, which can rebuild widgets
    // mid-dispose and trip "setState after dispose" assertions.
    String? pending;
    if (_debounce != null) {
      _debounce!.cancel();
      _debounce = null;
      final md = serializeDocumentToMarkdown(_document);
      if (md != _lastEmitted) pending = md;
    }
    widget.controller?._detach(_flushNow);
    _document.removeListener(_onDocumentChange);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    _composer.dispose();
    if (pending != null) {
      final emit = widget.onChanged;
      scheduleMicrotask(() => emit(pending!));
    }
    super.dispose();
  }

  void _seedDocument(String markdown) {
    _isApplyingExternal = true;

    // Tear down the previous generation before creating new instances.
    // `_initialized` is false only on the very first call (from initState),
    // when the late fields are still uninitialized.
    if (_initialized) {
      _document.removeListener(_onDocumentChange);
      _composer.dispose();
    }

    final sanitized = _sanitize(markdown);
    _document = sanitized.isEmpty
        ? MutableDocument.empty()
        : deserializeMarkdownToDocument(sanitized);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );
    _document.addListener(_onDocumentChange);
    // Baseline against what the editor would actually serialize right now —
    // not against the unsanitized input. The deserialize → serialize round
    // trip normalizes whitespace, so a literal equality against the input
    // string would flag the first keystroke as "different" against a stale
    // baseline.
    _lastEmitted = serializeDocumentToMarkdown(_document);
    _initialized = true;
    _isApplyingExternal = false;
  }

  /// Strips a few HTML residues the old admin-portal data sometimes carries
  /// from the legacy Quill editor. Mirrors the cleanup in
  /// `admin-portal/lib/utils/super_editor/super_editor.dart`. Permissive
  /// enough to catch self-closing variants (`<p/>`, `<div />`).
  String _sanitize(String md) {
    return md
        .replaceAll(RegExp(r'<\s*/?\s*p\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'<\s*/?\s*div\s*/?\s*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .trim();
  }

  void _onDocumentChange(DocumentChangeLog _) {
    if (_isApplyingExternal) return;
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, _emitNow);
  }

  void _emitNow() {
    final md = serializeDocumentToMarkdown(_document);
    if (md == _lastEmitted) return;
    _lastEmitted = md;
    widget.onChanged(md);
  }

  void _onFocusChanged() {
    // Flush any pending edits the moment focus leaves the editor so that
    // blur-then-save races don't drop the last keystroke.
    if (!_focusNode.hasFocus && _debounce != null) {
      _debounce!.cancel();
      _debounce = null;
      _emitNow();
    }
    // Drop back to the read-only `SuperReader` when focus leaves so the
    // IME client is released and this field stops participating in focus
    // traversal. Entering edit mode is driven by `_enterEditing` (tap or
    // keyboard activation on the reader host) — the editor focus node isn't
    // attached to a Focus widget until the `SuperEditor` mounts, so it can't
    // receive focus from here first.
    if (!_focusNode.hasFocus && _editing && mounted) {
      setState(() => _editing = false);
    }
  }

  /// Promote this field from the read-only `SuperReader` to the editing
  /// `SuperEditor`. Drops any other field's editor first and defers the
  /// rebuild to the next frame so the previously-edited field has already
  /// torn its `SuperEditor` down — guaranteeing at most one `SuperEditor`
  /// (one IME client) is ever mounted in a single frame, even when the user
  /// taps straight from one markdown field to another.
  void _enterEditing() {
    if (_editing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_editing) setState(() => _editing = true);
    });
  }

  bool _selectionHas(Attribution a) {
    final selection = _composer.selection;
    if (selection == null) return false;
    if (selection.isCollapsed) {
      return _composer.preferences.currentAttributions.contains(a);
    }
    return _document.doesSelectedTextContainAttributions(selection, {a});
  }

  void _toggleAttribution(Attribution a) {
    final selection = _composer.selection;
    if (selection == null) return;
    if (selection.isCollapsed) {
      _composer.preferences.toggleStyle(a);
      return;
    }
    _editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: _document.getRangeBetween(
          selection.base,
          selection.extent,
        ),
        attributions: {a},
      ),
    ]);
  }

  void _convertSelectedToList(ListItemType type) {
    final selection = _composer.selection;
    if (selection == null) return;
    final nodeId = selection.extent.nodeId;
    _editor.execute([
      ConvertParagraphToListItemRequest(nodeId: nodeId, type: type),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    final disabled = !widget.enabled;
    final canEdit = widget.enabled && !widget.readOnly;
    final showEditor = canEdit && _editing;
    final showToolbar = showEditor;

    // The sliver fed into the CustomScrollView host below. Must stay a raw
    // SuperEditor/SuperReader — they return a Sliver when hosted in a
    // Scrollable, so RenderBox wrappers (ExcludeFocus / GestureDetector) go
    // *around* the scroll host, never between it and the editor.
    //
    // Only the focused field mounts a `SuperEditor` (and therefore one IME
    // client); every other field renders a read-only `SuperReader` with no
    // IME, so the many-editor screens never collide on the null input id.
    final Widget sliver = showEditor
        ? SuperEditor(
            editor: _editor,
            focusNode: _focusNode,
            // The reader had no editing focus to hand over, so grab focus on
            // mount. Caret lands at the document edge rather than the exact
            // tap offset — an accepted tradeoff for never colliding IME
            // registrations across the many-editor screens.
            autofocus: true,
            stylesheet: _buildStylesheet(t),
          )
        : SuperReader(editor: _editor, stylesheet: _buildStylesheet(t));

    final frame = Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showToolbar)
            _MarkdownToolbar(
              composer: _composer,
              isActive: _selectionHas,
              onBold: () => _toggleAttribution(boldAttribution),
              onItalic: () => _toggleAttribution(italicsAttribution),
              onUnderline: () => _toggleAttribution(underlineAttribution),
              onBulletList: () =>
                  _convertSelectedToList(ListItemType.unordered),
              onNumberedList: () =>
                  _convertSelectedToList(ListItemType.ordered),
            ),
          _EditorHost(
            height: widget.height,
            expand: widget.expand,
            // In reader mode the inner `SuperReader` subtree is `ExcludeFocus`'d
            // so its deep, possibly-unlaid render objects stay out of the
            // geometry-based `ReadingOrderTraversalPolicy` sort (closes the
            // `hasSize` crash), while a single lightweight host `Focus` node
            // remains Tab-reachable and keyboard-activatable. Tap or keyboard
            // activation promotes the field to the editing `SuperEditor`.
            // These wrappers sit *outside* the sliver host — never between it
            // and the editor — so the sliver protocol stays intact.
            //
            // Edge: a field scrolled off-screen in a `TabBarView` while still
            // focused/editing keeps its `SuperEditor` mounted; switching tabs
            // normally unfocuses it (→ reader), so this is not a live path.
            excludeFocus: !showEditor,
            enterEditing: (!showEditor && canEdit) ? _enterEditing : null,
            sliver: sliver,
          ),
        ],
      ),
    );

    final body = disabled
        ? IgnorePointer(child: Opacity(opacity: 0.55, child: frame))
        : frame;

    if (!widget.showLabel) return body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: InSpacing.xs, left: 2),
          child: Text(
            widget.label,
            style: TextStyle(
              color: disabled ? t.ink3 : t.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body,
      ],
    );
  }

  Stylesheet _buildStylesheet(InTheme t) {
    // Replace the default block-level rule (which hardcodes black text + 640
    // max width + horizontal padding sized for a full-screen editor) with one
    // tuned for a settings-form field. Subsequent rules from defaultStylesheet
    // still apply for headers, lists, blockquote, etc.
    return defaultStylesheet.copyWith(
      addRulesAfter: [
        StyleRule(
          BlockSelector.all,
          (doc, docNode) => {
            Styles.maxWidth: double.infinity,
            Styles.padding: CascadingPadding.symmetric(
              horizontal: InSpacing.md(context),
              vertical: InSpacing.xs,
            ),
            Styles.textStyle: TextStyle(
              color: t.ink,
              fontSize: 14,
              height: 1.4,
            ),
          },
        ),
      ],
    );
  }
}

/// Bounds the editor's height and gives SuperEditor/SuperReader their own
/// (closer) sliver host.
///
/// SuperEditor/SuperReader walk the ancestor chain for a vertical Scrollable
/// and return their content as a Sliver when they find one. Settings screens
/// sit inside a `ListView` (SettingsFormShell), so without this nested
/// CustomScrollView the returned Sliver would collide with the non-sliver
/// parent. The focus/tap wrappers are applied *around* the scroll host so the
/// sliver protocol between CustomScrollView and the editor is never broken.
class _EditorHost extends StatelessWidget {
  const _EditorHost({
    required this.height,
    required this.expand,
    required this.excludeFocus,
    required this.enterEditing,
    required this.sliver,
  });

  final double height;
  final bool expand;
  final bool excludeFocus;

  /// Non-null only in the editable read-only state: invoked to promote the
  /// field to the editing `SuperEditor` (by pointer tap, by Tab focusing the
  /// host, or by Enter/Space activating it).
  final VoidCallback? enterEditing;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    Widget host = expand
        ? CustomScrollView(slivers: [sliver])
        : SizedBox(
            height: height,
            child: CustomScrollView(slivers: [sliver]),
          );
    if (excludeFocus) {
      // Keep the reader's deep (possibly-unlaid) render objects out of the
      // focus-traversal tree so the geometry-based traversal policy can't
      // read `.rect` on them.
      host = ExcludeFocus(child: host);
    }
    if (enterEditing != null) {
      final enter = enterEditing!;
      host = FocusableActionDetector(
        // Tab lands on this single lightweight host node; focusing or
        // activating (Enter/Space) it promotes to the editor — markdown
        // fields stay keyboard-reachable.
        onFocusChange: (focused) {
          if (focused) enter();
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              enter();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enter,
          // The reader is inert to pointers so this tap layer
          // deterministically wins the gesture arena over SuperReader's own
          // mouse/selection interactor. Read-mode text selection is
          // sacrificed — acceptable; the field's purpose is editing.
          child: IgnorePointer(child: host),
        ),
      );
    }
    // In expand mode the host fills the remaining height of the frame's
    // Column (toolbar takes its intrinsic height, the editor takes the rest)
    // so there's no dead space below the editor inside a fixed-height panel.
    return expand ? Expanded(child: host) : host;
  }
}

class _MarkdownToolbar extends StatelessWidget {
  const _MarkdownToolbar({
    required this.composer,
    required this.isActive,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onBulletList,
    required this.onNumberedList,
  });

  final MutableDocumentComposer composer;

  /// Returns whether the given attribution applies to the current selection
  /// (or composer preferences when the selection is collapsed). Used to paint
  /// the active state of the corresponding button.
  final bool Function(Attribution) isActive;

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border(bottom: BorderSide(color: t.border)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InRadii.r1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.xs,
        vertical: 2,
      ),
      child: ListenableBuilder(
        // Repaint button active states as the selection (and composer
        // preferences when the selection is collapsed) changes.
        listenable: composer,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                tooltip: context.tr('bold'),
                active: isActive(boldAttribution),
                onPressed: onBold,
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: context.tr('italic'),
                active: isActive(italicsAttribution),
                onPressed: onItalic,
              ),
              _ToolbarButton(
                icon: Icons.format_underline,
                tooltip: context.tr('underline'),
                active: isActive(underlineAttribution),
                onPressed: onUnderline,
              ),
              const SizedBox(width: InSpacing.sm),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                tooltip: context.tr('bullet_list'),
                onPressed: onBulletList,
              ),
              _ToolbarButton(
                icon: Icons.format_list_numbered,
                tooltip: context.tr('numbered_list'),
                onPressed: onNumberedList,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: active ? t.accent : t.ink2,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => active ? t.accentSoft : null,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InRadii.r1),
          ),
        ),
      ),
    );
  }
}
