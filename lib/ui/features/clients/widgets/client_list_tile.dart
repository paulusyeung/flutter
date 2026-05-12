import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/domain/contact.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/avatar_tint.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/status_pill.dart';
import 'package:admin/utils/formatting.dart';

// ─── Shared layout constants ───────────────────────────────────────────
// The screen-level column header strip reads these so headers and rows
// stay column-aligned. Don't drift them apart.
const double kColWPillSlot = 96;
const double kColWMoreMenu = 48;
const double kColLeadingWidth = 32; // avatar / checkbox
const double kColCellGap = 12;
// Legacy column widths consumed by the screen's `_ColumnHeaders` strip
// while the columns refactor is in flight. Safe to remove once the header
// migrates to the `ClientColumn`-driven layout.
const double kColWOutstanding = 140;
const double kColWLifetime = 120;

/// Actions a row can fire from its trailing menu. View/Edit map to navigation,
/// Archive/Restore call repository mutations. **No `delete`** — that needs
/// the password sheet flow, not yet wired here.
enum ClientRowAction { view, edit, archive, restore }

/// One row in the clients list. Adopts the v2 design system anatomy from
/// `docs/design/v2/screens.jsx:577-596` — square-ish tinted avatar, two
/// lines of identity, right-aligned monospace money columns.
///
/// The wide/narrow decision lives on the caller (typically a screen-level
/// `LayoutBuilder`) so the screen can decide whether to render a column
/// header strip above the rows. Pass [wide] in.
class ClientListTile extends StatefulWidget {
  const ClientListTile({
    super.key,
    required this.client,
    required this.formatter,
    required this.onTap,
    required this.wide,
    this.columns = const <ClientColumn>[],
    this.onAction,
    this.onLongPress,
    this.onSelectTap,
    this.selecting = false,
    this.selected = false,
    this.isLast = false,
  });

  final Client client;

  /// Built from `Services.formatterFor(companyId)` by the parent screen.
  /// Resolves per-client currency overrides via `client.currencyId`. Null
  /// while the screen's `formatterFor` future is still resolving — in that
  /// transient state the money columns render as `—`.
  final Formatter? formatter;

  /// Columns to render in wide mode. Empty list falls back to the legacy
  /// outstanding/lifetime layout (mainly for tests that haven't been
  /// updated). The narrow layout ignores this entirely — mobile keeps the
  /// rich identity card.
  final List<ClientColumn> columns;

  final VoidCallback onTap;

  /// Fires on long-press. Wired by the screen to enter selection mode and
  /// toggle this row.
  final VoidCallback? onLongPress;

  /// Fires when the user clicks the leading-slot selection checkbox. On
  /// desktop, hovering reveals an empty checkbox in place of the avatar; a
  /// click on it enters multi-select with this row toggled. In selection
  /// mode the checkbox is always visible and tapping it likewise toggles.
  final VoidCallback? onSelectTap;

  /// True for the wide table-style row; false for the narrow stacked tile.
  final bool wide;

  /// Action menu callback. When null, the more-horiz menu is hidden — which
  /// is exactly what selection mode wants (bulk actions live in the AppBar).
  final ValueChanged<ClientRowAction>? onAction;

  /// True while the list is in multi-select mode. The leading avatar swaps
  /// for a checkbox; the per-row action menu hides.
  final bool selecting;

  /// True when this tile is part of the active selection. Renders the
  /// `accentSoft` bg + 3px leading accent border. Also drives the
  /// checkbox's checked state when [selecting] is true.
  final bool selected;

  /// True for the last row in a list. Suppresses the bottom hairline so
  /// the list doesn't end with a stray divider above empty space.
  final bool isLast;

  @override
  State<ClientListTile> createState() => _ClientListTileState();
}

