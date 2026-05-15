import 'package:drift/drift.dart';

import 'package:admin/data/db/tables/_entity_table_mixin.dart';

/// Drift table for Payment rows.
///
/// `id` may be a `tmp_<uuid>` until the server assigns a real one (see
/// `id_remap`). `payload` carries the full JSON body so we can extend the
/// model without a schema migration for every new field.
///
/// Denormalized columns are the ones the list filters, searches, and sorts
/// by: `number`, `date`, `amount` / `applied` / `refunded` (TEXT for
/// Decimal, sorted via `CAST(... AS REAL)`), `client_id`, `vendor_id`,
/// `project_id`, `company_gateway_id`, `gateway_type_id`, `type_id`,
/// `status_id`, `currency_id`, `exchange_currency_id`, `exchange_rate`,
/// `transaction_reference`, `is_manual`.
///
/// `paymentables`, `invoices`, and `credits` are JSON-encoded lists kept as
/// their own TEXT columns so the detail screen + refund screen can render
/// them without parsing `payload` every read. Documents follow the same
/// pattern (see `EntityDocumentsColumn`).
@DataClassName('PaymentRow')
class Payments extends Table
    with
        EntityIdColumns,
        EntityTimestampColumns,
        EntityCustomValueColumns,
        EntityFlagColumns,
        EntityDocumentsColumn,
        EntityPayloadColumn {
  TextColumn get number =>
      text().named('number').withDefault(const Constant(''))();

  /// `YYYY-MM-DD` calendar date the payment was made. Empty string when
  /// the user hasn't set one (matches the API's tolerant `String` shape).
  TextColumn get date => text().named('date').withDefault(const Constant(''))();

  /// Decimal stored as TEXT — round-trips precisely without IEEE-754 loss.
  /// Sort the columns numerically via `CAST(<col> AS REAL)` in the DAO.
  TextColumn get amount =>
      text().named('amount').withDefault(const Constant('0'))();
  TextColumn get applied =>
      text().named('applied').withDefault(const Constant('0'))();
  TextColumn get refunded =>
      text().named('refunded').withDefault(const Constant('0'))();
  TextColumn get exchangeRate =>
      text().named('exchange_rate').withDefault(const Constant('1'))();

  TextColumn get statusId =>
      text().named('status_id').withDefault(const Constant(''))();
  TextColumn get typeId =>
      text().named('type_id').withDefault(const Constant(''))();
  TextColumn get clientId =>
      text().named('client_id').withDefault(const Constant(''))();
  TextColumn get vendorId =>
      text().named('vendor_id').withDefault(const Constant(''))();
  TextColumn get projectId =>
      text().named('project_id').withDefault(const Constant(''))();
  TextColumn get companyGatewayId =>
      text().named('company_gateway_id').withDefault(const Constant(''))();
  TextColumn get gatewayTypeId =>
      text().named('gateway_type_id').withDefault(const Constant(''))();
  TextColumn get currencyId =>
      text().named('currency_id').withDefault(const Constant(''))();
  TextColumn get exchangeCurrencyId =>
      text().named('exchange_currency_id').withDefault(const Constant(''))();
  TextColumn get transactionReference =>
      text().named('transaction_reference').withDefault(const Constant(''))();

  BoolColumn get isManual =>
      boolean().named('is_manual').withDefault(const Constant(false))();

  /// JSON-encoded `List<PaymentableApi>`. Nullable to distinguish
  /// JSON-omitted from JSON-empty (`null` vs `[]`). Reads back as
  /// `const <Paymentable>[]` in the repository's `_fromRow` overlay.
  TextColumn get paymentables => text().nullable()();

  /// JSON-encoded `List<PaymentInvoiceRefApi>` — server-include refs used by
  /// the refund screen to compute per-invoice refundable amounts.
  TextColumn get invoices => text().nullable()();

  /// JSON-encoded `List<PaymentCreditRefApi>`.
  TextColumn get credits => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (company_id, id)'];
}
