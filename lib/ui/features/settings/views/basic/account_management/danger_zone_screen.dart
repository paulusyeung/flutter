import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/env.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Search keys rendered by the danger zone — referenced from the settings
/// search catalog through the `account_management` parent entry (no
/// duplication; this constant is the colocated source for the consistency
/// test's grep).
const kAccountManagementDangerZoneSearchKeys = <String>[
  'purge_data',
  'delete_company',
  'cancel_account',
];

/// Settings → Account Management → Danger Zone. Two destructive flows:
///
/// * **Purge Data** — `POST /api/v1/companies/purge_save_settings/{id}` with
///   `X-API-PASSWORD-BASE64`. Server-side wipes every entity row attached to
///   the company but leaves settings intact. Client-side mirror: nuke the
///   local Drift DB and re-pull via `auth.refreshSession()` so cached entity
///   lists don't keep showing rows the server has just deleted.
/// * **Delete Company / Cancel Account** — `DELETE /api/v1/companies/{id}`
///   with `X-API-PASSWORD-BASE64`. The legacy admin-portal sends
///   `cancellation_message` in the body; React drops it on the floor (bug),
///   so we follow the admin-portal contract so hosted "reason for canceling"
///   actually reaches the server. On success: switch to the next company if
///   there is one; otherwise logout → `/login`.
class AccountManagementDangerZoneScreen extends StatelessWidget {
  const AccountManagementDangerZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Services>().auth.session;
    return SettingsScreenScaffold(
      titleKey: 'danger_zone',
      body: ValueListenableBuilder(
        valueListenable: session,
        builder: (context, value, _) {
          // Gate: destructive ops are owner-only and disabled in demo mode.
          // Demo gate fires before owner gate so a demo build run by a
          // non-owner doesn't leak the owner-only message.
          if (Env.demoMode) {
            return EmptyState(
              icon: Icons.science_outlined,
              title: context.tr('danger_zone'),
            );
          }
          final currentCompany = value?.currentCompany;
          if (currentCompany == null || !currentCompany.isOwner) {
            return EmptyState(
              icon: Icons.lock_outline,
              title: context.tr('owner'),
            );
          }
          return SettingsFormShell(
            sections: const [
              _PurgeSection(),
              _DeleteSection(),
            ],
          );
        },
      ),
    );
  }
}

