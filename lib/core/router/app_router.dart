import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../features/auth/landing_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/privacy_policy_screen.dart';
import '../../features/docs/docs_screen.dart';
import '../../features/overview/overview_screen.dart';
import '../../features/logs/logs_screen.dart';
import '../../features/analytics/analytics_screen.dart';
// import '../../features/funnel/funnel_screen.dart';
import '../../features/funnel/named_funnel_screen.dart';
import '../../features/users/users_screen.dart';
import '../../features/users/user_details_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/projects/project_settings_screen.dart';
import '../../features/projects/version_config_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../features/deep_link/deep_link_handler_screen.dart';
import '../../features/deep_link/analytics_deep_link_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/organization_provider.dart';
import '../../features/auth/organization_onboarding_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ValueNotifier<int>(0);

  ref.listen(authProvider, (_, __) => routerNotifier.value++);
  ref.listen(projectProvider, (_, __) => routerNotifier.value++);
  ref.listen(organizationProvider, (_, __) => routerNotifier.value++);

  return GoRouter(
    initialLocation: '/landing',
    observers: [Telling.instance.goRouterScreenTracker],
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final projectState = ref.read(projectProvider);
      final orgState = ref.read(organizationProvider);

      final isLoggedIn = authState.isAuthenticated;
      final hasSelectedProject = projectState.selectedProject != null;
      final hasOrganization = orgState.organization != null;
      final orgLoaded = orgState.isLoaded;
      final isOnLanding = state.matchedLocation == '/landing';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-otp';

      final isPublicRoute =
          state.matchedLocation == '/privacy' ||
          state.matchedLocation == '/docs';

      // Deep link routes should be allowed through (they handle auth internally)
      final isDeepLinkRoute =
          state.matchedLocation.startsWith('/log/') ||
          state.matchedLocation.startsWith('/digest');

      final isOnProjectsScreen = state.matchedLocation == '/projects';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      // Logged in but on landing page? Go to projects
      if (isLoggedIn && isOnLanding) return '/projects';

      // Not logged in and not on any auth/public screen? Go to landing
      // Allow deep link routes through - they handle auth internally
      if (!isLoggedIn &&
          !isAuthRoute &&
          !isPublicRoute &&
          !isOnLanding &&
          !isDeepLinkRoute) {
        return '/landing';
      }

      // Logged in but on auth screens? Go to projects
      if (isLoggedIn && isAuthRoute) return '/projects';

      // Logged in, no team yet (and we know it) → onboarding
      if (isLoggedIn && orgLoaded && !hasOrganization && !isOnOnboarding) {
        return '/onboarding';
      }

      // Logged in, has a team, but still on onboarding → projects
      if (isLoggedIn && hasOrganization && isOnOnboarding) {
        return '/projects';
      }

      // Logged in but no project selected and not on projects screen? Force project selection
      // Exception: deep link routes handle project selection internally
      if (isLoggedIn &&
          !hasSelectedProject &&
          !isOnProjectsScreen &&
          !isDeepLinkRoute &&
          !isOnOnboarding) {
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
      // Organization onboarding (create or join a team)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OrganizationOnboardingScreen(),
      ),
      // Projects Selection Screen (No Dashboard Layout)
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(path: '/docs', builder: (context, state) => const DocsScreen()),
      // Deep link handler for /log/:logId URLs (from emails, shared links)
      GoRoute(
        path: '/log/:logId',
        builder: (context, state) {
          final logId = state.pathParameters['logId']!;
          final projectId = state.uri.queryParameters['project'];
          return DeepLinkHandlerScreen(logId: logId, projectId: projectId);
        },
      ),
      // Deep link handler for /digest URLs (from digest emails)
      GoRoute(
        path: '/digest',
        builder: (context, state) {
          final projectId = state.uri.queryParameters['project'];
          final period = state.uri.queryParameters['period'];
          return AnalyticsDeepLinkScreen(projectId: projectId, period: period);
        },
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
          // GoRoute(
          //   path: '/funnel',
          //   name: 'funnel',
          //   pageBuilder: (context, state) =>
          //       NoTransitionPage(child: const FunnelScreen()),
          // ),
          GoRoute(
            path: '/funnelytics',
            name: 'funnelytics',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const NamedFunnelScreen()),
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
          GoRoute(
            path: '/projects/version-config',
            name: 'version_config',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const VersionConfigScreen()),
          ),
          GoRoute(
            path: '/projects/notifications',
            name: 'notification_settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const NotificationSettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
