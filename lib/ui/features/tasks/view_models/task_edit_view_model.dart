import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/project.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the Task edit + create screen. Optimistic — `save()` lands the
/// draft in Drift via the repo, returns the saved entity, and the outbox
/// handles the server round-trip.
///
/// Task-specific surface area beyond the standard edit VM:
///   * Time-log mutations: [addEntry] / [removeEntry] / [updateEntry]
///     / [startTimer] / [stopTimer] / [resumeTimer]. Each mutates the
///     draft's `timeLog: List<TimeEntry>` and notifies; saving is still
///     done by the parent edit-scaffold's Save button.
///   * [hasRunningEntry] / [hasStoppedEntries] drive the Start/Stop/
///     Resume label swap in `TaskEditTimesSection`.
class TaskEditViewModel extends GenericEditViewModel<Task> {
  TaskEditViewModel({
    required this.repo,
    required this.companyId,
    required this.now,
    Task? existing,
    Task? cloneFrom,
    super.sync,
    super.connectivity,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? emptyTask(),
         original: existing,
         companyId: companyId,
       );

  final TaskRepository repo;
  final String companyId;
  final DateTime Function() now;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.description.isNotEmpty ||
        d.rate != Decimal.zero ||
        d.clientId.isNotEmpty ||
        d.timeLog.isNotEmpty;
  }

  @override
  Future<SaveResult<Task>> performSave() async {
    if (isCreate) {
      final result = await repo.create(
        companyId: companyId,
        draft: draft,
        existingTempId: recoveryTempId,
      );
      rememberCreateTempId(result.entity.id);
      return result;
    }
    return repo.save(companyId: companyId, task: draft);
  }

  void resetToEmpty() => reset(emptyDraft: emptyTask());

  // ── Plain field setters ────────────────────────────────────────────

