import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pusher_service.dart';
import 'auth_provider.dart';
import 'project_provider.dart';

/// Singleton Pusher service provider.
final pusherServiceProvider = Provider<PusherService>((ref) {
  final service = PusherService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider that manages Pusher connection lifecycle.
/// 
/// Automatically connects when:
/// - User is authenticated (has token)
/// - Project is selected
/// 
/// Automatically disconnects when:
/// - User logs out
/// - Project is deselected
final pusherConnectionProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final projectState = ref.watch(projectProvider);
  final service = ref.watch(pusherServiceProvider);

  if (authState.isAuthenticated &&
      authState.token != null &&
      projectState.selectedProject != null) {
    service.connect(
      token: authState.token!,
      projectId: projectState.selectedProject!.id,
    );
  } else {
    service.disconnect();
  }
});

/// Stream provider for Pusher events.
/// 
/// Consumers can filter by event type:
/// ```dart
/// ref.listen<AsyncValue<PusherEvent>>(pusherEventsProvider, (_, next) {
///   next.whenData((event) {
///     if (event.type == 'log_created') {
///       // Handle new log
///     }
///   });
/// });
/// ```
final pusherEventsProvider = StreamProvider<PusherEvent>((ref) {
  // Ensure connection is established
  ref.watch(pusherConnectionProvider);

  final service = ref.watch(pusherServiceProvider);
  return service.events;
});

/// Provider to check if Pusher is connected.
final pusherConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(pusherServiceProvider);
  // Trigger connection check
  ref.watch(pusherConnectionProvider);
  return service.isConnected;
});
