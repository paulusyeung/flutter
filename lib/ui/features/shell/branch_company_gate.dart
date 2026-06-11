/// Decides whether entering a shell branch must reset it to its initial
/// location after a company switch.
///
/// `StatefulShellRoute.indexedStack` preserves every visited branch's
/// Navigator (and widget state) offstage. Re-entering a branch last visited
/// under a *different* company would otherwise restore the previous
/// company's detail/edit screen — those screens bind their company id at
/// `initState`, and Drift retains every company's rows, so the old
/// company's record renders fully populated (and its actions mutate it)
/// under the new company's chrome. The company picker's
/// `companySafeLocation` go() only sanitizes the *current* branch's
/// location; this gate covers the offstage ones lazily on re-entry.
///
/// One instance lives on `ScaffoldWithNav`'s State and is exposed through a
/// `Provider` next to the `StatefulNavigationShell` so both `_goBranch` and
/// `AppDrawer` consult the same record.
class BranchCompanyGate {
  final Map<int, String> _lastCompanyByBranch = {};

  /// Stamp every branch index with the company active at shell mount.
  /// Without this, branches first entered OUTSIDE `goBranch` — the boot
  /// branch (mounted by the router's `initialLocation`) and any branch
  /// first reached via a cross-branch `context.go` — have no record, so
  /// [shouldResetOnEnter] would return false on their first re-entry after
  /// a company switch (and then stamp the NEW company, masking the stale
  /// stack forever): the exact cross-company restore this gate exists to
  /// prevent. `go()` navigations are inherently safe (they replace the
  /// target branch's stack), so seeding mount-time ownership for every
  /// index closes the gap.
  void seedAll({required int branchCount, required String companyId}) {
    if (companyId.isEmpty) return;
    for (var i = 0; i < branchCount; i++) {
      _lastCompanyByBranch.putIfAbsent(i, () => companyId);
    }
  }

  /// Record [companyId] as branch [index]'s current owner and report whether
  /// the branch's preserved stack belongs to a different company — in which
  /// case the caller must pass `initialLocation: true` to `goBranch` so the
  /// stale stack is dropped. Call only when the branch switch is actually
  /// happening (after any unsaved-changes guard has passed).
  bool shouldResetOnEnter({required int index, required String companyId}) {
    final last = _lastCompanyByBranch[index];
    _lastCompanyByBranch[index] = companyId;
    return last != null &&
        last.isNotEmpty &&
        companyId.isNotEmpty &&
        last != companyId;
  }
}