  void setDescription(String v) => updateDraft(draft.copyWith(description: v));
  void setNumber(String v) => updateDraft(draft.copyWith(number: v));
  void setRate(String input) => updateDraft(
    draft.copyWith(rate: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setClientId(String v) {
    // Changing the client invalidates a previously-selected project that
    // belonged to a different client — clear projectId so the form doesn't
    // serialize a mismatched pair. Caller (Project picker) will re-select.
    if (draft.projectId.isNotEmpty && v != draft.clientId) {
      updateDraft(draft.copyWith(clientId: v, projectId: ''));
    } else {
      updateDraft(draft.copyWith(clientId: v));
    }
  }

  void setProjectId(String v) => updateDraft(draft.copyWith(projectId: v));
  void setStatusId(String v) => updateDraft(draft.copyWith(statusId: v));
  void setAssignedUserId(String v) =>
      updateDraft(draft.copyWith(assignedUserId: v));

  /// Pick a project (or clear with null). Mirrors React's `TaskDetails`
  /// bidirectional pick: setting a project also sets the clientId from the
  /// project and auto-fills `rate` from `project.taskRate` **only when**
  /// the current rate is zero (never overwrite a value the user typed).
  /// The auto-fill check is intentional — do not "fix" it to always copy.
  void selectProject(Project? project) {
    if (project == null) {
      updateDraft(draft.copyWith(projectId: ''));
      return;
    }
    final shouldFillRate = draft.rate == Decimal.zero;
    updateDraft(
      draft.copyWith(
        projectId: project.id,
        clientId: project.clientId,
        rate: shouldFillRate && project.taskRate != Decimal.zero
            ? project.taskRate
            : draft.rate,
      ),
    );
  }

  void setCustomValue1(String v) =>
      updateDraft(draft.copyWith(customValue1: v));
  void setCustomValue2(String v) =>
      updateDraft(draft.copyWith(customValue2: v));
  void setCustomValue3(String v) =>
      updateDraft(draft.copyWith(customValue3: v));
  void setCustomValue4(String v) =>
      updateDraft(draft.copyWith(customValue4: v));

  // ── time_log mutations ────────────────────────────────────────────

  /// Whether the draft has an entry that's currently running (no stop).
  bool get hasRunningEntry =>
      draft.timeLog.isNotEmpty && draft.timeLog.last.isRunning;

  /// Whether the draft has any non-running entries.
  bool get hasStoppedEntries =>
      draft.timeLog.any((e) => !e.isRunning && e.start != null);

  /// Append a new entry. Defaults to seeding 30 minutes before now → now,
  /// matching the "I worked on this for the last half hour" case.
  void addEntry({
    DateTime? start,
    DateTime? stop,
    String description = '',
    bool billable = true,
  }) {
    final n = now();
    final defaultedStart = start ?? n.subtract(const Duration(minutes: 30));
    final defaultedStop = stop ?? n;
    final entry = _clamp(
      TimeEntry(
        start: defaultedStart,
        stop: defaultedStop,
        description: description,
        billable: billable,
      ),
    );
    updateDraft(draft.copyWith(timeLog: <TimeEntry>[...draft.timeLog, entry]));
  }

  /// Clamp an inverted entry (stop before start) to zero length — matches
  /// React's auto-correct and keeps the server from rejecting the time_log
  /// on save (a negative interval 422s).
  TimeEntry _clamp(TimeEntry e) {
    final s = e.start;
    final p = e.stop;
    if (s != null && p != null && p.isBefore(s)) return e.copyWith(stop: s);
    return e;
  }

  void removeEntry(int index) {
    if (index < 0 || index >= draft.timeLog.length) return;
    final next = <TimeEntry>[...draft.timeLog]..removeAt(index);
    updateDraft(draft.copyWith(timeLog: next));
  }

  void updateEntry(int index, TimeEntry next) {
    if (index < 0 || index >= draft.timeLog.length) return;
    final entries = <TimeEntry>[...draft.timeLog]..[index] = _clamp(next);
    updateDraft(draft.copyWith(timeLog: entries));
  }

  /// Begin a fresh timer. Atomically stops any currently-running entry
  /// first so we never have two running entries at once.
  void startTimer({String description = '', bool billable = true}) {
    final n = now();
    final entries = <TimeEntry>[...draft.timeLog];
    if (entries.isNotEmpty && entries.last.isRunning) {
      entries[entries.length - 1] = entries.last.copyWith(stop: n);
    }
    entries.add(
      TimeEntry(
        start: n,
        stop: null,
        description: description,
        billable: billable,
      ),
    );
    updateDraft(draft.copyWith(timeLog: entries));
  }

  /// Stop the currently-running entry. No-op when nothing is running.
  void stopTimer() {
    if (draft.timeLog.isEmpty) return;
    final last = draft.timeLog.last;
    if (!last.isRunning) return;
    final n = now();
    final entries = <TimeEntry>[...draft.timeLog];
    entries[entries.length - 1] = last.copyWith(stop: n);
    updateDraft(draft.copyWith(timeLog: entries));
  }

  /// Resume tracking by appending a new running entry seeded with the
  /// previous entry's description + billable. Saves the user from
  /// re-typing context for an ongoing work session.
  void resumeTimer() {
    final entries = draft.timeLog;
    if (entries.isEmpty) {
      startTimer();
      return;
    }
    final last = entries.last;
    startTimer(description: last.description, billable: last.billable);
  }

  /// Seed a single running entry on a brand-new task when the company has
  /// `auto_start_tasks` enabled (admin-portal parity). No-op when the draft
  /// already has entries (e.g. a clone), so it's safe to call once after the
  /// company resolves.
  void applyAutoStartIfEmpty() {
    if (draft.timeLog.isNotEmpty) return;
    startTimer();
  }
}

Task emptyTask() => Task(
  id: '',
  number: '',
  description: '',
  rate: Decimal.zero,
  invoiceId: '',
  clientId: '',
  projectId: '',
  statusId: '',
  statusOrder: 0,
  assignedUserId: '',
  timeLog: const <TimeEntry>[],
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
  isDeleted: false,
);
