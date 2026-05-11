import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/l10n/localization.dart';

/// Country picker for the client edit screen. Backed by the cached statics
/// `services.statics.countries`. Users see country names; the underlying
/// value bound to the VM is the country **id** (the server's integer id as
/// a string).
///
/// Falls back to a plain text field when the statics map is empty (i.e. the
/// very first frame after login, before statics has loaded) — keeps the
/// edit form usable instead of blocking.
class ClientEditCountryField extends StatefulWidget {
  const ClientEditCountryField({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// Country id (server id, e.g. `"840"` for US).
  final String initial;

  /// Fired with the selected country id (or `''` when cleared).
  final ValueChanged<String> onChanged;

  @override
  State<ClientEditCountryField> createState() => _ClientEditCountryFieldState();
}

class _ClientEditCountryFieldState extends State<ClientEditCountryField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _committedId = '';

  @override
  void initState() {
    super.initState();
    _committedId = widget.initial;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    // Resolve the initial id → name once the first frame can read Services.
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    if (!mounted) return;
    final services = context.read<Services>();
    final country = services.statics.country(widget.initial);
    if (country != null && country.name != _controller.text) {
      _controller.text = country.name;
    }
  }

  void _onFocusChange() {
    // When focus leaves, snap the visible text back to the committed
    // country's name. Otherwise the user could leave half-typed garbage in
    // the field — the underlying id wouldn't reflect it, which would be
    // surprising when they save and reopen.
    if (_focusNode.hasFocus) return;
    final services = context.read<Services>();
    final country = services.statics.country(_committedId);
    final expected = country?.name ?? '';
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
    final services = context.read<Services>();
    final countries = services.statics.countries.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(InRadii.r1),
      borderSide: BorderSide(color: tokens.border),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InSpacing.xs),
      child: RawAutocomplete<Country>(
        textEditingController: _controller,
        focusNode: _focusNode,
        displayStringForOption: (c) => c.name,
        optionsBuilder: (value) {
          if (countries.isEmpty) return const Iterable.empty();
          final q = value.text.trim().toLowerCase();
          if (q.isEmpty) return countries.take(20);
          return countries
              .where((c) => c.name.toLowerCase().contains(q))
              .take(50);
        },
        onSelected: (c) {
          _committedId = c.id;
          widget.onChanged(c.id);
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textController,
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
                decoration: InputDecoration(
                  labelText: context.tr('country'),
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
                            _committedId = '';
                            widget.onChanged('');
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
                    final country = options.elementAt(i);
                    return InkWell(
                      onTap: () => onSelected(country),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: InSpacing.md,
                          vertical: InSpacing.sm,
                        ),
                        child: Text(
                          country.name,
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
