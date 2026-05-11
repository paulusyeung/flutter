import 'package:flutter/material.dart';

import '../../../../app/design_tokens.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'company_avatar.dart';
import 'show_company_picker.dart';

/// Header button at the top of the sidebar showing the active company and
/// (when more than one workspace is available) opening the [CompanyPicker]
/// on tap.
///
/// Single-company case: chevron is hidden and the button is inert.
class CompanySwitcherButton extends StatelessWidget {
  CompanySwitcherButton({required this.session, this.onBeforeOpen, super.key});

  final AuthSession session;

  /// Fires after the user taps the button and before the picker is shown.
  /// Used by `AppDrawer` to pop the drawer first so the picker doesn't sit
  /// on top of an open drawer. Null in the desktop sidebar.
  final VoidCallback? onBeforeOpen;

  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final current = session.currentCompany;
    final multi = session.companies.length > 1;
    final name = current?.displayName ?? '—';
    final seed = current?.id ?? '';
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
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CompanyAvatar(
                name: name,
                seed: seed,
                size: 28,
                logoUrl: current?.logoUrl,
              ),
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
