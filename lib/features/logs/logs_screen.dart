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
import 'widgets/log_details_dialog.dart';

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
          child: _buildLogsList(logsAsync, ref, isMobile, horizontalPadding),
        ),
      ],
    );
  }

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
                  backgroundColor: page > 1
                      ? AppColors.white
                      : AppColors.darkSlate,
                  foregroundColor: page > 1
                      ? AppColors.primary
                      : AppColors.slate,
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
                  backgroundColor: hasMore
                      ? AppColors.white
                      : AppColors.darkSlate,
                  foregroundColor: hasMore
                      ? AppColors.primary
                      : AppColors.slate,
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
      onTap: () => LogDetailsDialog.show(context, log),
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
                  child: Icon(log.icon, color: color, size: 20),
                ),
              )
            else
              Icon(log.icon, color: color, size: 18),
            SizedBox(width: isMobile ? 8 : 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.message.toUpperCase(),
                    style:
                        (isMobile
                                ? AppTextStyles.labelSmall
                                : AppTextStyles.labelLarge)
                            .copyWith(color: AppColors.white),
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
                                '${log.device!.platform} :: ${log.device!.deviceModel}'
                                    .toUpperCase(),
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
                                  '${log.device!.platform} :: ${log.device!.deviceModel}'
                                      .toUpperCase(),
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
}
