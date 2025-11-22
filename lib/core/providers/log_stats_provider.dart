import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_model/log_model.dart';
import '../models/log_level/log_level.dart';
import 'logs_provider.dart';

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

// Computed provider for log statistics
final logStatsProvider = Provider<AsyncValue<LogStats>>((ref) {
  final logsAsync = ref.watch(logsProvider);

  return logsAsync.whenData((logs) {
    int errorCount = 0;
    int warningCount = 0;
    int eventCount = 0;
    int performanceCount = 0;

    for (final log in logs) {
      log.level.when(
        debug: () {},
        info: () {},
        warning: () => warningCount++,
        error: () => errorCount++,
        fatal: () => errorCount++,
      );

      log.type.when(
        log: () {},
        errorr: () {},
        analytics: () {},
        event: () => eventCount++,
        performance: () => performanceCount++,
        network: () {},
        custom: (_) {},
      );
    }

    return LogStats(
      totalLogs: logs.length,
      errorCount: errorCount,
      warningCount: warningCount,
      eventCount: eventCount,
      performanceCount: performanceCount,
    );
  });
});
