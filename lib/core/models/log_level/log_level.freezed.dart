// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_level.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
LogLevel _$LogLevelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'trace':
          return _Trace.fromJson(
            json
          );
                case 'debug':
          return _Debug.fromJson(
            json
          );
                case 'info':
          return _Info.fromJson(
            json
          );
                case 'warning':
          return _Warning.fromJson(
            json
          );
                case 'error':
          return _Error.fromJson(
            json
          );
                case 'fatal':
          return _Fatal.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'LogLevel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$LogLevel {



  /// Serializes this LogLevel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogLevel);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel()';
}


}

/// @nodoc
class $LogLevelCopyWith<$Res>  {
$LogLevelCopyWith(LogLevel _, $Res Function(LogLevel) __);
}


/// Adds pattern-matching-related methods to [LogLevel].
extension LogLevelPatterns on LogLevel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Trace value)?  trace,TResult Function( _Debug value)?  debug,TResult Function( _Info value)?  info,TResult Function( _Warning value)?  warning,TResult Function( _Error value)?  error,TResult Function( _Fatal value)?  fatal,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trace() when trace != null:
return trace(_that);case _Debug() when debug != null:
return debug(_that);case _Info() when info != null:
return info(_that);case _Warning() when warning != null:
return warning(_that);case _Error() when error != null:
return error(_that);case _Fatal() when fatal != null:
return fatal(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Trace value)  trace,required TResult Function( _Debug value)  debug,required TResult Function( _Info value)  info,required TResult Function( _Warning value)  warning,required TResult Function( _Error value)  error,required TResult Function( _Fatal value)  fatal,}){
final _that = this;
switch (_that) {
case _Trace():
return trace(_that);case _Debug():
return debug(_that);case _Info():
return info(_that);case _Warning():
return warning(_that);case _Error():
return error(_that);case _Fatal():
return fatal(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Trace value)?  trace,TResult? Function( _Debug value)?  debug,TResult? Function( _Info value)?  info,TResult? Function( _Warning value)?  warning,TResult? Function( _Error value)?  error,TResult? Function( _Fatal value)?  fatal,}){
final _that = this;
switch (_that) {
case _Trace() when trace != null:
return trace(_that);case _Debug() when debug != null:
return debug(_that);case _Info() when info != null:
return info(_that);case _Warning() when warning != null:
return warning(_that);case _Error() when error != null:
return error(_that);case _Fatal() when fatal != null:
return fatal(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  trace,TResult Function()?  debug,TResult Function()?  info,TResult Function()?  warning,TResult Function()?  error,TResult Function()?  fatal,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trace() when trace != null:
return trace();case _Debug() when debug != null:
return debug();case _Info() when info != null:
return info();case _Warning() when warning != null:
return warning();case _Error() when error != null:
return error();case _Fatal() when fatal != null:
return fatal();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  trace,required TResult Function()  debug,required TResult Function()  info,required TResult Function()  warning,required TResult Function()  error,required TResult Function()  fatal,}) {final _that = this;
switch (_that) {
case _Trace():
return trace();case _Debug():
return debug();case _Info():
return info();case _Warning():
return warning();case _Error():
return error();case _Fatal():
return fatal();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  trace,TResult? Function()?  debug,TResult? Function()?  info,TResult? Function()?  warning,TResult? Function()?  error,TResult? Function()?  fatal,}) {final _that = this;
switch (_that) {
case _Trace() when trace != null:
return trace();case _Debug() when debug != null:
return debug();case _Info() when info != null:
return info();case _Warning() when warning != null:
return warning();case _Error() when error != null:
return error();case _Fatal() when fatal != null:
return fatal();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trace implements LogLevel {
  const _Trace({final  String? $type}): $type = $type ?? 'trace';
  factory _Trace.fromJson(Map<String, dynamic> json) => _$TraceFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$TraceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trace);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.trace()';
}


}




/// @nodoc
@JsonSerializable()

class _Debug implements LogLevel {
  const _Debug({final  String? $type}): $type = $type ?? 'debug';
  factory _Debug.fromJson(Map<String, dynamic> json) => _$DebugFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$DebugToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Debug);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.debug()';
}


}




/// @nodoc
@JsonSerializable()

class _Info implements LogLevel {
  const _Info({final  String? $type}): $type = $type ?? 'info';
  factory _Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$InfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Info);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.info()';
}


}




/// @nodoc
@JsonSerializable()

