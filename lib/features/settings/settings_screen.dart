import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/app_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.slate, size: 32),
              const SizedBox(width: 16),
              GlitchText(
                text: 'SETTINGS',
                style: isMobile
                    ? AppTextStyles.titleMedium
                    : AppTextStyles.headlineSmall,
                glitchAmount: 2.0,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Log Generator Section
          MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            showGrid: false,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slate.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Text(
                        'LOG GENERATOR',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'GENERATE TEST SIGNALS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildLogButton(
                        label: 'DEBUG LOG',
                        color: AppColors.slate,
                        icon: Icons.bug_report_outlined,
                        onPressed: () {
                          Telling.instance.log(
                            'Debug signal initiated',
                            level: LogLevel.debug,
                            type: LogType.event, // Event type for app events
                          );
                        },
                      ),
                      _buildLogButton(
                        label: 'INFO LOG',
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
                        label: 'WARNING LOG',
                        color: Colors.orange,
                        icon: Icons.warning_amber,
                        onPressed: () {
                          Telling.instance.log(
                            'Resource usage high',
                            level: LogLevel.warning,
                            type: LogType
                                .performance, // Performance type for resource warnings
                            metadata: {'cpu_usage': '85%', 'memory': '1.2GB'},
                          );
                        },
                      ),
                      _buildLogButton(
                        label: 'ERROR LOG',
                        color: AppColors.error,
                        icon: Icons.error_outline,
                        onPressed: () {
                          try {
                            throw Exception('Connection refused by host');
                          } catch (e, stack) {
                            Telling.instance.log(
                              'Connection failed',
                              level: LogLevel.error,
                              type: LogType
                                  .exception, // Exception type for caught errors
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
                        label: 'FATAL LOG',
                        color: Colors.red.shade900,
                        icon: Icons.dangerous,
                        onPressed: () {
                          Telling.instance.log(
                            'CRITICAL SYSTEM FAILURE',
                            level: LogLevel.fatal,
                            type: LogType.crash, // Crash type for fatal errors
                            metadata: {'code': '0xDEADBEEF'},
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'EVENTS & CRASHES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildLogButton(
                        label: 'TRACK EVENT',
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
                        label: 'NETWORK LOG',
                        color: Colors.purple,
                        icon: Icons.wifi,
                        onPressed: () {
                          Telling.instance.log(
                            'API Request: GET /api/v1/users',
                            level: LogLevel.info,
                            type: LogType.network,
                            metadata: {
                              'status': 200,
                              'duration_ms': 145,
                              'bytes_received': 2048,
                            },
                          );
                        },
                      ),
                      _buildLogButton(
                        label: 'FORCE CRASH',
                        color: AppColors.error,
                        icon: Icons.flash_on,
                        // isOutlined: true,
                        onPressed: () {
                          // This will be caught by the global error handler if enabled
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
      backgroundColor: isOutlined ? Colors.transparent : color.withOpacity(0.1),
      borderColor: color,
      foregroundColor: color,
    );
  }
}
