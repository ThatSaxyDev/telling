import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize SDK
      await Telling.instance.init(
        'TEST_API_KEY',
        userId: 'demo_user_123',
        userName: 'Demo User',
      );

      Telling.instance.enableCrashReporting();

      runApp(const ProviderScope(child: MainApp()));
    },
    (error, stack) {
      print('Telling: CAUGHT ZONED ERROR: $error');
      Telling.instance.log(
        'Zoned Crash: $error',
        level: LogLevel.error,
        error: error,
        stackTrace: stack,
        type: LogType.error,
      );
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Telling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