class _ClientListTileState extends State<ClientListTile> {
  // Toggled by the wrapping `MouseRegion`. Mouse-only — `onEnter`/`onExit`
  // never fire on touch, so iOS keeps its long-press-only entry to
  // multi-select.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final tokens = context.inTheme;
    final displayName = _displayName(w.client);
    final state = _stateFor(w.client);
    final outstandingPositive = w.client.balance > Decimal.zero;
    final formattedOutstanding =
        w.formatter?.money(
          w.client.balance,
          clientCurrencyId: w.client.currencyId,
        ) ??
        '';
    final formattedPaid =
        w.formatter?.money(
          w.client.paidToDate,
          clientCurrencyId: w.client.currencyId,
        ) ??
        '';

    return Semantics(
      button: true,
      label: _semanticsLabel(
        displayName: displayName,
        outstanding: formattedOutstanding,
        outstandingPositive: outstandingPositive,
        state: state,
        selecting: w.selecting,
        selected: w.selected,
      ),
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered) setState(() => _isHovered = false);
        },
        child: Material(
          color: w.selected
              ? Color.alphaBlend(
                  tokens.accent.withValues(alpha: 0.18),
                  tokens.surface,
                )
              : Colors.transparent,
          child: InkWell(
            onTap: w.onTap,
            onLongPress: w.onLongPress,
            hoverColor: w.selected ? Colors.transparent : tokens.surfaceAlt,
            child: Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  bottom: w.isLast
                      ? BorderSide.none
                      : BorderSide(color: tokens.border),
                  start: w.selected
                      ? BorderSide(color: tokens.accent, width: 3)
                      : BorderSide.none,
                ),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
              child: w.wide
                  ? _wide(
                      context,
                      tokens,
                      displayName: displayName,
                      state: state,
                    )
                  : _narrow(
                      context,
                      tokens,
                      displayName: displayName,
                      state: state,
                      formattedOutstanding: formattedOutstanding,
                      formattedPaid: formattedPaid,
                      outstandingPositive: outstandingPositive,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _narrow(
    BuildContext context,
    InTheme tokens, {
    required String displayName,
    required _RowState? state,
    required String formattedOutstanding,
    required String formattedPaid,
    required bool outstandingPositive,
  }) {
    final w = widget;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(displayName),
        const SizedBox(width: 12),
        Expanded(child: _identity(context, tokens, displayName)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _money(
              formattedOutstanding,
              isZero: !outstandingPositive,
              bold: outstandingPositive,
              color: outstandingPositive ? tokens.overdue : tokens.ink3,
            ),
            const SizedBox(height: 2),
            _money(
              formattedPaid,
              isZero: w.client.paidToDate == Decimal.zero,
              color: tokens.ink3,
              fontSize: 11,
            ),
          ],
        ),
        if (state != null) ...[
          const SizedBox(width: 8),
          _Pill(state: state, tokens: tokens),
        ],
        if (w.onAction != null) ...[
          const SizedBox(width: 4),
          ActionMenu(client: w.client, onAction: w.onAction!),
        ],
      ],
    );
  }

  Widget _wide(
    BuildContext context,
    InTheme tokens, {
    required String displayName,
    required _RowState? state,
  }) {
    final w = widget;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Leading `…` actions slot. Empty when `onAction` is null
        // (selection mode); otherwise the in-row PopupMenuButton.
        SizedBox(
          width: kColWMoreMenu,
          child: w.onAction == null
              ? const SizedBox.shrink()
              : ActionMenu(client: w.client, onAction: w.onAction!),
        ),
        const SizedBox(width: kColCellGap),
        _leading(displayName),
        const SizedBox(width: kColCellGap),
        for (final col in w.columns) ...[
          _CellSlot(
            column: col,
            entity: w.client,
            child: col.cellBuilder(w.client, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        // Pill slot — reserved width so the row's right edge stays fixed
        // even when the pill is absent.
        SizedBox(
          width: kColWPillSlot,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: state == null
                ? const SizedBox.shrink()
                : _Pill(state: state, tokens: tokens),
          ),
        ),
      ],
    );
  }

  /// Leading slot: tinted-initials avatar normally; circular checkbox in
  /// selection mode or on mouse hover (desktop entry to multi-select).
  /// Same 32×32 footprint in all states so right-hand columns don't shift.
  Widget _leading(String displayName) {
    final w = widget;
    if (w.selecting) {
      return _LeadingHitTarget(
        onTap: w.onSelectTap,
        child: SelectionCheckbox(checked: w.selected),
      );
    }
    if (_isHovered && w.onSelectTap != null) {
      return _LeadingHitTarget(
        onTap: w.onSelectTap,
        child: const SelectionCheckbox(checked: false),
      );
    }
    return _Avatar(seed: w.client.id, label: _initials(displayName));
  }

  Widget _identity(BuildContext context, InTheme tokens, String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tokens.ink,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        _SubtitleLine(client: widget.client, tokens: tokens),
      ],
    );
  }

  Widget _money(
    String text, {
    required bool isZero,
    Color? color,
    bool bold = false,
    double fontSize = 13,
  }) {
    return Text(
      isZero ? '—' : text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
        color: color,
        height: 1.2,
        // Tabular figures align decimal columns row-to-row.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ─── Column slot ───────────────────────────────────────────────────────

/// Renders one column's cell at its declared width or as a flex-expanded
/// slot for the identity column.
class _CellSlot extends StatelessWidget {
  const _CellSlot({
    required this.column,
    required this.entity,
    required this.child,
  });
  final ClientColumn column;
  final Client entity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aligned = Align(
      alignment: column.align == ColumnAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
    final cell = CellCopyHover(
      value: column.valueBuilder?.call(entity),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) {
      return Expanded(child: cell);
    }
    return SizedBox(width: column.width, child: cell);
  }
}

// ─── Action menu ───────────────────────────────────────────────────────

class ActionMenu extends StatelessWidget {
  const ActionMenu({super.key, required this.client, required this.onAction});

  final Client client;
  final ValueChanged<ClientRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    final canArchive = client.archivedAt == null && !client.isDeleted;
    final canRestore = client.archivedAt != null || client.isDeleted;
    return PopupMenuButton<ClientRowAction>(
      tooltip: context.tr('actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: onAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ClientRowAction.view,
          child: _MenuRow(
            icon: Icons.visibility_outlined,
            label: context.tr('view'),
          ),
        ),
        PopupMenuItem(
          value: ClientRowAction.edit,
          child: _MenuRow(icon: Icons.edit_outlined, label: context.tr('edit')),
        ),
        if (canArchive)
          PopupMenuItem(
            value: ClientRowAction.archive,
            child: _MenuRow(
              icon: Icons.archive_outlined,
              label: context.tr('archive'),
            ),
          ),
        if (canRestore)
          PopupMenuItem(
            value: ClientRowAction.restore,
            child: _MenuRow(
              icon: Icons.unarchive_outlined,
              label: context.tr('restore'),
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.inTheme.ink3),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ─── Subtitle line ─────────────────────────────────────────────────────

class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({required this.client, required this.tokens});
  final Client client;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final contact = _primaryContact(client);
    final contactLabel = _contactLabel(contact);
    final city = client.city.trim();

    final pieces = <String>[
      if (contactLabel.isNotEmpty) contactLabel,
      if (city.isNotEmpty) city,
    ];

    String text;
    Color color;
    if (pieces.isNotEmpty) {
      text = pieces.join(' · ');
      color = tokens.ink3;
    } else if (client.number.isNotEmpty) {
      text = client.number;
      color = tokens.ink3;
    } else {
      text = '—';
      color = tokens.ink4;
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: color, height: 1.25),
    );
  }
}

// ─── Selection checkbox ───────────────────────────────────────────────

/// Round 32×32 checkbox used in selection mode in place of the avatar, and
/// as the hover-reveal target in the leading slot on desktop. The underlying
/// row's onTap (wired by the screen) toggles selection, so this widget is
/// **display only** — it doesn't need its own onChanged.
class SelectionCheckbox extends StatelessWidget {
  const SelectionCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? tokens.accent : tokens.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? tokens.accent : tokens.borderStrong,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }
}

// ─── Leading hit target ───────────────────────────────────────────────

/// Wraps the leading-slot checkbox with a click-only hit target that
/// intercepts the tap so it doesn't bubble to the row's `InkWell` (which
/// would navigate). `HitTestBehavior.opaque` ensures the tap is consumed
/// even when the child painted region is smaller than the touch slop.
/// Also paints a `click` mouse cursor over the slot to signal the new
/// affordance on desktop.
class _LeadingHitTarget extends StatelessWidget {
  const _LeadingHitTarget({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

// ─── Avatar ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed, required this.label});
  final String seed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarTintFor(seed),
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1,
        ),
      ),
    );
  }
}

