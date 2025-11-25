import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_model/log_model.dart';
import '../models/filter_state/filter_state.dart';
import 'logs_provider.dart';
import 'filter_provider.dart';

// Computed provider for filtered logs
final filteredLogsProvider = Provider<AsyncValue<List<LogModel>>>((
  ref,
) {
  final logsAsync = ref.watch(logsProvider);
  final filter = ref.watch(filterProvider);

  return logsAsync.whenData((logs) {
    var filtered = logs;

    // Filter by level
    if (filter.level != null) {
      filtered = filtered.where((log) => log.level == filter.level).toList();
    }

    // Filter by type
    if (filter.type != null) {
      filtered = filtered.where((log) => log.type == filter.type).toList();
    }

    // Filter by date range
    if (filter.dateFrom != null) {
      filtered = filtered
          .where((log) => log.timestamp.isAfter(filter.dateFrom!))
          .toList();
    }
    if (filter.dateTo != null) {
      filtered = filtered
          .where((log) => log.timestamp.isBefore(filter.dateTo!))
          .toList();
    }

    // Filter by search query
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        return log.message.toLowerCase().contains(query) ||
            log.stackTrace?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison;
      switch (filter.sortBy) {
        case SortField.timestamp:
          comparison = a.timestamp.compareTo(b.timestamp);
          break;
        case SortField.level:
          comparison = a.level.toString().compareTo(b.level.toString());
          break;
        case SortField.type:
          comparison = a.type.toString().compareTo(b.type.toString());
          break;
        case SortField.message:
          comparison = a.message.compareTo(b.message);
          break;
      }

      return filter.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  });
});
