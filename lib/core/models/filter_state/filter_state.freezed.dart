// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FilterState {

 LogLevel? get level; LogType? get type; DateTime? get dateFrom; DateTime? get dateTo; String get searchQuery; SortField get sortBy; SortOrder get sortOrder; String? get userId;
/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterStateCopyWith<FilterState> get copyWith => _$FilterStateCopyWithImpl<FilterState>(this as FilterState, _$identity);

  /// Serializes this FilterState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilterState&&(identical(other.level, level) || other.level == level)&&(identical(other.type, type) || other.type == type)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,level,type,dateFrom,dateTo,searchQuery,sortBy,sortOrder,userId);

@override
String toString() {
  return 'FilterState(level: $level, type: $type, dateFrom: $dateFrom, dateTo: $dateTo, searchQuery: $searchQuery, sortBy: $sortBy, sortOrder: $sortOrder, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $FilterStateCopyWith<$Res>  {
  factory $FilterStateCopyWith(FilterState value, $Res Function(FilterState) _then) = _$FilterStateCopyWithImpl;
@useResult
$Res call({
 LogLevel? level, LogType? type, DateTime? dateFrom, DateTime? dateTo, String searchQuery, SortField sortBy, SortOrder sortOrder, String? userId
});


$LogLevelCopyWith<$Res>? get level;$LogTypeCopyWith<$Res>? get type;

}
/// @nodoc
class _$FilterStateCopyWithImpl<$Res>
    implements $FilterStateCopyWith<$Res> {
  _$FilterStateCopyWithImpl(this._self, this._then);

  final FilterState _self;
  final $Res Function(FilterState) _then;

/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = freezed,Object? type = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? searchQuery = null,Object? sortBy = null,Object? sortOrder = null,Object? userId = freezed,}) {
  return _then(_self.copyWith(
level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LogType?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortField,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as SortOrder,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogLevelCopyWith<$Res>? get level {
    if (_self.level == null) {
    return null;
  }

  return $LogLevelCopyWith<$Res>(_self.level!, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogTypeCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $LogTypeCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}


/// Adds pattern-matching-related methods to [FilterState].
extension FilterStatePatterns on FilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FilterState value)  $default,){
final _that = this;
switch (_that) {
case _FilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FilterState value)?  $default,){
final _that = this;
switch (_that) {
case _FilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LogLevel? level,  LogType? type,  DateTime? dateFrom,  DateTime? dateTo,  String searchQuery,  SortField sortBy,  SortOrder sortOrder,  String? userId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FilterState() when $default != null:
return $default(_that.level,_that.type,_that.dateFrom,_that.dateTo,_that.searchQuery,_that.sortBy,_that.sortOrder,_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LogLevel? level,  LogType? type,  DateTime? dateFrom,  DateTime? dateTo,  String searchQuery,  SortField sortBy,  SortOrder sortOrder,  String? userId)  $default,) {final _that = this;
switch (_that) {
case _FilterState():
return $default(_that.level,_that.type,_that.dateFrom,_that.dateTo,_that.searchQuery,_that.sortBy,_that.sortOrder,_that.userId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LogLevel? level,  LogType? type,  DateTime? dateFrom,  DateTime? dateTo,  String searchQuery,  SortField sortBy,  SortOrder sortOrder,  String? userId)?  $default,) {final _that = this;
switch (_that) {
case _FilterState() when $default != null:
return $default(_that.level,_that.type,_that.dateFrom,_that.dateTo,_that.searchQuery,_that.sortBy,_that.sortOrder,_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FilterState implements FilterState {
  const _FilterState({this.level, this.type, this.dateFrom, this.dateTo, this.searchQuery = '', this.sortBy = SortField.timestamp, this.sortOrder = SortOrder.descending, this.userId});
  factory _FilterState.fromJson(Map<String, dynamic> json) => _$FilterStateFromJson(json);

@override final  LogLevel? level;
@override final  LogType? type;
@override final  DateTime? dateFrom;
@override final  DateTime? dateTo;
@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  SortField sortBy;
@override@JsonKey() final  SortOrder sortOrder;
@override final  String? userId;

/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterStateCopyWith<_FilterState> get copyWith => __$FilterStateCopyWithImpl<_FilterState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilterStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilterState&&(identical(other.level, level) || other.level == level)&&(identical(other.type, type) || other.type == type)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,level,type,dateFrom,dateTo,searchQuery,sortBy,sortOrder,userId);

@override
String toString() {
  return 'FilterState(level: $level, type: $type, dateFrom: $dateFrom, dateTo: $dateTo, searchQuery: $searchQuery, sortBy: $sortBy, sortOrder: $sortOrder, userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$FilterStateCopyWith<$Res> implements $FilterStateCopyWith<$Res> {
  factory _$FilterStateCopyWith(_FilterState value, $Res Function(_FilterState) _then) = __$FilterStateCopyWithImpl;
@override @useResult
$Res call({
 LogLevel? level, LogType? type, DateTime? dateFrom, DateTime? dateTo, String searchQuery, SortField sortBy, SortOrder sortOrder, String? userId
});


@override $LogLevelCopyWith<$Res>? get level;@override $LogTypeCopyWith<$Res>? get type;

}
/// @nodoc
class __$FilterStateCopyWithImpl<$Res>
    implements _$FilterStateCopyWith<$Res> {
  __$FilterStateCopyWithImpl(this._self, this._then);

  final _FilterState _self;
  final $Res Function(_FilterState) _then;

/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = freezed,Object? type = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? searchQuery = null,Object? sortBy = null,Object? sortOrder = null,Object? userId = freezed,}) {
  return _then(_FilterState(
level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LogType?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortField,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as SortOrder,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogLevelCopyWith<$Res>? get level {
    if (_self.level == null) {
    return null;
  }

  return $LogLevelCopyWith<$Res>(_self.level!, (value) {
    return _then(_self.copyWith(level: value));
  });
}/// Create a copy of FilterState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LogTypeCopyWith<$Res>? get type {
    if (_self.type == null) {
    return null;
  }

  return $LogTypeCopyWith<$Res>(_self.type!, (value) {
    return _then(_self.copyWith(type: value));
  });
}
}

// dart format on
