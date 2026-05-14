import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/tax_rate_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'tax_rate.freezed.dart';

/// Clean domain model for a TaxRate row. Powers the default-tax pickers on
/// Settings → Tax Settings. Loaded bundled via `/refresh?first_load=true`.
@freezed
abstract class TaxRate with _$TaxRate {
  const factory TaxRate({
    required String id,
    required String name,
    required double rate,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _TaxRate;

  factory TaxRate.fromApi(TaxRateApi a) => TaxRate(
    id: a.id,
    name: a.name,
    rate: a.rate,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

extension TaxRatePayload on TaxRate {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'rate': rate,
    };
  }
}
