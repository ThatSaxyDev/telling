import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telling/core/theme/app_colors.dart';
import '../log_level/log_level.dart';
import '../device_info/device_info.dart';
import '../log_entry.dart';
import '../stack_trace_frame/stack_trace_frame.dart';

part 'log_model.freezed.dart';
// part 'log_model.g.dart';

@freezed
abstract class LogModel with _$LogModel {
  const factory LogModel({
    required String id,
    required String message,
    required LogLevel level,
    required LogType type,
    required DateTime timestamp,
    String? stackTrace,
    @Default({}) Map<String, dynamic> metadata,
    DeviceInfo? device,
    String? userId,
    String? userName,
    String? userEmail,
  }) = _LogModel;

  factory LogModel.fromJson(Map<String, dynamic> json) {
    // Handle raw API response format
    return LogModel(
      id: json['id']?.toString() ?? '',
      message: json['message'] as String? ?? '',
      level: json['level'] != null 
          ? LogLevel.fromString(json['level'] as String)
          : const LogLevel.info(),
      type: json['type'] != null
          ? LogType.fromString(json['type'] as String)
          : const LogType.general(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      device: json['device'] != null
          ? DeviceInfo.fromJson(json['device'] as Map<String, dynamic>)
          : null,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }

  /// Convert a LogEntry to LogModel for use with LogDetailsDialog
  factory LogModel.fromLogEntry(LogEntry entry) {
    return LogModel(
      id: entry.id.toString(),
      message: entry.message,
      level: LogLevel.fromString(entry.level),
      type: LogType.fromString(entry.type),
      timestamp: entry.timestamp,
      stackTrace: entry.stackTrace,
      metadata: entry.metadata ?? {},
      device: entry.device != null ? DeviceInfo.fromJson(entry.device!) : null,
      userId: entry.userId,
      userName: entry.userName,
      userEmail: entry.userEmail,
    );
  }
}


extension LogModelX on LogModel {
  IconData get icon {
    return type.when(
      general: () => Icons.info,
      analytics: () => Icons.analytics,
      crash: () => Icons.dangerous,
      performance: () => Icons.speed,
    );
  }

  Color get getLevelColor {
    switch (level) {
      case LogLevel.fatal:
        return Colors.red.shade900;
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return AppColors.white;
      case LogLevel.debug:
        return AppColors.primary;
      case LogLevel.trace:
        return AppColors.slate;
      default:
        return AppColors.slate;
    }
  }

  /// Parsed structured stack trace frames from metadata.
  /// Returns null if not available (fallback to raw stackTrace).
  List<StackTraceFrame>? get stackTraceElements {
    final elements = metadata['stackTraceElements'];
    if (elements == null || elements is! List) return null;

    try {
      return elements
          .cast<Map<String, dynamic>>()
          .map((e) => StackTraceFrame.fromJson(e))
          .toList();
    } catch (_) {
      return null;
    }
  }
}


