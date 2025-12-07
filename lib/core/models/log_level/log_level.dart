import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_level.freezed.dart';
part 'log_level.g.dart';

@freezed
abstract class LogLevel with _$LogLevel {
  const factory LogLevel.trace() = _Trace;
  const factory LogLevel.debug() = _Debug;
  const factory LogLevel.info() = _Info;
  const factory LogLevel.warning() = _Warning;
  const factory LogLevel.error() = _Error;
  const factory LogLevel.fatal() = _Fatal;

  factory LogLevel.fromJson(Map<String, dynamic> json) => _$LogLevelFromJson(json);
  
  static LogLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'trace':
        return const LogLevel.trace();
      case 'debug':
        return const LogLevel.debug();
      case 'info':
        return const LogLevel.info();
      case 'warning':
        return const LogLevel.warning();
      case 'error':
        return const LogLevel.error();
      case 'fatal':
        return const LogLevel.fatal();
      default:
        return const LogLevel.info();
    }
  }
}

@freezed
abstract class LogType with _$LogType {
  const factory LogType.general() = _General;
  const factory LogType.analytics() = _Analytics;
  const factory LogType.crash() = _Crash;
  const factory LogType.performance() = _Performance;

  factory LogType.fromJson(Map<String, dynamic> json) => _$LogTypeFromJson(json);
  
  /// Parse LogType with backward compatibility for deprecated types
  static LogType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'general':
      case 'log': // Legacy
      case 'error': // Legacy (the type, not level)
      case 'errorr': // Legacy typo
      case 'network': // Deprecated → general
      case 'security': // Deprecated → general
      case 'custom': // Deprecated → general
        return const LogType.general();
      case 'analytics':
      case 'event': // Deprecated → analytics
        return const LogType.analytics();
      case 'crash':
      case 'exception': // Deprecated → crash
        return const LogType.crash();
      case 'performance':
        return const LogType.performance();
      default:
        return const LogType.general();
    }
  }
}
