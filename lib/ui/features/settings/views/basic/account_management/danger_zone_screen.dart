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

const kAccountManagementDangerZoneSearchKeys = <String>[
  'purge_data',
  'delete_company',
  'cancel_account',
];

/// Settings → Account Management → Danger Zone.
///
/// **Purge** (`POST /api/v1/companies/purge_save_settings/{id}`) erases every
/// entity row server-side but keeps settings. Locally we mirror with
/// [AppDatabase.wipeForCompany] (NOT [AppDatabase.wipe] — that nukes pending
/// edits on other companies, silent data loss) and `auth.refreshSession()`.
///
/// **Delete** routes through the outbox via `CompanyRepository.deleteCompany`
/// so CLAUDE.md's "every write goes through the outbox" rule holds. After
/// `drainOnce`, we inspect the row via `OutboxDao.byId`: gone = success;
/// `state == 'dead'` = inspect `lastStatusCode` (403 password, 422 fields,
/// other); `state == 'pending'` = sync engine parked it (403 / 409 /
/// network / 5xx-backoff / 429 — branch on `lastStatusCode`).
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
          // Demo gate fires first so a demo build run by a non-owner doesn't
          // leak the owner-only message.
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
              title: context.tr('only_owners_can_access'),
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
        // Picked explicitly (not via a variable) so the catalog-consistency
        // test sees both keys as literals.
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
    // Destructive flow: refuse swipe-down + tap-outside so a half-typed
    // password isn't silently lost. The sheet host already applies
    // viewInsets for the keyboard — no manual AnimatedPadding needed.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(InSpacing.lg(ctx)),
        child: _DangerDialogBody(kind: kind, services: services),
      ),
    );
  } else {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
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
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _busy = false;
  // Synchronous guard against double-tap. `_busy` flips inside `setState`
  // which is microtask-deferred; a rapid second tap before the next frame
  // would otherwise enqueue a second outbox row.
  bool _submitting = false;
  String? _passwordError;
  String? _feedbackError;

  String get _expectedConfirm =>
      widget.kind == _DangerKind.purge ? 'purge' : 'delete';

  bool get _canSubmit {
    if (_busy) return false;
    if (_confirmCtrl.text.trim().toLowerCase() != _expectedConfirm) {
      return false;
    }
    if (_passwordCtrl.text.isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() => setState(() {}));
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
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_canSubmit) return;
    _submitting = true;
    try {
      await _submitInner();
    } finally {
      _submitting = false;
    }
  }

  Future<void> _submitInner() async {
    final services = widget.services;
    final preSession = services.auth.session.value;
    final companyId = preSession?.currentCompanyId ?? '';
    if (companyId.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final purgeSuccessMsg = context.tr('purge_successful');
    final deleteSuccessMsg = context.tr('deleted_company');
    final pwIncorrectMsg = context.tr('password_error_incorrect');
    final fallbackErrMsg = context.tr('error_title');
    final alreadyDeletedMsg = context.tr('already_deleted_remote');
    final serverDidntRespondMsg = context.tr('server_didnt_respond');
    final isHosted = preSession?.isHosted ?? false;
    final isDelete = widget.kind == _DangerKind.delete;

    setState(() {
      _busy = true;
      _passwordError = null;
      _feedbackError = null;
    });

    services.passwordCache.set(_passwordCtrl.text);

    try {
      if (!isDelete) {
        // Purge: server-side erases entity data but keeps settings; we mirror
        // with `wipeForCompany` so other companies' pending edits stay intact.
        await services.apiClient.postJson(
          '/api/v1/companies/purge_save_settings/$companyId',
          body: {'cancellation_message': _feedbackCtrl.text},
          requiresPassword: true,
        );
        await services.db.wipeForCompany(companyId);
        try {
          await services.auth.refreshSession();
        } catch (_) {/* non-fatal */}
        if (!mounted) return;
        Navigator.of(context).pop();
        Notify.success(context, purgeSuccessMsg, messenger: messenger);
        context.go('/dashboard');
        return;
      }

      // Delete via outbox.
      final rowId = await services.company.deleteCompany(
        companyId: companyId,
        cancellationMessage: isHosted ? _feedbackCtrl.text : '',
      );
      await services.sync.drainOnce(companyId: companyId);
      final terminal = await services.db.outboxDao.byId(rowId);
      if (terminal != null) {
        services.passwordCache.clear();
        if (!mounted) return;
        _surfaceTerminal(
          terminal,
          pwIncorrectMsg: pwIncorrectMsg,
          alreadyDeletedMsg: alreadyDeletedMsg,
          serverDidntRespondMsg: serverDidntRespondMsg,
          fallbackErrMsg: fallbackErrMsg,
        );
        return;
      }

      // Row cleared → success. Re-read the session AFTER the drain in case a
      // background `/refresh` updated `companies` mid-call.
      final postSession = services.auth.session.value;
      final remaining = (postSession?.companies ?? const [])
          .where((c) => c.id != companyId)
          .toList();
      // Wipe only this company's rows so other companies stay intact.
      try {
        await services.db.wipeForCompany(companyId);
      } catch (_) {/* non-fatal */}
      if (remaining.isNotEmpty) {
        await services.auth.switchCompany(remaining.first.id);
        try {
          await services.auth.refreshSession();
        } catch (_) {/* non-fatal */}
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

  /// Map the terminal outbox row state into an inline error. The sync engine
  /// uses `lastStatusCode` consistently across dead and parked-pending rows;
  /// branch on it so 409 / 5xx / network don't get misreported as 412.
  void _surfaceTerminal(
    dynamic terminal, {
    required String pwIncorrectMsg,
    required String alreadyDeletedMsg,
    required String serverDidntRespondMsg,
    required String fallbackErrMsg,
  }) {
    final code = terminal.lastStatusCode as int?;
    // 422 first — fielded errors take precedence over a generic 422 message.
    if (terminal.fieldErrorsJson != null) {
      try {
        final errs = jsonDecode(terminal.fieldErrorsJson as String)
            as Map<String, dynamic>;
        final pwErr =
            (errs['password'] as List?)?.cast<String>().firstOrNull;
        final fbErr = (errs['cancellation_message'] as List?)
            ?.cast<String>()
            .firstOrNull;
        setState(() {
          _busy = false;
          _passwordError = pwErr;
          _feedbackError = fbErr;
        });
        return;
      } catch (_) {/* fall through */}
    }
    String msg;
    switch (code) {
      case 403:
      case 412:
        _surface412(pwIncorrectMsg);
        return;
      case 409:
        msg = alreadyDeletedMsg;
        break;
      case 401:
        // Sync engine already routed this through onUnauthorized → /login.
        // The dialog will dismiss when the route changes; no inline UI.
        setState(() => _busy = false);
        return;
      case null:
        msg = serverDidntRespondMsg;
        break;
      default:
        if (code >= 500 || code == 429) {
          msg = serverDidntRespondMsg;
        } else {
          msg = (terminal.lastError as String?)?.isNotEmpty == true
              ? terminal.lastError as String
              : fallbackErrMsg;
        }
    }
    setState(() {
      _busy = false;
      _passwordError = msg;
    });
  }

  void _surface412(String msg) {
    widget.services.passwordCache.clear();
    _passwordCtrl.clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _passwordError = msg;
    });
    _passwordFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = widget.services;
    final session = services.auth.session.value;
    final companyName = session?.currentCompany?.displayName ?? '';
    final isHosted = session?.isHosted ?? false;
    final scope = _scopeText(
      context,
      kind: widget.kind,
      companyName: companyName,
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
              focusNode: _passwordFocus,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: context.tr('password'),
                errorText: _passwordError,
                // Focus(canRequestFocus: false): tapping the eye toggle
                // shouldn't steal focus from the password field.
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
                    foregroundColor: tokens.onOverdue,
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  child: _busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(tokens.onOverdue),
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

/// Dialog opening text. Purge has a specific listing of what gets erased
/// (`purge_data_scope`); delete drops the body paragraph since it would
/// duplicate the section-card description verbatim — instead we show just
/// the company name as a one-line scope so the user knows which company
/// they're about to destroy.
String _scopeText(
  BuildContext context, {
  required _DangerKind kind,
  required String companyName,
}) {
  if (kind == _DangerKind.purge) {
    return context.tr('purge_data_scope');
  }
  if (companyName.isEmpty) return '';
  return companyName;
}
