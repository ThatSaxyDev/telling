import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/log_model/log_model.dart';
import '../../core/models/log_level/log_level.dart';
import '../../core/providers/logs_provider.dart';
import '../../core/providers/filtered_logs_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/error_formatter.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';

import 'widgets/log_filter_bar.dart';



class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  Color _getLevelColor(LogLevel level) {
    return level.when(
      trace: () => AppColors.slate.withAlpha(179),
      debug: () => AppColors.slate,
      info: () => AppColors.white,
      warning: () => Colors.orange,
      error: () => AppColors.error,
      fatal: () => Colors.red.shade900,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isSessionGrouped = ref.watch(isSessionGroupedProvider);
    final logsAsync = ref.watch(filteredLogsProvider);
    // final sessionsAsync = ref.watch(sessionsProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.list_alt,
                      color: AppColors.slate,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: GlitchText(
                        text: 'LOGS EXPLORER',
                        style: isMobile
                            ? AppTextStyles.titleMedium
                            : AppTextStyles.headlineSmall,
                        glitchAmount: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  // Group by Session Toggle
                  // InkWell(
                  //   onTap: () =>
                  //       ref.read(isSessionGroupedProvider.notifier).toggle(),
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 12,
                  //       vertical: 8,
                  //     ),
                  //     decoration: BoxDecoration(
                  //       color: isSessionGrouped
                  //           ? AppColors.primary.withAlpha(51)
                  //           : Colors.transparent,
                  //       border: Border.all(
                  //         color: isSessionGrouped
                  //             ? AppColors.primary
                  //             : AppColors.slate.withAlpha(77),
                  //       ),
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         Icon(
                  //           isSessionGrouped
                  //               ? Icons.view_agenda
                  //               : Icons.view_headline,
                  //           size: 16,
                  //           color: isSessionGrouped
                  //               ? AppColors.primary
                  //               : AppColors.slate,
                  //         ),
                  //         if (!isMobile) ...[
                  //           const SizedBox(width: 8),
                  //           Text(
                  //             'GROUP BY SESSION',
                  //             style: TextStyle(
                  //               color: isSessionGrouped
                  //                   ? AppColors.primary
                  //                   : AppColors.slate,
                  //               fontWeight: FontWeight.bold,
                  //               fontSize: 12,
                  //             ),
                  //           ),
                  //         ],
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: isMobile ? '' : 'REFRESH',
                    icon: Icons.refresh,
                    isOutlined: true,
                    onPressed: () {
                      ref.invalidate(logsProvider);
                      if (isSessionGrouped) ref.invalidate(sessionsProvider);
                    },
                    width: isMobile ? 48 : null,
                    height: isMobile ? 48 : null,
                    padding: isMobile ? EdgeInsets.zero : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Bar (only show if not grouped, or adapt it)
        if (!isSessionGrouped) LogFilterBar(),

        // Content
        Expanded(
          child:
              // isSessionGrouped
              //     ? _buildSessionsList(sessionsAsync)
              //     :
              _buildLogsList(logsAsync, ref),
        ),
      ],
    );
  }

