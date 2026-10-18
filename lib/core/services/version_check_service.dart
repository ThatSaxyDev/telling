import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Result of version check
class VersionCheckResult {
  final bool requiresUpdate;
  final String? storeUrl;
  final String? message;

  VersionCheckResult({
    required this.requiresUpdate,
    this.storeUrl,
    this.message,
  });
}

/// Service for checking if app update is required
class VersionCheckService {
  static const String _baseUrl = 'https://telling-api.kiishi.space/api/v1';

  /// Check if the app requires an update
  /// Returns VersionCheckResult with requiresUpdate = true if update needed
  /// Fail-open: returns requiresUpdate = false on any error
  static Future<VersionCheckResult> check() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Determine platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Call version check endpoint
      final uri = Uri.parse('$_baseUrl/app/version-check').replace(
        queryParameters: {
          'platform': platform,
          'version': currentVersion,
          if (packageInfo.buildNumber.isNotEmpty)
            'build': packageInfo.buildNumber,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VersionCheckResult(
          requiresUpdate: data['requiresUpdate'] as bool? ?? false,
          storeUrl: data['storeUrl'] as String?,
          message: data['message'] as String?,
        );
      }

      // Non-200 response, fail-open
      return VersionCheckResult(requiresUpdate: false);
    } catch (e) {
      // Any error (network, timeout, parsing), fail-open
      return VersionCheckResult(requiresUpdate: false);
    }
  }
}
