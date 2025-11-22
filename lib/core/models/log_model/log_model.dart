import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../log_level/log_level.dart';
import '../device_info/device_info.dart';

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
    );
  }
}


extension LogModelX on LogModel {
  IconData get icon {
    return type.when(
      general: () => Icons.info,
      analytics: () => Icons.analytics,
      event: () => Icons.event,
      performance: () => Icons.speed, // or Icons.show_chart, Icons.timer
      network: () => Icons.wifi, // or Icons.cloud, Icons.lan
      security: () => Icons.security,
      custom: (name) => Icons.info,
    );
  }
}
