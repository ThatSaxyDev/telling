import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_models.dart';
import '../repositories/analytics_repository.dart';
import './project_provider.dart';
import '../services/api_client.dart';

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRepository(
    apiClient,
    baseUrl: 'http://localhost:8080/api/v1',
  );
});

// Time range provider (24, 168 for 7d, 720 for 30d)
class AnalyticsTimeRangeNotifier extends Notifier<int> {
  @override
  int build() => 24;
  void set(int hours) => state = hours;
}

final analyticsTimeRangeProvider =
    NotifierProvider<AnalyticsTimeRangeNotifier, int>(
      AnalyticsTimeRangeNotifier.new,
    );

// Analytics summary provider
final analyticsSummaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getSummary(
    projectId: projectId,
    hours: hours,
  );
});

// Logs timeline provider
final logsTimelineProvider = FutureProvider.autoDispose<List<LogTimelinePoint>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
    final hours = ref.watch(analyticsTimeRangeProvider);
    final projectState = ref.watch(projectProvider);

    final projectId = projectState.selectedProject?.id;

    if (projectId == null) {
      throw Exception('Project not selected');
    }

    return repository.getLogsTimeline(
    projectId: projectId, hours: hours);
});

// Log levels distribution provider
final logLevelsProvider = FutureProvider.autoDispose<List<LogLevelStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getLogLevels(
    projectId: projectId,
    hours: hours,
  );
});

// Top errors provider
final topErrorsProvider = FutureProvider.autoDispose<List<TopErrorItem>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getTopErrors(
    projectId: projectId,
    hours: hours,
    limit: 10,
  );
});

// Active users provider
final activeUsersProvider = FutureProvider.autoDispose<List<ActiveUserStat>>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getActiveUsers(
    projectId: projectId,
    hours: hours,
    limit: 10,
  );
});
