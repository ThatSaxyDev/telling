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
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                        ),
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
                              title: 'EFFECTIVE_DATE',
                              content: 'December 7, ${DateTime.now().year}',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'OVERVIEW',
                              content: 'Telling is a real-time application monitoring and error tracking service consisting of:\n\n'
                                  '• **telling_logger SDK**: A Flutter package that developers integrate into their apps to collect and send logs.\n'
                                  '• **Telling Dashboard** (this web app): A command center for viewing and analyzing logs sent by the SDK.\n\n'
                                  'This Privacy Policy explains how we handle data across both components.',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'DASHBOARD_DATA_COLLECTION',
                              content: '''This dashboard web app collects:

• **Account Information**: Email address and name for authentication.

• **Project Configuration**: Project names and API keys you create.

The dashboard does NOT collect logs directly—it only displays logs that your apps send via the SDK.''',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'SDK_DATA_COLLECTION',
                              content: '''The telling_logger SDK (integrated into your Flutter apps) collects:

• **Log Data**: Application logs, error reports, crash data, and performance metrics that you explicitly log.

• **Device Information**: Platform, OS version, device model, and app version for debugging purposes.

• **Session Data**: Anonymous session identifiers to track app usage patterns.

• **User Properties**: Custom properties you explicitly set via setUserProperty().

The SDK only collects data when you call its logging methods—it does not collect anything automatically without your explicit code.''',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'HOW_WE_USE_YOUR_DATA',
                              content: '''We use collected data to:

• Display logs, errors, and analytics in your dashboard.
• Identify and help you debug application issues.
• Generate aggregated analytics and insights.

We do NOT sell your data to third parties.''',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'DATA_RETENTION',
                              content: 'Log data is retained for 90 days by default. Account information is retained until you request deletion.',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'DATA_SECURITY',
                              content: 'All data is transmitted over HTTPS with TLS encryption. GZIP compression is used to minimize data transfer. '
                                  'API keys are project-scoped and can be regenerated at any time.',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'YOUR_RIGHTS',
                              content: '''You have the right to:

• Access your data through the dashboard.
• Delete your account and associated data.
• Regenerate API keys to revoke SDK access.''',
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 32),

                            _buildSection(
                              title: 'CONTACT',
                              content: 'For privacy-related inquiries, contact us at: kiishidart@gmail.com',
                              isMobile: isMobile,
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

  Widget _buildSection({
    required String title,
    required String content,
    required bool isMobile,
  }) {
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
