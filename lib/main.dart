import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'core/services/version_check_service.dart';
import 'features/force_update/force_update_screen.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
