// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FilterState _$FilterStateFromJson(Map<String, dynamic> json) => _FilterState(
  level: json['level'] == null
      ? null
      : LogLevel.fromJson(json['level'] as Map<String, dynamic>),
  type: json['type'] == null
      ? null
      : LogType.fromJson(json['type'] as Map<String, dynamic>),
  dateFrom: json['dateFrom'] == null
      ? null
      : DateTime.parse(json['dateFrom'] as String),
  dateTo: json['dateTo'] == null
      ? null
      : DateTime.parse(json['dateTo'] as String),
  searchQuery: json['searchQuery'] as String? ?? '',
  sortBy:
      $enumDecodeNullable(_$SortFieldEnumMap, json['sortBy']) ??
      SortField.timestamp,
  sortOrder:
      $enumDecodeNullable(_$SortOrderEnumMap, json['sortOrder']) ??
      SortOrder.descending,
);

Map<String, dynamic> _$FilterStateToJson(_FilterState instance) =>
    <String, dynamic>{
      'level': instance.level,
      'type': instance.type,
      'dateFrom': instance.dateFrom?.toIso8601String(),
      'dateTo': instance.dateTo?.toIso8601String(),
      'searchQuery': instance.searchQuery,
      'sortBy': _$SortFieldEnumMap[instance.sortBy]!,
      'sortOrder': _$SortOrderEnumMap[instance.sortOrder]!,
    };

const _$SortFieldEnumMap = {
  SortField.timestamp: 'timestamp',
  SortField.level: 'level',
  SortField.type: 'type',
  SortField.message: 'message',
};

const _$SortOrderEnumMap = {
  SortOrder.ascending: 'ascending',
  SortOrder.descending: 'descending',
};
