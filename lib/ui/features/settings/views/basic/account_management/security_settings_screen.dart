import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/confirm_password_sheet.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Timeout options in milliseconds. Mirrors admin-portal `account_management.dart`.
/// Sorted by ascending duration; `0` = never, sentinel.
class _TimeoutOption {
  const _TimeoutOption({required this.ms, required this.label});
  final int ms;
  final String label;
}

List<_TimeoutOption> _timeoutOptions(BuildContext context) {
  String mins(int v) =>
      context.tr('count_minutes').replaceAll(':count', v.toString());
  String hours(int v) =>
      context.tr('count_hours').replaceAll(':count', v.toString());
  String days(int v) =>
      context.tr('count_days').replaceAll(':count', v.toString());
  return [
    _TimeoutOption(ms: 1000 * 60 * 30, label: mins(30)),
    _TimeoutOption(ms: 1000 * 60 * 60 * 2, label: hours(2)),
    _TimeoutOption(ms: 1000 * 60 * 60 * 8, label: hours(8)),
    _TimeoutOption(ms: 1000 * 60 * 60 * 24, label: context.tr('count_day')),
    _TimeoutOption(ms: 1000 * 60 * 60 * 24 * 7, label: days(7)),
    _TimeoutOption(ms: 1000 * 60 * 60 * 24 * 30, label: days(30)),
    _TimeoutOption(ms: 0, label: context.tr('never')),
  ];
}

/// Snap an arbitrary stored value to the closest option so the dropdown
/// never lands on a value not in the list (Material throws an assertion in
/// that case). The server-side value is preserved on the company until the
/// user picks a different option.
int _snapToOption(int stored, List<_TimeoutOption> opts) {
  for (final o in opts) {
    if (o.ms == stored) return o.ms;
  }
  return 0; // fall back to "Never" rather than throwing.
}

class AccountManagementSecuritySettingsScreen extends StatefulWidget {
  const AccountManagementSecuritySettingsScreen({super.key});

  @override
  State<AccountManagementSecuritySettingsScreen> createState() =>
      _AccountManagementSecuritySettingsScreenState();
}

class _AccountManagementSecuritySettingsScreenState
    extends State<AccountManagementSecuritySettingsScreen> {
  bool _endingSessions = false;

  Future<void> _onEndAllSessions() async {
    final services = context.read<Services>();
    final ok = await showConfirmPasswordSheet(
      context,
      cache: services.passwordCache,
    );
    if (!mounted || !ok) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final successMsg = context.tr('end_all_sessions');
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _endingSessions = true);
    try {
      await services.auth.endAllSessions();
      if (!mounted) return;
      Notify.success(context, successMsg, messenger: messenger);
      // Brief delay so the snackbar paints before the forced redirect to
      // /login (logout() flips credentials, which the router watches).
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      services.passwordCache.clear();
      Notify.error(context, errorMsg, error: e, messenger: messenger);
    } finally {
      if (mounted) setState(() => _endingSessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(companyId),
      builder: (context, snapshot) {
        final company = snapshot.data;
        if (company == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final opts = _timeoutOptions(context);
        final passwordTimeoutValue = _snapToOption(
          company.defaultPasswordTimeout,
          opts,
        );
        final sessionTimeoutValue = _snapToOption(
                  company.sessionTimeout,
                  opts,
                );

                Future<void> applyAndSave(Company draft) async {
                  try {
                    await services.company.updateCompany(draft: draft);
                  } catch (e) {
                    if (!context.mounted) return;
                    Notify.error(
                      context,
                      context.tr('error_refresh_page'),
                      error: e,
                    );
                  }
                }

                return SettingsFormShell(
                  sections: [
                    FormSection(
                      title: context.tr('security_settings'),
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: passwordTimeoutValue,
                          decoration: InputDecoration(
                            labelText: context.tr('password_timeout'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final o in opts)
                              DropdownMenuItem<int>(
                                value: o.ms,
                                child: Text(o.label),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            applyAndSave(
                              company.copyWith(defaultPasswordTimeout: v),
                            );
                          },
                        ),
                        DropdownButtonFormField<int>(
                          initialValue: sessionTimeoutValue,
                          decoration: InputDecoration(
                            labelText: context.tr('web_session_timeout'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final o in opts)
                              DropdownMenuItem<int>(
                                value: o.ms,
                                child: Text(o.label),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            applyAndSave(company.copyWith(sessionTimeout: v));
                          },
                        ),
                        DropdownButtonFormField<bool>(
                          initialValue: company.oauthPasswordRequired,
                          decoration: InputDecoration(
                            labelText: context.tr(
                              'require_password_with_social_login',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<bool>(
                              value: false,
                              child: Text(context.tr('no')),
                            ),
                            DropdownMenuItem<bool>(
                              value: true,
                              child: Text(context.tr('yes')),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            applyAndSave(
                              company.copyWith(oauthPasswordRequired: v),
                            );
                          },
                        ),
                      ],
                    ),
                    FormSection(
                      title: context.tr('end_all_sessions'),
                      children: [
                        Text(
                          context.tr('end_all_sessions_help'),
                          style: TextStyle(color: context.inTheme.ink2),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.logout,
                              color: context.inTheme.overdue,
                            ),
                            label: Text(
                              context.tr('end_all_sessions'),
                              style: TextStyle(color: context.inTheme.overdue),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(160, 44),
                              side: BorderSide(color: context.inTheme.overdue),
                            ),
                            onPressed: _endingSessions
                        ? null
                        : _onEndAllSessions,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
