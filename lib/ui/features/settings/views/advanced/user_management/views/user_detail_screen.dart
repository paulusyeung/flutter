import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/user.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Read-only User detail screen. Reached from `/settings/users/:id`.
///
/// Action chips: edit, resend email, detach, archive/restore, delete, purge.
/// Owner-protection: every action no-ops with a toast when the target is the
/// owner or the currently-authenticated user.
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId;
    final authUserId = session?.userId ?? '';

    if (companyId == null || companyId.isEmpty) {
      return SettingsScreenScaffold(
        titleKey: 'user',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SettingsScreenScaffold(
      titleKey: 'user',
      body: StreamBuilder<User?>(
        stream: services.user.watch(companyId: companyId, id: widget.id),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final isSelf = user.id == authUserId;
          final isOwner = user.companyUser.isOwner;
          final canModify = !isOwner && !isSelf;
          return SettingsFormShell(
            sections: [
              if (user.isPending)
                FormSection(
                  title: context.tr('invitation'),
                  children: [
                    _Banner(
                      icon: Icons.email_outlined,
                      message: context.tr('email_sent_to_confirm_email'),
                    ),
                  ],
                ),
              FormSection(
                title: context.tr('details'),
                children: [
                  _SummaryRow(
                    labelKey: 'name',
                    value: user.displayName.isNotEmpty
                        ? user.displayName
                        : context.tr('blank'),
                  ),
                  _SummaryRow(labelKey: 'email', value: user.email),
                  if (user.phone.isNotEmpty)
                    _SummaryRow(labelKey: 'phone', value: user.phone),
                  _SummaryRow(
                    labelKey: 'role',
                    value: context.tr(
                      isOwner
                          ? 'owner'
                          : user.companyUser.isAdmin
                              ? 'administrator'
                              : 'user',
                    ),
                  ),
                  if (user.companyUser.isLocked)
                    _SummaryRow(
                      labelKey: 'status',
                      value: context.tr('locked'),
                    ),
                  if (user.oauthProviderId.isNotEmpty)
                    _SummaryRow(
                      labelKey: 'sign_in_method',
                      value: user.oauthProviderId,
                    ),
                  if (user.googleTwoFactorEnabled)
                    _SummaryRow(
                      labelKey: 'two_factor_authentication',
                      value: context.tr('enabled'),
                    ),
                ],
              ),
              FormSection(
                title: context.tr('actions'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(context.tr('edit_user')),
                    onTap: canModify
                        ? () => context.go('/settings/users/${user.id}/edit')
                        : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(context.tr('resend_email')),
                    onTap: canModify ? () => _resendEmail(services, companyId, user) : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: Text(context.tr('remove_user')),
                    onTap: canModify ? () => _detach(services, companyId, user) : null,
                  ),
                  if (!isOwner) ...[
                    if (user.archivedAt == 0 && !user.isDeleted)
                      ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(context.tr('archive')),
                        onTap: canModify
                            ? () => _archive(services, companyId, user)
                            : null,
                      ),
                    if (user.archivedAt > 0 || user.isDeleted)
                      ListTile(
                        leading: const Icon(Icons.unarchive_outlined),
                        title: Text(context.tr('restore')),
                        onTap: canModify
                            ? () => _restore(services, companyId, user)
                            : null,
                      ),
                    if (!user.isDeleted)
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: Text(context.tr('delete')),
                        onTap: canModify
                            ? () => _delete(services, companyId, user)
                            : null,
                      ),
                    if (user.isDeleted || user.archivedAt > 0)
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined),
                        title: Text(context.tr('purge')),
                        onTap: canModify
                            ? () => _purge(services, companyId, user)
                            : null,
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resendEmail(Services services, String companyId, User user) async {
    await services.user.resendEmail(companyId: companyId, userId: user.id);
    if (mounted) {
      Notify.success(
        context,
        context.tr('sent_invitation_email', {':email': user.email}),
      );
    }
  }

  Future<void> _detach(Services services, String companyId, User user) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'remove_user',
      body: 'confirm_detach_user_body',
      user: user,
    );
    if (!confirmed) return;
    await services.user.detachFromCompany(companyId: companyId, userId: user.id);
    if (mounted) context.go('/settings/users');
  }

  Future<void> _archive(Services services, String companyId, User user) async {
    await services.user.archive(companyId: companyId, id: user.id);
  }

  Future<void> _restore(Services services, String companyId, User user) async {
    await services.user.restore(companyId: companyId, id: user.id);
  }

  Future<void> _delete(Services services, String companyId, User user) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'delete',
      body: 'confirm_delete_user_body',
      user: user,
    );
    if (!confirmed) return;
    await services.user.delete(companyId: companyId, id: user.id);
    if (mounted) context.go('/settings/users');
  }

  Future<void> _purge(Services services, String companyId, User user) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'purge',
      body: 'confirm_purge_user_body',
      user: user,
    );
    if (!confirmed) return;
    await services.user.purge(companyId: companyId, id: user.id);
    if (mounted) context.go('/settings/users');
  }

  Future<bool> _confirmAction({
    required BuildContext context,
    required String title,
    required String body,
    User? user,
  }) async {
    final services = context.read<Services>();
    final company = services.auth.session.value?.currentCompany;
    final params = <String, String>{
      ':user': user?.displayName ?? '',
      ':company': company?.displayName ?? company?.name ?? '',
    };
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(title)),
        content: Text(ctx.tr(body, params)),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('continue')),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.labelKey, required this.value});
  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: InSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              context.tr(labelKey),
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink3),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.overdueSoft,
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.overdue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: tokens.overdue),
            ),
          ),
        ],
      ),
    );
  }
}
