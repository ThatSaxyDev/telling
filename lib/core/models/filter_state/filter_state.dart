import 'package:freezed_annotation/freezed_annotation.dart';
import '../log_level/log_level.dart';

part 'filter_state.freezed.dart';
part 'filter_state.g.dart';

enum SortField { timestamp, level, type, message }
enum SortOrder { ascending, descending }

@freezed
abstract class FilterState with _$FilterState {
  const factory FilterState({
    LogLevel? level,
    LogType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    @Default('') String searchQuery,
    @Default(SortField.timestamp) SortField sortBy,
    @Default(SortOrder.descending) SortOrder sortOrder,
    String? userId,
  }) = _FilterState;

  factory FilterState.fromJson(Map<String, dynamic> json) => _$FilterStateFromJson(json);
}
