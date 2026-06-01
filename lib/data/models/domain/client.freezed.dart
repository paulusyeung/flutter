// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Client {

 String get id; String get name; String get displayName; String get number; String get idNumber; String get vatNumber;// Server-assigned, read-only. Drives the client-portal silent
// auto-login URL. `@Default('')` (not `required`) so existing
// `Client(...)` fixtures don't all need updating.
 String get clientHash; String get website; String get phone; String get address1; String get address2; String get city; String get state; String get postalCode; String get countryId; Decimal get balance; Decimal get paidToDate; Decimal get creditBalance; String get currencyId; String get languageId; String get paymentTerms; String get privateNotes; String get publicNotes; String get groupSettingsId; String get assignedUserId;// Filterable client columns the API exposes but the model historically
// omitted. `@Default('')` (not `required`) so existing `Client(...)`
// fixtures don't all need updating — these are optional id/enum strings.
 String get industryId; String get sizeId; String get classification; DateTime get updatedAt; DateTime get createdAt; DateTime? get archivedAt; bool get isDeleted; String get customValue1; String get customValue2; String get customValue3; String get customValue4; List<Contact> get contacts; List<Location> get locations; List<Document> get documents;// Sparse per-client settings overrides. Mirrors the wire shape — keys
// not present mean "inherit from company via the cascade." Stored raw
// because the wire is open-ended; the typed `CompanySettings` view is
// reconstructed in the settings VM on demand.
 Map<String, dynamic>? get settings;// Local-only — never sent to the server. Populated by the repository
// from the Drift row's `is_dirty` column so the UI can render an
// "Unsynced" chip on the detail screen.
 bool get isDirty;
/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientCopyWith<Client> get copyWith => _$ClientCopyWithImpl<Client>(this as Client, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Client&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.number, number) || other.number == number)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.vatNumber, vatNumber) || other.vatNumber == vatNumber)&&(identical(other.clientHash, clientHash) || other.clientHash == clientHash)&&(identical(other.website, website) || other.website == website)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address1, address1) || other.address1 == address1)&&(identical(other.address2, address2) || other.address2 == address2)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.paidToDate, paidToDate) || other.paidToDate == paidToDate)&&(identical(other.creditBalance, creditBalance) || other.creditBalance == creditBalance)&&(identical(other.currencyId, currencyId) || other.currencyId == currencyId)&&(identical(other.languageId, languageId) || other.languageId == languageId)&&(identical(other.paymentTerms, paymentTerms) || other.paymentTerms == paymentTerms)&&(identical(other.privateNotes, privateNotes) || other.privateNotes == privateNotes)&&(identical(other.publicNotes, publicNotes) || other.publicNotes == publicNotes)&&(identical(other.groupSettingsId, groupSettingsId) || other.groupSettingsId == groupSettingsId)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&const DeepCollectionEquality().equals(other.contacts, contacts)&&const DeepCollectionEquality().equals(other.locations, locations)&&const DeepCollectionEquality().equals(other.documents, documents)&&const DeepCollectionEquality().equals(other.settings, settings)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,displayName,number,idNumber,vatNumber,clientHash,website,phone,address1,address2,city,state,postalCode,countryId,balance,paidToDate,creditBalance,currencyId,languageId,paymentTerms,privateNotes,publicNotes,groupSettingsId,assignedUserId,industryId,sizeId,classification,updatedAt,createdAt,archivedAt,isDeleted,customValue1,customValue2,customValue3,customValue4,const DeepCollectionEquality().hash(contacts),const DeepCollectionEquality().hash(locations),const DeepCollectionEquality().hash(documents),const DeepCollectionEquality().hash(settings),isDirty]);

