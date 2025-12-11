import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';

/// Full-screen blocking UI shown when app update is required
/// Styled to match the app's military aesthetic
class ForceUpdateScreen extends StatelessWidget {
  final String message;
  final String storeUrl;

  const ForceUpdateScreen({
    super.key,
    required this.message,
    required this.storeUrl,
  });

  Future<void> _openStore() async {
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.backgroundDark,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            // Animated grid background
            const Positioned.fill(
              child: GridBackground(
                color: Color(0xFF1A1A1A),
                spacing: 40,
                strokeWidth: 0.5,
              ),
            ),
            // Scanline effect
            const Positioned.fill(
              child: Scanline(
                color: Color(0x0AFFFFFF),
                duration: Duration(seconds: 6),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with corner brackets
                      CornerBrackets(
                        color: AppColors.white,
                        length: 16,
                        thickness: 1.5,
                        offset: 0,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            border: Border.all(
                              color: AppColors.slate,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.system_update_outlined,
                            size: 52,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Title with glitch effect
                      const GlitchText(
                        text: 'UPDATE REQUIRED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 3,
                        ),
                        glitchAmount: 4.0,
                      ),
                      const SizedBox(height: 48),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.error, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'VERSION OUTDATED',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Message
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          border: Border.all(color: AppColors.slate, width: 1),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 16,
                            color: AppColors.white,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 56),
                      // Update Button with military style
                      SizedBox(
                        width: double.infinity,
                        child: CornerBrackets(
                          color: AppColors.white,
                          length: 12,
                          thickness: 1.5,
                          offset: 0,
                          child: ElevatedButton(
                            onPressed: storeUrl.isNotEmpty ? _openStore : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.tertiary,
                              disabledForegroundColor: AppColors.slate,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.download, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'UPDATE NOW',
                                  style: TextStyle(
                                    fontFamily: 'Syne',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: storeUrl.isNotEmpty
                                        ? AppColors.primary
                                        : AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Footer text
                      Text(
                        storeUrl.isEmpty
                            ? 'Update not available for your platform'
                            : 'Redirects to app store',
                        style:  TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 13,
                          color: AppColors.slate.withAlpha(170),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
