import 'device_metadata.dart';

enum LogLevel {
  info,
  warning,
  error,
}

enum LogType {
  log,
  error,
  analytics,
}

class LogEvent {
  final LogType type;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final DeviceMetadata? deviceMetadata;

  LogEvent({
    this.type = LogType.log,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
    this.deviceMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'level': level.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (metadata != null) 'metadata': metadata,
      if (deviceMetadata != null) 'device': deviceMetadata!.toJson(),
    };
  }
}
