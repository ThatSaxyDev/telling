import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_state/filter_state.dart';
import '../models/log_level/log_level.dart';

// Filter state notifier
class FilterNotifier extends Notifier<FilterState> {
  static const String _filterKey = 'logs_filter_state';

  @override
  FilterState build() {
    _loadFromStorage();
    return const FilterState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_filterKey);
      if (json != null) {
        // Filter state can be restored from SharedPreferences
        // For now, just keep default state
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  Future<void> _saveToStorage() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // We can implement JSON serialization later
      // For now, just keep state in memory
    } catch (e) {
      // Ignore storage errors
    }
  }

  void setLevel(LogLevel? level) {
    state = state.copyWith(level: level);
    _saveToStorage();
  }

  void setType(LogType? type) {
    state = state.copyWith(type: type);
    _saveToStorage();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    _saveToStorage();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _saveToStorage();
  }

  void setSortBy(SortField field, SortOrder order) {
    state = state.copyWith(sortBy: field, sortOrder: order);
    _saveToStorage();
  }

  void clearFilters() {
    state = const FilterState();
    _saveToStorage();
  }
}

// Filter provider
final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});
