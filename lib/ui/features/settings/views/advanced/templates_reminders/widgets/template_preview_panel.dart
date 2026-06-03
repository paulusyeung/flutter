import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/services/templates_api.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/views/advanced/templates_reminders/preview_controller.dart';

/// Live preview of the rendered email template. Listens to a
/// [PreviewController] for state transitions (idle / loading / loaded /
/// error) and renders the appropriate UI.
///
/// Platform switch on the success branch:
///
/// * iOS / Android — `WebViewWidget` loads the full HTML wrapper returned
///   from `/api/v1/templates` via `loadHtmlString`. CSS, inline images,
///   and the server's template chrome all render correctly.
/// * macOS / Windows / Linux / web — `webview_flutter` is mobile-only, so
///   we fall back to v1's pattern (admin-portal `templates_and_reminders.
///   dart:600-614`): render the rendered subject + body markdown through
///   `SuperReader` (the read-only viewer — no IME interactor, so it never
///   collides with the editable body field's `SuperEditor`). The server-side variable
///   substitution still happens (the `/templates` POST runs on every
///   debounced edit); only the rendering layer differs.
class TemplatePreviewPanel extends StatelessWidget {
  const TemplatePreviewPanel({super.key, required this.controller});

  final PreviewController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<TemplatePreviewState>(
        valueListenable: controller,
        builder: (context, state, _) {
          return switch (state) {
            TemplatePreviewIdle() => const _PreviewPlaceholder(),
            TemplatePreviewLoading() => const _PreviewLoading(),
            TemplatePreviewLoaded(:final preview) => _PreviewBody(
              preview: preview,
            ),
            TemplatePreviewError(:final kind) => _PreviewError(
              kind: kind,
              onRetry: controller.refresh,
            ),
          };
        },
      ),
    );
  }
}

/// Fills the panel's bounded height when one is given (side-by-side right
/// column, fullscreen `_PreviewSheet`), and falls back to a fixed 600px
/// when the panel is laid out without a height bound. Keeps every preview
/// state the same height and prevents the `RenderFlex overflowed` that a
/// hard-coded 600 caused inside a shorter parent.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => c.hasBoundedHeight
          ? SizedBox.expand(child: child)
          : SizedBox(height: 600, child: child),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    return _PreviewFrame(
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: InSpacing.lg(context)),
        child: Text(
          context.tr('template_preview_placeholder'),
          textAlign: TextAlign.center,
          style: TextStyle(color: t.ink2, fontSize: 14),
        ),
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    return const _PreviewFrame(
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.kind, required this.onRetry});

  final TemplatePreviewErrorKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetwork = kind == TemplatePreviewErrorKind.network;
    final labelKey = isNetwork
        ? 'no_internet_connection'
        : 'error_refresh_page';
    return _PreviewFrame(
      child: Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(labelKey),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              // Network errors can't be solved by an immediate retry —
              // disable the button so the user knows to fix connectivity
              // first. Timeout and server-side errors are retryable.
              onPressed: isNetwork ? null : onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.preview});

  final TemplatePreview preview;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    return LayoutBuilder(
      builder: (context, c) {
        final body = isMobile
            ? _MobileWebView(wrapper: preview.wrapper)
            : _DesktopMarkdownPreview(body: preview.body);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PreviewSubjectBar(subject: preview.subject),
            if (c.hasBoundedHeight)
              Expanded(child: body)
            else
              SizedBox(height: 600, child: body),
          ],
        );
      },
    );
  }
}

class _PreviewSubjectBar extends StatelessWidget {
  const _PreviewSubjectBar({required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context) {
    final t = context.inTheme;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Text(
            '${context.tr('subject')}: ',
            style: theme.textTheme.bodySmall?.copyWith(color: t.ink2),
          ),
          Expanded(
            child: Text(
              subject.isEmpty ? '—' : subject,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileWebView extends StatefulWidget {
  const _MobileWebView({required this.wrapper});

  final String wrapper;

  @override
  State<_MobileWebView> createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<_MobileWebView> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(widget.wrapper);
  }

  @override
  void didUpdateWidget(covariant _MobileWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wrapper != widget.wrapper) {
      _controller.loadHtmlString(widget.wrapper);
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

class _DesktopMarkdownPreview extends StatefulWidget {
  const _DesktopMarkdownPreview({required this.body});

  final String body;

  @override
  State<_DesktopMarkdownPreview> createState() =>
      _DesktopMarkdownPreviewState();
}

class _DesktopMarkdownPreviewState extends State<_DesktopMarkdownPreview> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;

  @override
  void initState() {
    super.initState();
    _seed(widget.body);
  }

  @override
  void didUpdateWidget(covariant _DesktopMarkdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      _composer.dispose();
      _seed(widget.body);
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  /// The `/api/v1/templates` server returns the rendered body as HTML
  /// (after variable substitution + markdown→HTML conversion). SuperEditor
  /// only ingests markdown — strip the most common block-level tags so
  /// users see a passable preview without a real HTML renderer.
  void _seed(String body) {
    final stripped = body
        .replaceAll(RegExp(r'<\s*/?\s*p\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'<\s*/?\s*div\s*/?\s*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    _document = stripped.trim().isEmpty
        ? MutableDocument.empty()
        : deserializeMarkdownToDocument(stripped);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Render the email body on white in both light and dark mode:
    // super_editor's default stylesheet uses fixed dark text, and the real
    // email (and the mobile WebView / PDF preview) is white — so painting it
    // on the dark app surface would be dark-on-dark and unreadable.
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: InSpacing.lg(context)),
      child: SuperReader(editor: _editor),
    );
  }
}
