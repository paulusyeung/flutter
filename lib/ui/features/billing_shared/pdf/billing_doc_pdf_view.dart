import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/billing_shared/billing_doc_type.dart';

/// Shared PDF preview pane for billing docs. Fetches bytes via the
/// caller-supplied [fetcher] (typically `services.invoices.api.downloadPdf`)
/// and renders via the `printing` package's [PdfPreview] (which carries
/// its own print/share/download toolbar).
///
/// State machine:
///   * First load → full-pane spinner.
///   * Subsequent reloads (design change, delivery-note toggle) → keep the
///     last-good PDF visible behind a translucent overlay so the user
///     doesn't see a blink.
///   * Error → [ErrorView] with retry.
///
/// `entity` decides what extra controls render (only [BillingDocType.invoice]
/// gets the delivery-note toggle today).
class BillingDocPdfView extends StatefulWidget {
  const BillingDocPdfView({
    super.key,
    required this.entity,
    required this.entityNumber,
    required this.fetcher,
    this.initialDeliveryNote = false,
  });

  /// Whether the first render requests the delivery-note variant (and the
  /// toggle starts in the on position). Only meaningful when
  /// [BillingDocType.supportsDeliveryNote] — i.e. invoices.
  final bool initialDeliveryNote;

  /// Which billing-doc type this widget is rendering. Used for the file
  /// name on download + to gate the delivery-note toggle.
  final BillingDocType entity;

  /// Human-readable identifier (e.g. invoice `number`) used as the
  /// downloaded file name's stem.
  final String entityNumber;

  /// Fetches PDF bytes. Receives `(designId, deliveryNote)` — both
  /// optional. Caller maps to the right repo/api method. Throws on
  /// failure; the widget catches and renders [ErrorView].
  final Future<Uint8List> Function({
    String? designId,
    required bool deliveryNote,
  }) fetcher;

  @override
  State<BillingDocPdfView> createState() => _BillingDocPdfViewState();
}

class _BillingDocPdfViewState extends State<BillingDocPdfView> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;
  late bool _deliveryNote = widget.initialDeliveryNote;
  String? _designId;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final myGen = ++_generation;
    try {
      final bytes = await widget.fetcher(
        designId: _designId,
        deliveryNote: _deliveryNote,
      );
      if (!mounted || myGen != _generation) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || myGen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final err = _error;
    if (bytes == null && _loading && err == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bytes == null && err != null) {
      return ErrorView(
        message: '$err',
        onRetry: _load,
      );
    }
    if (bytes == null) {
      return EmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: context.tr('view_pdf'),
      );
    }
    final fileName =
        '${widget.entity.wireName}_${widget.entityNumber.isEmpty ? 'preview' : widget.entityNumber}.pdf';
    final scrim = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4);
    return Stack(
      children: [
        Positioned.fill(
          child: PdfPreview(
            build: (_) => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            maxPageWidth: 800,
            pdfFileName: fileName,
          ),
        ),
        if (widget.entity.supportsDeliveryNote)
          Positioned(
            top: InSpacing.md(context),
            right: InSpacing.md(context),
            child: _DeliveryNoteToggle(
              value: _deliveryNote,
              onChanged: (v) {
                setState(() => _deliveryNote = v);
                _load();
              },
            ),
          ),
        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: scrim,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _DeliveryNoteToggle extends StatelessWidget {
  const _DeliveryNoteToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    return Material(
      color: t.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.md(context),
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('delivery_note')),
            const SizedBox(width: 8),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
