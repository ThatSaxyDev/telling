import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import './widgets/api_key_display.dart';
import './widgets/profile_section.dart';
import './widgets/password_reset_flow_widgets.dart';
import '../../core/providers/user_profile_provider.dart';
import './widgets/account_deletion_dialog.dart';
import '../../shared/widgets/military_loader.dart';
import '../../core/providers/logs_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 12.0 : 24.0;
    final sectionPadding = isMobile ? 16.0 : 24.0;
    final sectionSpacing = isMobile ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 12.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppColors.slate,
                size: isMobile ? 24 : 32,
              ),
              SizedBox(width: isMobile ? 8 : 16),
              GlitchText(
                text: 'SETTINGS',
                style: isMobile
                    ? AppTextStyles.titleSmall
                    : AppTextStyles.headlineSmall,
                glitchAmount: 2.0,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 32),

          // API Key Section
          MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: false,
            child: Container(
              padding: EdgeInsets.all(sectionPadding),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slate.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: AppColors.secondary,
                        size: isMobile ? 20 : 24,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Text(
                        'API KEY',
                        style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium).copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  const ApiKeyDisplay(),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Version Config Section
          MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/projects/version-config'),
                child: Container(
                  padding: EdgeInsets.all(sectionPadding),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.slate.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(26),
                          border: Border.all(
                            color: AppColors.secondary.withAlpha(77),
                          ),
                        ),
                        child: Icon(
                          Icons.system_update,
                          color: AppColors.secondary,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERSION_CONFIG',
                              style:
                                  (isMobile
                                          ? AppTextStyles.titleSmall
                                          : AppTextStyles.titleMedium)
                                      .copyWith(color: AppColors.secondary),
                            ),
                            SizedBox(height: isMobile ? 4 : 6),
                            Text(
                              'Configure force update settings for your app',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.slate,
                        size: isMobile ? 20 : 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Notification Settings Section
          MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/projects/notifications'),
                child: Container(
                  padding: EdgeInsets.all(sectionPadding),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.slate.withAlpha(77)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(26),
                          border: Border.all(
                            color: AppColors.secondary.withAlpha(77),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: AppColors.secondary,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTIFICATION_SETTINGS',
                              style:
                                  (isMobile
                                          ? AppTextStyles.titleSmall
                                          : AppTextStyles.titleMedium)
                                      .copyWith(color: AppColors.secondary),
                            ),
                            SizedBox(height: isMobile ? 4 : 6),
                            Text(
                              'Configure push and email notifications',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.slate,
                        size: isMobile ? 20 : 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Profile Section
          const ProfileSection(),
          SizedBox(height: sectionSpacing),

          // Account Section
          MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: false,
            child: Container(
              padding: EdgeInsets.all(sectionPadding),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slate.withAlpha(77)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: AppColors.secondary,
                        size: isMobile ? 20 : 24,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Text(
                        'ACCOUNT',
                        style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium).copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  // Buttons - stack vertically on mobile, row on desktop
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton(
                          text: 'RESET PASSWORD',
                          icon: Icons.lock_reset,
                          onPressed: () => _initiatePasswordReset(context, ref),
                          backgroundColor: AppColors.white.withAlpha(26),
                          borderColor: AppColors.white,
                          foregroundColor: AppColors.white,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'VIEW DOCS',
                          icon: Icons.description,
                          onPressed: () => context.push('/docs'),
                          backgroundColor: AppColors.white.withAlpha(26),
                          borderColor: AppColors.white,
                          foregroundColor: AppColors.white,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'LOGOUT',
                          icon: Icons.logout,
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            ref.read(projectProvider.notifier).reset();
                            context.go('/login');
                          },
                          backgroundColor: AppColors.error.withAlpha(26),
                          borderColor: AppColors.error,
                          foregroundColor: AppColors.error,
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.slate, height: 1),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: isMobile ? 20 : 24,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'DANGER ZONE',
                              style:
                                  (isMobile
                                          ? AppTextStyles.titleSmall
                                          : AppTextStyles.titleMedium)
                                      .copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'DELETE ACCOUNT',
                          icon: Icons.delete_forever,
                          onPressed: () => _handleDeleteAccount(context, ref),
                          backgroundColor: AppColors.error.withAlpha(26),
                          borderColor: AppColors.error,
                          foregroundColor: AppColors.error,
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppButton(
                          text: 'RESET PASSWORD',
                          icon: Icons.lock_reset,
                          onPressed: () => _initiatePasswordReset(context, ref),
                          backgroundColor: AppColors.white.withAlpha(26),
                          borderColor: AppColors.white,
                          foregroundColor: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'VIEW DOCS',
                          icon: Icons.description,
                          onPressed: () => context.push('/docs'),
                          backgroundColor: AppColors.white.withAlpha(26),
                          borderColor: AppColors.white,
                          foregroundColor: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'LOGOUT',
                          icon: Icons.logout,
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            ref.read(projectProvider.notifier).reset();
                            context.go('/login');
                          },
                          backgroundColor: AppColors.error.withAlpha(26),
                          borderColor: AppColors.error,
                          foregroundColor: AppColors.error,
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: AppColors.slate, height: 1),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: isMobile ? 20 : 24,
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              'DANGER ZONE',
                              style:
                                  (isMobile
                                          ? AppTextStyles.titleSmall
                                          : AppTextStyles.titleMedium)
                                      .copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'DELETE ACCOUNT',
                          icon: Icons.delete_forever,
                          onPressed: () => _handleDeleteAccount(context, ref),
                          backgroundColor: AppColors.error.withAlpha(26),
                          borderColor: AppColors.error,
                          foregroundColor: AppColors.error,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (kDebugMode) SizedBox(height: sectionSpacing),

          // Log Generator Section
          if (kDebugMode)
            MilitaryHoverContainer(
              baseColor: AppColors.surfaceDark,
              showGrid: false,
              child: Container(
                padding: EdgeInsets.all(sectionPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.slate.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          color: AppColors.secondary,
                          size: isMobile ? 20 : 24,
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Text(
                          'LOG GENERATOR',
                          style: (isMobile ? AppTextStyles.titleSmall : AppTextStyles.titleMedium).copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 16 : 24),

                    Text(
                      'GENERATE TEST SIGNALS',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.slate,
                        fontSize: isMobile ? 10 : 11,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: isMobile ? 8 : 16,
                      children: [
                        _buildLogButton(
                          label: isMobile ? 'DEBUG' : 'DEBUG LOG',
                          color: AppColors.slate,
                          icon: Icons.bug_report_outlined,
                          onPressed: () {
                            Telling.instance.log(
                              'Debug signal initiated',
                              level: LogLevel.debug,
                              type: LogType.general,
                            );
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'INFO' : 'INFO LOG',
                          color: AppColors.white,
                          icon: Icons.info_outline,
                          onPressed: () {
                            Telling.instance.log(
                              'System status nominal',
                              level: LogLevel.info,
                              type: LogType.general,
                            );
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'WARNING' : 'WARNING LOG',
                          color: Colors.orange,
                          icon: Icons.warning_amber,
                          onPressed: () {
                            Telling.instance.log(
                              'Resource usage high',
                              level: LogLevel.warning,
                              type: LogType.performance,
                              metadata: {'cpu_usage': '85%', 'memory': '1.2GB'},
                            );
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'ERROR' : 'ERROR LOG',
                          color: AppColors.error,
                          icon: Icons.error_outline,
                          onPressed: () {
                            try {
                              throw Exception('Connection refused by host');
                            } catch (e, stack) {
                              Telling.instance.log(
                                'Connection failed',
                                level: LogLevel.error,
                                type: LogType.general,
                                error: e,
                                stackTrace: stack,
                                metadata: {
                                  'message': 'Connection refused by host',
                                },
                              );
                            }
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'FATAL' : 'FATAL LOG',
                          color: Colors.red.shade900,
                          icon: Icons.dangerous,
                          onPressed: () {
                            Telling.instance.log(
                              'CRITICAL SYSTEM FAILURE',
                              level: LogLevel.fatal,
                              type: LogType.crash,
                              metadata: {'code': '0xDEADBEEF'},
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 20 : 32),
                    Text(
                      'EVENTS & CRASHES',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.slate,
                        fontSize: isMobile ? 10 : 11,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),

                    Wrap(
                      spacing: isMobile ? 8 : 16,
                      runSpacing: isMobile ? 8 : 16,
                      children: [
                        _buildLogButton(
                          label: isMobile ? 'EVENT' : 'TRACK EVENT',
                          color: Colors.blue,
                          icon: Icons.analytics_outlined,
                          onPressed: () {
                            Telling.instance.event(
                              'user_action_performed',
                              properties: {
                                'action': 'button_click',
                                'screen': 'settings',
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'NETWORK' : 'NETWORK LOG',
                          color: Colors.purple,
                          icon: Icons.wifi,
                          onPressed: () {
                            Telling.instance.log(
                              'API Request: GET /api/v1/users',
                              level: LogLevel.info,
                              type: LogType.analytics,
                              metadata: {
                                'status': 200,
                                'duration_ms': 145,
                                'bytes_received': 2048,
                              },
                            );
                          },
                        ),
                        _buildLogButton(
                          label: isMobile ? 'CRASH' : 'FORCE CRASH',
                          color: AppColors.error,
                          icon: Icons.flash_on,
                          onPressed: () {
                            throw StateError(
                              'Forced application crash for testing',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _initiatePasswordReset(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Get user email from profile provider
    final profileAsync = ref.read(userProfileProvider);

    final profile = profileAsync.when(
      data: (p) => p,
      loading: () => null,
      error: (_, __) => null,
    );

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load user profile',
            style: TextStyle(fontFamily: 'Urbanist'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Step 1: Email Confirmation
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EmailConfirmationDialog(
        email: profile.email,
        onOtpSent: (userId) {
          // Step 2: OTP Verification
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => OtpVerificationDialog(
              userId: userId,
              email: profile.email,
              onVerified: (resetToken) {
                // Step 3: New Password
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) =>
                      NewPasswordDialog(resetToken: resetToken),
                ).then((success) {
                  if (success == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'PASSWORD RESET SUCCESSFULLY',
                          style: TextStyle(fontFamily: 'Urbanist'),
                        ),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return AppButton(
      text: label,
      icon: icon,
      onPressed: onPressed,
      isOutlined: isOutlined,
      backgroundColor: isOutlined ? Colors.transparent : color.withAlpha(26),
      borderColor: color,
      foregroundColor: color,
    );
  }

  void _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AccountDeletionDialog(),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: MilitaryLoader(
          size: 60,
          color: AppColors.error,
          label: 'DELETING ACCOUNT...',
        ),
      ),
    );

    try {
      final success = await ref.read(authProvider.notifier).deleteAccount();

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (success) {
        // Clear all data
        ref.invalidate(userProfileProvider);
        ref.invalidate(logsProvider);
        ref.read(projectProvider.notifier).reset();

        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to delete account'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
