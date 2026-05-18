import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import 'package:admin/app/design_tokens.dart';

/// Syntax-highlighting HTML editor for one custom-design template section
/// (body / header / footer / includes / product / task). Wraps `re_editor`
/// with a line-number gutter and an atom-one theme keyed to the active
/// brightness.
///
/// Designs are raw HTML (with `$placeholder` / Twig fragments), so the
/// `xml` grammar is used — it covers HTML markup. This is a multi-line code
/// surface: Enter inserts a newline and it is deliberately **not** wired to
/// `FormSaveScope` (per CLAUDE.md Forms rule).
///
/// One-way seeding: the parent owns the string and feeds [initial] +
/// [seedRevision]. A bump of [seedRevision] (Start-from / Blank / Import /
/// Discard replacing the whole template) reseeds the controller; ordinary
/// keystrokes do not, so the cursor isn't yanked while typing.
class DesignCodeField extends StatefulWidget {
  const DesignCodeField({
    super.key,
    required this.initial,
    required this.seedRevision,
    required this.onChanged,
    this.insertController,
  });

  final String initial;
  final int seedRevision;
  final ValueChanged<String> onChanged;

  /// Optional hook the workspace uses to insert a `$variable` at the caret
  /// from the Variables pane. Assigned the controller once mounted.
  final ValueChanged<CodeLineEditingController>? insertController;

  @override
  State<DesignCodeField> createState() => _DesignCodeFieldState();
}

class _DesignCodeFieldState extends State<DesignCodeField> {
  late final CodeLineEditingController _controller =
      CodeLineEditingController.fromText(widget.initial);

  /// True while a programmatic reseed is assigning `_controller.text`.
  /// `re_editor` fires `onChanged` synchronously from that setter; echoing
  /// it back to `widget.onChanged` during `didUpdateWidget` would call the
  /// parent VM's `notifyListeners()` mid-build. The parent already owns the
  /// reseeded string (it bumped `seedRevision`), so the echo is redundant.
  bool _suppressOnChanged = false;

  @override
  void initState() {
    super.initState();
    widget.insertController?.call(_controller);
  }

  @override
  void didUpdateWidget(DesignCodeField old) {
    super.didUpdateWidget(old);
    // Whole-template replacement (Start-from / Blank / Import / Discard).
    // Reseed unconditionally on a seedRevision bump: even when the new text
    // coincidentally equals the current buffer, reassigning resets the
    // caret/scroll to the freshly-seeded template (and is otherwise a no-op).
    if (old.seedRevision != widget.seedRevision) {
      _suppressOnChanged = true;
      _controller.text = widget.initial;
      _suppressOnChanged = false;
    }
    if (!identical(old.insertController, widget.insertController)) {
      widget.insertController?.call(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
        color: tokens.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: CodeEditor(
        controller: _controller,
        wordWrap: false,
        onChanged: (_) {
          if (_suppressOnChanged) return;
          widget.onChanged(_controller.text);
        },
        padding: EdgeInsets.all(InSpacing.sm),
        style: CodeEditorStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          codeTheme: CodeHighlightTheme(
            languages: {'xml': CodeHighlightThemeMode(mode: langXml)},
            theme: dark ? atomOneDarkTheme : atomOneLightTheme,
          ),
        ),
        indicatorBuilder:
            (context, editingController, chunkController, notifier) {
          return DefaultCodeLineNumber(
            controller: editingController,
            notifier: notifier,
          );
        },
      ),
    );
  }
}
