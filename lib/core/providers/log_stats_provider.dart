import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logs_provider.dart';
import 'auth_provider.dart';
import 'project_provider.dart';

class LogStats {
  final int totalLogs;
  final int errorCount;
  final int warningCount;
  final int eventCount;
  final int performanceCount;

  const LogStats({
    required this.totalLogs,
    required this.errorCount,
    required this.warningCount,
    required this.eventCount,
    required this.performanceCount,
  });

  static LogStats empty() => const LogStats(
        totalLogs: 0,
        errorCount: 0,
        warningCount: 0,
        eventCount: 0,
        performanceCount: 0,
      );
}

// Stats state notifier
class LogStatsNotifier extends AsyncNotifier<LogStats> {
  Timer? _pollingTimer;

  @override
  Future<LogStats> build() async {
    // Watch project provider to refetch when project changes
    ref.watch(projectProvider);
    
    // Start auto-polling
    _startPolling();
    
    // Clean up on dispose
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    
    // Initial fetch
    return _fetchStats();
  }

  void _startPolling() {
    _pollingTimer?.cancel();

    final interval = ref.watch(pollingIntervalProvider);
    _pollingTimer = Timer.periodic(interval, (_) {
      refresh();
    });
  }

  Future<LogStats> _fetchStats() async {
    final authState = ref.read(authProvider);
    final projectState = ref.read(projectProvider);

    if (authState.user == null || projectState.selectedProject == null) {
      return LogStats.empty();
    }

    final repository = ref.read(logsRepositoryProvider);
    final statsMap = await repository.fetchStats(
      projectId: projectState.selectedProject!.id,
    );
    
    return LogStats(
      totalLogs: statsMap['totalLogs'] ?? 0,
      errorCount: statsMap['errorCount'] ?? 0,
      warningCount: statsMap['warningCount'] ?? 0,
      eventCount: statsMap['eventCount'] ?? 0,
      performanceCount: statsMap['performanceCount'] ?? 0,
    );
  }

  /// Manually refresh stats
  Future<void> refresh() async {
    // Silent refresh
    final newStats = await AsyncValue.guard(() => _fetchStats());

    if (newStats.hasValue) {
      state = newStats;
    } else if (newStats.hasError) {
      state = newStats;
    }
  }
}

// Provider for log statistics
final logStatsProvider = AsyncNotifierProvider<LogStatsNotifier, LogStats>(() {
  return LogStatsNotifier();
});
