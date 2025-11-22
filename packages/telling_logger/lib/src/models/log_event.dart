import 'device_metadata.dart';

enum LogLevel { debug, info, warning, error, fatal }

enum LogType { log, error, analytics, event, performance, network, custom }

class LogEvent {
  final String id;
  final LogType type;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final DeviceMetadata? deviceMetadata;

  LogEvent({
    String? id,
    this.type = LogType.log,
    required this.level,
    required this.message,
    required this.timestamp,
    this.stackTrace,
    this.metadata,
    this.deviceMetadata,
  }) : id =
           id ??
           DateTime.now().millisecondsSinceEpoch
               .toString(); // Simple ID for now

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
