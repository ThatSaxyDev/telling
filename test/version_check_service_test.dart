import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:telling/core/services/version_check_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Telling',
      packageName: 'telling',
      version: '1.0.4',
      buildNumber: '23',
      buildSignature: '',
    ),
  );
  test(
    'Telling sends its build and returns build-triggered update to the existing UI',
    () async {
      final result = await http.runWithClient(
        () => VersionCheckService.check(),
        () => MockClient((request) async {
          expect(request.url.path, '/api/v1/app/version-check');
          expect(request.url.queryParameters['version'], '1.0.4');
          expect(request.url.queryParameters['build'], '23');
          return http.Response(
            jsonEncode({
              'requiresUpdate': true,
              'minVersion': '1.0.4',
              'minBuild': 24,
              'target': '1.0.4+24',
              'storeUrl': 'https://example.com/update',
              'message': 'New build required',
            }),
            200,
          );
        }),
      );
      expect(result.requiresUpdate, true);
      expect(result.message, 'New build required');
      expect(result.storeUrl, 'https://example.com/update');
    },
  );
  test(
    'legacy responses and failures preserve existing fail-open behavior',
    () async {
      for (final response in [
        http.Response('{"requiresUpdate":false}', 200),
        http.Response('offline', 503),
        http.Response('invalid json', 200),
      ]) {
        expect(
          (await http.runWithClient(
            () => VersionCheckService.check(),
            () => MockClient((_) async => response),
          )).requiresUpdate,
          false,
        );
      }
      expect(
        (await http.runWithClient(
          () => VersionCheckService.check(),
          () => MockClient((_) async => throw http.ClientException('offline')),
        )).requiresUpdate,
        false,
      );
    },
  );
}
