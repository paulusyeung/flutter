import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';
import 'package:admin/domain/entity_state.dart';

/// Settings → User Management.
///
/// Lists every company user except the owner and the currently-authenticated
/// user (the latter manages themselves via `/settings/user_details`). Renders
/// inside [SettingsFormShell] so the layout matches the rest of the settings
/// area; pagination caps at 5 pages (≈ 250 users — beyond that, a future
/// scroll-edge fetch can extend the cap).
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _showArchived = false;
  bool _hasKickedFetch = false;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId;
    final authUserId = session?.userId ?? '';

    if (companyId == null || companyId.isEmpty) {
      return SettingsScreenScaffold(
        titleKey: 'user_management',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasKickedFetch) {
      _hasKickedFetch = true;
      // Background fetch — load up to the watch cap (5 pages × 50 = 250)
      // so a 50–250-user company sees the whole roster on first open. The
      // loop short-circuits as soon as the server returns a partial page.
      // Errors surface in the global sync log; the watch stream handles
      // empty-state in the UI.
      Future.microtask(() async {
        for (var page = 1; page <= 5; page++) {
          final hasMore = await services.user.ensurePageLoaded(
            companyId: companyId,
            page: page,
            authUserId: authUserId,
            ignoreCursor: page == 1,
          );
          if (!hasMore) break;
        }
      });
    }

    final states = _showArchived
        ? const <EntityState>{EntityState.active, EntityState.archived}
        : const <EntityState>{EntityState.active};

    return SettingsScreenScaffold(
      titleKey: 'user_management',
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            icon: Icon(
              _showArchived
                  ? Icons.visibility_off_outlined
                  : Icons.archive_outlined,
              size: 18,
            ),
            label: Text(
              context.tr(_showArchived ? 'show_active' : 'show_archived'),
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ),
      ],
      body: StreamBuilder<List<User>>(
        stream: services.user.watchPage(
          companyId: companyId,
          loadedPages: 5,
          states: states,
          excludeAuthUserId: authUserId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const <User>[];
          final active = all.where((u) => u.archivedAt == 0 && !u.isDeleted).toList(growable: false);
          final archived = all.where((u) => u.archivedAt > 0 && !u.isDeleted).toList(growable: false);

          if (active.isEmpty && archived.isEmpty) {
            return EmptyState(
              icon: Icons.supervised_user_circle_outlined,
              title: context.tr('no_users'),
              subtitle: context.tr('no_users_found_invite'),
              action: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.add),
                label: Text(context.tr('new_user')),
                onPressed: () => context.go('/settings/users/new'),
              ),
            );
          }

          return SettingsFormShell(
            sections: [
              FormSection(
                title: context.tr('user_management'),
                spacing: 0,
                children: [
                  if (active.isNotEmpty)
                    for (final user in active) _UserRow(user: user),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(context.tr('new_user')),
                    onTap: () => context.go('/settings/users/new'),
                  ),
                ],
              ),
              if (_showArchived && archived.isNotEmpty)
                FormSection(
                  title: context.tr('archived'),
                  spacing: 0,
                  children: [
                    for (final user in archived)
                      _UserRow(user: user, isArchived: true),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, this.isArchived = false});

  final User user;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final roleKey = user.companyUser.isOwner
        ? 'owner'
        : user.companyUser.isAdmin
            ? 'administrator'
            : 'user';
    final subtitle = user.email.isNotEmpty ? user.email : user.phone;

    return ListTile(
      key: ValueKey(user.id),
      leading: CircleAvatar(
        backgroundColor: tokens.surfaceAlt,
        foregroundColor: tokens.ink2,
        child: Text(
          _initialsOf(user),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        user.displayName.isNotEmpty ? user.displayName : user.email,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          _Badge(labelKey: roleKey),
          if (user.isPending) _Badge(labelKey: 'pending_invite', tone: _BadgeTone.warning),
          if (isArchived) _Badge(labelKey: 'archived', tone: _BadgeTone.muted),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
      onTap: () => context.go('/settings/users/${user.id}'),
    );
  }

  static String _initialsOf(User u) {
    final first = u.firstName.isNotEmpty ? u.firstName[0] : '';
    final last = u.lastName.isNotEmpty ? u.lastName[0] : '';
    final initials = (first + last).toUpperCase();
    if (initials.isNotEmpty) return initials;
    return u.email.isNotEmpty ? u.email[0].toUpperCase() : '?';
  }
}

enum _BadgeTone { neutral, warning, muted }

class _Badge extends StatelessWidget {
  const _Badge({required this.labelKey, this.tone = _BadgeTone.neutral});

  final String labelKey;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      _BadgeTone.warning => (tokens.overdueSoft, tokens.overdue),
      _BadgeTone.muted => (tokens.surfaceAlt, tokens.ink3),
      _BadgeTone.neutral => (tokens.accentSoft, tokens.accentInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Text(
        context.tr(labelKey),
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
