import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/log_entry.dart';
import '../repositories/users_repository.dart';
import './auth_provider.dart';
import './project_provider.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final repository = ref.watch(usersRepositoryProvider);
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);

  final userId = authState.user?.id;
  final projectId = projectState.selectedProject?.id;

  if (userId == null || projectId == null) {
    throw Exception('User or project not selected');
  }

  return repository.getUsers(projectId: projectId, userId: userId);
});

final userStatsProvider = FutureProvider.autoDispose.family<UserStats, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserStats(userId);
});

final userSessionsProvider = FutureProvider.autoDispose
    .family<List<UserSession>, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserSessions(userId);
});

final userLogsProvider = FutureProvider.autoDispose
    .family<List<LogEntry>, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserLogs(userId);
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
