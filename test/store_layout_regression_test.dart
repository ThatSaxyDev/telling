import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/theme/app_theme.dart';
import 'package:telling/core/providers/log_stats_provider.dart';
import 'package:telling/core/providers/activity_timeline_provider.dart';
import 'package:telling/features/overview/overview_screen.dart';
import 'package:telling/shared/widgets/bottom_nav.dart';
import '../tool/store_artboard_capture.dart' show CaptureStats, CaptureActivity;

void main() {
  setUpAll(() async {
    final urbanist = FontLoader('Urbanist')
      ..addFont(rootBundle.load('assets/fonts/urbanist/Urbanist-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/urbanist/Urbanist-Bold.ttf'));
    final syne = FontLoader('Syne')
      ..addFont(rootBundle.load('assets/fonts/syne/Syne-Regular.ttf'));
    await Future.wait([urbanist.load(), syne.load()]);
  });
  for (final size in [const Size(1032, 1376), const Size(1376, 1032)]) {
    testWidgets('populated overview and navigation fit tablet $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logStatsProvider.overrideWith(CaptureStats.new),
            activityTimelineProvider.overrideWith(CaptureActivity.new),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: OverviewScreen(),
              bottomNavigationBar: BottomNav(currentRoute: '/'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.takeException(),
        isNull,
        reason: 'No card or navigation clipping in either tablet orientation',
      );
      expect(find.text('7,876'), findsOneWidget);
      expect(find.text('TOTAL LOGS'), findsOneWidget);
      expect(find.text('ANALYTICS'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
