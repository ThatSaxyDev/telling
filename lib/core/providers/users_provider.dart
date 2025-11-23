import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/log_entry.dart';
import '../repositories/users_repository.dart';
import './project_provider.dart';
import '../services/api_client.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsersRepository(apiClient);
});

final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final repository = ref.watch(usersRepositoryProvider);
  final projectState = ref.watch(projectProvider);

  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getUsers(projectId: projectId);
});

final userStatsProvider = FutureProvider.autoDispose.family<UserStats, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(usersRepositoryProvider);
  final projectState = ref.watch(projectProvider);
  final projectId = projectState.selectedProject?.id;

  if (projectId == null) {
    throw Exception('Project not selected');
  }

  return repository.getUserStats(userId, projectId: projectId);
});

final userSessionsProvider = FutureProvider.autoDispose
    .family<List<UserSession>, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);
      final projectState = ref.watch(projectProvider);
      final projectId = projectState.selectedProject?.id;

      if (projectId == null) {
        throw Exception('Project not selected');
      }

      return repository.getUserSessions(userId, projectId: projectId);
});

final userLogsProvider = FutureProvider.autoDispose
    .family<List<LogEntry>, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);
      final projectState = ref.watch(projectProvider);
      final projectId = projectState.selectedProject?.id;

      if (projectId == null) {
        throw Exception('Project not selected');
      }

      return repository.getUserLogs(userId, projectId: projectId);
});

class SelectedUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final selectedUserIdProvider =
    NotifierProvider<SelectedUserIdNotifier, String?>(
      SelectedUserIdNotifier.new,
    );
