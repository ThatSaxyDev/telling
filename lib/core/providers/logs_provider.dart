import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/log_model/log_model.dart';
import '../repositories/logs_repository.dart';

// Repository provider
final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final repository = LogsRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

// Logs state notifier
class LogsNotifier extends AsyncNotifier<List<LogModel>> {
  Timer? _pollingTimer;
  
  @override
  Future<List<LogModel>> build() async {
    // Start auto-polling
    _startPolling();
    
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
      refresh();
    });
  }

  Future<List<LogModel>> _fetchLogs() async {
    final repository = ref.read(logsRepositoryProvider);
    return repository.fetchLogs();
  }

  /// Manually refresh logs
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLogs());
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
final logsProvider = AsyncNotifierProvider<LogsNotifier, List<LogModel>>(() {
  return LogsNotifier();
});

// Polling interval provider (configurable)
final pollingIntervalProvider = StateProvider<Duration>((ref) {
  return const Duration(seconds: 2);
});
