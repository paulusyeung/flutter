import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
/// search catalog through the `account_management` parent entry. Colocated
/// here so `search_catalog_consistency_test` can grep the same source the
/// catalog points at.
const kAccountManagementDangerZoneSearchKeys = <String>[
  'purge_data',
  'delete_company',
  'cancel_account',
];

/// Settings → Account Management → Danger Zone. Two destructive flows:
///
/// * **Purge Data** — `POST /api/v1/companies/purge_save_settings/{id}` with
///   `X-API-PASSWORD-BASE64`. Server-side wipes every entity row attached to
///   the company but leaves settings intact. Local mirror: clear the company's
///   outbox rows (otherwise a pending mutation 404s on the next drain), wipe
///   the Drift DB, then re-pull via `auth.refreshSession()`.
/// * **Delete Company / Cancel Account** — routes through the outbox
///   (`CompanyRepository.deleteCompany` enqueues a `MutationKind.delete` row;
///   `CompanySyncDispatcher` issues `DELETE /api/v1/companies/{id}` with the
///   cached password). On success: switch to the next company (or logout to
///   `/login` when this was the last one) and refresh the session so the
///   deleted entry drops out of the picker.
class AccountManagementDangerZoneScreen extends StatelessWidget {
  const AccountManagementDangerZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session;
    return SettingsScreenScaffold(
      titleKey: 'danger_zone',
      body: ValueListenableBuilder(
        valueListenable: session,
        builder: (context, value, _) {
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
            sections: const [_PurgeSection(), _DeleteSection()],
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
          child: Semantics(
            button: true,
            label: '${context.tr('purge_data')} — destructive',
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
              onPressed: () =>
                  _openDangerDialog(context, kind: _DangerKind.purge),
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
    final session = context.read<Services>().auth.session;
    return ValueListenableBuilder(
      valueListenable: session,
      builder: (context, value, _) {
        final multi = (value?.companies.length ?? 0) > 1;
        // Pick the right key explicitly so the catalog-consistency test sees
        // both as literals.
        final label = multi
            ? context.tr('delete_company')
            : context.tr('cancel_account');
        final message = multi
            ? context.tr('delete_company_message')
            : context.tr('cancel_account_message');
        return FormSection(
          title: label,
          children: [
            Text(message, style: TextStyle(color: tokens.ink2)),
            SizedBox(height: InSpacing.lg(context)),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: '$label — destructive',
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.delete_forever_outlined,
                    color: tokens.overdue,
                  ),
                  label: Text(
                    label,
                    style: TextStyle(color: tokens.overdue),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 44),
                    side: BorderSide(color: tokens.overdue),
                  ),
                  onPressed: () =>
                      _openDangerDialog(context, kind: _DangerKind.delete),
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
      // useSafeArea + AnimatedPadding lets the body resize when the keyboard
      // opens; otherwise content under the keyboard becomes unreachable.
      useSafeArea: true,
      builder: (ctx) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(InSpacing.lg(ctx)),
            child: _DangerDialogBody(kind: kind, services: services),
          ),
        ),
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          _DangerDialogShell(kind: kind, services: services),
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
    if (_confirmCtrl.text.trim().toLowerCase() != _expectedConfirm) return false;
    if (_passwordCtrl.text.isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Clear inline errors as the user retypes — otherwise a 412's red label
    // sticks until the next submit.
    _confirmCtrl.addListener(() {
      setState(() {});
    });
    _passwordCtrl.addListener(() {
      if (_passwordError != null) {
        setState(() => _passwordError = null);
      } else {
        setState(() {});
      }
    });
    _feedbackCtrl.addListener(() {
      if (_feedbackError != null) {
        setState(() => _feedbackError = null);
      }
    });
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
    final isHosted = session?.isHosted ?? false;
    final isDelete = widget.kind == _DangerKind.delete;
    // For delete, only send feedback when hosted (the only branch that
    // surfaces the field). Self-hosted DELETEs get an empty body, matching
    // legacy admin-portal's behavior.
    final feedbackBody = isDelete
        ? (isHosted ? {'cancellation_message': _feedbackCtrl.text} : const <String, dynamic>{})
        : {'cancellation_message': _feedbackCtrl.text};

    setState(() {
      _busy = true;
      _passwordError = null;
      _feedbackError = null;
    });

    // Write the typed password into the cache — the ApiClient's
    // `requiresPassword: true` plumbing reads it from there and includes
    // `X-API-PASSWORD-BASE64`. Cache auto-expires after 5 min.
    services.passwordCache.set(_passwordCtrl.text);

    try {
      if (!isDelete) {
        await services.apiClient.postJson(
          '/api/v1/companies/purge_save_settings/$companyId',
          body: feedbackBody,
          requiresPassword: true,
        );
        // Clear pending outbox rows for this company BEFORE wiping the DB —
        // otherwise the next drain 404s against entities the server has
        // already erased.
        await services.db.outboxDao.deletePendingForCompany(companyId);
        await services.db.wipe();
        try {
          await services.auth.refreshSession();
        } catch (_) {
          // Network blip post-purge is non-fatal — the local DB is already
          // cleared; the next /refresh will re-populate.
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        Notify.success(context, purgeSuccessMsg, messenger: messenger);
        context.go('/dashboard');
        return;
      }

      // Delete branch — route through the outbox.
      final rowId = await services.company.deleteCompany(
        companyId: companyId,
        cancellationMessage: isHosted ? _feedbackCtrl.text : '',
      );
      await services.sync.drainOnce(companyId: companyId);
      final terminal = await services.db.outboxDao.byId(rowId);
      if (terminal != null) {
        // Row didn't clear. Sync engine parks pending on 412, marks dead on
        // 422 / max-retry. Inspect and surface inline.
        if (terminal.state == 'dead') {
          services.passwordCache.clear();
          if (terminal.lastStatusCode == 412) {
            _surface412(pwIncorrectMsg);
            return;
          }
          if (terminal.fieldErrorsJson != null) {
            final errs = jsonDecode(terminal.fieldErrorsJson!)
                as Map<String, dynamic>;
            final pwErr = (errs['password'] as List?)?.cast<String>().firstOrNull;
            final fbErr = (errs['cancellation_message'] as List?)
                ?.cast<String>()
                .firstOrNull;
            if (!mounted) return;
            setState(() {
              _busy = false;
              _passwordError = pwErr;
              _feedbackError = fbErr;
            });
            return;
          }
          if (!mounted) return;
          setState(() {
            _busy = false;
            _passwordError =
                terminal.lastError?.isNotEmpty == true
                    ? terminal.lastError
                    : fallbackErrMsg;
          });
          return;
        }
        // Still pending — sync engine treated it as password-required.
        _surface412(pwIncorrectMsg);
        return;
      }

      // Row cleared → delete succeeded server-side.
      final remaining = (session?.companies ?? const [])
          .where((c) => c.id != companyId)
          .toList();
      // Local wipe so the dead company doesn't linger in caches.
      try {
        await services.db.wipe();
      } catch (_) {/* non-fatal */}
      if (remaining.isNotEmpty) {
        await services.auth.switchCompany(remaining.first.id);
        try {
          await services.auth.refreshSession();
        } catch (_) {/* non-fatal — server may still 401 for a tick */}
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
    } on PasswordRequiredException {
      _surface412(pwIncorrectMsg);
    } on ServerException catch (e) {
      services.passwordCache.clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _passwordError = fallbackErrMsg;
      });
      Notify.error(context, fallbackErrMsg, error: e, messenger: messenger);
    } on ValidationException catch (e) {
      services.passwordCache.clear();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackError =
            e.fieldErrors['cancellation_message']?.firstOrNull;
        _passwordError = e.fieldErrors['password']?.firstOrNull;
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

  void _surface412(String msg) {
    widget.services.passwordCache.clear();
    // Clear the password so a fresh keystroke replaces it without a manual
    // select-all.
    _passwordCtrl.clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _passwordError = msg;
    });
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
                labelText: context
                    .tr('please_type_to_confirm')
                    .replaceFirst(':value', _expectedConfirm),
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
                // Wrap the obscure toggle in Focus(canRequestFocus: false) so
                // tapping it doesn't steal focus from the password field —
                // the user can keep typing after toggling visibility.
                suffixIcon: Focus(
                  canRequestFocus: false,
                  child: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
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
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.tr('cancel')),
                ),
                SizedBox(width: InSpacing.md(context)),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    backgroundColor: tokens.overdue,
                    // White stays legible on `tokens.overdue` in both light
                    // and dark mode — `tokens.surface` flips to near-black in
                    // dark mode and would WCAG-fail.
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
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
  return multi ? context.tr('delete_company') : context.tr('cancel_account');
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
