// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'two_factor_api_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TwoFactorSetupApi _$TwoFactorSetupApiFromJson(Map<String, dynamic> json) {
  return _TwoFactorSetupApi.fromJson(json);
}

/// @nodoc
mixin _$TwoFactorSetupApi {
  @JsonKey(name: 'qrCode')
  String get qrCode => throw _privateConstructorUsedError;
  String get secret => throw _privateConstructorUsedError;

  /// Serializes this TwoFactorSetupApi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TwoFactorSetupApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TwoFactorSetupApiCopyWith<TwoFactorSetupApi> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TwoFactorSetupApiCopyWith<$Res> {
  factory $TwoFactorSetupApiCopyWith(
    TwoFactorSetupApi value,
    $Res Function(TwoFactorSetupApi) then,
  ) = _$TwoFactorSetupApiCopyWithImpl<$Res, TwoFactorSetupApi>;
  @useResult
  $Res call({@JsonKey(name: 'qrCode') String qrCode, String secret});
}

/// @nodoc
class _$TwoFactorSetupApiCopyWithImpl<$Res, $Val extends TwoFactorSetupApi>
    implements $TwoFactorSetupApiCopyWith<$Res> {
  _$TwoFactorSetupApiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TwoFactorSetupApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? qrCode = null, Object? secret = null}) {
    return _then(
      _value.copyWith(
            qrCode: null == qrCode
                ? _value.qrCode
                : qrCode // ignore: cast_nullable_to_non_nullable
                      as String,
            secret: null == secret
                ? _value.secret
                : secret // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TwoFactorSetupApiImplCopyWith<$Res>
    implements $TwoFactorSetupApiCopyWith<$Res> {
  factory _$$TwoFactorSetupApiImplCopyWith(
    _$TwoFactorSetupApiImpl value,
    $Res Function(_$TwoFactorSetupApiImpl) then,
  ) = __$$TwoFactorSetupApiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'qrCode') String qrCode, String secret});
}

/// @nodoc
class __$$TwoFactorSetupApiImplCopyWithImpl<$Res>
    extends _$TwoFactorSetupApiCopyWithImpl<$Res, _$TwoFactorSetupApiImpl>
    implements _$$TwoFactorSetupApiImplCopyWith<$Res> {
  __$$TwoFactorSetupApiImplCopyWithImpl(
    _$TwoFactorSetupApiImpl _value,
    $Res Function(_$TwoFactorSetupApiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TwoFactorSetupApi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? qrCode = null, Object? secret = null}) {
    return _then(
      _$TwoFactorSetupApiImpl(
        qrCode: null == qrCode
            ? _value.qrCode
            : qrCode // ignore: cast_nullable_to_non_nullable
                  as String,
        secret: null == secret
            ? _value.secret
            : secret // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TwoFactorSetupApiImpl implements _TwoFactorSetupApi {
  const _$TwoFactorSetupApiImpl({
    @JsonKey(name: 'qrCode') this.qrCode = '',
    this.secret = '',
  });

  factory _$TwoFactorSetupApiImpl.fromJson(Map<String, dynamic> json) =>
      _$$TwoFactorSetupApiImplFromJson(json);

  @override
  @JsonKey(name: 'qrCode')
  final String qrCode;
  @override
  @JsonKey()
  final String secret;

  @override
  String toString() {
    return 'TwoFactorSetupApi(qrCode: $qrCode, secret: $secret)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TwoFactorSetupApiImpl &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode) &&
            (identical(other.secret, secret) || other.secret == secret));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, qrCode, secret);

  /// Create a copy of TwoFactorSetupApi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TwoFactorSetupApiImplCopyWith<_$TwoFactorSetupApiImpl> get copyWith =>
      __$$TwoFactorSetupApiImplCopyWithImpl<_$TwoFactorSetupApiImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TwoFactorSetupApiImplToJson(this);
  }
}

abstract class _TwoFactorSetupApi implements TwoFactorSetupApi {
  const factory _TwoFactorSetupApi({
    @JsonKey(name: 'qrCode') final String qrCode,
    final String secret,
  }) = _$TwoFactorSetupApiImpl;

  factory _TwoFactorSetupApi.fromJson(Map<String, dynamic> json) =
      _$TwoFactorSetupApiImpl.fromJson;

  @override
  @JsonKey(name: 'qrCode')
  String get qrCode;
  @override
  String get secret;

  /// Create a copy of TwoFactorSetupApi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TwoFactorSetupApiImplCopyWith<_$TwoFactorSetupApiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
