// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

 String get id; String get number; String get description; Decimal get rate; String get invoiceId; String get clientId; String get projectId; String get statusId; int get statusOrder; String get assignedUserId; List<TimeEntry> get timeLog; String get customValue1; String get customValue2; String get customValue3; String get customValue4; DateTime get updatedAt; DateTime get createdAt; DateTime? get archivedAt; bool get isDeleted; bool get isDirty;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.description, description) || other.description == description)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.statusOrder, statusOrder) || other.statusOrder == statusOrder)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&const DeepCollectionEquality().equals(other.timeLog, timeLog)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,number,description,rate,invoiceId,clientId,projectId,statusId,statusOrder,assignedUserId,const DeepCollectionEquality().hash(timeLog),customValue1,customValue2,customValue3,customValue4,updatedAt,createdAt,archivedAt,isDeleted,isDirty]);

@override
String toString() {
  return 'Task(id: $id, number: $number, description: $description, rate: $rate, invoiceId: $invoiceId, clientId: $clientId, projectId: $projectId, statusId: $statusId, statusOrder: $statusOrder, assignedUserId: $assignedUserId, timeLog: $timeLog, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String number, String description, Decimal rate, String invoiceId, String clientId, String projectId, String statusId, int statusOrder, String assignedUserId, List<TimeEntry> timeLog, String customValue1, String customValue2, String customValue3, String customValue4, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? description = null,Object? rate = null,Object? invoiceId = null,Object? clientId = null,Object? projectId = null,Object? statusId = null,Object? statusOrder = null,Object? assignedUserId = null,Object? timeLog = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as Decimal,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,statusId: null == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String,statusOrder: null == statusOrder ? _self.statusOrder : statusOrder // ignore: cast_nullable_to_non_nullable
as int,assignedUserId: null == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String,timeLog: null == timeLog ? _self.timeLog : timeLog // ignore: cast_nullable_to_non_nullable
as List<TimeEntry>,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number,  String description,  Decimal rate,  String invoiceId,  String clientId,  String projectId,  String statusId,  int statusOrder,  String assignedUserId,  List<TimeEntry> timeLog,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.number,_that.description,_that.rate,_that.invoiceId,_that.clientId,_that.projectId,_that.statusId,_that.statusOrder,_that.assignedUserId,_that.timeLog,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number,  String description,  Decimal rate,  String invoiceId,  String clientId,  String projectId,  String statusId,  int statusOrder,  String assignedUserId,  List<TimeEntry> timeLog,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.number,_that.description,_that.rate,_that.invoiceId,_that.clientId,_that.projectId,_that.statusId,_that.statusOrder,_that.assignedUserId,_that.timeLog,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number,  String description,  Decimal rate,  String invoiceId,  String clientId,  String projectId,  String statusId,  int statusOrder,  String assignedUserId,  List<TimeEntry> timeLog,  String customValue1,  String customValue2,  String customValue3,  String customValue4,  DateTime updatedAt,  DateTime createdAt,  DateTime? archivedAt,  bool isDeleted,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.number,_that.description,_that.rate,_that.invoiceId,_that.clientId,_that.projectId,_that.statusId,_that.statusOrder,_that.assignedUserId,_that.timeLog,_that.customValue1,_that.customValue2,_that.customValue3,_that.customValue4,_that.updatedAt,_that.createdAt,_that.archivedAt,_that.isDeleted,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.number, required this.description, required this.rate, required this.invoiceId, required this.clientId, required this.projectId, required this.statusId, required this.statusOrder, required this.assignedUserId, required final  List<TimeEntry> timeLog, required this.customValue1, required this.customValue2, required this.customValue3, required this.customValue4, required this.updatedAt, required this.createdAt, required this.archivedAt, required this.isDeleted, this.isDirty = false}): _timeLog = timeLog;
  

@override final  String id;
@override final  String number;
@override final  String description;
@override final  Decimal rate;
@override final  String invoiceId;
@override final  String clientId;
@override final  String projectId;
@override final  String statusId;
@override final  int statusOrder;
@override final  String assignedUserId;
 final  List<TimeEntry> _timeLog;
@override List<TimeEntry> get timeLog {
  if (_timeLog is EqualUnmodifiableListView) return _timeLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeLog);
}

@override final  String customValue1;
@override final  String customValue2;
@override final  String customValue3;
@override final  String customValue4;
@override final  DateTime updatedAt;
@override final  DateTime createdAt;
@override final  DateTime? archivedAt;
@override final  bool isDeleted;
@override@JsonKey() final  bool isDirty;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.description, description) || other.description == description)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.statusOrder, statusOrder) || other.statusOrder == statusOrder)&&(identical(other.assignedUserId, assignedUserId) || other.assignedUserId == assignedUserId)&&const DeepCollectionEquality().equals(other._timeLog, _timeLog)&&(identical(other.customValue1, customValue1) || other.customValue1 == customValue1)&&(identical(other.customValue2, customValue2) || other.customValue2 == customValue2)&&(identical(other.customValue3, customValue3) || other.customValue3 == customValue3)&&(identical(other.customValue4, customValue4) || other.customValue4 == customValue4)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,number,description,rate,invoiceId,clientId,projectId,statusId,statusOrder,assignedUserId,const DeepCollectionEquality().hash(_timeLog),customValue1,customValue2,customValue3,customValue4,updatedAt,createdAt,archivedAt,isDeleted,isDirty]);

@override
String toString() {
  return 'Task(id: $id, number: $number, description: $description, rate: $rate, invoiceId: $invoiceId, clientId: $clientId, projectId: $projectId, statusId: $statusId, statusOrder: $statusOrder, assignedUserId: $assignedUserId, timeLog: $timeLog, customValue1: $customValue1, customValue2: $customValue2, customValue3: $customValue3, customValue4: $customValue4, updatedAt: $updatedAt, createdAt: $createdAt, archivedAt: $archivedAt, isDeleted: $isDeleted, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String number, String description, Decimal rate, String invoiceId, String clientId, String projectId, String statusId, int statusOrder, String assignedUserId, List<TimeEntry> timeLog, String customValue1, String customValue2, String customValue3, String customValue4, DateTime updatedAt, DateTime createdAt, DateTime? archivedAt, bool isDeleted, bool isDirty
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? description = null,Object? rate = null,Object? invoiceId = null,Object? clientId = null,Object? projectId = null,Object? statusId = null,Object? statusOrder = null,Object? assignedUserId = null,Object? timeLog = null,Object? customValue1 = null,Object? customValue2 = null,Object? customValue3 = null,Object? customValue4 = null,Object? updatedAt = null,Object? createdAt = null,Object? archivedAt = freezed,Object? isDeleted = null,Object? isDirty = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as Decimal,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,statusId: null == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String,statusOrder: null == statusOrder ? _self.statusOrder : statusOrder // ignore: cast_nullable_to_non_nullable
as int,assignedUserId: null == assignedUserId ? _self.assignedUserId : assignedUserId // ignore: cast_nullable_to_non_nullable
as String,timeLog: null == timeLog ? _self._timeLog : timeLog // ignore: cast_nullable_to_non_nullable
as List<TimeEntry>,customValue1: null == customValue1 ? _self.customValue1 : customValue1 // ignore: cast_nullable_to_non_nullable
as String,customValue2: null == customValue2 ? _self.customValue2 : customValue2 // ignore: cast_nullable_to_non_nullable
as String,customValue3: null == customValue3 ? _self.customValue3 : customValue3 // ignore: cast_nullable_to_non_nullable
as String,customValue4: null == customValue4 ? _self.customValue4 : customValue4 // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
