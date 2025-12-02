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
import '../../core/extensions/responsive_extension.dart';
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
    final isMobile = context.isMobile;
    final isSessionGrouped = ref.watch(isSessionGroupedProvider);
    final logsAsync = ref.watch(filteredLogsProvider);
    // final sessionsAsync = ref.watch(sessionsProvider);
    
    // Responsive padding
    final horizontalPadding = context.responsive<double>(
      mobile: 12.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isMobile ? 12.0 : 24.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: AppColors.slate,
                      size: isMobile ? 24 : 32,
                    ),
                    SizedBox(width: isMobile ? 8 : 16),
                    Flexible(
                      child: GlitchText(
                        text: 'LOGS EXPLORER',
                        style: isMobile
                            ? AppTextStyles.titleSmall
                            : AppTextStyles.headlineSmall,
                        glitchAmount: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
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
                    width: isMobile ? 36 : null,
                    height: isMobile ? 36 : null,
                    padding: isMobile ? EdgeInsets.zero : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Bar (only show if not grouped, or adapt it)
        if (!isSessionGrouped) const LogFilterBar(),

        // Content
        Expanded(
          child:
              // isSessionGrouped
              //     ? _buildSessionsList(sessionsAsync)
              //     :
              _buildLogsList(logsAsync, ref, isMobile, horizontalPadding),
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

  Widget _buildLogsList(
    AsyncValue<List<LogModel>> logsAsync,
    WidgetRef ref,
    bool isMobile,
    double horizontalPadding,
  ) {
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
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isMobile ? 8 : 12,
                    ),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: isMobile ? 8 : 12),
                    itemBuilder: (context, index) =>
                        _buildLogItem(context, logs[index], isMobile),
                  ),
                ),
                _buildPaginationControls(ref, isMobile),
              ],
            ),
    );
  }

  Widget _buildPaginationControls(WidgetRef ref, bool isMobile) {
    final notifier = ref.read(logsProvider.notifier);
    final page = notifier.page;
    final hasMore = notifier.hasMore;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 6 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.white.withAlpha(26), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button - icon only on mobile
          isMobile
              ? _buildCompactNavButton(
                  icon: Icons.chevron_left,
                  onPressed: page > 1 ? () => notifier.previousPage() : null,
                  isEnabled: page > 1,
                )
              : AppButton(
                  text: 'PREVIOUS',
                  onPressed: page > 1 ? () => notifier.previousPage() : null,
                  backgroundColor: page > 1 ? AppColors.white : AppColors.darkSlate,
                  foregroundColor: page > 1 ? AppColors.primary : AppColors.slate,
                  width: 160,
                  height: 48,
                ),

          SizedBox(width: isMobile ? 12 : 16),

          // Page Indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 16,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white.withAlpha(51)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isMobile ? '$page' : 'PAGE $page',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: isMobile ? 0 : 1.5,
              ),
            ),
          ),

          SizedBox(width: isMobile ? 12 : 16),

          // Next Button - icon only on mobile
          isMobile
              ? _buildCompactNavButton(
                  icon: Icons.chevron_right,
                  onPressed: hasMore ? () => notifier.nextPage() : null,
                  isEnabled: hasMore,
                )
              : AppButton(
                  text: 'NEXT',
                  onPressed: hasMore ? () => notifier.nextPage() : null,
                  backgroundColor: hasMore ? AppColors.white : AppColors.darkSlate,
                  foregroundColor: hasMore ? AppColors.primary : AppColors.slate,
                  width: 160,
                  height: 48,
                ),
        ],
      ),
    );
  }

  Widget _buildCompactNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: isEnabled ? AppColors.white : AppColors.darkSlate,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.primary : AppColors.slate,
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogModel log, bool isMobile) {
    final color = _getLevelColor(log.level);

    return MilitaryHoverContainer(
      onTap: () => _showLogDetails(context, log),
      baseColor: AppColors.tertiary,
      hoverColor: AppColors.white,
      showGrid: false,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
        ),
        child: Row(
          children: [
            // Color indicator bar
            Container(width: 3, height: isMobile ? 32 : 40, color: color),
            SizedBox(width: isMobile ? 8 : 16),

            // Icon with brackets (hide on very small screens)
            if (!isMobile)
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
              )
            else
              Icon(
                log.icon,
                color: color,
                size: 18,
              ),
            SizedBox(width: isMobile ? 8 : 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message.toUpperCase(),
                    style: (isMobile ? AppTextStyles.labelSmall : AppTextStyles.labelLarge).copyWith(
                      color: AppColors.white,
                    ),
                    maxLines: isMobile ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  // On mobile, show timestamp and device on separate lines or wrap
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.slate,
                                fontSize: 10,
                              ),
                            ),
                            if (log.device != null)
                              Text(
                                '${log.device!.platform} :: ${log.device!.deviceModel}'.toUpperCase(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.slate,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        )
                      : Row(
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
                              Flexible(
                                child: Text(
                                  '${log.device!.platform} :: ${log.device!.deviceModel}'.toUpperCase(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.slate,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),

            // Actions - simplified on mobile
            if (!isMobile)
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
            SizedBox(width: isMobile ? 4 : 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.slate,
              size: isMobile ? 18 : 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetails(BuildContext context, LogModel log) {
    final isMobile = context.isMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final color = _getLevelColor(log.level);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 40,
          vertical: isMobile ? 16 : 40,
        ),
        child: Container(
          width: isMobile ? screenWidth : 650,
          constraints: BoxConstraints(
            maxHeight: isMobile ? screenHeight * 0.9 : 800,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1),
            color: AppColors.backgroundDark,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with level indicator
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(
                    bottom: BorderSide(color: AppColors.primary),
                    left: BorderSide(color: color, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    // Level badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(26),
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(log.icon, color: color, size: isMobile ? 14 : 16),
                          SizedBox(width: isMobile ? 4 : 8),
                          Text(
                            log.level.toString().split('.').last.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    // Type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(26),
                        border: Border.all(color: AppColors.secondary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
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
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Close button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: AppColors.slate,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message Section - prominent
                      _buildDetailCard(
                        label: 'MESSAGE',
                        child: SelectableText(
                          log.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            height: 1.5,
                          ),
                        ),
                        isMobile: isMobile,
                      ),
                      
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Timestamp & ID Row
                      isMobile
                          ? Column(
                              children: [
                                _buildInfoTile(
                                  icon: Icons.access_time,
                                  label: 'TIMESTAMP',
                                  value: _formatTimestamp(log.timestamp),
                                  isMobile: isMobile,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoTile(
                                  icon: Icons.tag,
                                  label: 'LOG ID',
                                  value: log.id,
                                  isMobile: isMobile,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    icon: Icons.access_time,
                                    label: 'TIMESTAMP',
                                    value: _formatTimestamp(log.timestamp),
                                    isMobile: isMobile,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoTile(
                                    icon: Icons.tag,
                                    label: 'LOG ID',
                                    value: log.id,
                                    isMobile: isMobile,
                                  ),
                                ),
                              ],
                            ),

                      // Device Info
                      if (log.device != null) ...[
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildDetailCard(
                          label: 'DEVICE INFO',
                          child: Column(
                            children: [
                              _buildDeviceInfoRow('Platform', log.device!.platform, isMobile),
                              _buildDeviceInfoRow('Model', log.device!.deviceModel, isMobile),
                              if (log.device!.osVersion != null)
                                _buildDeviceInfoRow('OS Version', log.device!.osVersion!, isMobile),
                              if (log.device!.appVersion != null)
                                _buildDeviceInfoRow('App Version', log.device!.appVersion!, isMobile),
                            ],
                          ),
                          isMobile: isMobile,
                        ),
                      ],

                      // Stack Trace
                      if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildDetailCard(
                          label: 'STACK TRACE',
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableText(
                              log.stackTrace!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: isMobile ? 10 : 12,
                                color: AppColors.error.withAlpha(204),
                                height: 1.4,
                              ),
                            ),
                          ),
                          isMobile: isMobile,
                          isError: true,
                        ),
                      ],

                      // Metadata
                      if (log.metadata.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 12 : 16),
                        _buildDetailCard(
                          label: 'METADATA',
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableText(
                              const JsonEncoder.withIndent('  ').convert(log.metadata),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: isMobile ? 10 : 12,
                                color: AppColors.secondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          isMobile: isMobile,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer with actions
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(
                    top: BorderSide(color: AppColors.slate.withAlpha(77)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.copy,
                        label: isMobile ? 'COPY' : 'COPY MESSAGE',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: log.message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'MESSAGE COPIED',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
                              ),
                              backgroundColor: AppColors.darkSlate,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.file_copy_outlined,
                        label: isMobile ? 'COPY ALL' : 'COPY FULL LOG',
                        onTap: () {
                          final fullLog = _formatFullLog(log);
                          Clipboard.setData(ClipboardData(text: fullLog));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'FULL LOG COPIED',
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
                              ),
                              backgroundColor: AppColors.darkSlate,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final date = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  String _formatFullLog(LogModel log) {
    final buffer = StringBuffer();
    buffer.writeln('=== LOG DETAILS ===');
    buffer.writeln('ID: ${log.id}');
    buffer.writeln('Level: ${log.level.toString().split('.').last.toUpperCase()}');
    buffer.writeln('Type: ${log.type.when(
      general: () => 'GENERAL',
      analytics: () => 'ANALYTICS',
      event: () => 'EVENT',
      performance: () => 'PERFORMANCE',
      network: () => 'NETWORK',
      security: () => 'SECURITY',
      exception: () => 'EXCEPTION',
      crash: () => 'CRASH',
      custom: (name) => name.toUpperCase(),
    )}');
    buffer.writeln('Timestamp: ${log.timestamp.toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Message: ${log.message}');
    
    if (log.device != null) {
      buffer.writeln('');
      buffer.writeln('=== DEVICE INFO ===');
      buffer.writeln('Platform: ${log.device!.platform}');
      buffer.writeln('Model: ${log.device!.deviceModel}');
      if (log.device!.osVersion != null) buffer.writeln('OS Version: ${log.device!.osVersion}');
      if (log.device!.appVersion != null) buffer.writeln('App Version: ${log.device!.appVersion}');
    }
    
    if (log.stackTrace != null) {
      buffer.writeln('');
      buffer.writeln('=== STACK TRACE ===');
      buffer.writeln(log.stackTrace);
    }
    
    if (log.metadata.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== METADATA ===');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(log.metadata));
    }
    
    return buffer.toString();
  }

  Widget _buildDetailCard({
    required String label,
    required Widget child,
    required bool isMobile,
    bool isError = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: isError ? AppColors.error.withAlpha(77) : AppColors.slate.withAlpha(51)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isError ? AppColors.error.withAlpha(13) : AppColors.backgroundDark,
              border: Border(
                bottom: BorderSide(color: isError ? AppColors.error.withAlpha(51) : AppColors.slate.withAlpha(51)),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isError ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 10 : 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Card content
          Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.slate.withAlpha(51)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 16 : 18, color: AppColors.slate),
          SizedBox(width: isMobile ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.slate,
                    fontSize: isMobile ? 9 : 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.slate,
                fontSize: isMobile ? 9 : 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Material(
      color: AppColors.backgroundDark,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate.withAlpha(77)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isMobile ? 14 : 16, color: AppColors.slate),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  fontSize: isMobile ? 10 : 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
