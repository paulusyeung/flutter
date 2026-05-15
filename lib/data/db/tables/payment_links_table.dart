import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Payment Link rows. Wire-side these are Subscriptions
/// (decoded by `SubscriptionApi`); the local table name + Drift class
/// mirror the user-facing label.
///
/// Bundled via `/refresh?first_load=true` (`company.subscriptions`) AND
/// paginated through `/api/v1/subscriptions` — same shape as
/// `expense_categories`. Denormalized columns are the ones the list view
/// filters and sorts on. The canonical money value lives in the `payload`
/// JSON blob (preserves [Decimal] precision); `price_cents` is a derived
/// `(price * 100).toInt()` column so list ordering is numeric, not the
/// lexicographic mess of TEXT-sorted decimal strings.
@DataClassName('PaymentLinkRow')
class PaymentLinks extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityFlagColumns,
        EntityPayloadColumn {
  TextColumn get name => text().named('name').withDefault(const Constant(''))();
  IntColumn get priceCents =>
      integer().named('price_cents').withDefault(const Constant(0))();
  TextColumn get purchasePage =>
      text().named('purchase_page').withDefault(const Constant(''))();
  TextColumn get groupId =>
      text().named('group_id').withDefault(const Constant(''))();
  TextColumn get assignedUserId =>
      text().named('assigned_user_id').withDefault(const Constant(''))();
  TextColumn get frequencyId =>
      text().named('frequency_id').withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
