import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/app/debug_capture_store.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/utils/formatting.dart';

/// Hidden Debug Panel surfaced on the System Logs screen after a long-press
/// on the AppBar title. Two stacked sections (Requests + Errors) plus a
/// toggle/clear/copy header. Reactive to [DebugCaptureStore] — flipping the
/// switch or capturing a new entry triggers a rebuild here automatically.
///
/// All data is in-memory and reset on app restart; turning the toggle off
/// also wipes both rings. The store applies redaction (`redact()` /
/// `redactHeaders()`) before anything reaches this widget.
class DebugPanelSection extends StatelessWidget {
  const DebugPanelSection({super.key, required this.store});

  final DebugCaptureStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final network = store.networkEntries;
        final errors = store.diagnosticEntries;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DebugPanelHeader(
              store: store,
              hasAny: network.isNotEmpty || errors.isNotEmpty,
            ),
            _NetworkSection(entries: network, enabled: store.enabled),
            _ErrorsSection(entries: errors, enabled: store.enabled),
          ],
        );
      },
    );
  }
}

class _DebugPanelHeader extends StatelessWidget {
  const _DebugPanelHeader({required this.store, required this.hasAny});

  final DebugCaptureStore store;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('debug_panel'),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('debug_capture_enabled')),
          subtitle: Text(context.tr('debug_capture_help')),
          value: store.enabled,
          onChanged: store.setEnabled,
        ),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all),
              label: Text(context.tr('clear_capture')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
              ),
              onPressed: hasAny ? store.clear : null,
            ),
            SizedBox(width: InSpacing.md(context)),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined),
              label: Text(context.tr('copy_debug_capture')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 40),
              ),
              onPressed: hasAny ? () => _copyAll(context) : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _copyAll(BuildContext context) async {
    final buf = StringBuffer();
    final network = store.networkEntries;
    final errors = store.diagnosticEntries;
    buf.writeln('# Debug Capture');
    buf.writeln('Captured at: ${DateTime.now().toUtc().toIso8601String()}');
    buf.writeln('Network entries: ${network.length}');
    buf.writeln('Diagnostic entries: ${errors.length}');
    buf.writeln();
    buf.writeln('## Network');
    for (final n in network) {
      buf.writeln('--');
      buf.writeln('${n.startedAt.toUtc().toIso8601String()}  '
          '${n.method} ${n.url}');
      buf.writeln('status: ${n.statusCode ?? "—"}  '
          'duration: ${n.duration.inMilliseconds}ms');
      if (n.error != null) buf.writeln('error: ${n.error}');
      buf.writeln('request_headers: ${n.requestHeaders}');
      if (n.requestBody != null) buf.writeln('request_body: ${n.requestBody}');
      if (n.responseHeaders != null) {
        buf.writeln('response_headers: ${n.responseHeaders}');
      }
      if (n.responseBody != null) buf.writeln('response_body: ${n.responseBody}');
    }
    buf.writeln();
    buf.writeln('## Errors');
    for (final e in errors) {
      buf.writeln('--');
      buf.writeln('${e.time.toUtc().toIso8601String()}  '
          '[${e.level}]${e.loggerName == null ? "" : " ${e.loggerName}"}');
      buf.writeln(e.message);
      if (e.stack != null) buf.writeln(e.stack);
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!context.mounted) return;
    Notify.success(context, context.tr('copied_to_clipboard'));
  }
}

class _NetworkSection extends StatelessWidget {
  const _NetworkSection({required this.entries, required this.enabled});

