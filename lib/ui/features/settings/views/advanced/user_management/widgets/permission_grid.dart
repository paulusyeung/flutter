import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/domain/permissions.dart';
import 'package:admin/l10n/localization.dart';

/// Pure widget — renders the 14×3 permission grid + the 3 "All" row checks +
/// the auto-promote logic. The owner's `is_admin` toggle and the three
/// special toggles (`view_dashboard` / `view_reports` / `disable_emails`)
/// live in the parent screen so the layout matches React: special toggles
/// *above* the grid, admin toggle above those.
///
/// The widget never mutates state itself — every interaction routes through
/// [onChange] with the next full permissions list. The edit VM auto-promotes
/// (14 entity boxes in one column → `<verb>_all`) and surfaces a toast.
class PermissionGrid extends StatelessWidget {
  const PermissionGrid({
    required this.permissions,
    required this.isAdmin,
    required this.onChange,
    this.onAutoPromote,
    super.key,
  });

  /// Current permission tokens (`view_client`, `create_all`, …). When
  /// `isAdmin = true` this is ignored — every cell renders muted-checked.
  final List<String> permissions;
  final bool isAdmin;
  final void Function(List<String> next) onChange;

  /// Fires when the grid auto-promotes a column from 14 explicit entity
  /// checks to one `<verb>_all` token. The screen renders a toast so the
  /// admin sees that "all entities for this verb" was granted — without
  /// the callback, the 14 boxes collapse to 1 with no explanation.
  final void Function(String verb)? onAutoPromote;

  bool _isAllSet(String verb) => permissions.contains(permissionAllToken(verb));

  bool _cellChecked(String verb, String entity) {
    if (isAdmin) return true;
    if (_isAllSet(verb)) return true;
    return permissions.contains(permissionToken(verb: verb, entity: entity));
  }

  // Only the admin toggle locks the grid. When `<verb>_all` is set the cells
  // render checked but stay interactive — unchecking one expands the column
  // to the other 13 entity tokens (React parity).
  bool _cellDisabled(String verb) => isAdmin;

  void _toggleAll(String verb, bool? value) {
    onChange(
      permissionsAfterToggleAll(
        current: permissions,
        verb: verb,
        checked: value ?? false,
      ),
    );
  }

  void _toggleCell(String verb, String entity, bool? value) {
    if (isAdmin) return;
    final result = permissionsAfterToggleCell(
      current: permissions,
      verb: verb,
      entity: entity,
      checked: value ?? false,
    );
    onChange(result.permissions);
    if (result.promoted) onAutoPromote?.call(verb);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      color: tokens.ink3,
      fontWeight: FontWeight.w600,
    );

    Widget headerCell(String labelKey, {TextAlign align = TextAlign.center}) =>
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: InSpacing.sm,
            horizontal: InSpacing.sm,
          ),
          child: Text(
            context.tr(labelKey).toUpperCase(),
            style: headerStyle,
            textAlign: align,
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below ~480 px the Expanded name column crushes long entity labels
        // ("Recurring invoice" / "Bank transaction"), so switch to fixed
        // columns + horizontal scroll. Wide layouts keep the stretch-to-fill
        // name column so the grid spans the section.
        final narrow = constraints.maxWidth < 480;
        final double verbWidth = narrow ? 76 : 90;
        final double? nameWidth = narrow ? 140 : null;

        Widget nameCell(Widget child) => nameWidth == null
            ? Expanded(child: child)
            : SizedBox(width: nameWidth, child: child);

        Widget verbHeaderRow() => Row(
          children: [
            nameCell(headerCell('name', align: TextAlign.start)),
            for (final verb in kPermissionVerbs)
              SizedBox(width: verbWidth, child: headerCell(verb)),
          ],
        );

        Widget rowFor({
          required String label,
          required Widget Function(String verb) checkboxFor,
          bool bold = false,
        }) => Padding(
          padding: EdgeInsets.symmetric(vertical: InSpacing.sm / 2),
          child: Row(
            children: [
              nameCell(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: InSpacing.sm),
                  child: Text(
                    label,
                    style: bold
                        ? theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              for (final verb in kPermissionVerbs)
                SizedBox(width: verbWidth, child: checkboxFor(verb)),
            ],
          ),
        );

        Widget allRow() => rowFor(
          label: context.tr('all'),
          bold: true,
          checkboxFor: (verb) => Center(
            child: Semantics(
              label: '${context.tr(verb)} ${context.tr('all')}',
              checked: isAdmin || _isAllSet(verb),
              child: Checkbox(
                value: isAdmin ? true : _isAllSet(verb),
                onChanged: isAdmin ? null : (v) => _toggleAll(verb, v),
              ),
            ),
          ),
        );

        Widget entityRow(String entity) => rowFor(
          label: context.tr(entity),
          checkboxFor: (verb) {
            final checked = _cellChecked(verb, entity);
            final disabled = _cellDisabled(verb);
            return Center(
              child: Semantics(
                label: '${context.tr(verb)} ${context.tr(entity)}',
                checked: checked,
                child: Checkbox(
                  value: checked,
                  onChanged: disabled
                      ? null
                      : (v) => _toggleCell(verb, entity, v),
                ),
              ),
            );
          },
        );

        final grid = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            verbHeaderRow(),
            const Divider(height: 1),
            allRow(),
            const Divider(height: 1),
            for (final entity in kPermissionEntities) entityRow(entity),
          ],
        );

        if (nameWidth == null) return grid;
        // Narrow: size the grid to its fixed total and scroll sideways.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: nameWidth + verbWidth * kPermissionVerbs.length,
            child: grid,
          ),
        );
      },
    );
  }
}
