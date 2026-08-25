import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/project.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/organization_provider.dart';
import 'deep_link_handler_screen.dart';

/// A screen that handles analytics deep links from digest emails.
/// 
/// This screen:
/// 1. Shows a loading indicator
/// 2. Checks authentication (stores pending deep link if not authenticated)
/// 3. Waits for projects to load
/// 4. Auto-selects the project from the deep link
/// 5. Sets the time range (24h for daily/morning, 7d for weekly)
/// 6. Navigates directly to analytics screen
class AnalyticsDeepLinkScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? period; // 'daily', 'morning', or 'weekly'

  const AnalyticsDeepLinkScreen({
    super.key,
    this.projectId,
    this.period,
  });

  @override
  ConsumerState<AnalyticsDeepLinkScreen> createState() => _AnalyticsDeepLinkScreenState();
}

class _AnalyticsDeepLinkScreenState extends ConsumerState<AnalyticsDeepLinkScreen> {
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
    debugPrint('AnalyticsDeepLink: $status');
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
      int authWaitAttempts = 10; // 5 seconds max
      while (!authState.isAuthenticated && authWaitAttempts > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        authState = ref.read(authProvider);
        authWaitAttempts--;
        
        if (authWaitAttempts == 0 && !authState.isAuthenticated) {
          break;
        }
      }
      
      if (!authState.isAuthenticated) {
        _updateStatus('Not authenticated, redirecting to login...');
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
      debugPrint('AnalyticsDeepLink: Selecting project: ${selected.name}');
      projectNotifier.selectProject(selected);

      // Wait for project selection to take effect
      await Future.delayed(const Duration(milliseconds: 300));

      // Set the appropriate time range based on period
      // daily/morning = 24 hours, weekly = 168 hours (7 days)
      _updateStatus('Setting time range...');
      final period = widget.period?.toLowerCase() ?? 'daily';
      final timeRangeHours = period == 'weekly' ? 168 : 24;
      ref.read(analyticsTimeRangeProvider.notifier).set(timeRangeHours);

      // Navigate directly to analytics screen
      _updateStatus('Opening analytics...');
      if (mounted) {
        context.go('/analytics');
      }

    } catch (e) {
      debugPrint('AnalyticsDeepLink: Error processing deep link: $e');
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
    // Normalize period
    final period = widget.period?.toLowerCase();
    final normalizedPeriod = (period == 'weekly') ? 'weekly' : 'daily';
    
    final pendingData = {
      'type': 'digest',
      'project_id': widget.projectId,
      'period': normalizedPeriod,
    };
    debugPrint('AnalyticsDeepLink: Storing pending deep link: $pendingData');
    PendingUrlDeepLink.data = pendingData;
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
