import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// Opens the Keyboard Shortcuts helper dialog. Lists every non-obvious
/// shortcut wired into the shell, master-detail pane, token search, and
/// form save scope so power users can find them without spelunking.
Future<void> showKeyboardShortcutsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _KeyboardShortcutsDialog(),
  );
}

/// Show `⌘` on macOS/iOS, `Ctrl` everywhere else. Module-private so the
/// widget test can construct the label without reaching into private state.
@visibleForTesting
String platformModifierLabel([TargetPlatform? override]) {
  final p = override ?? defaultTargetPlatform;
  return (p == TargetPlatform.macOS || p == TargetPlatform.iOS)
      ? '⌘'
      : 'Ctrl';
}

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final mod = platformModifierLabel();

    final sections = <_Section>[
      _Section(
        icon: Icons.public_outlined,
        title: context.tr('shortcuts_global'),
        rows: [
          _Row(keys: ['$mod K'], description: context.tr('switch_company')),
          _Row(keys: ['$mod B'], description: context.tr('toggle_sidebar')),
          _Row(keys: ['$mod ,'], description: context.tr('settings')),
          _Row(keys: ['?'], description: context.tr('keyboard_shortcuts')),
          _LeaderRow(
            leader: 'G',
            targets: ['D', 'C', 'I', 'P', 'S', 'T'],
            description: context.tr('jump_to_section'),
          ),
        ],
      ),
      _Section(
        icon: Icons.list_alt,
        title: context.tr('shortcuts_records'),
        rows: [
          _Row(keys: ['N'], description: context.tr('new_record')),
          _Row(keys: ['E'], description: context.tr('edit_current')),
        ],
      ),
      _Section(
        icon: Icons.unfold_more,
        title: context.tr('shortcuts_navigation'),
        rows: [
          _Row(
            keys: ['J', '↓'],
            description: context.tr('next_record'),
          ),
          _Row(
            keys: ['K', '↑'],
            description: context.tr('previous_record'),
          ),
          _Row(keys: ['F'], description: context.tr('toggle_full_screen')),
          _Row(keys: ['Esc'], description: context.tr('close')),
        ],
      ),
      _Section(
        icon: Icons.search,
        title: context.tr('shortcuts_search'),
        rows: [
          _Row(keys: ['/'], description: context.tr('focus_search')),
          _Row(
            keys: ['↑', '↓'],
            description: context.tr('move_selection'),
          ),
          _Row(keys: ['Enter'], description: context.tr('apply_filter')),
          _Row(
            keys: ['Backspace'],
            description: context.tr('remove_last_filter'),
          ),
          _Row(keys: ['Esc'], description: context.tr('dismiss_menu')),
        ],
      ),
      _Section(
        icon: Icons.edit_note,
        title: context.tr('shortcuts_forms'),
        rows: [
          _Row(keys: ['Enter'], description: context.tr('save')),
          _Row(keys: ['$mod S'], description: context.tr('save')),
        ],
      ),
    ];

    return AlertDialog(
      title: Text(context.tr('keyboard_shortcuts')),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) SizedBox(height: InSpacing.lg(context)),
                _SectionView(section: sections[i]),
              ],
              SizedBox(height: InSpacing.lg(context)),
              Text(
                context.tr('shortcuts_ignored_while_typing'),
                style: TextStyle(fontSize: 12, color: tokens.ink3),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }
}

class _Section {
  const _Section({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_RowSpec> rows;
}

sealed class _RowSpec {
  const _RowSpec();
  String get description;
}

class _Row extends _RowSpec {
  const _Row({required this.keys, required this.description});

  final List<String> keys;
  @override
  final String description;
}

/// Two-key sequence (leader + one of several second keys). Renders as
/// `[G] then [D] [C] [I] [P] [S] [T]`.
class _LeaderRow extends _RowSpec {
  const _LeaderRow({
    required this.leader,
    required this.targets,
    required this.description,
  });

  final String leader;
  final List<String> targets;
  @override
  final String description;
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(section.icon, size: 16, color: tokens.ink2),
            const SizedBox(width: 8),
            Text(
              section.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
          ],
        ),
        SizedBox(height: InSpacing.md(context)),
        for (final row in section.rows) _RowView(row: row),
      ],
    );
  }
}

class _RowView extends StatelessWidget {
  const _RowView({required this.row});

  final _RowSpec row;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final keysWidget = switch (row) {
      _Row r => Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < r.keys.length; i++) ...[
            if (i > 0)
              Text(
                context.tr('or'),
                style: TextStyle(fontSize: 11, color: tokens.ink3),
              ),
            _KeyBadge(label: r.keys[i]),
          ],
        ],
      ),
      _LeaderRow r => Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _KeyBadge(label: r.leader),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              context.tr('then'),
              style: TextStyle(fontSize: 11, color: tokens.ink3),
            ),
          ),
          for (final t in r.targets) _KeyBadge(label: t),
        ],
      ),
    };
    // Leader rows render more badges horizontally than plain rows, so
    // give them a wider key column. 130 px is comfortable for ⌘+letter
    // and "A or B" patterns; the leader sequence is full-width.
    final isLeader = row is _LeaderRow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isLeader
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                keysWidget,
                const SizedBox(height: 4),
                Text(
                  row.description,
                  style: TextStyle(fontSize: 13, color: tokens.ink2),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 130, child: keysWidget),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.description,
                    style: TextStyle(fontSize: 13, color: tokens.ink2),
                  ),
                ),
              ],
            ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Semantics(
      label: 'Key: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(InRadii.r1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: 12,
            color: tokens.ink,
          ),
        ),
      ),
    );
  }
}
