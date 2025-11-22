import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_level.freezed.dart';
part 'log_level.g.dart';

@freezed
abstract class LogLevel with _$LogLevel {
  const factory LogLevel.debug() = _Debug;
  const factory LogLevel.info() = _Info;
  const factory LogLevel.warning() = _Warning;
  const factory LogLevel.error() = _Error;
  const factory LogLevel.fatal() = _Fatal;

  factory LogLevel.fromJson(Map<String, dynamic> json) => _$LogLevelFromJson(json);
  
  static LogLevel fromString(String level) {
    switch (level.toLowerCase()) {
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
  const factory LogType.log() = _Log;
  const factory LogType.errorr() = _Errorr;
  const factory LogType.analytics() = _Analytics;
  const factory LogType.event() = _Event;
  const factory LogType.performance() = _Performance;
  const factory LogType.network() = _Network;
  const factory LogType.custom(String name) = _Custom;

  factory LogType.fromJson(Map<String, dynamic> json) => _$LogTypeFromJson(json);
  
  static LogType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'log':
        return const LogType.log();
      case 'error':
        return const LogType.errorr();
      case 'analytics':
        return const LogType.analytics();
      case 'event':
        return const LogType.event();
      case 'performance':
        return const LogType.performance();
      case 'network':
        return const LogType.network();
      default:
        return LogType.custom(type);
    }
  }
}
