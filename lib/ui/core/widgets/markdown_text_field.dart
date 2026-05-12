import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

import 'package:admin/app/design_tokens.dart';

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
    this.height = 200,
    this.enabled = true,
    this.readOnly = false,
    this.externalValueKey,
    this.focusNode,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Starting markdown content. Null and empty are equivalent.
  final String? initialValue;

  /// Fired with the serialized markdown after [debounce] of no further edits.
  /// Also flushed synchronously when focus leaves the editor.
  final ValueChanged<String> onChanged;

  /// Visible label above the editor frame.
  final String label;

  /// Fixed height of the editor's scroll viewport. Content beyond this scrolls
  /// inside the editor.
  final double height;

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
  }

  @override
  void didUpdateWidget(covariant MarkdownTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    final showToolbar = widget.enabled && !widget.readOnly;

    final frame = Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(
            height: widget.height,
            // SuperEditor walks the ancestor chain for a vertical Scrollable
            // and returns its content as a Sliver when it finds one. The
            // Defaults screen sits inside a `ListView` (SettingsFormShell), so
            // without this nested CustomScrollView the returned Sliver would
            // collide with whatever non-sliver parent we wrap it in. Giving
            // SuperEditor its own (closer) sliver host fixes the type
            // mismatch and bounds the editor's height at the SizedBox.
            child: CustomScrollView(
              slivers: [
                SuperEditor(
                  editor: _editor,
                  focusNode: _focusNode,
                  stylesheet: _buildStylesheet(t),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final body = disabled
        ? IgnorePointer(child: Opacity(opacity: 0.55, child: frame))
        : frame;

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
            Styles.padding: const CascadingPadding.symmetric(
              horizontal: InSpacing.md,
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
                tooltip: 'Bold',
                active: isActive(boldAttribution),
                onPressed: onBold,
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                tooltip: 'Italic',
                active: isActive(italicsAttribution),
                onPressed: onItalic,
              ),
              _ToolbarButton(
                icon: Icons.format_underline,
                tooltip: 'Underline',
                active: isActive(underlineAttribution),
                onPressed: onUnderline,
              ),
              const SizedBox(width: InSpacing.sm),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                tooltip: 'Bullet list',
                onPressed: onBulletList,
              ),
              _ToolbarButton(
                icon: Icons.format_list_numbered,
                tooltip: 'Numbered list',
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
