import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/search_result.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/l10n/localization.dart';

/// Maps a `POST /api/v1/search` response group key to an [EntityType] so
/// the hit routes through the entity registry (module-enabled + permission
/// gated). `settings` (and any unknown group) → null: the caller falls
/// back to the server-supplied `path`. Pure + unit-tested.
EntityType? entityTypeForSearchGroup(String group) {
  switch (group) {
    case 'clients':
    case 'client_contacts':
      return EntityType.client;
    case 'invoices':
      return EntityType.invoice;
    case 'quotes':
      return EntityType.quote;
    case 'credits':
      return EntityType.credit;
    case 'payments':
      return EntityType.payment;
    case 'recurrings':
    case 'recurring_invoices':
      return EntityType.recurringInvoice;
    case 'projects':
      return EntityType.project;
    case 'tasks':
      return EntityType.task;
    case 'products':
      return EntityType.product;
    case 'expenses':
      return EntityType.expense;
    case 'vendors':
    case 'vendor_contacts':
      return EntityType.vendor;
    default:
      return null; // settings + anything unknown → use server path
  }
}

/// Cmd/Ctrl+K global command palette. Server-backed search
/// (`SearchApi`) across all entities + settings; arrow/enter/escape
/// keyboard nav; selection routes via the entity registry (or the
/// server path for settings).
Future<void> showCommandPalette(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: _CommandPalette(),
    ),
  );
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette();

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> _results = const [];
  bool _loading = false;
  int _selected = 0;
  int _reqSeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String q) async {
    final seq = ++_reqSeq;
    setState(() => _loading = true);
    try {
      final r = await context.read<Services>().search.search(q);
      if (!mounted || seq != _reqSeq) return;
      setState(() {
        _results = r;
        _selected = 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _reqSeq) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  void _move(int delta) {
    if (_results.isEmpty) return;
    setState(() {
      _selected = (_selected + delta) % _results.length;
      if (_selected < 0) _selected += _results.length;
    });
  }

  void _select() {
    if (_selected < 0 || _selected >= _results.length) return;
    final r = _results[_selected];
    Navigator.of(context).pop();
    final type = entityTypeForSearchGroup(r.group);
    if (type != null && r.id.isNotEmpty) {
      goEntityRecord(context, type, r.id);
    } else if (r.path.isNotEmpty) {
      context.go(r.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.escape):
            () => Navigator.of(context).pop(),
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.go,
                onChanged: _onChanged,
                onSubmitted: (_) => _select(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: context.tr('search'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.tr(
                          _controller.text.trim().isEmpty
                              ? 'search'
                              : 'no_records_found',
                        ),
                        style: TextStyle(color: tokens.ink3),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        final sel = i == _selected;
                        return Material(
                          color: sel
                              ? tokens.accentSoft
                              : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            title: Text(r.name),
                            subtitle: Text(
                              context.tr(r.group),
                              style: TextStyle(
                                color: tokens.ink3,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () {
                              setState(() => _selected = i);
                              _select();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
