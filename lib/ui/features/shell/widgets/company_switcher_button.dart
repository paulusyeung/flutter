import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/ui/features/shell/widgets/company_avatar.dart';
import 'package:admin/ui/features/shell/widgets/show_company_picker.dart';

/// Header button at the top of the sidebar showing the active company and
/// (when more than one workspace is available) opening the [CompanyPicker]
/// on tap.
///
/// Single-company case: chevron is hidden and the button is inert.
class CompanySwitcherButton extends StatelessWidget {
  CompanySwitcherButton({
    required this.session,
    this.onBeforeOpen,
    this.compact = false,
    super.key,
  });

  final AuthSession session;

  /// Fires after the user taps the button and before the picker is shown.
  /// Used by `AppDrawer` to pop the drawer first so the picker doesn't sit
  /// on top of an open drawer. Null in the desktop sidebar.
  final VoidCallback? onBeforeOpen;

  /// Icon-only variant used when the wide-layout sidebar is collapsed: only
  /// the avatar renders, no name text or chevron. Tap still opens the picker
  /// anchored on the same key.
  final bool compact;

  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final current = session.currentCompany;
    final multi = session.companies.length > 1;
    final name = current?.displayName ?? '—';
    final seed = current?.id ?? '';
    final avatar = CompanyAvatar(
      name: name,
      seed: seed,
      size: 28,
      logoUrl: current?.logoUrl,
    );
    return Material(
      key: _anchorKey,
      color: tokens.surfaceAlt,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: InkWell(
        onTap: multi
            ? () {
                onBeforeOpen?.call();
                showCompanyPicker(context, anchorKey: _anchorKey);
              }
            : null,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(InRadii.r2),
            border: Border.all(color: tokens.border),
          ),
          padding: EdgeInsets.all(compact ? 4 : 8),
          child: compact
              ? Align(alignment: Alignment.centerLeft, child: avatar)
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    if (multi) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.unfold_more, size: 14, color: tokens.ink3),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
