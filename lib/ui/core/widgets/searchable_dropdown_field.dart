import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// Generic text-filter dropdown for long lists (countries, currencies,
/// industries, …). Replaces `DropdownButtonFormField` where scrolling through
/// every option is painful.
///
/// The caller owns the list and the projections — the widget has no knowledge
/// of `Services` or `statics`, so it stays reusable for any `T` (statics
/// values, gateway configs, freezed models, anything).
///
/// Typical use:
///
/// ```dart
/// SearchableDropdownField<Country>(
///   label: context.tr('country'),
///   items: countries,                       // pre-sorted by caller
///   initialValue: countries.firstWhereOrNull((c) => c.id == current),
///   displayString: (c) => c.name,
///   idOf: (c) => c.id,
///   onChanged: (c) => vm.set(c?.id ?? ''),
/// );
/// ```
class SearchableDropdownField<T extends Object> extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.initialValue,
    required this.displayString,
    required this.idOf,
    required this.onChanged,
    this.emptyHintKey,
    this.maxResults = 50,
    this.idleResults = 20,
  });

  /// Resolved (already-translated) field label.
  final String label;

  /// Source list. The caller is responsible for sorting.
  final List<T> items;

  /// Current selection (caller resolves id → item).
  final T? initialValue;

  /// Visible label for a given item.
  final String Function(T) displayString;

  /// Stable id used to detect external changes to [initialValue].
  final String Function(T) idOf;

  /// Fires with the new selection (or `null` when cleared).
  final ValueChanged<T?> onChanged;

  /// Localization key used as the placeholder label when [items] is empty
  /// (typically while statics is still loading). Defaults to `'loading'`.
  final String? emptyHintKey;

  /// Maximum items shown while filtering.
  final int maxResults;

  /// Items shown when the field is focused with an empty query.
  final int idleResults;

  @override
  State<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T extends Object>
    extends State<SearchableDropdownField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  T? _committed;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _committed = initial;
    _controller = TextEditingController(
      text: initial == null ? '' : widget.displayString(initial),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SearchableDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resync when the parent's [initialValue] changes (e.g. statics finished
    // loading async, or another part of the form reset the field). Skip while
    // focused — we'd be yanking the cursor mid-edit.
    final oldInitial = oldWidget.initialValue;
    final newInitial = widget.initialValue;
    final oldId = oldInitial == null ? null : oldWidget.idOf(oldInitial);
    final newId = newInitial == null ? null : widget.idOf(newInitial);
    if (oldId != newId && !_focusNode.hasFocus) {
      _committed = widget.initialValue;
      final expected = _committed == null
          ? ''
          : widget.displayString(_committed!);
      if (_controller.text != expected) {
        _controller.text = expected;
      }
    }
  }

  void _onFocusChange() {
    // On blur, snap the visible text back to the committed item's name —
    // otherwise the user could leave half-typed garbage in the field that
    // doesn't reflect any committed id.
    if (_focusNode.hasFocus) return;
    final expected = _committed == null
        ? ''
        : widget.displayString(_committed!);
    if (_controller.text != expected) {
      _controller.text = expected;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(InRadii.r1),
      borderSide: BorderSide(color: tokens.border),
    );

    // Statics not loaded yet — render a disabled placeholder so layout
    // doesn't shift when the list arrives.
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: context.tr(widget.emptyHintKey ?? 'loading'),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: InSpacing.md,
              vertical: 14,
            ),
            border: border,
            disabledBorder: border,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: RawAutocomplete<T>(
        textEditingController: _controller,
        focusNode: _focusNode,
        displayStringForOption: widget.displayString,
        optionsBuilder: (value) {
          final q = value.text.trim().toLowerCase();
          if (q.isEmpty) return widget.items.take(widget.idleResults);
          return widget.items
              .where((it) => widget.displayString(it).toLowerCase().contains(q))
              .take(widget.maxResults);
        },
        onSelected: (item) {
          _committed = item;
          widget.onChanged(item);
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textController,
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
                decoration: InputDecoration(
                  labelText: widget.label,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.ink3,
                  ),
                  floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.ink2,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: InSpacing.md,
                    vertical: 14,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(InRadii.r1),
                    borderSide: BorderSide(color: tokens.accent, width: 1.5),
                  ),
                  suffixIcon: textController.text.isEmpty
                      ? Icon(Icons.search, size: 18, color: tokens.ink3)
                      : IconButton(
                          tooltip: context.tr('clear'),
                          icon: Icon(Icons.close, size: 16, color: tokens.ink3),
                          onPressed: () {
                            textController.clear();
                            _committed = null;
                            widget.onChanged(null);
                          },
                        ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(InRadii.r2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 280,
                  maxWidth: 360,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final item = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InSpacing.md,
                          vertical: InSpacing.sm,
                        ),
                        child: Text(
                          widget.displayString(item),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