// ─── State pill ────────────────────────────────────────────────────────

enum _RowState { deleted, archived, unsynced }

_RowState? _stateFor(Client c) {
  if (c.isDeleted) return _RowState.deleted;
  if (c.archivedAt != null) return _RowState.archived;
  if (c.isDirty) return _RowState.unsynced;
  return null;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.state, required this.tokens});
  final _RowState state;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, tooltip) = switch (state) {
      _RowState.deleted => (
        context.tr('deleted'),
        tokens.overdueSoft,
        tokens.overdue,
        context.tr('deleted_soft_delete_tooltip'),
      ),
      _RowState.archived => (
        context.tr('archived'),
        tokens.draftSoft,
        tokens.draft,
        context.tr('archived'),
      ),
      _RowState.unsynced => (
        context.tr('unsynced'),
        tokens.sentSoft,
        tokens.sent,
        context.tr('unsynced_pending_outbox_tooltip'),
      ),
    };
    return StatusPill(label: label, fgColor: fg, bgColor: bg, tooltip: tooltip);
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────

String _displayName(Client c) {
  if (c.displayName.isNotEmpty) return c.displayName;
  if (c.name.isNotEmpty) return c.name;
  return '(no name)';
}

String _initials(String name) {
  // Strip non-letter characters (Unicode-aware so Cyrillic / CJK / Arabic /
  // etc. names get sensible initials, not '?'). `\P{L}` = "not a Letter".
  final nonLetter = RegExp(r'\P{L}', unicode: true);
  final words = name
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(nonLetter, ''))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words.last.characters.first)
      .toUpperCase();
}

Contact? _primaryContact(Client c) {
  if (c.contacts.isEmpty) return null;
  for (final ct in c.contacts) {
    if (ct.isPrimary) return ct;
  }
  return c.contacts.first;
}

String _contactLabel(Contact? c) {
  if (c == null) return '';
  final name = ('${c.firstName} ${c.lastName}').trim();
  if (name.isNotEmpty) return name;
  return c.email.trim();
}

String _semanticsLabel({
  required String displayName,
  required String outstanding,
  required bool outstandingPositive,
  required _RowState? state,
  required bool selecting,
  required bool selected,
}) {
  final parts = <String>[];
  // In selection mode lead with the toggle state — the row's tap toggles
  // selection rather than navigates, and a screen reader should announce
  // that intent first.
  if (selecting) {
    parts.add(selected ? 'selected' : 'not selected');
  }
  parts.add(displayName);
  if (outstandingPositive) {
    parts.add('outstanding $outstanding');
  } else {
    parts.add('no outstanding balance');
  }
  switch (state) {
    case _RowState.deleted:
      parts.add('deleted');
    case _RowState.archived:
      parts.add('archived');
    case _RowState.unsynced:
      parts.add('unsynced');
    case null:
      break;
  }
  return parts.join(', ');
}
