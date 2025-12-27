import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'core/services/version_check_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/providers/auth_provider.dart';
import 'features/force_update/force_update_screen.dart';
import 'features/deep_link/deep_link_handler_screen.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Use path-based URLs for web (removes # from URLs)
      // Required for deep links like /log/:id and /digest to work
      if (kIsWeb) {
        usePathUrlStrategy();
      }

      if (Responsive.isNativeMobile) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF0D0D0D),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );
      }

      await Telling.instance.init(
        'JKkqECvjKQCstnhjkmsvp0BWqJyBlEHzYdBOetN13z0=',
        enableDebugLogs: false,
      );

      Telling.instance.enableCrashReporting();

      // Check for force update (only on native mobile)
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        final versionCheck = await VersionCheckService.check();
        if (versionCheck.requiresUpdate) {
          runApp(
            ForceUpdateScreen(
              message: versionCheck.message ?? 'Please update to continue.',
              storeUrl: versionCheck.storeUrl ?? '',
            ),
          );
          return;
        }

        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

        OneSignal.initialize('aa70cb56-bec5-4bbc-a480-fd8985a035ed');
        // Use this method to prompt for push notifications.
        // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
        OneSignal.Notifications.requestPermission(false);

        // Handle notification clicks for deep linking
        OneSignal.Notifications.addClickListener((event) {
          final data = event.notification.additionalData;
          if (data != null) {
            // Store for later handling
            _pendingDeepLinkData = Map<String, dynamic>.from(data);

            // If app is already running, trigger processing via callback
            if (_onNotificationClick != null) {
              _onNotificationClick!(Map<String, dynamic>.from(data));
            }
          }
        });
      }

      runApp(const ProviderScope(child: MainApp()));
    },
    (error, stack) {
      Telling.instance.log(
        'Zoned Crash: $error',
        level: LogLevel.fatal,
        error: error,
        stackTrace: stack,
        type: LogType.crash,
      );
    },
  );
}

// Global storage for deep link data before app is ready
Map<String, dynamic>? _pendingDeepLinkData;

// Callback for when app is already running
void Function(Map<String, dynamic>)? _onNotificationClick;

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();

    // Set up callback for notification clicks while app is running
    _onNotificationClick = (data) {
      ref.read(deepLinkProvider.notifier).storePendingDeepLink(data);

      // Process after a short delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ref.read(deepLinkProvider.notifier).processPendingDeepLink(context);
        }
      });
    };

    // Check for pending deep link from cold start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingDeepLink();
    });
  }

  @override
  void dispose() {
    _onNotificationClick = null;
    super.dispose();
  }

  void _processPendingDeepLink() {
    if (_pendingDeepLinkData != null) {
      // Store in provider
      ref
          .read(deepLinkProvider.notifier)
          .storePendingDeepLink(_pendingDeepLinkData!);
      _pendingDeepLinkData = null;

      // Delay to ensure router is ready, then process
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ref.read(deepLinkProvider.notifier).processPendingDeepLink(context);
        }
      });
    }
  }

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    final wasNotAuthenticated = previous == null || !previous.isAuthenticated;
    final isNowAuthenticated = next.isAuthenticated;

    if (wasNotAuthenticated && isNowAuthenticated) {
      // User just logged in, try processing any pending deep links
      final deepLinkState = ref.read(deepLinkProvider);
      if (deepLinkState.pendingData != null && !deepLinkState.isProcessed) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(deepLinkProvider.notifier).processPendingDeepLink(context);
          }
        });
      }

      // Also check for pending URL deep links (from /log/:logId route)
      if (PendingUrlDeepLink.data != null) {
        final urlData = PendingUrlDeepLink.data!;
        PendingUrlDeepLink.clear();
        ref.read(deepLinkProvider.notifier).storePendingDeepLink(urlData);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            ref.read(deepLinkProvider.notifier).processPendingDeepLink(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to re-process pending deep links after login
    // Note: ref.listen must be called in build(), not initState()
    ref.listen<AuthState>(authProvider, _handleAuthStateChange);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Telling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,

      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          // More granular breakpoints for better mobile support
          const Breakpoint(start: 0, end: 320, name: 'MOBILE_SMALL'),
          const Breakpoint(start: 321, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 600, name: 'MOBILE_LARGE'),
          const Breakpoint(start: 601, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1024, name: DESKTOP),
          const Breakpoint(start: 1025, end: 1440, name: 'DESKTOP_LARGE'),
          const Breakpoint(start: 1441, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}

