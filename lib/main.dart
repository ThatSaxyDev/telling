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

      await Telling.instance.init(
        'rPoGEz5wqU18LnY3aDDVV9sJpMzpCRyb1siMQwQSJ7Y=',
        enableDebugLogs: false,
      );

      Telling.instance.enableCrashReporting();

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
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
