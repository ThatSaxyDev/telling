import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../features/auth/landing_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/overview/overview_screen.dart';
import '../../features/logs/logs_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/funnel/funnel_screen.dart';
import '../../features/users/users_screen.dart';
import '../../features/users/user_details_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/projects/project_settings_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ValueNotifier<int>(0);

  ref.listen(authProvider, (_, __) => routerNotifier.value++);
  ref.listen(projectProvider, (_, __) => routerNotifier.value++);

  return GoRouter(
    initialLocation: '/landing',
    observers: [Telling.instance.goRouterScreenTracker],
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final projectState = ref.read(projectProvider);

      final isLoggedIn = authState.isAuthenticated;
      final hasSelectedProject = projectState.selectedProject != null;
      final isOnLanding = state.matchedLocation == '/landing';
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-otp';
      final isOnProjectsScreen = state.matchedLocation == '/projects';

      // Logged in but on landing page? Go to projects
      if (isLoggedIn && isOnLanding) return '/projects';

      // Not logged in and not on any auth screen? Go to landing
      if (!isLoggedIn && !isLoggingIn && !isOnLanding) return '/landing';

      // Logged in but on auth screens? Go to projects
      if (isLoggedIn && isLoggingIn) return '/projects';

      // Logged in but no project selected and not on projects screen? Force project selection
      if (isLoggedIn && !hasSelectedProject && !isOnProjectsScreen) {
        return '/projects';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            userId: extras['userId'] as String,
            email: extras['email'] as String,
          );
        },
      ),
      // Projects Selection Screen (No Dashboard Layout)
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardLayout(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'overview',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const OverviewScreen()),
          ),
          GoRoute(
            path: '/logs',
            name: 'logs',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const LogsScreen()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const UsersScreen()),
            routes: [
              GoRoute(
                path: ':userId',
                pageBuilder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return NoTransitionPage(
                    child: UserDetailsScreen(userId: userId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const AnalyticsScreen()),
          ),
          GoRoute(
            path: '/funnel',
            name: 'funnel',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const FunnelScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SettingsScreen()),
          ),
          GoRoute(
            path: '/projects/settings',
            name: 'project_settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const ProjectSettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