class _PurgeSection extends StatelessWidget {
  const _PurgeSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('purge_data'),
      children: [
        Text(
          context.tr('purge_data_message'),
          style: TextStyle(color: tokens.ink2),
        ),
        SizedBox(height: InSpacing.lg(context)),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: Icon(Icons.delete_sweep_outlined, color: tokens.overdue),
            label: Text(
              context.tr('purge_data'),
              style: TextStyle(color: tokens.overdue),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              side: BorderSide(color: tokens.overdue),
            ),
            onPressed: () => _openDangerDialog(
              context,
              kind: _DangerKind.purge,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteSection extends StatelessWidget {
  const _DeleteSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final session = context.watch<Services>().auth.session;
    return ValueListenableBuilder(
      valueListenable: session,
      builder: (context, value, _) {
        final multi = (value?.companies.length ?? 0) > 1;
        final labelKey = multi ? 'delete_company' : 'cancel_account';
        final messageKey = multi
            ? 'delete_company_message'
            : 'cancel_account_message';
        return FormSection(
          title: context.tr(labelKey),
          children: [
            Text(
              context.tr(messageKey),
              style: TextStyle(color: tokens.ink2),
            ),
            SizedBox(height: InSpacing.lg(context)),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.delete_forever_outlined,
                  color: tokens.overdue,
                ),
                label: Text(
                  context.tr(labelKey),
                  style: TextStyle(color: tokens.overdue),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  side: BorderSide(color: tokens.overdue),
                ),
                onPressed: () => _openDangerDialog(
                  context,
                  kind: _DangerKind.delete,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _DangerKind { purge, delete }

Future<void> _openDangerDialog(
  BuildContext context, {
  required _DangerKind kind,
}) async {
  final services = context.read<Services>();
  final narrow = MediaQuery.sizeOf(context).width < 600;
  if (narrow) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _DangerDialogBody(kind: kind, services: services),
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DangerDialogShell(
        kind: kind,
        services: services,
      ),
    );
  }
}

class _DangerDialogShell extends StatelessWidget {
  const _DangerDialogShell({required this.kind, required this.services});

  final _DangerKind kind;
  final Services services;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_titleFor(context, kind, services)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _DangerDialogBody(kind: kind, services: services),
      ),
      contentPadding: EdgeInsets.fromLTRB(
        InSpacing.lg(context),
        InSpacing.md(context),
        InSpacing.lg(context),
        0,
      ),
      actionsPadding: EdgeInsets.zero,
    );
  }
}

class _DangerDialogBody extends StatefulWidget {
  const _DangerDialogBody({required this.kind, required this.services});

  final _DangerKind kind;
  final Services services;

  @override
  State<_DangerDialogBody> createState() => _DangerDialogBodyState();
}

class _DangerDialogBodyState extends State<_DangerDialogBody> {
  final _confirmCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  String? _passwordError;
  String? _feedbackError;

  String get _expectedConfirm =>
      widget.kind == _DangerKind.purge ? 'purge' : 'delete';

  bool get _canSubmit {
    if (_busy) return false;
    if (_confirmCtrl.text.trim() != _expectedConfirm) return false;
    if (_passwordCtrl.text.isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() => setState(() {}));
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _passwordCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final services = widget.services;
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId ?? '';
    if (companyId.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final purgeSuccessMsg = context.tr('purge_successful');
    final deleteSuccessMsg = context.tr('deleted_company');
    final pwIncorrectMsg = context.tr('password_error_incorrect');
    final fallbackErrMsg = context.tr('error_title');

    setState(() {
      _busy = true;
      _passwordError = null;
      _feedbackError = null;
    });

    // Write the typed password into the cache — the ApiClient's
    // `requiresPassword: true` plumbing reads it from there and includes
    // X-API-PASSWORD-BASE64. Cache auto-expires after 5 min.
    services.passwordCache.set(_passwordCtrl.text);

    try {
      if (widget.kind == _DangerKind.purge) {
        await services.apiClient.postJson(
          '/api/v1/companies/purge_save_settings/$companyId',
          body: {'cancellation_message': _feedbackCtrl.text},
          requiresPassword: true,
        );
        // Mirror the React `queryClient.invalidateQueries()` step: nuke the
        // local Drift DB and re-pull. Without it, the next visit to e.g.
        // Clients shows rows the server has just deleted.
        await services.db.wipe();
        try {
          await services.auth.refreshSession();
        } catch (_) {
          // Network blip after a successful purge is non-fatal — the local DB
          // is already cleared; the next /refresh will re-populate.
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        Notify.success(context, purgeSuccessMsg, messenger: messenger);
        // Land on the dashboard so the user isn't stranded on a now-empty
        // settings sub-page.
        context.go('/dashboard');
      } else {
        await services.apiClient.mutate(
          method: 'DELETE',
          path: '/api/v1/companies/$companyId',
          idempotencyKey: const Uuid().v4(),
          body: {'cancellation_message': _feedbackCtrl.text},
          requiresPassword: true,
        );
        final remaining = (session?.companies ?? const [])
            .where((c) => c.id != companyId)
            .toList();
        if (remaining.isNotEmpty) {
          await services.auth.switchCompany(remaining.first.id);
          if (!mounted) return;
          Navigator.of(context).pop();
          Notify.success(context, deleteSuccessMsg, messenger: messenger);
          context.go('/dashboard');
        } else {
          await services.auth.logout();
          if (!mounted) return;
          Navigator.of(context).pop();
          context.go('/login');
        }
      }
    } on PasswordRequiredException {
      services.passwordCache.clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _passwordError = pwIncorrectMsg;
      });
    } on ServerException catch (e) {
      services.passwordCache.clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.statusCode == 412) {
          _passwordError = pwIncorrectMsg;
        } else {
          _passwordError = fallbackErrMsg;
        }
      });
    } on ValidationException catch (e) {
      if (!mounted) return;
      final feedbackErr = e.fieldErrors['cancellation_message']?.firstOrNull;
      final passwordErr = e.fieldErrors['password']?.firstOrNull;
      setState(() {
        _busy = false;
        _feedbackError = feedbackErr;
        _passwordError = passwordErr;
      });
    } on ApiException catch (e) {
      services.passwordCache.clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _passwordError = fallbackErrMsg;
      });
      Notify.error(context, fallbackErrMsg, error: e, messenger: messenger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = widget.services;
    final session = services.auth.session.value;
    final companyName = session?.currentCompany?.displayName ?? '';
    final multi = (session?.companies.length ?? 0) > 1;
    final isHosted = session?.isHosted ?? false;
    final scope = _scopeText(
      context,
      kind: widget.kind,
      companyName: companyName,
      multi: multi,
    );
    final showFeedback =
        widget.kind == _DangerKind.purge ||
        (widget.kind == _DangerKind.delete && isHosted);
    final feedbackLabel = widget.kind == _DangerKind.purge
        ? context.tr('cancellation_message')
        : context.tr('reason_for_canceling');

    return FormSaveScope(
      onSubmit: _submit,
      enabled: _canSubmit,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (scope.isNotEmpty) ...[
              Text(scope, style: TextStyle(color: tokens.ink2)),
              SizedBox(height: InSpacing.md(context)),
            ],
            TextField(
              autofocus: true,
              enabled: !_busy,
              controller: _confirmCtrl,
              decoration: InputDecoration(
                labelText: context.tr('please_type_to_confirm').replaceFirst(
                  ':value',
                  _expectedConfirm,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            if (showFeedback) ...[
              SizedBox(height: InSpacing.md(context)),
              TextField(
                enabled: !_busy,
                controller: _feedbackCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: feedbackLabel,
                  errorText: _feedbackError,
                ),
                textInputAction: TextInputAction.next,
              ),
            ],
            SizedBox(height: InSpacing.md(context)),
            TextField(
              enabled: !_busy,
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: context.tr('password'),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            SizedBox(height: InSpacing.lg(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(context.tr('cancel')),
                ),
                SizedBox(width: InSpacing.md(context)),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    backgroundColor: tokens.overdue,
                    foregroundColor: tokens.surface,
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('continue')),
                ),
              ],
            ),
            SizedBox(height: InSpacing.md(context)),
          ],
        ),
      ),
    );
  }
}

String _titleFor(BuildContext context, _DangerKind kind, Services services) {
  if (kind == _DangerKind.purge) return context.tr('purge_data');
  final multi = (services.auth.session.value?.companies.length ?? 0) > 1;
  return context.tr(multi ? 'delete_company' : 'cancel_account');
}

String _scopeText(
  BuildContext context, {
  required _DangerKind kind,
  required String companyName,
  required bool multi,
}) {
  if (kind == _DangerKind.purge) {
    return context.tr('purge_data_scope');
  }
  if (companyName.isEmpty) {
    return multi
        ? context.tr('delete_company_message')
        : context.tr('cancel_account_message');
  }
  final base = multi
      ? context.tr('delete_company_message')
      : context.tr('cancel_account_message');
  return '$base ($companyName)';
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
