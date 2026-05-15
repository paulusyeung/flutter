import 'package:admin/data/models/domain/user.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';

export 'package:admin/ui/core/list/entity_list_constants.dart'
    show kColumnFlexMinWidth;

typedef UserColumn = ColumnDefinition<User>;

/// Default columns the User Management list shows when the user has never
/// customized the column set. Mirrors React's two-column DataTable plus the
/// role badge — the new app surfaces phone + last-login by default since
/// the wider list scaffold has room.
const List<String> kDefaultUserColumns = <String>[
  UserFieldIds.firstName,
  UserFieldIds.lastName,
  UserFieldIds.email,
  UserFieldIds.phone,
];

/// Wire ids for sort + persisted column selection.
class UserFieldIds {
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

final List<UserColumn> kAllUserColumns = <UserColumn>[
  UserColumn(
    id: UserFieldIds.firstName,
    labelKey: 'first_name',
    cellBuilder: (u, _) => cellText(u.firstName, bold: true),
    valueBuilder: (u) => u.firstName.isEmpty ? null : u.firstName,
  ),
  UserColumn(
    id: UserFieldIds.lastName,
    labelKey: 'last_name',
    cellBuilder: (u, _) => cellText(u.lastName),
    valueBuilder: (u) => u.lastName.isEmpty ? null : u.lastName,
  ),
  UserColumn(
    id: UserFieldIds.email,
    labelKey: 'email',
    cellBuilder: (u, _) => cellText(u.email),
    valueBuilder: (u) => u.email.isEmpty ? null : u.email,
  ),
  UserColumn(
    id: UserFieldIds.phone,
    labelKey: 'phone',
    width: 160,
    cellBuilder: (u, _) => cellText(u.phone),
    valueBuilder: (u) => u.phone.isEmpty ? null : u.phone,
  ),
];

final Map<String, UserColumn> userColumnsById = <String, UserColumn>{
  for (final c in kAllUserColumns) c.id: c,
};
