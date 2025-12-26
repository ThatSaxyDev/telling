import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/notification_settings.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _osPermissionGranted = true;
  String? _lastProjectId;

  @override
  void initState() {
    super.initState();
    _checkOsPermission();
  }

  Future<void> _checkOsPermission() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final permission = OneSignal.Notifications.permission;
      if (mounted) {
        setState(() => _osPermissionGranted = permission);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final projectId = projectState.selectedProject?.id;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final sectionPadding = isMobile ? 16.0 : 24.0;

    // Fetch settings when project changes
    if (projectId != null && projectId != _lastProjectId) {
      _lastProjectId = projectId;
      Future.microtask(() {
        ref.read(notificationSettingsProvider.notifier).fetchSettings(projectId);
      });
    }

    if (projectId == null) {
      return const Center(child: Text('No project selected'));
    }

    final settingsState = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              color: Color(0xFF1A1A1A),
              spacing: 40,
              strokeWidth: 0.5,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.notifications,
                        color: AppColors.secondary,
                        size: isMobile ? 24 : 32,
                      ),
                      const SizedBox(width: 12),
                      GlitchText(
                        text: 'NOTIFICATIONS',
                        style: isMobile
                            ? AppTextStyles.titleSmall
                            : AppTextStyles.headlineSmall,
                        glitchAmount: 2.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // OS Permission Banner
                  if (!_osPermissionGranted)
                    _buildPermissionBanner(sectionPadding, isMobile),

                  if (!_osPermissionGranted) const SizedBox(height: 16),

                  // Loading state - only on initial fetch
                  if (settingsState.isLoading && settingsState.settings == null)
                    const Center(
                      child: MilitaryLoader(size: 40, label: 'LOADING...'),
                    ),

                  // Error state
                  if (settingsState.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        settingsState.error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),

                  // Settings
                  if (settingsState.settings != null) ...[
                    // Push Notifications Section (mobile only)
                    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) ...[
                      _buildSection(
                        title: 'PUSH_NOTIFICATIONS',
                        icon: Icons.phone_android,
                        sectionPadding: sectionPadding,
                        isMobile: isMobile,
                        children: [
                          _buildToggle(
                            label: 'ENABLED',
                            subtitle: 'Receive push notifications on this device',
                            value: settingsState.settings!.pushEnabled,
                            onChanged: (v) => _updateSetting(
                              projectId,
                              (s) => s.copyWith(pushEnabled: v),
                            ),
                            isMobile: isMobile,
                          ),
                          if (settingsState.settings!.pushEnabled) ...[
                            const Divider(color: AppColors.slate, height: 32),
                            _buildDropdown(
                              label: 'MIN_SEVERITY',
                              subtitle: 'Only notify for this level or higher',
                              value: settingsState.settings!.pushMinSeverity,
                              items: const [
                                DropdownMenuItem(
                                  value: 'warning',
                                  child: Text('Warning'),
                                ),
                                DropdownMenuItem(
                                  value: 'error',
                                  child: Text('Error'),
                                ),
                                DropdownMenuItem(
                                  value: 'fatal',
                                  child: Text('Fatal'),
                                ),
                              ],
                              onChanged: (v) => _updateSetting(
                                projectId,
                                (s) => s.copyWith(pushMinSeverity: v),
                              ),
                              isMobile: isMobile,
                            ),
                            const Divider(color: AppColors.slate, height: 32),
                            _buildDropdown(
                              label: 'DIGEST_FREQUENCY',
                              subtitle: 'How often to receive digest summaries',
                              value: settingsState.settings!.pushDigestFrequency,
                              items: const [
                                DropdownMenuItem(
                                  value: 'daily',
                                  child: Text('Daily'),
                                ),
                                DropdownMenuItem(
                                  value: 'weekly',
                                  child: Text('Weekly'),
                                ),
                                DropdownMenuItem(
                                  value: 'both',
                                  child: Text('Daily & Weekly'),
                                ),
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text('None'),
                                ),
                              ],
                              onChanged: (v) => _updateSetting(
                                projectId,
                                (s) => s.copyWith(pushDigestFrequency: v),
                              ),
                              isMobile: isMobile,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Notifications Section
                    _buildSection(
                      title: 'EMAIL_NOTIFICATIONS',
                      icon: Icons.email,
                      sectionPadding: sectionPadding,
                      isMobile: isMobile,
                      children: [
                        _buildToggle(
                          label: 'ENABLED',
                          subtitle: 'Receive email notifications',
                          value: settingsState.settings!.emailEnabled,
                          onChanged: (v) => _updateSetting(
                            projectId,
                            (s) => s.copyWith(emailEnabled: v),
                          ),
                          isMobile: isMobile,
                        ),
                        if (settingsState.settings!.emailEnabled) ...[
                          const Divider(color: AppColors.slate, height: 32),
                          _buildToggle(
                            label: 'INSTANT_ALERTS',
                            subtitle: 'Get email immediately on errors',
                            value: settingsState.settings!.emailInstantAlerts,
                            onChanged: (v) => _updateSetting(
                              projectId,
                              (s) => s.copyWith(emailInstantAlerts: v),
                            ),
                            isMobile: isMobile,
                          ),
                          const Divider(color: AppColors.slate, height: 32),
                          _buildDropdown(
                            label: 'DIGEST_FREQUENCY',
                            subtitle: 'How often to receive summary emails',
                            value: settingsState.settings!.emailDigestFrequency,
                            items: const [
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text('Daily'),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text('Weekly'),
                              ),
                              DropdownMenuItem(
                                value: 'both',
                                child: Text('Daily & Weekly'),
                              ),
                              DropdownMenuItem(
                                value: 'none',
                                child: Text('None'),
                              ),
                            ],
                            onChanged: (v) => _updateSetting(
                              projectId,
                              (s) => s.copyWith(emailDigestFrequency: v),
                            ),
                            isMobile: isMobile,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(double padding, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTIFICATIONS_DISABLED',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable notifications in device settings',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              // Open app notification settings on iOS
              if (Platform.isIOS) {
                await launchUrl(Uri.parse('app-settings:'));
              }
            },
            child: Text(
              'OPEN',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required double sectionPadding,
    required bool isMobile,
    required List<Widget> children,
  }) {
    return MilitaryHoverContainer(
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
                  icon,
                  color: AppColors.secondary,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Text(
                  title,
                  style:
                      (isMobile
                              ? AppTextStyles.titleSmall
                              : AppTextStyles.titleMedium)
                          .copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.slate,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.secondary,
          activeTrackColor: AppColors.secondary.withAlpha(77),
          inactiveThumbColor: AppColors.slate,
          inactiveTrackColor: AppColors.slate.withAlpha(77),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.slate,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(77),
            border: Border.all(color: AppColors.slate.withAlpha(77)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.surfaceDark,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.slate),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateSetting(
    String projectId,
    NotificationSettings Function(NotificationSettings) updater,
  ) async {
    await ref.read(notificationSettingsProvider.notifier).updateField(updater);
  }
}
