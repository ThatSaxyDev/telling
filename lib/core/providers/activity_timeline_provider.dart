import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_model/log_model.dart';
import '../services/pusher_service.dart';
import 'auth_provider.dart';
import 'project_provider.dart';
import 'logs_provider.dart';
import 'pusher_provider.dart';

/// Notifier for activity timeline logs (recent activity on overview)
class ActivityTimelineNotifier extends AsyncNotifier<List<LogModel>> {
  @override
  Future<List<LogModel>> build() async {
    final authState = ref.watch(authProvider);
    final projectState = ref.watch(projectProvider);

    if (authState.user == null || projectState.selectedProject == null) {
      return [];
    }

    // Listen to Pusher events for real-time updates
    ref.listen<AsyncValue<PusherEvent>>(pusherEventsProvider, (_, next) {
      next.whenData((event) {
        if (event.type == 'log_created') {
          // Prepend new log to timeline
          try {
            final newLog = LogModel.fromJson(event.data);
            state.whenData((logs) {
              // Prepend and limit to 20 items
              state = AsyncValue.data([newLog, ...logs.take(19)]);
            });
          } catch (e) {
            // Invalid log data, ignore
          }
        }
      });
    });

    final repository = ref.watch(logsRepositoryProvider);
    return repository.fetchLogs(
      page: 1,
      limit: 20,
      projectId: projectState.selectedProject!.id,
    );
  }

  /// Manually refresh the timeline
  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    final projectState = ref.read(projectProvider);

    if (authState.user == null || projectState.selectedProject == null) {
      return;
    }

    final repository = ref.read(logsRepositoryProvider);
    final logs = await repository.fetchLogs(
      page: 1,
      limit: 20,
      projectId: projectState.selectedProject!.id,
    );
    state = AsyncValue.data(logs);
  }
}

/// Provider for activity timeline logs
final activityTimelineProvider =
    AsyncNotifierProvider<ActivityTimelineNotifier, List<LogModel>>(() {
      return ActivityTimelineNotifier();
});
