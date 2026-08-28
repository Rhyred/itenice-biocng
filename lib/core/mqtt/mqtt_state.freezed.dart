// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mqtt_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MqttState {

 BrokerRole get activeBrokerRole; MqttConnectionStatus get connectionStatus;/// Maps compound key (deviceId:component) to TelemetryModel
 Map<String, TelemetryModel> get realtimeTelemetry;/// Maps deviceId to status ('online' or 'offline')
 Map<String, String> get deviceStatus;
/// Create a copy of MqttState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MqttStateCopyWith<MqttState> get copyWith => _$MqttStateCopyWithImpl<MqttState>(this as MqttState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MqttState&&(identical(other.activeBrokerRole, activeBrokerRole) || other.activeBrokerRole == activeBrokerRole)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&const DeepCollectionEquality().equals(other.realtimeTelemetry, realtimeTelemetry)&&const DeepCollectionEquality().equals(other.deviceStatus, deviceStatus));
}


@override
int get hashCode => Object.hash(runtimeType,activeBrokerRole,connectionStatus,const DeepCollectionEquality().hash(realtimeTelemetry),const DeepCollectionEquality().hash(deviceStatus));

@override
String toString() {
  return 'MqttState(activeBrokerRole: $activeBrokerRole, connectionStatus: $connectionStatus, realtimeTelemetry: $realtimeTelemetry, deviceStatus: $deviceStatus)';
}


}

/// @nodoc
abstract mixin class $MqttStateCopyWith<$Res>  {
  factory $MqttStateCopyWith(MqttState value, $Res Function(MqttState) _then) = _$MqttStateCopyWithImpl;
@useResult
$Res call({
 BrokerRole activeBrokerRole, MqttConnectionStatus connectionStatus, Map<String, TelemetryModel> realtimeTelemetry, Map<String, String> deviceStatus
});




}
/// @nodoc
class _$MqttStateCopyWithImpl<$Res>
    implements $MqttStateCopyWith<$Res> {
  _$MqttStateCopyWithImpl(this._self, this._then);

  final MqttState _self;
  final $Res Function(MqttState) _then;

/// Create a copy of MqttState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeBrokerRole = null,Object? connectionStatus = null,Object? realtimeTelemetry = null,Object? deviceStatus = null,}) {
  return _then(MqttState(
activeBrokerRole: null == activeBrokerRole ? _self.activeBrokerRole : activeBrokerRole // ignore: cast_nullable_to_non_nullable
as BrokerRole,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as MqttConnectionStatus,realtimeTelemetry: null == realtimeTelemetry ? _self.realtimeTelemetry : realtimeTelemetry // ignore: cast_nullable_to_non_nullable
as Map<String, TelemetryModel>,deviceStatus: null == deviceStatus ? _self.deviceStatus : deviceStatus // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MqttState].
extension MqttStatePatterns on MqttState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MqttState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MqttState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MqttState value)  $default,){
final _that = this;
switch (_that) {
case _MqttState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MqttState value)?  $default,){
final _that = this;
switch (_that) {
case _MqttState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BrokerRole activeBrokerRole,  MqttConnectionStatus connectionStatus,  Map<String, TelemetryModel> realtimeTelemetry,  Map<String, String> deviceStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MqttState() when $default != null:
return $default(_that.activeBrokerRole,_that.connectionStatus,_that.realtimeTelemetry,_that.deviceStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BrokerRole activeBrokerRole,  MqttConnectionStatus connectionStatus,  Map<String, TelemetryModel> realtimeTelemetry,  Map<String, String> deviceStatus)  $default,) {final _that = this;
switch (_that) {
case _MqttState():
return $default(_that.activeBrokerRole,_that.connectionStatus,_that.realtimeTelemetry,_that.deviceStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BrokerRole activeBrokerRole,  MqttConnectionStatus connectionStatus,  Map<String, TelemetryModel> realtimeTelemetry,  Map<String, String> deviceStatus)?  $default,) {final _that = this;
switch (_that) {
case _MqttState() when $default != null:
return $default(_that.activeBrokerRole,_that.connectionStatus,_that.realtimeTelemetry,_that.deviceStatus);case _:
  return null;

}
}

}

/// @nodoc


class _MqttState extends MqttState {
  const _MqttState({this.activeBrokerRole = BrokerRole.primary, this.connectionStatus = MqttConnectionStatus.disconnected,  Map<String, TelemetryModel> realtimeTelemetry = const {},  Map<String, String> deviceStatus = const {}}): _realtimeTelemetry = realtimeTelemetry,_deviceStatus = deviceStatus,super._();
  

@override@JsonKey() final  BrokerRole activeBrokerRole;
@override@JsonKey() final  MqttConnectionStatus connectionStatus;
/// Maps compound key (deviceId:component) to TelemetryModel
 final  Map<String, TelemetryModel> _realtimeTelemetry;
/// Maps compound key (deviceId:component) to TelemetryModel
@override@JsonKey() Map<String, TelemetryModel> get realtimeTelemetry {
  if (_realtimeTelemetry is EqualUnmodifiableMapView) return _realtimeTelemetry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_realtimeTelemetry);
}

/// Maps deviceId to status ('online' or 'offline')
 final  Map<String, String> _deviceStatus;
/// Maps deviceId to status ('online' or 'offline')
@override@JsonKey() Map<String, String> get deviceStatus {
  if (_deviceStatus is EqualUnmodifiableMapView) return _deviceStatus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_deviceStatus);
}


/// Create a copy of MqttState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MqttStateCopyWith<_MqttState> get copyWith => __$MqttStateCopyWithImpl<_MqttState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MqttState&&(identical(other.activeBrokerRole, activeBrokerRole) || other.activeBrokerRole == activeBrokerRole)&&(identical(other.connectionStatus, connectionStatus) || other.connectionStatus == connectionStatus)&&const DeepCollectionEquality().equals(other._realtimeTelemetry, _realtimeTelemetry)&&const DeepCollectionEquality().equals(other._deviceStatus, _deviceStatus));
}


