import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/log_entry.dart';
import '../repositories/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

final usersListProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUsers();
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
