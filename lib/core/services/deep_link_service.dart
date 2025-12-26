import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../../features/logs/widgets/log_details_dialog.dart';

/// State for pending deep links
class DeepLinkState {
  final Map<String, dynamic>? pendingData;
  final bool isProcessed;

  const DeepLinkState({
    this.pendingData,
    this.isProcessed = false,
  });

  DeepLinkState copyWith({
    Map<String, dynamic>? pendingData,
    bool? isProcessed,
  }) {
    return DeepLinkState(
      pendingData: pendingData ?? this.pendingData,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}

/// Notifier for handling deep links from push notifications
class DeepLinkNotifier extends Notifier<DeepLinkState> {
  @override
  DeepLinkState build() {
    return const DeepLinkState();
  }

  /// Store notification data for later processing
  void storePendingDeepLink(Map<String, dynamic> data) {
    state = DeepLinkState(pendingData: data, isProcessed: false);
  }

  /// Process pending deep link
  Future<void> processPendingDeepLink(BuildContext context) async {
    final data = state.pendingData;
    if (data == null || state.isProcessed) return;

    // Check if user is authenticated
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      debugPrint(
        'DeepLink: User not authenticated, deferring deep link processing',
      );
      // Don't mark as processed - will retry after login
      return;
    }

    // Mark as processed (only after auth check passes)
    state = state.copyWith(isProcessed: true);

    final type = data['type'] as String?;
    final projectId = data['project_id'] as String?;

    if (projectId == null) {
      debugPrint('DeepLink: Missing project ID');
      return;
    }

    // Wait for app to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Wait for projects to load (they auto-load when authenticated)
    var projectState = ref.read(projectProvider);

    // If projects are loading, wait for them
    int maxWaitAttempts = 20; // 10 seconds max
    while (projectState.isLoading && maxWaitAttempts > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      projectState = ref.read(projectProvider);
      maxWaitAttempts--;
    }

    // If projects list is empty and not loading, trigger a load
    if (projectState.projects.isEmpty && !projectState.isLoading) {
      debugPrint('DeepLink: Projects empty, triggering load');
      await ref.read(projectProvider.notifier).loadProjects();
      projectState = ref.read(projectProvider);

      // Wait a bit more for load to complete
      maxWaitAttempts = 10;
      while (projectState.isLoading && maxWaitAttempts > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        projectState = ref.read(projectProvider);
        maxWaitAttempts--;
      }
    }

    debugPrint('DeepLink: Projects loaded: ${projectState.projects.length}');

    // Select the project first
    final projectNotifier = ref.read(projectProvider.notifier);

    // Find the project by ID
    try {
      final project = projectState.projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      );
      projectNotifier.selectProject(project);
    } catch (e) {
      debugPrint('DeepLink: Could not find project $projectId');
      return;
    }

    // Wait for project selection to take effect
    await Future.delayed(const Duration(milliseconds: 300));

    // Get the router from provider (safer than context.go)
    final router = ref.read(appRouterProvider);

    // Navigate based on notification type
    switch (type) {
      case 'error_alert':
      case 'instant_alert':
        // Navigate to dashboard first
        router.go('/');

        // Wait for navigation, then fetch log and show dialog
        await Future.delayed(const Duration(milliseconds: 500));

        if (!context.mounted) {
          debugPrint('DeepLink: Context unmounted after navigation');
          return;
        }

        // Get the log_id (UUID) from notification data
        final logId = data['log_id'] as String?;
        debugPrint('DeepLink: log_id from notification: $logId');
        debugPrint('DeepLink: Full notification data: $data');
        
        if (logId != null && logId.isNotEmpty) {
          await _fetchLogByUuidAndShowDialog(context, logId);
        } else {
          debugPrint('DeepLink: No log_id in notification data!');
        }
        break;

      case 'digest':
        // Get the period type from notification data (daily or weekly)
        final period = data['period'] as String?;
        debugPrint('DeepLink: Digest notification, period: $period');

        // Set the appropriate time range
        // daily = 24 hours, weekly = 168 hours (7 days)
        final timeRangeHours = period == 'weekly' ? 168 : 24;
        ref.read(analyticsTimeRangeProvider.notifier).set(timeRangeHours);
        
        // Navigate to analytics screen
        router.go('/analytics');
        break;

      default:
        // Default to overview
        router.go('/');
        break;
    }

    // Clear pending data
    state = const DeepLinkState();
  }

  /// Fetch log by UUID and show dialog
  Future<void> _fetchLogByUuidAndShowDialog(
    BuildContext context,
    String logId,
  ) async {
    try {
      debugPrint('DeepLink: Fetching log by UUID: $logId');
      
      // Use the logs repository to fetch the log by UUID
      final logsRepository = ref.read(logsRepositoryProvider);
      final log = await logsRepository.fetchLogByUuid(logId);

      debugPrint('DeepLink: Log fetched successfully: ${log.message}');

      // Get the navigator context from the router (this has MaterialLocalizations)
      final router = ref.read(appRouterProvider);
      final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
      
      if (navigatorContext != null) {
        debugPrint('DeepLink: Showing LogDetailsDialog with navigator context...');
        // Show the log details dialog using navigator context
        LogDetailsDialog.show(navigatorContext, log);
      } else {
        debugPrint('DeepLink: Navigator context is null, cannot show dialog');
      }
    } catch (e) {
      debugPrint('DeepLink: Failed to fetch log by UUID: $e');
    }
  }

  /// Clear pending deep link
  void clear() {
    state = const DeepLinkState();
  }
}

/// Provider for deep link handling
final deepLinkProvider = NotifierProvider<DeepLinkNotifier, DeepLinkState>(() {
  return DeepLinkNotifier();
});
