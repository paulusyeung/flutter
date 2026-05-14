import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'payment_term.freezed.dart';

/// Clean domain model for a PaymentTerm row. Powers the payment-term picker
/// on Online Payments → Defaults and the list/edit screens under Settings →
/// Advanced → Payment Terms.
@freezed
abstract class PaymentTerm with _$PaymentTerm {
  const factory PaymentTerm({
    required String id,
    required String name,
    required int numDays,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _PaymentTerm;

  factory PaymentTerm.fromApi(PaymentTermApi a) => PaymentTerm(
    id: a.id,
    name: a.name,
    numDays: a.numDays,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

extension PaymentTermPayload on PaymentTerm {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'num_days': numDays,
    };
  }
}
