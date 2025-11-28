import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_models.dart';
import '../repositories/analytics_repository.dart';
import './project_provider.dart';
import '../services/api_client.dart';
import '../config/api_config.dart'; // Added import for ApiConfig

// Repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRepository(
    apiClient,
    baseUrl: ApiConfig.baseUrl, // Replaced hardcoded URL with ApiConfig.baseUrl
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
final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
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
final logsTimelineProvider = FutureProvider<List<LogTimelinePoint>>((
  ref,
) async {
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
final logLevelsProvider = FutureProvider<List<LogLevelStat>>((ref) async {
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
final topErrorsProvider = FutureProvider<List<TopErrorItem>>((ref) async {
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
final activeUsersProvider = FutureProvider<List<ActiveUserStat>>((ref) async {
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

// Performance metrics provider
final performanceMetricsProvider = FutureProvider<PerformanceMetrics>((
  ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final hours = ref.watch(analyticsTimeRangeProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;
  final apiKey = projectState.selectedProject?.apiKey;

  if (projectId == null || apiKey == null) {
    throw Exception('Project not selected');
  }

  return repository.getPerformanceMetrics(
    projectId: projectId,
    apiKey: apiKey,
    hours: hours,
  );
});

// Funnel selected steps notifier
class FunnelStepsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void setSteps(List<String> steps) => state = steps;
  void addStep(String step) => state = [...state, step];
  void removeStep(String step) =>
      state = state.where((s) => s != step).toList();
  void clearSteps() => state = [];
  void reorderSteps(int oldIndex, int newIndex) {
    final items = [...state];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }
}

final funnelStepsProvider = NotifierProvider<FunnelStepsNotifier, List<String>>(
  FunnelStepsNotifier.new,
);

// Funnel date range notifier
class FunnelDateRangeNotifier extends Notifier<(DateTime?, DateTime?)> {
  @override
  (DateTime?, DateTime?) build() => (null, null);

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = (startDate, endDate);
  }

  void clearDateRange() => state = (null, null);
}

final funnelDateRangeProvider =
    NotifierProvider<FunnelDateRangeNotifier, (DateTime?, DateTime?)>(
      FunnelDateRangeNotifier.new,
    );

// Available events provider
final availableEventsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getAvailableEvents(projectId: projectId);
});

// Funnel data provider
final funnelDataProvider = FutureProvider.autoDispose<FunnelData?>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final projectState = ref.watch(projectProvider);
  final steps = ref.watch(funnelStepsProvider);
  final dateRange = ref.watch(funnelDateRangeProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  // Don't fetch if no steps are selected
  if (steps.isEmpty) {
    return null;
  }

  return repository.getFunnelData(
    projectId: projectId,
    steps: steps,
    startDate: dateRange.$1,
    endDate: dateRange.$2,
  );
});