  // Widget _buildSessionsList(
  //   AsyncValue<List<Map<String, dynamic>>> sessionsAsync,
  // ) {
  //   return sessionsAsync.when(
  //     loading: () =>
  //         const Center(child: MilitaryLoader(label: 'LOADING SESSIONS...')),
  //     error: (error, stack) => Center(
  //       child: Text(
  //         'Error: $error',
  //         style: const TextStyle(color: AppColors.error),
  //       ),
  //     ),
  //     data: (sessions) {
  //       if (sessions.isEmpty) {
  //         return const Center(
  //           child: Text(
  //             'NO SESSIONS FOUND',
  //             style: TextStyle(color: AppColors.slate),
  //           ),
  //         );
  //       }
  //       return ListView.separated(
  //         padding: const EdgeInsets.all(24),
  //         itemCount: sessions.length,
  //         separatorBuilder: (context, index) => const SizedBox(height: 12),
  //         itemBuilder: (context, index) {
  //           final session = sessions[index];
  //           final duration = Duration(seconds: session['durationSeconds']);
  //           return MilitaryHoverContainer(
  //             onTap: () {
  //               showDialog(
  //                 context: context,
  //                 builder: (context) => SessionTimelineDialog(
  //                   sessionId: session['sessionId'],
  //                   userName: session['userName'],
  //                   eventCount: session['eventCount'],
  //                   duration: duration,
  //                 ),
  //               );
  //             },
  //             child: Container(
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: AppColors.surfaceDark,
  //                 border: Border(
  //                   left: BorderSide(color: AppColors.secondary, width: 4),
  //                 ),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         'SESSION ID: ${session['sessionId']}',
  //                         style: const TextStyle(
  //                           fontFamily: 'Urbanist',
  //                           fontWeight: FontWeight.bold,
  //                           color: AppColors.white,
  //                         ),
  //                       ),
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 8,
  //                           vertical: 4,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: AppColors.secondary.withAlpha(26),
  //                           borderRadius: BorderRadius.circular(4),
  //                         ),
  //                         child: Text(
  //                           '${duration.inMinutes}m ${duration.inSeconds % 60}s',
  //                           style: const TextStyle(
  //                             color: AppColors.secondary,
  //                             fontWeight: FontWeight.bold,
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Row(
  //                     children: [
  //                       const Icon(
  //                         Icons.person,
  //                         size: 14,
  //                         color: AppColors.slate,
  //                       ),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         session['userName'] ?? 'Unknown User',
  //                         style: const TextStyle(
  //                           color: AppColors.slate,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                       const SizedBox(width: 16),
  //                       const Icon(
  //                         Icons.list,
  //                         size: 14,
  //                         color: AppColors.slate,
  //                       ),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         '${session['eventCount']} EVENTS',
  //                         style: const TextStyle(
  //                           color: AppColors.slate,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildLogsList(AsyncValue<List<LogModel>> logsAsync, WidgetRef ref) {
    return logsAsync.when(
      loading: () =>
          const Center(child: MilitaryLoader(label: 'SCANNING LOGS...')),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'ERROR LOADING LOGS',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              ErrorFormatter.format(error),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (logs) => logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.signal_wifi_off,
                    size: 48,
                    color: AppColors.slate,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO SIGNALS DETECTED',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildLogItem(context, logs[index]),
                  ),
                ),
                _buildPaginationControls(ref),
              ],
            ),
    );
  }

  Widget _buildPaginationControls(WidgetRef ref) {
    final notifier = ref.read(logsProvider.notifier);
    final page = notifier.page;
    final hasMore = notifier.hasMore;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withAlpha(26), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          AppButton(
            text: 'PREVIOUS',
            onPressed: page > 1 ? () => notifier.previousPage() : null,
            backgroundColor: page > 1 ? AppColors.white : AppColors.darkSlate,
            foregroundColor: page > 1 ? AppColors.primary : AppColors.slate,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),

          const SizedBox(width: 16),

          // Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white.withAlpha(51)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PAGE $page',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Next Button
          AppButton(
            text: 'NEXT',
            onPressed: hasMore ? () => notifier.nextPage() : null,
            backgroundColor: hasMore ? AppColors.white : AppColors.darkSlate,
            foregroundColor: hasMore ? AppColors.primary : AppColors.slate,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogModel log) {
    final color = _getLevelColor(log.level);

    return MilitaryHoverContainer(
      onTap: () => _showLogDetails(context, log),
      baseColor: AppColors.tertiary,
      hoverColor: AppColors.white,
      showGrid: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 40, color: color),
            const SizedBox(width: 16),

            CornerBrackets(
              length: 6,
              thickness: 1,
              color: AppColors.slate,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  log.icon,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message.toUpperCase(),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                      if (log.device != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '//',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${log.device!.platform} :: ${log.device!.deviceModel}'
                              .toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: AppColors.slate),
              tooltip: 'COPY MESSAGE',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: log.message));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'MESSAGE COPIED TO CLIPBOARD',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    backgroundColor: AppColors.darkSlate,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(BuildContext context, LogModel log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 800),
          child: MilitaryHoverContainer(
            baseColor: AppColors.surfaceDark,
            hoverColor: AppColors.white,
            showGrid: true,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                color: AppColors.backgroundDark.withAlpha(242),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlitchText(
                          text: 'LOG DETAILS // ID: ${log.id}',
                          style: AppTextStyles.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection('MESSAGE', log.message),
                          _buildDetailSection(
                            'TYPE',
                            log.type.when(
                              general: () => 'GENERAL',
                              analytics: () => 'ANALYTICS',
                              event: () => 'EVENT',
                              performance: () => 'PERFORMANCE',
                              network: () => 'NETWORK',
                              security: () => 'SECURITY',
                              exception: () => 'EXCEPTION',
                              crash: () => 'CRASH',
                              custom: (name) => name.toUpperCase(),
                            ),
                          ),
                          _buildDetailSection(
                            'LEVEL',
                            log.level.toString().split('.').last.toUpperCase(),
                          ),
                          _buildDetailSection(
                            'TIMESTAMP',
                            log.timestamp.toIso8601String(),
                          ),

                          if (log.stackTrace != null)
                            _buildDetailSection(
                              'STACK TRACE',
                              log.stackTrace,
                              isCode: true,
                            ),

                          if (log.metadata.isNotEmpty)
                            _buildDetailSection(
                              'METADATA',
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(log.metadata),
                              isCode: true,
                            ),

                          if (log.device != null)
                            _buildDetailSection(
                              'DEVICE INFO',
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(log.device!.toJson()),
                              isCode: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String label,
    String? content, {
    bool isCode = false,
  }) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          if (isCode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: SelectableText(
                content,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  height: 1.5,
                ),
              ),
            )
          else
            SelectableText(
              content,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
        ],
      ),
    );
  }
}