  final List<NetworkCaptureEntry> entries;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: '${context.tr('network_requests')} (${entries.length})',
      children: [
        if (entries.isEmpty)
          _EmptyHint(enabled: enabled)
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.inTheme.border,
                  ),
                _NetworkRow(entry: entries[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _ErrorsSection extends StatelessWidget {
  const _ErrorsSection({required this.entries, required this.enabled});

  final List<DiagnosticCaptureEntry> entries;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: '${context.tr('recent_errors')} (${entries.length})',
      children: [
        if (entries.isEmpty)
          _EmptyHint(enabled: enabled)
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.inTheme.border,
                  ),
                _ErrorRow(entry: entries[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        enabled ? context.tr('debug_capture_waiting') : context.tr('capture_off_hint'),
        style: TextStyle(color: tokens.ink3, fontSize: 13),
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.entry});

  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (fg, bg) = _statusColors(tokens, entry);
    final pillLabel = entry.error != null
        ? 'ERR'
        : entry.statusCode?.toString() ?? '—';
    final time = formatRelativeTime(
      context,
      DateTime.now().difference(entry.startedAt),
    );
    final durationMs = entry.duration.inMilliseconds;
    final pathPreview = _shortenUrl(entry.url);
    return InkWell(
      onTap: () => _showDetail(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: StatusPill(label: pillLabel, fgColor: fg, bgColor: bg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.method}  $pathPreview',
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${durationMs}ms · $time',
                    style: TextStyle(color: tokens.ink3, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tokens.ink3),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(InTheme t, NetworkCaptureEntry e) {
    if (e.error != null) return (t.overdue, t.overdueSoft);
    final s = e.statusCode ?? 0;
    if (s >= 200 && s < 300) return (t.paid, t.paidSoft);
    if (s >= 300 && s < 400) return (t.partial, t.partialSoft);
    if (s >= 400 && s < 500) return (t.sent, t.sentSoft);
    return (t.overdue, t.overdueSoft);
  }

  static String _shortenUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    final path = parsed.path;
    final query = parsed.hasQuery ? '?${parsed.query}' : '';
    return '$path$query';
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.entry});

  final DiagnosticCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final (fg, bg) = _levelColors(tokens, entry.level);
    final time = formatRelativeTime(
      context,
      DateTime.now().difference(entry.time),
    );
    final source = entry.loggerName ?? entry.level;
    return InkWell(
      onTap: () => _showDetail(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              child: StatusPill(label: entry.level, fgColor: fg, bgColor: bg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$source · $time',
                    style: TextStyle(color: tokens.ink3, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: tokens.ink3),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _levelColors(InTheme t, String level) {
    final upper = level.toUpperCase();
    if (upper == 'ERROR' || upper == 'SEVERE' || upper == 'SHOUT') {
      return (t.overdue, t.overdueSoft);
    }
    if (upper == 'WARNING') return (t.sent, t.sentSoft);
    return (t.ink3, t.accentSoft);
  }
}

void _showDetail(BuildContext context, Object entry) {
  showDialog<void>(
    context: context,
    builder: (context) => _DetailDialog(entry: entry),
  );
}

class _DetailDialog extends StatelessWidget {
  const _DetailDialog({required this.entry});

  final Object entry;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final title = entry is NetworkCaptureEntry
        ? '${entry.method} ${_pathOf(entry.url)}'
        : entry is DiagnosticCaptureEntry
            ? '[${entry.level}] ${entry.loggerName ?? ''}'
            : '';
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: entry is NetworkCaptureEntry
              ? _NetworkDetail(entry: entry)
              : entry is DiagnosticCaptureEntry
                  ? _ErrorDetail(entry: entry)
                  : const SizedBox.shrink(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final text = _entryAsText(entry);
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            Notify.success(context, context.tr('copied_to_clipboard'));
          },
          child: Text(context.tr('copy')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }

  static String _pathOf(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    return u.path;
  }

  static String _entryAsText(Object e) {
    if (e is NetworkCaptureEntry) {
      final buf = StringBuffer()
        ..writeln('${e.method} ${e.url}')
        ..writeln('started: ${e.startedAt.toUtc().toIso8601String()}')
        ..writeln('status:  ${e.statusCode ?? "—"}')
        ..writeln('duration: ${e.duration.inMilliseconds}ms');
      if (e.error != null) buf.writeln('error: ${e.error}');
      buf
        ..writeln()
        ..writeln('request_headers:')
        ..writeln(_formatMap(e.requestHeaders));
      if (e.requestBody != null) {
        buf
          ..writeln()
          ..writeln('request_body:')
          ..writeln(_prettyJson(e.requestBody!));
      }
      if (e.responseHeaders != null) {
        buf
          ..writeln()
          ..writeln('response_headers:')
          ..writeln(_formatMap(e.responseHeaders!));
      }
      if (e.responseBody != null) {
        buf
          ..writeln()
          ..writeln('response_body:')
          ..writeln(_prettyJson(e.responseBody!));
      }
      return buf.toString();
    }
    if (e is DiagnosticCaptureEntry) {
      final buf = StringBuffer()
        ..writeln('[${e.level}] ${e.loggerName ?? ""}')
        ..writeln(e.time.toUtc().toIso8601String())
        ..writeln()
        ..writeln(e.message);
      if (e.stack != null) {
        buf
          ..writeln()
          ..writeln(e.stack);
      }
      return buf.toString();
    }
    return e.toString();
  }
}

class _NetworkDetail extends StatelessWidget {
  const _NetworkDetail({required this.entry});

  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kv(
          context,
          [
            ('URL', entry.url),
            ('Started', entry.startedAt.toUtc().toIso8601String()),
            ('Status', entry.statusCode?.toString() ?? '—'),
            ('Duration', '${entry.duration.inMilliseconds}ms'),
            if (entry.error != null) ('Error', entry.error!),
          ],
        ),
        const SizedBox(height: 12),
        _MonoBlock(
          label: context.tr('request_headers'),
          text: _formatMap(entry.requestHeaders),
          tokens: tokens,
        ),
        if (entry.requestBody != null) ...[
          const SizedBox(height: 12),
          _MonoBlock(
            label: context.tr('request_body'),
            text: _prettyJson(entry.requestBody!),
            tokens: tokens,
          ),
        ],
        if (entry.responseHeaders != null) ...[
          const SizedBox(height: 12),
          _MonoBlock(
            label: 'Response headers',
            text: _formatMap(entry.responseHeaders!),
            tokens: tokens,
          ),
        ],
        if (entry.responseBody != null) ...[
          const SizedBox(height: 12),
          _MonoBlock(
            label: context.tr('response_body'),
            text: _prettyJson(entry.responseBody!),
            tokens: tokens,
          ),
        ],
      ],
    );
  }

  Widget _kv(BuildContext context, List<(String, String)> rows) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    row.$1,
                    style: TextStyle(color: tokens.ink3, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    row.$2,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  const _ErrorDetail({required this.entry});

  final DiagnosticCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entry.time.toUtc().toIso8601String(),
          style: TextStyle(color: tokens.ink3, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SelectableText(
          entry.message,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        if (entry.stack != null) ...[
          const SizedBox(height: 12),
          _MonoBlock(label: 'Stack', text: entry.stack!, tokens: tokens),
        ],
      ],
    );
  }
}

class _MonoBlock extends StatelessWidget {
  const _MonoBlock({
    required this.label,
    required this.text,
    required this.tokens,
  });

  final String label;
  final String text;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(color: tokens.ink3, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: tokens.accentSoft,
            borderRadius: BorderRadius.circular(InRadii.r2),
          ),
          padding: const EdgeInsets.all(8),
          child: SelectableText(
            text,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatMap(Map<String, String> map) {
  if (map.isEmpty) return '(none)';
  final buf = StringBuffer();
  final entries = map.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  for (final e in entries) {
    buf.writeln('${e.key}: ${e.value}');
  }
  return buf.toString().trimRight();
}

String _prettyJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '(empty)';
  final first = trimmed.codeUnitAt(0);
  if (first != 0x7B && first != 0x5B) return raw;
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(trimmed));
  } catch (_) {
    return raw;
  }
}
