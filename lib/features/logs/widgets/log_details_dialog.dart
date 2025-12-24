import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/extensions/responsive_extension.dart';
import '../../../core/models/log_level/log_level.dart';
import '../../../core/models/log_model/log_model.dart';
import '../../../core/models/stack_trace_frame/stack_trace_frame.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A reusable dialog widget that displays detailed information about a log entry.
/// 
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => LogDetailsDialog(log: logModel),
/// );
/// ```
/// 
/// Or use the static helper:
/// ```dart
/// LogDetailsDialog.show(context, logModel);
/// ```
class LogDetailsDialog extends StatelessWidget {
  final LogModel log;

  const LogDetailsDialog({super.key, required this.log});

  /// Convenience method to show the dialog
  static void show(BuildContext context, LogModel log) {
    showDialog(
      context: context,
      builder: (_) => LogDetailsDialog(log: log),
    );
  }

  Color _getLevelColor() {
    return log.level.when(
      trace: () => AppColors.slate.withAlpha(179),
      debug: () => AppColors.slate,
      info: () => Colors.blue,
      warning: () => Colors.orange,
      error: () => AppColors.error,
      fatal: () => Colors.red,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final date =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  String _formatFullLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== LOG DETAILS ===');
    buffer.writeln('ID: ${log.id}');
    buffer.writeln(
      'Level: ${log.level.toString().split('.').last.toUpperCase()}',
    );
    buffer.writeln(
      'Type: ${log.type.when(general: () => 'GENERAL', analytics: () => 'ANALYTICS', crash: () => 'CRASH', performance: () => 'PERFORMANCE')}',
    );
    buffer.writeln('Timestamp: ${log.timestamp.toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Message: ${log.message}');

    if (log.device != null) {
      buffer.writeln('');
      buffer.writeln('=== DEVICE INFO ===');
      buffer.writeln('Platform: ${log.device!.platform}');
      buffer.writeln('Model: ${log.device!.deviceModel}');
      if (log.device!.osVersion != null) {
        buffer.writeln('OS Version: ${log.device!.osVersion}');
      }
      if (log.device!.appVersion != null) {
        buffer.writeln('App Version: ${log.device!.appVersion}');
      }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final color = _getLevelColor();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: isMobile ? screenWidth : 850,
        constraints: BoxConstraints(
          maxHeight: isMobile ? screenHeight * 0.9 : screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1),
          color: AppColors.backgroundDark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with level indicator
            _buildHeader(context, isMobile, color),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Section
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

                    // Stack Trace - structured frames if available, raw fallback
                    if ((log.stackTrace != null &&
                            log.stackTrace!.isNotEmpty) ||
                        log.stackTraceElements != null) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      _buildDetailCard(
                        label: 'STACK TRACE',
                        child: log.stackTraceElements != null
                            ? _buildStructuredStackTrace(
                                log.stackTraceElements!,
                                isMobile,
                              )
                            : _buildRawStackTrace(log.stackTrace!, isMobile),
                        isMobile: isMobile,
                        isError: true,
                      ),
                    ],

                    // Breadcrumbs
                    if (log.metadata['breadcrumbs'] != null &&
                        log.metadata['breadcrumbs'] is List &&
                        (log.metadata['breadcrumbs'] as List).isNotEmpty) ...[
                      SizedBox(height: isMobile ? 12 : 16),
                      _buildBreadcrumbsSection(isMobile),
                    ],

                    // Metadata
                    if (log.metadata.isNotEmpty) _buildMetadataSection(isMobile),
                  ],
                ),
              ),
            ),

            // Footer with actions
            _buildFooter(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, Color color) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: const BorderSide(color: AppColors.primary),
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
                crash: () => 'CRASH',
                performance: () => 'PERFORMANCE',
              ),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 10 : 13,
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
    );
  }

  Widget _buildBreadcrumbsSection(bool isMobile) {
    return _buildDetailCard(
      label: 'ACTIVITY TRAIL (BREADCRUMBS)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final breadcrumb in (log.metadata['breadcrumbs'] as List).reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: isMobile ? 14 : 16,
                    color: AppColors.slate,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (breadcrumb['message'] ?? 'Unknown').toString(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white,
                            fontSize: isMobile ? 11 : 14,
                          ),
                        ),
                        if (breadcrumb['timestamp'] != null)
                          Text(
                            breadcrumb['timestamp'].toString().substring(11, 19),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.slate,
                              fontSize: isMobile ? 9 : 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      isMobile: isMobile,
    );
  }

  Widget _buildMetadataSection(bool isMobile) {
    // Filter out breadcrumbs and stackTraceElements from metadata display
    // (they have their own dedicated UI sections)
    final displayMetadata = Map<String, dynamic>.from(log.metadata)
      ..remove('breadcrumbs')
      ..remove('stackTraceElements');
    if (displayMetadata.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
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
              const JsonEncoder.withIndent('  ').convert(displayMetadata),
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: isMobile ? 10 : 14,
                color: AppColors.secondary,
                height: 1.5,
              ),
            ),
          ),
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
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
              context: context,
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
              context: context,
              icon: Icons.file_copy_outlined,
              label: isMobile ? 'COPY ALL' : 'COPY FULL LOG',
              onTap: () {
                final fullLog = _formatFullLog();
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
    );
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
        border: Border.all(
          color: isError ? AppColors.error.withAlpha(77) : AppColors.slate.withAlpha(51),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isError ? AppColors.error.withAlpha(13) : AppColors.backgroundDark,
              border: Border(
                bottom: BorderSide(
                  color: isError ? AppColors.error.withAlpha(51) : AppColors.slate.withAlpha(51),
                ),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isError ? AppColors.error : AppColors.slate,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 10 : 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(padding: EdgeInsets.all(isMobile ? 10 : 12), child: child),
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
                    fontSize: isMobile ? 9 : 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontSize: isMobile ? 11 : 14,
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
                fontSize: isMobile ? 9 : 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontSize: isMobile ? 11 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
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

  /// Renders structured stack trace frames as a list
  Widget _buildStructuredStackTrace(
    List<StackTraceFrame> frames,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < frames.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < frames.length - 1 ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frame index
                  SizedBox(
                    width: isMobile ? 24 : 32,
                    child: Text(
                      '#$i',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: isMobile ? 10 : 13,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                  // Frame details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Method name (class.method or just method)
                        SelectableText(
                          frames[i].displayName,
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: isMobile ? 11 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error.withAlpha(230),
                          ),
                        ),
                        // File:line
                        SelectableText(
                          '${frames[i].shortFile}:${frames[i].line}',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: isMobile ? 9 : 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Renders raw stack trace as a monospace text block (fallback)
  Widget _buildRawStackTrace(String stackTrace, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SelectableText(
        stackTrace,
        style: TextStyle(
          fontFamily: 'Urbanist',
          fontSize: isMobile ? 10 : 14,
          color: AppColors.error.withAlpha(204),
          height: 1.5,
        ),
      ),
    );
  }
}
