/// Permission grid constants for the User Management Permissions tab.
///
/// The server stores permissions as a comma-separated string on
/// `company_user.permissions` (e.g. `view_client,edit_invoice,create_all`).
/// The 14 entity rows × 3 verb columns combine into `<verb>_<entity>` tokens;
/// the "All" row uses `<verb>_all`; three special-case toggles live above
/// the grid.
///
/// When `is_admin = true`, the permissions string is empty and every grid
/// cell is implicitly granted. The edit ViewModel preserves a draft buffer
/// so flipping admin off restores the previous selection in-session.
library;

/// Entities that appear as rows in the permission grid. Order matches React's
/// `pages/settings/users/edit/components/Permissions.tsx`.
const List<String> kPermissionEntities = <String>[
  'client',
  'product',
  'invoice',
  'payment',
  'recurring_invoice',
  'quote',
  'credit',
  'project',
  'task',
  'vendor',
  'expense',
  'bank_transaction',
  'purchase_order',
  'recurring_expense',
];

/// Verb columns. Mirrors React. Order is preserved on the wire.
const List<String> kPermissionVerbs = <String>['create', 'view', 'edit'];

/// Special toggles rendered *above* the grid (per React layout).
const List<String> kPermissionSpecial = <String>[
  'view_dashboard',
  'view_reports',
  'disable_emails',
];

/// Cell token for an entity-verb pair (`create_client`, `view_invoice`, …).
String permissionToken({required String verb, required String entity}) =>
    '${verb}_$entity';

/// "All" row token (`create_all` / `view_all` / `edit_all`).
String permissionAllToken(String verb) => '${verb}_all';
