// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogModel {

 String get id; String get message; LogLevel get level; LogType get type; DateTime get timestamp; String? get stackTrace; Map<String, dynamic> get metadata; DeviceInfo? get device;
/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogModelCopyWith<LogModel> get copyWith => _$LogModelCopyWithImpl<LogModel>(this as LogModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode => Object.hash(runtimeType,id,message,level,type,timestamp,stackTrace,const DeepCollectionEquality().hash(metadata),device);

@override
String toString() {
  return 'LogModel(id: $id, message: $message, level: $level, type: $type, timestamp: $timestamp, stackTrace: $stackTrace, metadata: $metadata, device: $device)';
}


}

/// @nodoc
abstract mixin class $LogModelCopyWith<$Res>  {
  factory $LogModelCopyWith(LogModel value, $Res Function(LogModel) _then) = _$LogModelCopyWithImpl;
@useResult
$Res call({
 String id, String message, LogLevel level, LogType type, DateTime timestamp, String? stackTrace, Map<String, dynamic> metadata, DeviceInfo? device
});


$LogLevelCopyWith<$Res> get level;$LogTypeCopyWith<$Res> get type;$DeviceInfoCopyWith<$Res>? get device;

}
/// @nodoc
class _$LogModelCopyWithImpl<$Res>
    implements $LogModelCopyWith<$Res> {
  _$LogModelCopyWithImpl(this._self, this._then);

  final LogModel _self;
  final $Res Function(LogModel) _then;

/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? level = null,Object? type = null,Object? timestamp = null,Object? stackTrace = freezed,Object? metadata = null,Object? device = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LogType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as DeviceInfo?,
  ));
}
/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogLevelCopyWith<$Res> get level {
  
  return $LogLevelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogTypeCopyWith<$Res> get type {
  
  return $LogTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $DeviceInfoCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// Adds pattern-matching-related methods to [LogModel].
extension LogModelPatterns on LogModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogModel value)  $default,){
final _that = this;
switch (_that) {
case _LogModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogModel value)?  $default,){
final _that = this;
switch (_that) {
case _LogModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String message,  LogLevel level,  LogType type,  DateTime timestamp,  String? stackTrace,  Map<String, dynamic> metadata,  DeviceInfo? device)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogModel() when $default != null:
return $default(_that.id,_that.message,_that.level,_that.type,_that.timestamp,_that.stackTrace,_that.metadata,_that.device);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String message,  LogLevel level,  LogType type,  DateTime timestamp,  String? stackTrace,  Map<String, dynamic> metadata,  DeviceInfo? device)  $default,) {final _that = this;
switch (_that) {
case _LogModel():
return $default(_that.id,_that.message,_that.level,_that.type,_that.timestamp,_that.stackTrace,_that.metadata,_that.device);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String message,  LogLevel level,  LogType type,  DateTime timestamp,  String? stackTrace,  Map<String, dynamic> metadata,  DeviceInfo? device)?  $default,) {final _that = this;
switch (_that) {
case _LogModel() when $default != null:
return $default(_that.id,_that.message,_that.level,_that.type,_that.timestamp,_that.stackTrace,_that.metadata,_that.device);case _:
  return null;

}
}

}

/// @nodoc


class _LogModel implements LogModel {
  const _LogModel({required this.id, required this.message, required this.level, required this.type, required this.timestamp, this.stackTrace, final  Map<String, dynamic> metadata = const {}, this.device}): _metadata = metadata;
  

@override final  String id;
@override final  String message;
@override final  LogLevel level;
@override final  LogType type;
@override final  DateTime timestamp;
@override final  String? stackTrace;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  DeviceInfo? device;

/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogModelCopyWith<_LogModel> get copyWith => __$LogModelCopyWithImpl<_LogModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.device, device) || other.device == device));
}


@override
int get hashCode => Object.hash(runtimeType,id,message,level,type,timestamp,stackTrace,const DeepCollectionEquality().hash(_metadata),device);

@override
String toString() {
  return 'LogModel(id: $id, message: $message, level: $level, type: $type, timestamp: $timestamp, stackTrace: $stackTrace, metadata: $metadata, device: $device)';
}


}

/// @nodoc
abstract mixin class _$LogModelCopyWith<$Res> implements $LogModelCopyWith<$Res> {
  factory _$LogModelCopyWith(_LogModel value, $Res Function(_LogModel) _then) = __$LogModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String message, LogLevel level, LogType type, DateTime timestamp, String? stackTrace, Map<String, dynamic> metadata, DeviceInfo? device
});


@override $LogLevelCopyWith<$Res> get level;@override $LogTypeCopyWith<$Res> get type;@override $DeviceInfoCopyWith<$Res>? get device;

}
/// @nodoc
class __$LogModelCopyWithImpl<$Res>
    implements _$LogModelCopyWith<$Res> {
  __$LogModelCopyWithImpl(this._self, this._then);

  final _LogModel _self;
  final $Res Function(_LogModel) _then;

/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? level = null,Object? type = null,Object? timestamp = null,Object? stackTrace = freezed,Object? metadata = null,Object? device = freezed,}) {
  return _then(_LogModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LogType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as DeviceInfo?,
  ));
}

/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogLevelCopyWith<$Res> get level {
  
  return $LogLevelCopyWith<$Res>(_self.level, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogTypeCopyWith<$Res> get type {
  
  return $LogTypeCopyWith<$Res>(_self.type, (value) {
    return _then(_self.copyWith(type: value));
  });
}/// Create a copy of LogModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $DeviceInfoCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}

// dart format on
