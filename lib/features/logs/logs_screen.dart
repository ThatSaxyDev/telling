import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/log_model/log_model.dart';
import '../../core/models/log_level/log_level.dart';
import '../../core/providers/logs_provider.dart';
import '../../core/providers/filtered_logs_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';
import '../../shared/widgets/military_loader.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/log_filter_bar.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  Color _getLevelColor(LogLevel level) {
    return level.when(
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
    final logsAsync = ref.watch(filteredLogsProvider);

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
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: GlitchText(
                        text: 'LOGS EXPLORER',
                        style: AppTextStyles.headlineSmall,
                        glitchAmount: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AppButton(
                text: isMobile ? '' : 'REFRESH',
                icon: Icons.refresh,
                isOutlined: true,
                onPressed: () => ref.refresh(logsProvider),
                width: isMobile ? 48 : null,
                height: isMobile ? 48 : null,
                padding: isMobile ? EdgeInsets.zero : null,
              ),
            ],
          ),
        ),

        // Filter Bar
        const LogFilterBar(),

        // Content
        Expanded(
          child: logsAsync.when(
            loading: () =>
                const Center(child: MilitaryLoader(label: 'SCANNING LOGS...')),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ERROR LOADING LOGS',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate,
                    ),
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
                      // Logs List
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          itemCount: logs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _buildLogItem(context, log);
                          },
                        ),
                      ),

                      // Pagination Controls
                      _buildPaginationControls(ref),
                    ],
                  ),
          ),
        ),
      ],
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
          top: BorderSide(color: AppColors.white.withOpacity(0.1), width: 1),
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
              border: Border.all(color: AppColors.white.withOpacity(0.2)),
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
          border: Border.all(color: AppColors.slate.withOpacity(0.3)),
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
                  log.type.maybeWhen(
                    errorr: () => Icons.warning_amber,
                    orElse: () => Icons.info_outline,
                  ),
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
                color: AppColors.backgroundDark.withOpacity(0.95),
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
                              log: () => 'LOG',
                              errorr: () => 'ERROR',
                              analytics: () => 'ANALYTICS',
                              event: () => 'EVENT',
                              performance: () => 'PERFORMANCE',
                              network: () => 'NETWORK',
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
              child: Text(
                content,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.slate,
                  height: 1.5,
                ),
              ),
            )
          else
            Text(
              content,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
        ],
      ),
    );
  }
}