class _Warning implements LogLevel {
  const _Warning({final  String? $type}): $type = $type ?? 'warning';
  factory _Warning.fromJson(Map<String, dynamic> json) => _$WarningFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$WarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Warning);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.warning()';
}


}




/// @nodoc
@JsonSerializable()

class _Error implements LogLevel {
  const _Error({final  String? $type}): $type = $type ?? 'error';
  factory _Error.fromJson(Map<String, dynamic> json) => _$ErrorFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.error()';
}


}




/// @nodoc
@JsonSerializable()

class _Fatal implements LogLevel {
  const _Fatal({final  String? $type}): $type = $type ?? 'fatal';
  factory _Fatal.fromJson(Map<String, dynamic> json) => _$FatalFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$FatalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fatal);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogLevel.fatal()';
}


}




LogType _$LogTypeFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'general':
          return _General.fromJson(
            json
          );
                case 'analytics':
          return _Analytics.fromJson(
            json
          );
                case 'crash':
          return _Crash.fromJson(
            json
          );
                case 'performance':
          return _Performance.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'LogType',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$LogType {



  /// Serializes this LogType to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogType);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogType()';
}


}

/// @nodoc
class $LogTypeCopyWith<$Res>  {
$LogTypeCopyWith(LogType _, $Res Function(LogType) __);
}


/// Adds pattern-matching-related methods to [LogType].
extension LogTypePatterns on LogType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _General value)?  general,TResult Function( _Analytics value)?  analytics,TResult Function( _Crash value)?  crash,TResult Function( _Performance value)?  performance,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _General() when general != null:
return general(_that);case _Analytics() when analytics != null:
return analytics(_that);case _Crash() when crash != null:
return crash(_that);case _Performance() when performance != null:
return performance(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _General value)  general,required TResult Function( _Analytics value)  analytics,required TResult Function( _Crash value)  crash,required TResult Function( _Performance value)  performance,}){
final _that = this;
switch (_that) {
case _General():
return general(_that);case _Analytics():
return analytics(_that);case _Crash():
return crash(_that);case _Performance():
return performance(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _General value)?  general,TResult? Function( _Analytics value)?  analytics,TResult? Function( _Crash value)?  crash,TResult? Function( _Performance value)?  performance,}){
final _that = this;
switch (_that) {
case _General() when general != null:
return general(_that);case _Analytics() when analytics != null:
return analytics(_that);case _Crash() when crash != null:
return crash(_that);case _Performance() when performance != null:
return performance(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  general,TResult Function()?  analytics,TResult Function()?  crash,TResult Function()?  performance,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _General() when general != null:
return general();case _Analytics() when analytics != null:
return analytics();case _Crash() when crash != null:
return crash();case _Performance() when performance != null:
return performance();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  general,required TResult Function()  analytics,required TResult Function()  crash,required TResult Function()  performance,}) {final _that = this;
switch (_that) {
case _General():
return general();case _Analytics():
return analytics();case _Crash():
return crash();case _Performance():
return performance();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  general,TResult? Function()?  analytics,TResult? Function()?  crash,TResult? Function()?  performance,}) {final _that = this;
switch (_that) {
case _General() when general != null:
return general();case _Analytics() when analytics != null:
return analytics();case _Crash() when crash != null:
return crash();case _Performance() when performance != null:
return performance();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _General implements LogType {
  const _General({final  String? $type}): $type = $type ?? 'general';
  factory _General.fromJson(Map<String, dynamic> json) => _$GeneralFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GeneralToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _General);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogType.general()';
}


}




/// @nodoc
@JsonSerializable()

class _Analytics implements LogType {
  const _Analytics({final  String? $type}): $type = $type ?? 'analytics';
  factory _Analytics.fromJson(Map<String, dynamic> json) => _$AnalyticsFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$AnalyticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Analytics);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogType.analytics()';
}


}




/// @nodoc
@JsonSerializable()

class _Crash implements LogType {
  const _Crash({final  String? $type}): $type = $type ?? 'crash';
  factory _Crash.fromJson(Map<String, dynamic> json) => _$CrashFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$CrashToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Crash);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogType.crash()';
}


}




/// @nodoc
@JsonSerializable()

class _Performance implements LogType {
  const _Performance({final  String? $type}): $type = $type ?? 'performance';
  factory _Performance.fromJson(Map<String, dynamic> json) => _$PerformanceFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$PerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Performance);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogType.performance()';
}


}




// dart format on
