// Screenshot-only entrypoint. Production widgets, local sample data, no live APIs.
// Never imported by lib/main.dart. SDKs and notification services are not started.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:telling/core/models/auth_user.dart';
import 'package:telling/core/models/organization.dart';
import 'package:telling/core/models/project.dart';
import 'package:telling/core/models/analytics_models.dart';
import 'package:telling/core/models/log_model/log_model.dart';
import 'package:telling/core/providers/auth_provider.dart';
import 'package:telling/core/providers/project_provider.dart';
import 'package:telling/core/providers/organization_provider.dart';
import 'package:telling/core/providers/log_stats_provider.dart';
import 'package:telling/core/providers/activity_timeline_provider.dart';
import 'package:telling/core/providers/logs_provider.dart';
import 'package:telling/core/providers/analytics_provider.dart';
import 'package:telling/core/providers/project_config_provider.dart';
import 'package:telling/core/services/api_client.dart';
import 'package:telling/core/theme/app_theme.dart';
import 'package:telling/features/overview/overview_screen.dart';
import 'package:telling/features/analytics/analytics_screen.dart';
import 'package:telling/features/projects/version_config_screen.dart';
import 'package:telling/features/logs/widgets/log_details_dialog.dart';
import 'package:telling/features/logs/widgets/session_timeline_dialog.dart';
import 'package:telling/shared/widgets/dashboard_layout.dart';

const captureScreen =
    0; // 0 overview, 1 error, 2 session, 3 analytics, 4 versions
final now = DateTime.now();
final sampleProject = Project(
  id: 'demo',
  name: 'Demo App',
  apiKey: 'not-a-real-key',
  createdAt: now,
);
final sampleLogs = <LogModel>[
  for (var i = 0; i < 8; i++)
    LogModel.fromJson({
      'id': 'sample-${i + 1}',
      'message': [
        'Session started',
        'User identified',
        'User properties set',
        'home_viewed',
        'update_check_completed',
        'sync_request_finished',
        'profile_opened',
        'Session ended',
      ][i],
      'level': 'info',
      'type': 'analytics',
      'timestamp': now
          .subtract(Duration(seconds: 16 - i * 2))
          .toIso8601String(),
      'userId': 'sample-user',
      'userName': 'demo walker',
    }),
];
final sampleError = LogModel.fromJson({
  'id': '8552',
  'message': 'Bad state: Request took too long to respond. Try again.',
  'level': 'error',
  'type': 'general',
  'timestamp': now.toIso8601String(),
  'device': {
    'platform': Platform.isAndroid ? 'Android' : 'iOS',
    'deviceModel': Platform.isAndroid ? 'Pixel 9 Pro' : 'iPhone',
    'osVersion': Platform.isAndroid ? '15' : '26.0',
    'appVersion': '1.0.3',
  },
  'stackTrace':
      '#0      ApiClient.request (api_client.dart:113)\n#1      Future.timeout (dart:async:0)\n#2      ProjectRepository.refresh (project_repository.dart:40)\n#3      ProjectNotifier.refresh (project_notifier.dart:76)',
});

class CaptureAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    user: AuthUser(
      id: 'demo',
      email: 'demo@example.invalid',
      name: 'Demo developer',
    ),
    token: 'not-a-real-token',
  );
}

class CaptureProject extends ProjectNotifier {
  @override
  ProjectState build() =>
      ProjectState(projects: [sampleProject], selectedProject: sampleProject);
}

class CaptureOrg extends OrganizationNotifier {
  @override
  OrganizationState build() => OrganizationState(
    isLoaded: true,
    activeUnitId: 'demo',
    units: [
      Organization(
        id: 'demo',
        name: 'Demo Unit',
        slug: 'demo-unit',
        plan: 'free',
        role: 'owner',
      ),
    ],
  );
}

class CaptureStats extends LogStatsNotifier {
  @override
  Future<LogStats> build() async => const LogStats(
    totalLogs: 7876,
    errorCount: 80,
    warningCount: 38,
    eventCount: 7758,
    performanceCount: 0,
  );
  @override
  Future<void> refresh() async {}
}

