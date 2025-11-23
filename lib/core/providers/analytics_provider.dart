import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/analytics_models.dart';
import '../repositories/analytics_repository.dart';
import './auth_provider.dart';
import './project_provider.dart';

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
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  final userId = authState.user?.id;
  final projectId = projectState.selectedProject?.id;

  if (userId == null || projectId == null) {
    throw Exception('User or project not selected');
  }

  return repository.getSummary(
    userId: userId,
    projectId: projectId,
    hours: hours,
  );
});

// Logs timeline provider
final logsTimelineProvider = FutureProvider.autoDispose<List<LogTimelinePoint>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
    final authState = ref.watch(authProvider);
    final projectState = ref.watch(projectProvider);

    final userId = authState.user?.id;
    final projectId = projectState.selectedProject?.id;

    if (userId == null || projectId == null) {
      throw Exception('User or project not selected');
    }

    return repository.getLogsTimeline(
      userId: userId,
      projectId: projectId,
      hours: hours,
    );
});

// Log levels distribution provider
final logLevelsProvider = FutureProvider.autoDispose<List<LogLevelStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  final userId = authState.user?.id;
  final projectId = projectState.selectedProject?.id;

  if (userId == null || projectId == null) {
    throw Exception('User or project not selected');
  }

  return repository.getLogLevels(
    userId: userId,
    projectId: projectId,
    hours: hours,
  );
});

// Top errors provider
final topErrorsProvider = FutureProvider.autoDispose<List<TopErrorItem>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  final userId = authState.user?.id;
  final projectId = projectState.selectedProject?.id;

  if (userId == null || projectId == null) {
    throw Exception('User or project not selected');
  }

  return repository.getTopErrors(
    userId: userId,
    projectId: projectId,
    hours: hours,
    limit: 10,
  );
});

// Active users provider
final activeUsersProvider = FutureProvider.autoDispose<List<ActiveUserStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  final userId = authState.user?.id;
  final projectId = projectState.selectedProject?.id;

  if (userId == null || projectId == null) {
    throw Exception('User or project not selected');
  }

  return repository.getActiveUsers(
    userId: userId,
    projectId: projectId,
    hours: hours,
    limit: 10,
  );
});
