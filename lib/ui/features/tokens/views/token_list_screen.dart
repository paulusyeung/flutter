import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/token.dart';
import 'package:admin/data/repositories/token_repository.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/widgets/settings_entity_list_scaffold.dart';
import 'package:admin/ui/features/tokens/widgets/token_created_dialog.dart';

const kTokensListSearchKeys = <String>['api_tokens', 'token', 'new_token'];

/// `/settings/integrations/api_tokens` — list every API token. Tap a row
/// to rename; tap "+ New Token" to create. System tokens (`is_system`)
/// render as locked rows that can't be edited or deleted.
///
/// Subscribes to [TokenRepository.newSecrets] on mount: when a freshly-
/// minted secret arrives (after an outbox-driven `POST /tokens`
/// completes), shows a one-time [TokenCreatedDialog] with the raw
/// bearer secret. The user can copy it before dismissal; afterwards the
/// local row carries only the masked form.
class TokenListScreen extends StatefulWidget {
  const TokenListScreen({super.key});

  @override
  State<TokenListScreen> createState() => _TokenListScreenState();
}

class _TokenListScreenState extends State<TokenListScreen> {
  StreamSubscription<FreshTokenSecret>? _secretSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = context.read<Services>().tokens;
      _secretSub = repo.newSecrets.listen((event) async {
        if (!mounted) return;
        await TokenCreatedDialog.show(context, event.secret);
      });
    });
  }

  @override
  void dispose() {
    _secretSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final repo = services.tokens;

    return SettingsEntityListScaffold<Token>(
      titleKey: 'api_tokens',
      sectionTitleKey: 'api_tokens',
      newRoute: '/settings/integrations/api_tokens/new',
      newLabelKey: 'new_token',
      emptyIcon: Icons.key_outlined,
      emptyTitleKey: 'no_api_tokens',
      emptyHintKey: 'no_api_tokens_hint',
      supportsArchive: true,
      refreshAll: () async {
        if (companyId.isEmpty) return;
        await repo.refreshAll(companyId: companyId);
      },
      stream: ({required includeArchived}) => repo
          .watchPage(
            companyId: companyId,
            loadedPages: 4,
            states: includeArchived
                ? const {EntityState.active, EntityState.archived}
                : const {EntityState.active},
          )
          .map(
            (list) => list.where((t) => !t.isSystem).toList(growable: false),
          ),
      isArchivedOf: (t) => t.archivedAt != null,
      isDeletedOf: (t) => t.isDeleted,
      rowBuilder: (t) => _TokenRow(key: ValueKey(t.id), token: t),
      archivedRowBuilder: (t) =>
          _TokenRow.archived(key: ValueKey(t.id), token: t),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token, super.key}) : _isArchived = false;

  const _TokenRow.archived({required this.token, super.key})
    : _isArchived = true;

  final Token token;
  final bool _isArchived;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final displayName = token.name.trim().isEmpty
        ? context.tr('untitled')
        : token.name;
    final subtitleParts = <String>[
      token.tokenHint,
      if (token.isSystem) context.tr('system'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            token.isSystem ? Icons.lock_outline : Icons.key_outlined,
            color: tokens.ink2,
          ),
          title: Text(displayName),
          subtitle: Text(
            subtitleParts.join(' · '),
            style: TextStyle(color: tokens.ink2, fontSize: 12),
          ),
          trailing: _isArchived
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.draftSoft,
                    borderRadius: BorderRadius.circular(InRadii.r1),
                  ),
                  child: Text(
                    context.tr('archived'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.draft,
                    ),
                  ),
                )
              : token.isSystem
              ? Icon(Icons.lock_outline, color: tokens.ink3)
              : const Icon(Icons.chevron_right),
          onTap: token.isSystem
              ? null
              : () =>
                    context.go('/settings/integrations/api_tokens/${token.id}'),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
