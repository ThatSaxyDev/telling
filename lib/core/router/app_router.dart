import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/overview/overview_screen.dart';
import '../../features/logs/logs_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/widgets/dashboard_layout.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return DashboardLayout(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const OverviewScreen()),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const LogsScreen()),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const AnalyticsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}