@override
String toString() {
  return 'Client(id: $id, name: $name, displayName: $displayName, number: $number, idNumber: $idNumber, vatNumber: $vatNumber, clientHash: $clientHash, website: $website, phone: $phone, address1: $address1, address2: $address2, city: $city, state: $state, postalCode: $postalCode, countryId: $countryId, balance: $balance, paidToDate: $paidToDate, creditBalance: $creditBalance, currencyId: $currencyId, languageId: $languageId, paymentTerms: $paymentTerms, privateNotes: $privateNotes, publicNotes: $publicNotes, groupSettingsId: $groupSettingsId, assignedUserId: $assignedUserId, industryId: $industryId, sizeId: $sizeId, classification: $classification, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, contacts: $contacts, locations: $locations, documents: $documents, settings: $settings, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $ClientCopyWith<$Res>  {
  factory $ClientCopyWith(Client value, $Res Function(Client) _then) = _$ClientCopyWithImpl;
@useResult
$Res call({
 String id, String name, String displayName, String number, String idNumber, String vatNumber, String clientHash, String website, String phone, String address1, String address2, String city, String state, String postalCode, String countryId, Decimal balance, Decimal paidToDate, Decimal creditBalance, String currencyId, String languageId, String paymentTerms, String privateNotes, String publicNotes, String groupSettingsId, String assignedUserId, String industryId, String sizeId, String classification, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, String customValue1, String customValue2, String customValue3, String customValue4, List<Contact> contacts, List<Location> locations, List<Document> documents, Map<String, dynamic>? settings, bool isDirty
});




}
/// @nodoc
class _$ClientCopyWithImpl<$Res>
    implements $ClientCopyWith<$Res> {
  _$ClientCopyWithImpl(this._self, this._then);

  final Client _self;
  final $Res Function(Client) _then;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? number = null,Object? idNumber = null,Object? vatNumber = null,Object? clientHash = null,Object? website = null,Object? phone = null,Object? address1 = null,Object? address2 = null,Object? city = null,Object? state = null,Object? postalCode = null,Object? countryId = null,Object? balance = null,Object? paidToDate = null,Object? creditBalance = null,Object? currencyId = null,Object? languageId = null,Object? paymentTerms = null,Object? privateNotes = null,Object? publicNotes = null,Object? groupSettingsId = null,Object? assignedUserId = null,Object? industryId = null,Object? sizeId = null,Object? classification = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? contacts = null,Object? locations = null,Object? documents = null,Object? settings = freezed,Object? isDirty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,idNumber: null == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String,vatNumber: null == vatNumber ? _self.vatNumber : vatNumber // ignore: cast_nullable_to_non_nullable
as String,clientHash: null == clientHash ? _self.clientHash : clientHash // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,address1: null == address1 ? _self.address1 : address1 // ignore: cast_nullable_to_non_nullable
as String,address2: null == address2 ? _self.address2 : address2 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal,paidToDate: null == paidToDate ? _self.paidToDate : paidToDate // ignore: cast_nullable_to_non_nullable
as Decimal,creditBalance: null == creditBalance ? _self.creditBalance : creditBalance // ignore: cast_nullable_to_non_nullable
as Decimal,currencyId: null == currencyId ? _self.currencyId : currencyId // ignore: cast_nullable_to_non_nullable
as String,languageId: null == languageId ? _self.languageId : languageId // ignore: cast_nullable_to_non_nullable
as String,paymentTerms: null == paymentTerms ? _self.paymentTerms : paymentTerms // ignore: cast_nullable_to_non_nullable
as String,privateNotes: null == privateNotes ? _self.privateNotes : privateNotes // ignore: cast_nullable_to_non_nullable
as String,publicNotes: null == publicNotes ? _self.publicNotes : publicNotes // ignore: cast_nullable_to_non_nullable
as String,groupSettingsId: null == groupSettingsId ? _self.groupSettingsId : groupSettingsId // ignore: cast_nullable_to_non_nullable
as String,assignedUserId: null == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,contacts: null == contacts ? _self.contacts : contacts // ignore: cast_nullable_to_non_nullable
as List<Contact>,locations: null == locations ? _self.locations : locations // ignore: cast_nullable_to_non_nullable
as List<Location>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Client].
extension ClientPatterns on Client {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Client value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Client value)  $default,){
final _that = this;
switch (_that) {
case _Client():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Client value)?  $default,){
final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String displayName,  String number,  String idNumber,  String vatNumber,  String clientHash,  String website,  String phone,  String address1,  String address2,  String city,  String state,  String postalCode,  String countryId,  Decimal balance,  Decimal paidToDate,  Decimal creditBalance,  String currencyId,  String languageId,  String paymentTerms,  String privateNotes,  String publicNotes,  String groupSettingsId,  String assignedUserId,  String industryId,  String sizeId,  String classification,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  List<Contact> contacts,  List<Location> locations,  List<Document> documents,  Map<String, dynamic>? settings,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.number,_that.idNumber,_that.vatNumber,_that.clientHash,_that.website,_that.phone,_that.address1,_that.address2,_that.city,_that.state,_that.postalCode,_that.countryId,_that.balance,_that.paidToDate,_that.creditBalance,_that.currencyId,_that.languageId,_that.paymentTerms,_that.privateNotes,_that.publicNotes,_that.groupSettingsId,_that.assignedUserId,_that.industryId,_that.sizeId,_that.classification,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.contacts,_that.locations,_that.documents,_that.settings,_that.isDirty);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String displayName,  String number,  String idNumber,  String vatNumber,  String clientHash,  String website,  String phone,  String address1,  String address2,  String city,  String state,  String postalCode,  String countryId,  Decimal balance,  Decimal paidToDate,  Decimal creditBalance,  String currencyId,  String languageId,  String paymentTerms,  String privateNotes,  String publicNotes,  String groupSettingsId,  String assignedUserId,  String industryId,  String sizeId,  String classification,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  List<Contact> contacts,  List<Location> locations,  List<Document> documents,  Map<String, dynamic>? settings,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _Client():
return $default(_that.id,_that.name,_that.displayName,_that.number,_that.idNumber,_that.vatNumber,_that.clientHash,_that.website,_that.phone,_that.address1,_that.address2,_that.city,_that.state,_that.postalCode,_that.countryId,_that.balance,_that.paidToDate,_that.creditBalance,_that.currencyId,_that.languageId,_that.paymentTerms,_that.privateNotes,_that.publicNotes,_that.groupSettingsId,_that.assignedUserId,_that.industryId,_that.sizeId,_that.classification,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.contacts,_that.locations,_that.documents,_that.settings,_that.isDirty);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String displayName,  String number,  String idNumber,  String vatNumber,  String clientHash,  String website,  String phone,  String address1,  String address2,  String city,  String state,  String postalCode,  String countryId,  Decimal balance,  Decimal paidToDate,  Decimal creditBalance,  String currencyId,  String languageId,  String paymentTerms,  String privateNotes,  String publicNotes,  String groupSettingsId,  String assignedUserId,  String industryId,  String sizeId,  String classification,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  List<Contact> contacts,  List<Location> locations,  List<Document> documents,  Map<String, dynamic>? settings,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _Client() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.number,_that.idNumber,_that.vatNumber,_that.clientHash,_that.website,_that.phone,_that.address1,_that.address2,_that.city,_that.state,_that.postalCode,_that.countryId,_that.balance,_that.paidToDate,_that.creditBalance,_that.currencyId,_that.languageId,_that.paymentTerms,_that.privateNotes,_that.publicNotes,_that.groupSettingsId,_that.assignedUserId,_that.industryId,_that.sizeId,_that.classification,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.contacts,_that.locations,_that.documents,_that.settings,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _Client implements Client {
  const _Client({required this.id, required this.name, required this.displayName, required this.number, required this.idNumber, required this.vatNumber, this.clientHash = '', required this.website, required this.phone, required this.address1, required this.address2, required this.city, required this.state, required this.postalCode, required this.countryId, required this.balance, required this.paidToDate, required this.creditBalance, required this.currencyId, required this.languageId, required this.paymentTerms, required this.privateNotes, required this.publicNotes, required this.groupSettingsId, required this.assignedUserId, this.industryId = '', this.sizeId = '', this.classification = '', required this.updatedAt, required this.createdAt, required this.archivedAt, required this.isDeleted, required this.customValue1, required this.customValue2, required this.customValue3, required this.customValue4, required final  List<Contact> contacts, final  List<Location> locations = const <Location>[], final  List<Document> documents = const <Document>[], final  Map<String, dynamic>? settings, this.isDirty = false}): _contacts = contacts,_locations = locations,_documents = documents,_settings = settings;
  

@override final  String id;
@override final  String name;
@override final  String displayName;
@override final  String number;
@override final  String idNumber;
@override final  String vatNumber;
// Server-assigned, read-only. Drives the client-portal silent
// auto-login URL. `@Default('')` (not `required`) so existing
// `Client(...)` fixtures don't all need updating.
@override@JsonKey() final  String clientHash;
@override final  String website;
@override final  String phone;
@override final  String address1;
@override final  String address2;
@override final  String city;
@override final  String state;
@override final  String postalCode;
@override final  String countryId;
@override final  Decimal balance;
@override final  Decimal paidToDate;
@override final  Decimal creditBalance;
@override final  String currencyId;
@override final  String languageId;
@override final  String paymentTerms;
@override final  String privateNotes;
@override final  String publicNotes;
@override final  String groupSettingsId;
@override final  String assignedUserId;
// Filterable client columns the API exposes but the model historically
// omitted. `@Default('')` (not `required`) so existing `Client(...)`
// fixtures don't all need updating — these are optional id/enum strings.
@override@JsonKey() final  String industryId;
@override@JsonKey() final  String sizeId;
@override@JsonKey() final  String classification;
@override final  DateTime updatedAt;
@override final  DateTime createdAt;
@override final  DateTime? archivedAt;
@override final  bool isDeleted;
@override final  String customValue1;
@override final  String customValue2;
@override final  String customValue3;
@override final  String customValue4;
 final  List<Contact> _contacts;
@override List<Contact> get contacts {
  if (_contacts is EqualUnmodifiableListView) return _contacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contacts);
}

 final  List<Location> _locations;
