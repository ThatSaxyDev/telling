import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_model/log_model.dart';
import '../repositories/logs_repository.dart';
import '../services/pusher_service.dart';
import 'auth_provider.dart';
import 'project_provider.dart';
import 'pusher_provider.dart';
import '../services/api_client.dart';

// Repository provider
final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final repository = LogsRepository(apiClient);
  // ref.onDispose(() => repository.dispose()); // ApiClient manages its own client
  return repository;
});

// Logs state notifier
class LogsNotifier extends AsyncNotifier<List<LogModel>> {
  int _page = 1;
  final int _limit = 50;
  bool _hasMore = true;
  String? _userId;

  int get page => _page;
  int get limit => _limit;
  bool get hasMore => _hasMore;
  String? get userId => _userId;

  Timer? _pollingTimer;
  
  @override
  Future<List<LogModel>> build() async {
    // Watch project provider to refetch when project changes
    ref.watch(projectProvider);
    
    // Listen to Pusher events for real-time log updates
    ref.listen<AsyncValue<PusherEvent>>(pusherEventsProvider, (_, next) {
      next.whenData((event) {
        if (event.type == 'log_created' && _page == 1 && _userId == null) {
          // Only prepend new logs if we're on page 1 and no user filter
          try {
            // On web, event.data may be a JS object that doesn't cast properly
            final Map<String, dynamic> logData;
            if (event.data is Map<String, dynamic>) {
              logData = event.data;
            } else {
              final jsonStr = jsonEncode(event.data);
              logData = jsonDecode(jsonStr) as Map<String, dynamic>;
            }
            final newLog = LogModel.fromJson(logData);
            state.whenData((logs) {
              state = AsyncValue.data([newLog, ...logs.take(_limit - 1)]);
            });
          } catch (e) {
            // Invalid log data from Pusher, ignore
          }
        }
      });
    });
    
    // Clean up on dispose
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    
    // Initial fetch
    return _fetchLogs();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    
    final interval = ref.watch(pollingIntervalProvider);
    _pollingTimer = Timer.periodic(interval, (_) {
      // Only poll if we are on the first page
      if (_page == 1) {
        refresh();
      }
    });
  }

  Future<List<LogModel>> _fetchLogs() async {
    final authState = ref.read(authProvider);
    final projectState = ref.read(projectProvider);

    if (authState.user == null || projectState.selectedProject == null) {
      return [];
    }

    final repository = ref.read(logsRepositoryProvider);
    final logs = await repository.fetchLogs(
      page: _page,
      limit: _limit,
      userId: _userId,
      projectId: projectState.selectedProject!.id,
    );

    // Update hasMore flag
    _hasMore = logs.length == _limit;

    return logs;
  }

  /// Set user filter
  void setUserFilter(String? userId) async {
    _userId = userId;
    _page = 1; // Reset to first page
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLogs());
  }

  /// Manually refresh logs
  Future<void> refresh() async {
    // Silent refresh - don't set loading state
    final newLogs = await AsyncValue.guard(() => _fetchLogs());

    // Only update state if successful to avoid error flickering too
    if (newLogs.hasValue) {
      state = newLogs;
    } else if (newLogs.hasError) {
      // Optionally handle error silently or update state
      // For now, we'll update state so errors are visible
      state = newLogs;
    }
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (_hasMore) {
      _page++;
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchLogs());
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (_page > 1) {
      _page--;
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchLogs());
    }
  }

  /// Delete a log
  Future<void> deleteLog(String id) async {
    try {
      final repository = ref.read(logsRepositoryProvider);
      await repository.deleteLog(id);
      
      // Optimistically update state
      state.whenData((logs) {
        state = AsyncValue.data(
          logs.where((log) => log.id != id).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for logs with auto-polling
final logsProvider =
    AsyncNotifierProvider<LogsNotifier, List<LogModel>>(() {
  return LogsNotifier();
});

// Polling interval provider (configurable)
// NOTE: Increased from 30 seconds to 5 minutes to reduce API usage
class PollingIntervalNotifier extends Notifier<Duration> {
  @override
  Duration build() => const Duration(minutes: 5);
  void set(Duration duration) => state = duration;
}

final pollingIntervalProvider =
    NotifierProvider<PollingIntervalNotifier, Duration>(
      PollingIntervalNotifier.new,
    );

// Session grouping toggle
class SessionGroupedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final isSessionGroupedProvider = NotifierProvider<SessionGroupedNotifier, bool>(
  SessionGroupedNotifier.new,
);

// Sessions provider
final sessionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(logsRepositoryProvider);
  // Re-fetch when polling interval triggers (optional, but good for live updates)
  ref.watch(pollingIntervalProvider);
  
  // Watch project changes
  final projectState = ref.watch(projectProvider);
  if (projectState.selectedProject == null) return [];

  return repository.fetchSessions(
    projectId: projectState.selectedProject!.id,
    limit: 50,
    offset: 0,
  );
});

// Session logs provider
final sessionLogsProvider = FutureProvider.family<List<LogModel>, String>((
  ref,
  sessionId,
) async {
  final repository = ref.watch(logsRepositoryProvider);
  final projectState = ref.watch(projectProvider);

  if (projectState.selectedProject == null) {
    throw Exception('Project not selected');
  }

  return repository.fetchSessionLogs(
    sessionId,
    projectId: projectState.selectedProject!.id,
  );
});
