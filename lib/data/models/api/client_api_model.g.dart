// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClientApiImpl _$$ClientApiImplFromJson(Map<String, dynamic> json) =>
    _$ClientApiImpl(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      number: json['number'] as String? ?? '',
      idNumber: json['id_number'] as String? ?? '',
      vatNumber: json['vat_number'] as String? ?? '',
      website: json['website'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address1: json['address1'] as String? ?? '',
      address2: json['address2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      countryId: json['country_id'] as String? ?? '',
      shippingAddress1: json['shipping_address1'] as String? ?? '',
      shippingAddress2: json['shipping_address2'] as String? ?? '',
      shippingCity: json['shipping_city'] as String? ?? '',
      shippingState: json['shipping_state'] as String? ?? '',
      shippingPostalCode: json['shipping_postal_code'] as String? ?? '',
      shippingCountryId: json['shipping_country_id'] as String? ?? '',
      balance: json['balance'] as Object? ?? '0',
      paidToDate: json['paid_to_date'] as Object? ?? '0',
      creditBalance: json['credit_balance'] as Object? ?? '0',
      currencyId: json['currency_id'] as String? ?? '',
      languageId: json['language_id'] as String? ?? '',
      paymentTerms: json['payment_terms'] as String? ?? '',
      privateNotes: json['private_notes'] as String? ?? '',
      publicNotes: json['public_notes'] as String? ?? '',
      customValue1: json['custom_value1'] as String? ?? '',
      customValue2: json['custom_value2'] as String? ?? '',
      customValue3: json['custom_value3'] as String? ?? '',
      customValue4: json['custom_value4'] as String? ?? '',
      groupSettingsId: json['group_settings_id'] as String? ?? '',
      assignedUserId: json['assigned_user_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      contacts:
          (json['contacts'] as List<dynamic>?)
              ?.map((e) => ContactApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ContactApi>[],
    );

Map<String, dynamic> _$$ClientApiImplToJson(_$ClientApiImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'number': instance.number,
      'id_number': instance.idNumber,
      'vat_number': instance.vatNumber,
      'website': instance.website,
      'phone': instance.phone,
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'state': instance.state,
      'postal_code': instance.postalCode,
      'country_id': instance.countryId,
      'shipping_address1': instance.shippingAddress1,
      'shipping_address2': instance.shippingAddress2,
      'shipping_city': instance.shippingCity,
      'shipping_state': instance.shippingState,
      'shipping_postal_code': instance.shippingPostalCode,
      'shipping_country_id': instance.shippingCountryId,
      'balance': instance.balance,
      'paid_to_date': instance.paidToDate,
      'credit_balance': instance.creditBalance,
      'currency_id': instance.currencyId,
      'language_id': instance.languageId,
      'payment_terms': instance.paymentTerms,
      'private_notes': instance.privateNotes,
      'public_notes': instance.publicNotes,
      'custom_value1': instance.customValue1,
      'custom_value2': instance.customValue2,
      'custom_value3': instance.customValue3,
      'custom_value4': instance.customValue4,
      'group_settings_id': instance.groupSettingsId,
      'assigned_user_id': instance.assignedUserId,
      'user_id': instance.userId,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
      'is_deleted': instance.isDeleted,
      'contacts': instance.contacts,
    };

_$ClientListApiImpl _$$ClientListApiImplFromJson(Map<String, dynamic> json) =>
    _$ClientListApiImpl(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => ClientApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ClientApi>[],
    );

Map<String, dynamic> _$$ClientListApiImplToJson(_$ClientListApiImpl instance) =>
    <String, dynamic>{'data': instance.data};

_$ClientItemApiImpl _$$ClientItemApiImplFromJson(Map<String, dynamic> json) =>
    _$ClientItemApiImpl(
      data: ClientApi.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ClientItemApiImplToJson(_$ClientItemApiImpl instance) =>
    <String, dynamic>{'data': instance.data};