@override@JsonKey() List<Location> get locations {
  if (_locations is EqualUnmodifiableListView) return _locations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locations);
}

 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

// Sparse per-client settings overrides. Mirrors the wire shape — keys
// not present mean "inherit from company via the cascade." Stored raw
// because the wire is open-ended; the typed `CompanySettings` view is
// reconstructed in the settings VM on demand.
 final  Map<String, dynamic>? _settings;
// Sparse per-client settings overrides. Mirrors the wire shape — keys
// not present mean "inherit from company via the cascade." Stored raw
// because the wire is open-ended; the typed `CompanySettings` view is
// reconstructed in the settings VM on demand.
@override Map<String, dynamic>? get settings {
  final value = _settings;
  if (value == null) return null;
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Local-only — never sent to the server. Populated by the repository
// from the Drift row's `is_dirty` column so the UI can render an
// "Unsynced" chip on the detail screen.
@override@JsonKey() final  bool isDirty;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientCopyWith<_Client> get copyWith => __$ClientCopyWithImpl<_Client>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Client&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.number, number) || other.number == number)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.vatNumber, vatNumber) || other.vatNumber == vatNumber)&&(identical(other.clientHash, clientHash) || other.clientHash == clientHash)&&(identical(other.website, website) || other.website == website)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.address1, address1) || other.address1 == address1)&&(identical(other.address2, address2) || other.address2 == address2)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.countryId, countryId) || other.countryId == countryId)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.paidToDate, paidToDate) || other.paidToDate == paidToDate)&&(identical(other.creditBalance, creditBalance) || other.creditBalance == creditBalance)&&(identical(other.currencyId, currencyId) || other.currencyId == currencyId)&&(identical(other.languageId, languageId) || other.languageId == languageId)&&(identical(other.paymentTerms, paymentTerms) || other.paymentTerms == paymentTerms)&&(identical(other.privateNotes, privateNotes) || other.privateNotes == privateNotes)&&(identical(other.publicNotes, publicNotes) || other.publicNotes == publicNotes)&&(identical(other.groupSettingsId, groupSettingsId) || other.groupSettingsId == groupSettingsId)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&(identical(other.industryId, industryId) || other.industryId == industryId)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&const DeepCollectionEquality().equals(other._contacts, _contacts)&&const DeepCollectionEquality().equals(other._locations, _locations)&&const DeepCollectionEquality().equals(other._documents, _documents)&&const DeepCollectionEquality().equals(other._settings, _settings)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,displayName,number,idNumber,vatNumber,clientHash,website,phone,address1,address2,city,state,postalCode,countryId,balance,paidToDate,creditBalance,currencyId,languageId,paymentTerms,privateNotes,publicNotes,groupSettingsId,assignedUserId,industryId,sizeId,classification,updatedAt,createdAt,archivedAt,isDeleted,customValue1,customValue2,customValue3,customValue4,const DeepCollectionEquality().hash(_contacts),const DeepCollectionEquality().hash(_locations),const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_settings),isDirty]);

