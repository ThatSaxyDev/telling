import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/log_model/log_model.dart';
import 'auth_provider.dart';
import 'project_provider.dart';
import 'logs_provider.dart';

/// Provider for activity timeline logs (recent activity on overview)
final activityTimelineProvider = FutureProvider<List<LogModel>>((ref) async {
  // Keep provider alive for 2 minutes after last listener
  // This prevents loading flicker when navigating to/from overview
  // final link = ref.keepAlive();
  
  // // Auto-cancel the keepAlive after 2 minutes
  // Timer(const Duration(minutes: 2), () {
  //   link.close();
  // });
  
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  if (authState.user == null || projectState.selectedProject == null) {
    return [];
  }

  final repository = ref.watch(logsRepositoryProvider);
  return repository.fetchLogs(
    page: 1,
    limit: 20,
    projectId: projectState.selectedProject!.id,
  );
});
