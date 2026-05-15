import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/models/value/money.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'bank_account.freezed.dart';

/// `integration_type` constants. Empty string = manual / unknown.
const String kBankIntegrationYodlee = 'YODLEE';
const String kBankIntegrationNordigen = 'NORDIGEN';

/// User-facing label for a provider/integration-type wire value. Maps
/// `YODLEE` / `NORDIGEN` (and the empty manual case) to a stable
/// translation key. Render via `context.tr(labelKeyForProvider(p))`.
String labelKeyForProvider(String wireValue) {
  switch (wireValue.toUpperCase()) {
    case kBankIntegrationYodlee:
      return 'provider_name_yodlee';
    case kBankIntegrationNordigen:
      return 'provider_name_nordigen';
    case '':
      return 'manual';
    default:
      return wireValue;
  }
}

/// Domain `BankAccount` (wire entity: `bank_integration`). Settings-area
/// entity reached via Settings → Bank Accounts. `isDirty` is local-only —
/// `fromApi` defaults it to false and the repo overlays the Drift row's
/// value (mirrors the Expense pattern).
@freezed
abstract class BankAccount with _$BankAccount {
  const BankAccount._();

  const factory BankAccount({
    required String id,
    required String name,
    required String status,
    required String type,
    required String provider,
    required Decimal balance,
    required String currency,
    required Date? fromDate,
    required bool autoSync,
    required bool disabledUpstream,
    required String integrationType,
    required String nordigenInstitutionId,
    required bool isDeleted,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    @Default(false) bool isDirty,
  }) = _BankAccount;

  factory BankAccount.fromApi(BankAccountApi a) => BankAccount(
    id: a.id,
    name: a.bankAccountName,
    status: a.bankAccountStatus,
    type: a.bankAccountType,
    provider: a.providerName,
    balance: parseMoney(a.balance),
    currency: a.currency,
    fromDate: Date.tryParse(a.fromDate),
    autoSync: a.autoSync,
    disabledUpstream: a.disabledUpstream,
    integrationType: a.integrationType,
    nordigenInstitutionId: a.nordigenInstitutionId,
    isDeleted: a.isDeleted,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
  );

  /// Build the PUT/POST body. `preserveTempId`: keep the tmp id in JSON for
  /// local Drift writes; outbound `POST /bank_integrations` drops it so
  /// the server assigns the real id.
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = BankAccountApi(
      id: id,
      bankAccountName: name,
      bankAccountStatus: status,
      bankAccountType: type,
      providerName: provider,
      balance: balance.toString(),
      currency: currency,
      fromDate: fromDate?.toIso() ?? '',
      autoSync: autoSync,
      disabledUpstream: disabledUpstream,
      integrationType: integrationType,
      nordigenInstitutionId: nordigenInstitutionId,
      isDeleted: isDeleted,
      updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
      archivedAt: archivedAt == null
          ? 0
          : archivedAt!.millisecondsSinceEpoch ~/ 1000,
    ).toJson();
    if (!preserveTempId && id.startsWith('tmp_')) {
      json.remove('id');
    }
    return json;
  }

  /// True when the upstream provider connection is broken. Drives the
  /// "Reconnect" affordance on the list + detail screens.
  bool get needsReconnect =>
      disabledUpstream && integrationType.isNotEmpty;
}