@override
int get hashCode => Object.hash(runtimeType,activeBrokerRole,connectionStatus,const DeepCollectionEquality().hash(_realtimeTelemetry),const DeepCollectionEquality().hash(_deviceStatus));

@override
String toString() {
  return 'MqttState(activeBrokerRole: $activeBrokerRole, connectionStatus: $connectionStatus, realtimeTelemetry: $realtimeTelemetry, deviceStatus: $deviceStatus)';
}


}

/// @nodoc
abstract mixin class _$MqttStateCopyWith<$Res> implements $MqttStateCopyWith<$Res> {
  factory _$MqttStateCopyWith(_MqttState value, $Res Function(_MqttState) _then) = __$MqttStateCopyWithImpl;
@override @useResult
$Res call({
 BrokerRole activeBrokerRole, MqttConnectionStatus connectionStatus, Map<String, TelemetryModel> realtimeTelemetry, Map<String, String> deviceStatus
});




}
/// @nodoc
class __$MqttStateCopyWithImpl<$Res>
    implements _$MqttStateCopyWith<$Res> {
  __$MqttStateCopyWithImpl(this._self, this._then);

  final _MqttState _self;
  final $Res Function(_MqttState) _then;

/// Create a copy of MqttState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeBrokerRole = null,Object? connectionStatus = null,Object? realtimeTelemetry = null,Object? deviceStatus = null,}) {
  return _then(_MqttState(
activeBrokerRole: null == activeBrokerRole ? _self.activeBrokerRole : activeBrokerRole // ignore: cast_nullable_to_non_nullable
as BrokerRole,connectionStatus: null == connectionStatus ? _self.connectionStatus : connectionStatus // ignore: cast_nullable_to_non_nullable
as MqttConnectionStatus,realtimeTelemetry: null == realtimeTelemetry ? _self._realtimeTelemetry : realtimeTelemetry // ignore: cast_nullable_to_non_nullable
as Map<String, TelemetryModel>,deviceStatus: null == deviceStatus ? _self._deviceStatus : deviceStatus // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
