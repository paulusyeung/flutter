import 'package:flutter/widgets.dart';

/// Runs an AFTER-SAVE action against a just-*created* entity and reports whether
/// the action took over post-save navigation.
///
/// The problem this solves: on create the entity is written to Drift under a
/// `tmp_<uuid>` id and only gets a real server id once its outbox row drains.
/// `GenericEditViewModel.save()` returns the *draft* (still tmp-id) even after a
/// successful online drain, so a server-bound action dispatched against it trips
/// its `tmpGate()` and never navigates — and the edit scaffold's create-mode
/// path then redirects to the detail screen regardless.
///
/// By the time `save()` returns success the dispatcher has already written the
/// `tmp → real` mapping into `id_remap` (see `recordCreateSuccess`), so
/// [resolveId] returns the real id here. We rebuild the entity with it via
/// [withId] and dispatch against that, so navigating actions (Send Email, View
/// PDF, …) navigate with a real id. The return value tells the scaffold to skip
/// its own detail redirect so the action's navigation survives.
///
/// Safety: only treat the action as "owns navigation" when it *unconditionally*
/// navigates ([navigatesOnCreate]) AND the id actually resolved. On the offline
/// / sync-timeout path no remap exists, [resolveId] returns the tmp id
/// unchanged, [dispatch] tmp-gates (toasts `sync_first`) without navigating, and
/// this returns `false` — the scaffold then falls back to the detail screen,
/// identical to the pre-fix behavior.
Future<bool> dispatchAfterSaveOnCreate<T, A>(
  BuildContext context, {
  required T saved,
  required String Function(T entity) idOf,
  required T Function(T entity, String id) withId,
  required Future<String> Function(String id) resolveId,
  required A action,
  required bool Function(A action) navigatesOnCreate,
  required Future<void> Function(BuildContext context, T resolved, A action)
  dispatch,
}) async {
  final tmpId = idOf(saved);
  final realId = await resolveId(tmpId);
  if (!context.mounted) return false;
  final resolved = realId == tmpId ? saved : withId(saved, realId);
  await dispatch(context, resolved, action);
  return realId != tmpId && navigatesOnCreate(action);
}
