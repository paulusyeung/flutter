import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/live_design_service.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/design_edit_view_model.dart';
import 'package:admin/utils/pdf_bytes_guard.dart';

/// Server-PDF preview of the current WYSIWYG draft. Sends the [Design]
/// through `POST /api/v1/preview?html=false` via
/// [LiveDesignService.renderDesignPreview] and renders the response bytes
/// with the `printing` package.
///
/// Phase 0 confirmed the server accepts the new `blocks` +
/// `documentSettings` shape; Phase 1.5 #1 makes sure the annotated blocks
/// ride along on the request. 422 responses surface as an inline banner
/// (no green PDF over a real error).
///
/// Entity-type picker lives in the header — the design's `entities` list
/// drives the options (e.g. `['invoice', 'quote', 'credit']`). Defaults to
/// the first entity.
class WysiwygPreviewSheet extends StatefulWidget {
  const WysiwygPreviewSheet({
    super.key,
    required this.service,
    required this.design,
    this.initialEntityType,
    this.debounce = const Duration(milliseconds: 800),
    this.isPro = true,
  });

  final LiveDesignService service;
  final Design design;

  /// Initial entity type (defaults to `design.entities.first` or
  /// `'invoice'` if the list is empty).
  final String? initialEntityType;

  /// Time between [design] / entity-type changes and the server call. Tests
  /// pass [Duration.zero] to skip the wait.
  final Duration debounce;

  /// When false, overlay a diagonal "Pro required" watermark over the
  /// rendered PDF — Phase 8l acceptance criterion. Defaults to `true`
  /// so existing call sites + tests aren't affected; the WYSIWYG screen
  /// passes the auth-derived value explicitly.
  final bool isPro;

  @override
  State<WysiwygPreviewSheet> createState() => _WysiwygPreviewSheetState();
}

class _WysiwygPreviewSheetState extends State<WysiwygPreviewSheet> {
  late String _entityType;
  Timer? _debounce;
  bool _loading = false;
  Uint8List? _pdf;
  String? _errorMessage;
  Map<String, List<String>>? _fieldErrors;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _entityType =
        widget.initialEntityType ??
        widget.design.entities.firstOrNull ??
        'invoice';
    _scheduleRender(immediate: true);
  }

  @override
  void didUpdateWidget(WysiwygPreviewSheet old) {
    super.didUpdateWidget(old);
    // Re-render when the design draft changes (parent rebuilds with a new
    // [Design] reference each time the VM notifies).
    if (!identical(old.design, widget.design)) {
      _scheduleRender();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onEntityChanged(String? next) {
    if (next == null || next == _entityType) return;
    setState(() => _entityType = next);
    _scheduleRender(immediate: true);
  }

  void _scheduleRender({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate || widget.debounce == Duration.zero) {
      _render();
      return;
    }
    _debounce = Timer(widget.debounce, _render);
  }

  Future<void> _render() async {
    if (!mounted) return;
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });
    try {
      final bytes = await widget.service.renderDesignPreview(
        entityType: _entityType,
        design: widget.design,
      );
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        // Guard: an empty / non-PDF body would crash printing's rasterizer
        // (RangeError on a zero-page document). Leave _pdf null so the body
        // falls back to the existing "no preview available" placeholder.
        _pdf = isRenderablePdf(bytes) ? bytes : null;
        _loading = false;
      });
    } on ValidationException catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
        _fieldErrors = e.fieldErrors;
      });
    } on NetworkException catch (_) {
      // Phase 20c: the api client wraps SocketException / TimeoutException
      // / failed-host-lookup into NetworkException. Map to a friendly
      // banner string instead of dumping the raw exception.
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _errorMessage = context.tr('network_error');
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    // Phase 18: dropdown lists every supported entity type (invoice /
    // quote / credit / purchase_order; broader set for templates) so
    // the user can preview any rendering regardless of which entities
    // the design happens to be bound to. The default selection logic
    // in initState still prefers `design.entities.first` when set.
    final entityOptions = widget.design.isTemplate
        ? DesignEditViewModel.supportedTemplateEntities
        : DesignEditViewModel.supportedEntities;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          entityType: _entityType,
          entityOptions: entityOptions,
          loading: _loading,
          onChanged: _onEntityChanged,
        ),
        if (_errorMessage != null)
          _ErrorBanner(message: _errorMessage!, fieldErrors: _fieldErrors),
        Expanded(
          child: _pdf == null
              ? Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(
                          context.tr('no_preview_available'),
                          style: TextStyle(color: tokens.ink3),
                        ),
                )
              : Stack(
                  children: [
                    PdfPreview(
                      build: (_) => _pdf!,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      maxPageWidth: 800,
                      pdfFileName: 'invoice_design_preview.pdf',
                    ),
                    // Phase 8l: free-user watermark. Doesn't block
                    // pointer input — print/share buttons inside the
                    // PdfPreview stay usable.
                    if (!widget.isPro)
                      const Positioned.fill(
                        key: ValueKey('wysiwyg-preview-watermark'),
                        child: IgnorePointer(child: _PreviewWatermark()),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.entityType,
    required this.entityOptions,
    required this.loading,
    required this.onChanged,
  });

  final String entityType;
  final List<String> entityOptions;
  final bool loading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.inTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            context.tr('preview'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(width: InSpacing.lg(context)),
          DropdownButton<String>(
            value: entityType,
            underline: const SizedBox.shrink(),
            items: [
              for (final type in entityOptions)
                DropdownMenuItem(value: type, child: Text(context.tr(type))),
            ],
            onChanged: onChanged,
          ),
          const Spacer(),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.tr('close'),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Phase 8l: diagonal "Pro required" watermark over the PDF preview for
/// free users. Translucent so the underlying design stays inspectable;
/// large rotated text reads as "you can preview, but not save without
/// upgrading."
class _PreviewWatermark extends StatelessWidget {
  const _PreviewWatermark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 6,
        child: Text(
          context.tr('pro_required_to_save_visual_designer').toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: context.inTheme.overdue.withValues(alpha: 0.18),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.fieldErrors});

  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  Widget build(BuildContext context) {
    final firstFieldError = fieldErrors?.values
        .expand((msgs) => msgs)
        .firstOrNull;
    return Material(
      color: context.inTheme.overdueSoft,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: InSpacing.lg(context),
          vertical: InSpacing.md(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 18, color: context.inTheme.overdue),
            SizedBox(width: InSpacing.sm),
            Expanded(
              child: Text(
                firstFieldError ?? message,
                style: TextStyle(color: context.inTheme.overdue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