class CaptureActivity extends ActivityTimelineNotifier {
  @override
  Future<List<LogModel>> build() async => [sampleError, ...sampleLogs.reversed];
  @override
  Future<void> refresh() async {}
}

class CaptureConfig extends ProjectConfigNotifier {
  @override
  ProjectConfigState build() => ProjectConfigState(
    config: {
      'min_ios_version': '1.0.3',
      'min_android_version': '1.0.3',
      'ios_store_url': 'https://apps.apple.com/',
      'android_store_url': 'https://play.google.com/',
      'force_update_message': 'Update to continue with the latest features.',
    },
  );
  @override
  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = state.copyWith(isLoading: false);
  }
}

class CaptureApi extends ApiClient {
  CaptureApi(super.ref);
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async =>
      http.Response(jsonEncode({}), 200);
  @override
  Future<http.Response> post(
    Uri url, {
    Object? body,
    Map<String, String>? headers,
  }) async => http.Response('{}', 405);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF050505),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CaptureScreen()),
    ],
  );
  runApp(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(CaptureAuth.new),
        projectProvider.overrideWith(CaptureProject.new),
        organizationProvider.overrideWith(CaptureOrg.new),
        logStatsProvider.overrideWith(CaptureStats.new),
        activityTimelineProvider.overrideWith(CaptureActivity.new),
        projectConfigProvider.overrideWith(CaptureConfig.new),
        apiClientProvider.overrideWith((ref) => CaptureApi(ref)),
        sessionLogsProvider.overrideWith((ref, id) async => sampleLogs),
        analyticsSummaryProvider.overrideWith(
          (ref) async => AnalyticsSummary(
            totalLogs: 1468,
            errorCount: 19,
            errorRate: 1.3,
            activeSessions: 25,
            activeUsers: 18,
            logsTrend: 18,
          ),
        ),
        lifecycleEventsProvider.overrideWith(
          (ref) async => LifecycleEvents(
            periodHours: 24,
            firstOpen: 7,
            appOpen: 108,
            appUpdate: 3,
          ),
        ),
        logsTimelineProvider.overrideWith(
          (ref) async => [
            for (var i = 0; i < 12; i++)
              LogTimelinePoint(
                timestamp: now.subtract(Duration(hours: 12 - i)),
                counts: {
                  'info': 40 + i * 4,
                  'warning': i % 3 + 1,
                  'error': i % 2 + 1,
                },
              ),
          ],
        ),
        logLevelsProvider.overrideWith(
          (ref) async => [
            LogLevelStat(level: 'info', count: 1411),
            LogLevelStat(level: 'warning', count: 38),
            LogLevelStat(level: 'error', count: 19),
          ],
        ),
        topErrorsProvider.overrideWith(
          (ref) async => [
            TopErrorItem(
              message: 'Request timed out',
              count: 12,
              lastSeen: now,
            ),
            TopErrorItem(
              message: 'Connection interrupted',
              count: 7,
              lastSeen: now,
            ),
          ],
        ),
        activeUsersProvider.overrideWith(
          (ref) async => [
            ActiveUserStat(
              userId: 'sample-user',
              userName: 'demo walker',
              logCount: 248,
              lastActive: now,
            ),
          ],
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    if (captureScreen == 1 || captureScreen == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog<void>(
          context: context,
          builder: (_) => captureScreen == 1
              ? LogDetailsDialog(log: sampleError)
              : const SessionTimelineDialog(
                  sessionId: 'sample-session',
                  userName: 'demo walker',
                  eventCount: 8,
                  duration: Duration(seconds: 16),
                ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => DashboardLayout(
    currentRoute: captureScreen == 3
        ? '/analytics'
        : captureScreen == 4
        ? '/settings'
        : '/',
    child: captureScreen == 3
        ? const AnalyticsScreen()
        : captureScreen == 4
        ? const VersionConfigScreen()
        : const OverviewScreen(),
  );
}
