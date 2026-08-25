import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/project.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/organization_provider.dart';
import '../../core/providers/logs_provider.dart';
import '../../core/router/app_router.dart';
import '../logs/widgets/log_details_dialog.dart';

/// A screen that handles URL-based deep links (from Universal Links or web URLs).
/// 
/// This screen:
/// 1. Shows a loading indicator
/// 2. Checks authentication (stores pending deep link if not authenticated)
/// 3. Waits for projects to load
/// 4. Auto-selects the project from the deep link
/// 5. Navigates to dashboard and shows LogDetailsDialog
class DeepLinkHandlerScreen extends ConsumerStatefulWidget {
  final String logId;
  final String? projectId;

  const DeepLinkHandlerScreen({
    super.key,
    required this.logId,
    this.projectId,
  });

  @override
  ConsumerState<DeepLinkHandlerScreen> createState() => _DeepLinkHandlerScreenState();
}

class _DeepLinkHandlerScreenState extends ConsumerState<DeepLinkHandlerScreen> {
  bool _isProcessing = false;
  String? _error;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processDeepLink();
    });
  }

  void _updateStatus(String status) {
    if (mounted) {
      setState(() => _status = status);
    }
    debugPrint('DeepLinkHandler: $status');
  }

  Future<void> _processDeepLink() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Wait for auth session to load from storage  
      // (AuthNotifier.build runs _checkSession async, we need to wait for it)
      _updateStatus('Checking authentication...');
      var authState = ref.read(authProvider);
      
      // Give the auth provider a moment to load from storage
      // If auth is loading or we don't have a definitive answer, wait
      int authWaitAttempts = 10; // 5 seconds max
      while (!authState.isAuthenticated && authWaitAttempts > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        authState = ref.read(authProvider);
        authWaitAttempts--;
        
        // If we've waited and still no auth, they're not logged in
        if (authWaitAttempts == 0 && !authState.isAuthenticated) {
          break;
        }
      }
      
      if (!authState.isAuthenticated) {
        _updateStatus('Not authenticated, redirecting to login...');
        // Store the deep link data for later processing
        _storePendingDeepLink();
        if (mounted) {
          context.go('/login');
        }
        return;
      }
      
      _updateStatus('Authenticated! Loading projects...');

      // Wait for projects to load
      var projectState = ref.read(projectProvider);
      
      // If projects are loading, wait for them
      int maxWaitAttempts = 40; // 20 seconds max
      while (projectState.isLoading && maxWaitAttempts > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        projectState = ref.read(projectProvider);
        maxWaitAttempts--;
      }
      
      // If projects list is empty and not loading, trigger a load
      if (projectState.projects.isEmpty && !projectState.isLoading) {
        _updateStatus('Fetching projects...');
        await ref.read(projectProvider.notifier).loadProjects();
        
        // Wait for load to complete
        projectState = ref.read(projectProvider);
        maxWaitAttempts = 20;
        while (projectState.isLoading && maxWaitAttempts > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          projectState = ref.read(projectProvider);
          maxWaitAttempts--;
        }
      }

      _updateStatus('Projects loaded: ${projectState.projects.length}');

      // The link may target a project in another of the user's units —
      // switch to the owning unit (and reload its projects) first.
      if (widget.projectId != null &&
          !projectState.projects.any((p) => p.id == widget.projectId)) {
        await _switchToProjectUnit(widget.projectId!);
        projectState = ref.read(projectProvider);
      }

      // If still no projects, show error
      if (projectState.projects.isEmpty) {
        setState(() {
          _error = 'No projects found. Please create a project first.';
        });
        return;
      }

      // Auto-select the project from the deep link
      _updateStatus('Selecting project...');
      final projectNotifier = ref.read(projectProvider.notifier);

      Project? match;
      if (widget.projectId != null) {
        for (final p in projectState.projects) {
          if (p.id == widget.projectId) {
            match = p;
            break;
          }
        }
      }
      final selected = match ?? projectState.projects.first;
      debugPrint('DeepLinkHandler: Selecting project: ${selected.name}');
      projectNotifier.selectProject(selected);

      // Wait for project selection to take effect
      await Future.delayed(const Duration(milliseconds: 300));

      // Save references BEFORE navigating (widget will unmount after navigation)
      final router = ref.read(appRouterProvider);
      final logsRepository = ref.read(logsRepositoryProvider);

      // Navigate to dashboard
      _updateStatus('Opening dashboard...');
      if (mounted) {
        context.go('/');
      }

      // Wait for navigation to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the log and show dialog (using pre-saved references)
      _updateStatus('Loading log details...');
      await _fetchLogAndShowDialog(router, logsRepository);

    } catch (e) {
      debugPrint('DeepLinkHandler: Error processing deep link: $e');
      setState(() {
        _error = 'Failed to load: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Switches to the unit owning [projectId] (when the user belongs to it)
  /// and reloads its projects so the deep-linked project becomes selectable.
  Future<void> _switchToProjectUnit(String projectId) async {
    final orgNotifier = ref.read(organizationProvider.notifier);
    final organizationId = await orgNotifier.resolveProjectUnit(projectId);
    if (organizationId == null) return;

    _updateStatus('Switching to owning unit...');
    final switched = await orgNotifier.switchUnit(organizationId);
    if (!switched) return;

    ref.read(projectProvider.notifier).reset();
    await ref.read(projectProvider.notifier).loadProjects();
  }

  void _storePendingDeepLink() {
    final pendingData = {
      'type': 'error_alert',
      'log_id': widget.logId,
      'project_id': widget.projectId,
    };
    debugPrint('DeepLinkHandler: Storing pending deep link: $pendingData');
    PendingUrlDeepLink.data = pendingData;
  }

  Future<void> _fetchLogAndShowDialog(GoRouter router, dynamic logsRepository) async {
    try {
      debugPrint('DeepLinkHandler: Fetching log by UUID: ${widget.logId}');
      
      final log = await logsRepository.fetchLogByUuid(widget.logId);

      debugPrint('DeepLinkHandler: Log fetched successfully: ${log.message}');

      // Get the navigator context from the router (pre-saved reference)
      final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
      
      if (navigatorContext != null) {
        debugPrint('DeepLinkHandler: Showing LogDetailsDialog');
        LogDetailsDialog.show(navigatorContext, log);
      } else {
        debugPrint('DeepLinkHandler: Navigator context is null');
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Failed to fetch log: $e');
      final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
      if (navigatorContext != null) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: const Text('Could not find the requested log'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Dashboard'),
              ),
            ] else ...[
              const CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static storage for pending URL deep links (used when user is not authenticated)
class PendingUrlDeepLink {
  static Map<String, dynamic>? data;
  
  static void clear() {
    data = null;
  }
}
