import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models/log_event.dart';
import 'models/device_metadata.dart';
import 'device_info_collector.dart';

class Telling {
  static final Telling _instance = Telling._internal();
  static Telling get instance => _instance;

  String? _apiKey;
  String _baseUrl = 'https://api.telling.dev/v1/logs'; // Placeholder
  bool _initialized = false;
  DeviceMetadata? _deviceMetadata;
  
  // Simple buffer to avoid spamming network
  final List<LogEvent> _buffer = [];
  Timer? _flushTimer;

  Telling._internal();

  /// Initialize the Telling SDK
  Future<void> init(String apiKey, {String? baseUrl}) async {
    _apiKey = apiKey;
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    _initialized = true;
    
    // Collect device metadata
    _deviceMetadata = await DeviceInfoCollector.collect();
    
    _startFlushTimer();
    print('Telling SDK Initialized');
  }

  /// Enable automatic crash reporting
  void enableCrashReporting() {
    if (!_initialized) {
      print('Telling SDK not initialized. Call Telling.instance.init() first.');
      return;
    }
    
    // Catch Flutter framework errors
    FlutterError.onError = (details) {
      print('Telling: CAUGHT FLUTTER ERROR: ${details.exception}');
      log(
        'Crash: ${details.exception}',
        level: LogLevel.error,
        error: details.exception,
        stackTrace: details.stack,
        type: LogType.error,
      );
      
      // Pass to original handler if it exists (e.g. to print to console)
      FlutterError.presentError(details);
    };
    
    // Catch async platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Telling: CAUGHT ASYNC ERROR: $error');
      log(
        'Async Crash: $error',
        level: LogLevel.error,
        error: error,
        stackTrace: stack,
        type: LogType.error,
      );
      return true; // Prevent app crash
    };
    
    print('Telling Crash Reporting Enabled');
  }

  /// Track an analytics event
  void event(String name, {Map<String, dynamic>? properties}) {
    log(
      name,
      level: LogLevel.info,
      metadata: properties,
      type: LogType.analytics,
    );
  }

  /// Log a message
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
    LogType type = LogType.log,
  }) {
    if (!_initialized) {
      print('Telling SDK not initialized. Call Telling.instance.init() first.');
      return;
    }

    final event = LogEvent(
      type: type,
      level: level,
      message: message,
      timestamp: DateTime.now(),
      stackTrace: stackTrace?.toString() ?? (error is Error ? error.stackTrace?.toString() : null),
      metadata: metadata,
      deviceMetadata: _deviceMetadata,
    );

    _buffer.add(event);
    
    // If error, flush immediately
    if (level == LogLevel.error) {
      _flush();
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flush());
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;

    final eventsToSend = List<LogEvent>.from(_buffer);
    _buffer.clear();

    try {
      // Batch sending
      print('Telling: Sending ${eventsToSend.length} logs to $_baseUrl');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
        },
        body: jsonEncode(eventsToSend.map((e) => e.toJson()).toList()),
      );
      
      if (response.statusCode != 200) {
        print('Telling: Failed to send logs. Status: ${response.statusCode}');
        // In a real app, we might retry or persist to disk
      }
      
    } catch (e) {
      print('Telling: Failed to send logs: $e');
      // Restore buffer on failure? Or just drop?
      // For now, drop to avoid memory leaks if backend is down
    }
  }
  
  void dispose() {
    _flushTimer?.cancel();
  }
}
