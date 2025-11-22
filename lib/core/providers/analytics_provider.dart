import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/analytics_models.dart';
import '../repositories/analytics_repository.dart';

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(baseUrl: 'http://localhost:8080/api/v1');
});

// Time range provider (24, 168 for 7d, 720 for 30d)
final analyticsTimeRangeProvider = StateProvider<int>((ref) => 24);

// Analytics summary provider
final analyticsSummaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  return repository.getSummary(hours: hours);
});

// Logs timeline provider
final logsTimelineProvider = FutureProvider.autoDispose<List<LogTimelinePoint>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  return repository.getLogsTimeline(hours: hours);
});

// Log levels distribution provider
final logLevelsProvider = FutureProvider.autoDispose<List<LogLevelStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  return repository.getLogLevels(hours: hours);
});

// Top errors provider
final topErrorsProvider = FutureProvider.autoDispose<List<TopErrorItem>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  return repository.getTopErrors(hours: hours, limit: 10);
});

// Active users provider
final activeUsersProvider = FutureProvider.autoDispose<List<ActiveUserStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  return repository.getActiveUsers(hours: hours, limit: 10);
});