@override
String toString() {
  return 'Client(id: $id, name: $name, displayName: $displayName, number: $number, idNumber: $idNumber, vatNumber: $vatNumber, clientHash: $clientHash, website: $website, phone: $phone, address1: $address1, address2: $address2, city: $city, state: $state, postalCode: $postalCode, countryId: $countryId, balance: $balance, paidToDate: $paidToDate, creditBalance: $creditBalance, currencyId: $currencyId, languageId: $languageId, paymentTerms: $paymentTerms, privateNotes: $privateNotes, publicNotes: $publicNotes, groupSettingsId: $groupSettingsId, assignedUserId: $assignedUserId, industryId: $industryId, sizeId: $sizeId, classification: $classification, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, contacts: $contacts, locations: $locations, documents: $documents, settings: $settings, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$ClientCopyWith<$Res> implements $ClientCopyWith<$Res> {
  factory _$ClientCopyWith(_Client value, $Res Function(_Client) _then) = __$ClientCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String displayName, String number, String idNumber, String vatNumber, String clientHash, String website, String phone, String address1, String address2, String city, String state, String postalCode, String countryId, Decimal balance, Decimal paidToDate, Decimal creditBalance, String currencyId, String languageId, String paymentTerms, String privateNotes, String publicNotes, String groupSettingsId, String assignedUserId, String industryId, String sizeId, String classification, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, String customValue1, String customValue2, String customValue3, String customValue4, List<Contact> contacts, List<Location> locations, List<Document> documents, Map<String, dynamic>? settings, bool isDirty
});




}
/// @nodoc
class __$ClientCopyWithImpl<$Res>
    implements _$ClientCopyWith<$Res> {
  __$ClientCopyWithImpl(this._self, this._then);

  final _Client _self;
  final $Res Function(_Client) _then;

/// Create a copy of Client
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? number = null,Object? idNumber = null,Object? vatNumber = null,Object? clientHash = null,Object? website = null,Object? phone = null,Object? address1 = null,Object? address2 = null,Object? city = null,Object? state = null,Object? postalCode = null,Object? countryId = null,Object? balance = null,Object? paidToDate = null,Object? creditBalance = null,Object? currencyId = null,Object? languageId = null,Object? paymentTerms = null,Object? privateNotes = null,Object? publicNotes = null,Object? groupSettingsId = null,Object? assignedUserId = null,Object? industryId = null,Object? sizeId = null,Object? classification = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? contacts = null,Object? locations = null,Object? documents = null,Object? settings = freezed,Object? isDirty = null,}) {
  return _then(_Client(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,idNumber: null == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String,vatNumber: null == vatNumber ? _self.vatNumber : vatNumber // ignore: cast_nullable_to_non_nullable
as String,clientHash: null == clientHash ? _self.clientHash : clientHash // ignore: cast_nullable_to_non_nullable
as String,website: null == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,address1: null == address1 ? _self.address1 : address1 // ignore: cast_nullable_to_non_nullable
as String,address2: null == address2 ? _self.address2 : address2 // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,countryId: null == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal,paidToDate: null == paidToDate ? _self.paidToDate : paidToDate // ignore: cast_nullable_to_non_nullable
as Decimal,creditBalance: null == creditBalance ? _self.creditBalance : creditBalance // ignore: cast_nullable_to_non_nullable
as Decimal,currencyId: null == currencyId ? _self.currencyId : currencyId // ignore: cast_nullable_to_non_nullable
as String,languageId: null == languageId ? _self.languageId : languageId // ignore: cast_nullable_to_non_nullable
as String,paymentTerms: null == paymentTerms ? _self.paymentTerms : paymentTerms // ignore: cast_nullable_to_non_nullable
as String,privateNotes: null == privateNotes ? _self.privateNotes : privateNotes // ignore: cast_nullable_to_non_nullable
as String,publicNotes: null == publicNotes ? _self.publicNotes : publicNotes // ignore: cast_nullable_to_non_nullable
as String,groupSettingsId: null == groupSettingsId ? _self.groupSettingsId : groupSettingsId // ignore: cast_nullable_to_non_nullable
as String,assignedUserId: null == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String,industryId: null == industryId ? _self.industryId : industryId // ignore: cast_nullable_to_non_nullable
as String,sizeId: null == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String,classification: null == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,contacts: null == contacts ? _self._contacts : contacts // ignore: cast_nullable_to_non_nullable
as List<Contact>,locations: null == locations ? _self._locations : locations // ignore: cast_nullable_to_non_nullable
as List<Location>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,settings: freezed == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
