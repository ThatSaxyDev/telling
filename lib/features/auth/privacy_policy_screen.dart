import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: GridBackground(
              color: Color(0xFF1A1A1A),
              spacing: 40,
              strokeWidth: 0.5,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withAlpha(230),
                    border: Border(
                      bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.white),
                        onPressed: () => context.go('/'),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'PRIVACY_POLICY',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 20 : 40),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection(
                              'EFFECTIVE_DATE',
                              'December 7, ${DateTime.now().year}',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'OVERVIEW',
                              'Telling is a real-time application monitoring and error tracking service consisting of:\n\n'
                              '• **telling_logger SDK**: A Flutter package that developers integrate into their apps to collect and send logs.\n'
                              '• **Telling Dashboard** (this web app): A command center for viewing and analyzing logs sent by the SDK.\n\n'
                              'This Privacy Policy explains how we handle data across both components.',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'DASHBOARD_DATA_COLLECTION',
                              '''This dashboard web app collects:

• **Account Information**: Email address and name for authentication.

• **Project Configuration**: Project names and API keys you create.

The dashboard does NOT collect logs directly—it only displays logs that your apps send via the SDK.''',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'SDK_DATA_COLLECTION',
                              '''The telling_logger SDK (integrated into your Flutter apps) collects:

• **Log Data**: Application logs, error reports, crash data, and performance metrics that you explicitly log.

• **Device Information**: Platform, OS version, device model, and app version for debugging purposes.

• **Session Data**: Anonymous session identifiers to track app usage patterns.

• **User Properties**: Custom properties you explicitly set via setUserProperty().

The SDK only collects data when you call its logging methods—it does not collect anything automatically without your explicit code.''',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'HOW_WE_USE_YOUR_DATA',
                              '''We use collected data to:

• Display logs, errors, and analytics in your dashboard.
• Identify and help you debug application issues.
• Generate aggregated analytics and insights.

We do NOT sell your data to third parties.''',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'DATA_RETENTION',
                              'Log data is retained for 90 days by default. Account information is retained until you request deletion.',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'DATA_SECURITY',
                              'All data is transmitted over HTTPS with TLS encryption. GZIP compression is used to minimize data transfer. '
                              'API keys are project-scoped and can be regenerated at any time.',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'YOUR_RIGHTS',
                              '''You have the right to:

• Access your data through the dashboard.
• Delete your account and associated data.
• Regenerate API keys to revoke SDK access.''',
                              isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              'CONTACT',
                              'For privacy-related inquiries, contact us at: privacy@telling.dev',
                              isMobile,
                            ),
                            const SizedBox(height: 48),

                            // Footer
                            Center(
                              child: Text(
                                '© ${DateTime.now().year} Telling. All rights reserved.',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  color: AppColors.slate,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.white.withAlpha(77)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.white,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content,
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.slate,
            fontSize: isMobile ? 14 : 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}
