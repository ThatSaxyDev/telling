import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telling/core/models/project.dart';
import 'package:telling/core/providers/project_config_provider.dart';
import 'package:telling/core/providers/project_provider.dart';
import 'package:telling/features/projects/version_config_screen.dart';

class SelectedProject extends ProjectNotifier {
  @override
  ProjectState build() => ProjectState(
    selectedProject: Project(
      id: 'project-a',
      name: 'Customer App',
      apiKey: 'key',
      createdAt: DateTime(2026),
    ),
  );
}

class Config extends ProjectConfigNotifier {
  Map<String, String> saved = {
    'min_ios_version': '1.0.4',
    'min_ios_build': '24',
    'min_android_build': '20',
  };
  int writes = 0;
  @override
  Future<void> loadConfig() async {
    state = ProjectConfigState(isLoading: true);
    state = ProjectConfigState(config: saved);
  }

  @override
  Future<bool> updateConfig(Map<String, String> newConfig) async {
    writes++;
    saved = Map.of(newConfig);
    state = ProjectConfigState(config: saved);
    return true;
  }
}

void main() {
  for (final width in [390.0, 1100.0]) {
    testWidgets(
      'project builds load, validate, save, cancel and clear at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final config = Config();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectProvider.overrideWith(SelectedProject.new),
              projectConfigProvider.overrideWith(() => config),
            ],
            child: const MaterialApp(home: VersionConfigScreen()),
          ),
        );
        await tester.pumpAndSettle();
        final ios = find.widgetWithText(TextFormField, 'MIN_IOS_BUILD');
        final android = find.widgetWithText(TextFormField, 'MIN_ANDROID_BUILD');
        expect(tester.widget<TextFormField>(ios).controller!.text, '24');
        expect(tester.widget<TextFormField>(ios).enabled, false);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('EDIT'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(ios);
        await tester.enterText(ios, '-1');
        final save = find.text('SAVE_CONFIGURATION');
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(config.writes, 0);
        expect(
          find.text('Enter a positive whole number, or leave blank'),
          findsOneWidget,
        );
        await tester.ensureVisible(ios);
        await tester.enterText(ios, '25');
        await tester.ensureVisible(android);
        await tester.enterText(android, '21');
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(config.saved['min_ios_build'], '25');
        expect(config.saved['min_android_build'], '21');
        expect(config.writes, 1);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('EDIT'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(ios);
        await tester.enterText(ios, '99');
        await tester.ensureVisible(android);
        await tester.enterText(android, '99');
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextFormField>(ios).controller!.text, '25');
        expect(tester.widget<TextFormField>(android).controller!.text, '21');
        await tester.tap(find.text('EDIT'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(ios);
        await tester.enterText(ios, '');
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(config.saved['min_ios_build'], '');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
